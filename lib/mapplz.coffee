geolib = require 'geolib'
csv = require 'fast-csv'
MapItem = require './mapitem'

class MapPLZ
  constructor: ->
    @mapitems = []
    @database = null

  add: (param1, param2, param3, param4) ->
    @mapitems = [] unless @mapitems
    @database = null unless @database

    callback = (err, items) ->
    callback = param2 if typeof param2 == "function"
    callback = param3 if typeof param3 == "function"
    callback = param4 if typeof param4 == "function"

    # try for lat, lng point
    lat = param1 * 1
    lng = param2 * 1
    unless isNaN(lat) or isNaN(lng)
      pt = MapPLZ.standardize({ lat: lat, lng: lng })
      pt.type = "point"

      if param3 != null
        # allow JSON string of properties
        if typeof param3 == 'string'
          try
            pt.properties = JSON.parse param3
          catch

        if @isArray param3
          # array
          pt.properties = { property: param3 }
        else if typeof param3 == 'object'
          # object
          for key in Object.keys(param3)
            pt.properties[key] = param3[key]
        else if typeof param3 != 'function'
          # string, number, or other singular property
          pt.properties = { property: param3 }

      @save pt, callback
      return

    if typeof param1 == 'string'
      # try JSON parse
      try
        param1 = JSON.parse param1
        if @isGeoJson param1
          result = @addGeoJson param1, callback
          @save result, callback if result
          return
      catch
        if param1[param1.length-1] == ')' and (param1.indexOf 'POINT' == 0 or param1.indexOf 'LINESTRING' == 0 or param1.indexOf 'POLYGON' == 0)
          # try WKT
          contents = ''
          if param1.indexOf('POINT') == 0
            contents = param1.replace('POINT', '').replace('(', '').replace(')', '').trim().split(' ').reverse()
          else if param1.indexOf('LINESTRING') == 0
            pts = param1.replace('LINESTRING', '').replace('(', '').replace(')', '').split(',')
            contents = []
            for pt in pts
              contents.push pt.trim().split(' ').reverse()
          else if param1.indexOf('POLYGON') == 0
            pts = param1.replace('POLYGON', '').replace('(', '').replace(')', '').replace('(', '').replace(')', '').split(',')
            contents = []
            for pt in pts
              contents.push pt.trim().split(' ').reverse()

          @add contents, param2 or callback, callback
          return

        if (param1.indexOf('map') > -1) and (param1.indexOf('plz') > -1)
          # try mapplz code
          @process_code param1, callback
          return

        else
          # try CSV
          callbacks = 0
          contents = []

          records = 0
          finished = false

          csv.fromString(param1, { headers: true })
            .on('record', (data) =>
              records++
              if data.geo or data.geom or data.wkt
                @add (data.geo or data.geom or data.wkt), data, (err, item) ->
                  contents.push item unless err
                  callback(err, contents) if finished and contents.length == records
              else
                @add data, (err, item) ->
                  contents.push item unless err
                  callback(err, contents) if finished and contents.length == records
            )
            .on('end', ->
              finished = true
              callback(null, contents) if contents.length == records
            )
          return

    if @isArray param1
      # param1 is an array

      if param1.length >= 2
        lat = param1[0] * 1
        lng = param1[1] * 1
        unless isNaN(lat) or isNaN(lng)
          result = MapPLZ.standardize { lat: lat, lng: lng }
          result.type = 'point'
          for prop in param1.slice(2)
            if typeof prop == 'string'
              try
                prop = JSON.parse prop
              catch
                prop = prop

            if typeof prop == 'object'
              for key in Object.keys(prop)
                result.properties[key] = prop[key]
            else if typeof prop != 'function'
              result.properties = { property: prop }

          @save result, callback
          return

      if typeof param1[0] == 'object'
        if @isArray param1[0]
          # param1 contains an array of arrays - probably coordinates
          if @isArray param1[0][0]
            # polygon
            result = MapPLZ.standardize({ path: param1 })
            result.type = 'polygon'
          else
            # line
            result = MapPLZ.standardize({ path: param1 })
            result.type = 'line'

          if result and param2
            # try JSON parsing
            if typeof param2 == 'string'
              try
                param2 = JSON.parse param2
              catch
                param2 = param2

            if typeof param2 == 'object'
              if @isArray param2
                result.properties = { property: param2 }
              else
                result.properties = param2
            else if typeof param2 != 'function'
              result.properties = { property: param2 }

          @save result, callback
          return
        else
          # param1 contains an array of objects to add
          results = []
          for obj in param1
            results.push @add(obj)
          @save results, callback
          return


    else if typeof param1 == 'object'
      # regular object
      if param1.lat and param1.lng
        result = MapPLZ.standardize({ lat: param1.lat, lng: param1.lng })
        result.type = "point"
        for key in Object.keys(param1)
          result.properties[key] = param1[key] unless key == 'lat' or key == 'lng'
        @save result, callback
        return

      else if param1.path
        result = MapPLZ.standardize({ path: param1.path })
        if typeof param1.path[0][0] == 'object'
          result.type = 'polygon'
        else
          result.type = 'line'
        for key in Object.keys(param1)
          result.properties[key] = param1[key] unless key == 'path'

        @save result, callback
        return

      else if @isGeoJson param1
        results = @addGeoJson param1, callback
        @save results, callback if results
        return

  count: (query, callback) ->
    if @database
      @database.count(query, callback)
    else
      @query query, (err, results) ->
        callback(err, results.length)

  embed_html: (callback) ->
    @query '', (err, results) ->
      embed_code = '<div id="map"></div>\n'
      embed_code += '<link rel="stylesheet" type="text/css" href="http://cdn.leafletjs.com/leaflet-0.7.3/leaflet.css"/>\n'
      embed_code += '<script type="text/javascript" src="http://cdn.leafletjs.com/leaflet-0.7.3/leaflet.js"></script>\n'
      embed_code += '<script type="text/javascript">\n'
      embed_code += 'var map = L.map("map");\n'
      for result in results
        properties = {}
        properties["color"] = result.properties.color if result.properties.color
        properties["opacity"] = result.properties.opacity if typeof(result.properties.opacity) != "undefined"
        properties["fillColor"] = result.properties.fillColor if result.properties.fillColor
        properties["fillOpacity"] = result.properties.fillOpacity if typeof(result.properties.fillOpacity) != "undefined"
        properties["weight"] = result.properties.weight if typeof(result.properties.weight) != "undefined"
        properties["stroke"] = result.properties.stroke if result.properties.stroke

        if result.type == 'point'
          if result.properties.label or result.properties.popup
            embed_code += "L.marker([#{result.lat}, #{result.lng}]).bindPopup('#{result.properties.label or result.properties.popup}').addTo(map);\n"
          else
            embed_code += "L.marker([#{result.lat}, #{result.lng}], { clickable: false }).addTo(map);\n"
        else if result.type == 'line'
          if result.properties.label or result.properties.popup
            properties["clickable"] = true
            embed_code += "L.polyline(#{JSON.stringify(result.path)}, #{properties.to_json}).bindPopup('#{result.properties.label or result.properties.popup}').addTo(map);\n"
          else
            embed_code += "L.polyline(#{JSON.stringify(result.path)}).addTo(map);\n"
        else if result.type == 'polygon'
          if result.properties.label or result.properties.popup
            properties["clickable"] = true
            embed_code += "L.polygon(#{JSON.stringify(result.path)}, #{properties.to_json}).bindPopup('#{result.properties.label or result.properties.popup}').addTo(map);\n"
          else
            embed_code += "L.polygon(#{JSON.stringify(result.path)}).addTo(map);\n"
      embed_code += '</script>\n'
      callback(embed_code)

  render_html: (callback) ->
    @embed_html (embed_code) ->
      embed_page = '<!DOCTYPE html>\n<html>\n<head>\n<style>\nhtml, body, #map { width: 100%; height: 100%; padding: 0; margin: 0; }\n</style>\n</head>\n<body>\n'
      embed_page += embed_code
      embed_page += '</body>\n</html>\n'
      callback(embed_page)

  query: (query, callback) ->
    if @database
      @database.query(query, callback)
    else
      if query == null or query == ""
        callback(null, @mapitems)
      else
        results = []
        for mapitem in @mapitems
          if mapitem and mapitem.type != "deleted"
            match = true
            for key of query
              match = (mapitem.properties[key] == query[key])
              break unless match
            results.push mapitem if match
        callback(null, results)

  where: (query, callback) ->
    @query(query, callback)

  near: (neargeo, count, callback) ->
    nearpt = neargeo
    if @isArray(neargeo)
      nearpt = new MapItem
      nearpt.type = "point"
      nearpt.lat = neargeo[0]
      nearpt.lng = neargeo[1]
    else
      if typeof neargeo == 'string'
        neargeo = JSON.parse(neargeo)
      unless typeof neargeo.lat == "undefined" and typeof neargeo.lng == "undefined"
        nearpt = @addGeoJson(neargeo)

    if @database
      @database.near(nearpt, count, callback)
    else
      @query "", (err, items) ->
        centerpts = []
        for item in items
          center = item.center()
          centerpts.push { latitude: center.lat, longitude: center.lng }
        centerpts = geolib.orderByDistance({ latitude: nearpt.lat, longitude: nearpt.lng }, centerpts)
        for pt, p in centerpts
          centerpts[p] = items[p]
          break if p >= count
        callback(null, centerpts.slice(0, count))

  inside: (withingeo, callback) ->
    withinpoly = withingeo
    if @isArray(withingeo)
      withinpoly = new MapItem
      withinpoly.type = "polygon"
      withinpoly.path = withingeo
    else
      if typeof withingeo == 'string'
        withingeo = JSON.parse(withingeo)
      unless withingeo.path
        withinpoly = @addGeoJson(withingeo)

    if @database
      @database.inside(withinpoly, callback)
    else
      @query "", (err, items) ->
        withinpoly = withinpoly.path[0]
        for pt, p in withinpoly
          withinpoly[p] = { latitude: pt[0], longitude: pt[1] }
        results = []
        for item in items
          center = item.center()
          if geolib.isPointInside({ latitude: center.lat, longitude: center.lng }, withinpoly)
            results.push item
        callback(null, results)

  save: (items, callback) ->
    if @database
      if @isArray(items)
        for item in items
          item.database = @database
          item.save(callback)
      else
        items.database = @database
        items.save(callback)
    else
      if @isArray(items)
        for item in items
          item.mapitems = @mapitems
        @mapitems.concat items
      else
        items.mapitems = @mapitems
        @mapitems.push items
      callback(null, items)

  isArray: (inspect) ->
    if typeof Array.isArray == 'function'
      return Array.isArray inspect
    else
      return Object::toString.call(arg) == '[object Array]'

  isGeoJson: (json) ->
    type = json.type
    return (type and (type == "Feature" or type == "FeatureCollection"))

  addGeoJson: require './addGeoJson'

  process_code: (code, callback) ->
    code_lines = code.split("\n")
    code_level = "toplevel"
    button_layers = []
    code_button = 0
    code_layers = []
    code_label = ""
    code_color = null
    code_latlngs = []

    finish_add = ->
      added = 0
      for item in code_layers
        item.database = @database
        item.save (err) ->
          added++
          callback(err, code_layers) if code_layers.length == added

    code_line = (index) ->
      if index >= code_lines.length
        return finish_add()

      line = code_lines[index].trim()
      codeline = line.toLowerCase().split(' ')

      if code_level == 'toplevel'
        code_level = 'map' if line.indexOf('map') > -1
        return code_line(index + 1)

      else if code_level == 'map' or code_level == 'button'
        if codeline.indexOf('button') > -1 or codeline.indexOf('btn') > -1
          code_level = 'button'
          button_layers.push { layers: [] }
          code_button = button_layers.length

        if codeline.indexOf('marker') > -1
          code_level = 'marker'
          code_latlngs = []
          return code_line(index + 1)

        else if codeline.indexOf('line') > -1
          code_level = 'line'
          code_latlngs = []
          return code_line(index + 1)

        else if codeline.indexOf('shape') > -1
          code_level = 'shape'
          code_latlngs = []
          return code_line(index + 1)

        if codeline.indexOf('plz') > -1 or codeline.indexOf('please') > -1
          if code_level == 'map'
            code_level = 'toplevel'
            return finish_add()

          else if code_level == 'button'
            # add button
            code_level = 'map'
            code_button = nil
            return code_line(index + 1)

      else if code_level == 'marker' or code_level == 'line' or code_level == 'shape'
        if codeline.indexOf('plz') > -1 or codeline.indexOf('please') > -1

          if code_level == 'marker'
            geoitem = new MapItem
            geoitem.lat = code_latlngs[0][0]
            geoitem.lng = code_latlngs[0][1]
            geoitem.properties = { label: (code_label or '') }
            code_layers.push geoitem

          else if code_level == 'line'
            geoitem = new MapItem
            geoitem.path = code_latlngs
            geoitem.properties = {
              color: (code_color or ''),
              label: (code_label or '')
            }
            code_layers.push geoitem

          else if code_level == 'shape'
            geoitem = new MapItem
            geoitem.path = [code_latlngs]
            geoitem.properties = {
              color: (code_color or ''),
              fill_color: (code_color or ''),
              label: (code_label or '')
            }
            code_layers.push geoitem

          if code_button
            code_level = 'button'
          else
            code_level = 'map'

          code_latlngs = []
          return code_line(index + 1)

      # geocoding starts with @ - disabled

      # reading a color
      if codeline[0].indexOf('#') == 0
        code_color = codeline.trim()
        if code_color.length != 4 and code_color.length != 7
          # named color
          code_color = code_color.replace('#', '')

        return code_line(index + 1)

      # reading a raw string (probably text for a popup)
      if codeline[0].indexOf('"') == 0
        # check button
        code_label = line.substring( line.indexOf('"') + 1 )
        code_label = code_label.substring(0, code_label.indexOf('"') - 1)

      # reading a latlng coordinate
      if line.indexOf('[') > -1 and line.indexOf(',') > -1 and line.indexOf(']') > -1
        latlng_line = line.replace('[', '').replace(']', '').split(',')
        latlng_line[0] *= 1
        latlng_line[1] *= 1

        # must be a 2D coordinate
        return code_line(index + 1) if latlng_line.length != 2

        code_latlngs.push latlng_line

        return code_line(index + 1)

      code_line(index + 1)
    code_line(0)

MapPLZ.reverse_path = require './reverse_path'

MapPLZ.standardize = require './standardize'
## MapPLZ data is returned as MapItems



module.exports = exports = MapPLZ
exports.MapPLZ = MapPLZ
exports.MapItem = MapItem
exports.PostGIS = require './postgis'
exports.MongoDB = require './mongodb'
exports.RethinkDB = require './rethinkdb'
