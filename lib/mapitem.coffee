reverse_path = require './reverse_path'
class MapItem
  toGeoJson: ->
    if @type == "point"
      gj_geo = { type: "Point", coordinates: [@lng, @lat] }
    else if @type == "line"
      linepath = reverse_path(@path)
      gj_geo = { type: "LineString", coordinates: linepath }
    else if @type == 'polygon'
      polypath = [reverse_path(@path[0])]
      gj_geo = { type: "Polygon", coordinates: polypath }
    JSON.stringify { type: "Feature", geometry: gj_geo, properties: @properties }

  toWKT: ->
    if @type == "point"
      "POINT(#{@lng} #{@lat})"
    else if @type == "line"
      linepath = reverse_path(@path)
      for p, pt in linepath
        linepath[pt] = linepath[pt].join ' '
      linepath = linepath.join ', '
      "LINESTRING(#{linepath})"
    else if @type == 'polygon'
      polypath = reverse_path(@path[0])
      for p, pt in polypath
        polypath[pt] = polypath[pt].join ' '
      polypath = polypath.join ', '
      "POLYGON((#{polypath}))"

  save: (callback) ->
    if @database
      @database.save @, (err, id)=>
        @id = id if id
        callback(err, @)
    else
      callback(null, this)

  delete: (callback) ->
    if @database
      @database.delete this, (err) ->
        callback(err)
    else
      if @mapitems.indexOf(this) > -1
        @mapitems.splice(@mapitems.indexOf(this), 1)
      @type = "deleted"
      callback(null)

  center: ->
    if @type == "point"
      { lat: @lat, lng: @lng }
    else if @type == "line"
      avg = { lat: 0, lng: 0 }
      for pt in @path
        avg.lat += pt[0]
        avg.lng += pt[1]
      avg.lat /= @path.length
      avg.lng /= @path.length
      avg
    else if @type == "polygon"
      avg = { lat: 0, lng: 0 }
      for pt in @path[0]
        avg.lat += pt[0]
        avg.lng += pt[1]
      avg.lat /= @path[0].length
      avg.lng /= @path[0].length
      avg

module.exports = MapItem