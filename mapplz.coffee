
MapPLZ = ->

MapPLZ.prototype.add = (param1, param2, param3) ->
  this.mapitems = [] unless this.mapitems
  this.dbtype = "array" unless this.dbtype

  # try for lat, lng point
  lat = param1 * 1
  lng = param2 * 1
  unless isNaN(lat) || isNaN(lng)
    pt = new MapItem
    pt.lat = lat
    pt.lng = lng
    pt.type = "point"
    pt.properties = {}

    if param3 != null
      # allow JSON string of properties
      if typeof param3 == 'string'
        try
          pt.properties = JSON.parse param3
        catch

      if this.isArray param3
        # array
        pt.properties = { property: param3 }
      else if typeof param3 == 'object'
        # object
        for key in Object.keys(param3)
          pt.properties[key] = param3[key]
      else
        # string, number, or other singular property
        pt.properties = { property: param3 }

    this.mapitems.push pt
    return pt

  if typeof param1 == 'string'
    # try JSON parse
    try
      param1 = JSON.parse param1
      if this.isGeoJson param1
        result = this.addGeoJson param1
        this.mapitems.push result
        return result
    catch

  if this.isArray param1
    # param1 is an array

    if param1.length >= 2
      lat = param1[0] * 1
      lng = param1[1] * 1
      unless isNaN(lat) || isNaN(lng)
        result = new MapItem
        result.type = 'point'
        result.lat = lat
        result.lng = lng
        result.properties = {}
        for prop in param1.slice(2)
          if typeof prop == 'string'
            try
              prop = JSON.parse prop
            catch

          if typeof prop == 'object'
            for key in Object.keys(prop)
              result.properties[key] = prop[key]
          else
            result.properties = { property: prop }

        this.mapitems.push result
        return result

    if typeof param1[0] == 'object'
      if this.isArray param1[0]
        # param1 contains an array of arrays - probably coordinates
        if this.isArray param1[0][0]
          # polygon
          result = new MapItem
          result.type = 'polygon'
          result.path = param1
          result.properties = {}
        else
          # line
          result = new MapItem
          result.type = 'line'
          result.path = param1
          result.properties = {}

        if result && param2
          # try JSON parsing
          if typeof param2 == 'string'
            try
              param2 = JSON.parse param2
            catch

          if typeof param2 == 'object'
            if this.isArray param2
              result.properties = { property: param2 }
            else
              result.properties = param2
          else
            result.properties = { property: param2 }
        else
          result.properties = {}

        this.mapitems.push result
        return result
      else
        # param1 contains an array of objects to add
        results = []
        for obj in param1
          results.push this.add(obj)
        this.mapitems.concat results
        return results


  else if typeof param1 == 'object'
    # regular object
    if param1.lat && param1.lng
      result = new MapItem
      result.type = "point"
      result.lat = param1.lat * 1
      result.lng = param1.lng * 1
      result.properties = {}
      for key in Object.keys(param1)
        result.properties[key] = param1[key] unless key == 'lat' || key == 'lng'
      this.mapitems.push result
      return result

    else if param1.path
      result = new MapItem
      result.properties = {}
      if typeof param1.path[0][0] == 'object'
        result.type = 'polygon'
        rings = param1.path
        for ring in rings
          ring = this.reverse_path(ring)
        result.path = rings
      else
        result.type = 'line'
        result.path = param1.path
      for key in Object.keys(param1)
        result.properties[key] = param1[key] unless key == 'path'

      this.mapitems.push result
      return result

    else if this.isGeoJson param1
      results = this.addGeoJson param1
      this.mapitems.concat results
      return results

MapPLZ.prototype.isArray = (inspect) ->
  return (typeof inspect == 'object' && typeof inspect.push == 'function')

MapPLZ.prototype.isGeoJson = (json) ->
  type = json.type
  return (type && (type == "Feature" || type == "FeatureCollection"))

MapPLZ.prototype.addGeoJson = (gj) ->
  results = []
  if gj.type == "FeatureCollection"
    for feature in gj.features
      results.push this.add(feature)
    results

  else if gj.type == "Feature"
    result = new MapItem
    geom = gj.geometry
    if geom.type == "Point"
      result.type = "point"
      result.lat = geom.coordinates[1]
      result.lng = geom.coordinates[0]
    else if geom.type == "LineString"
      result.type = "line"
      result.path = this.reverse_path geom.coordinates

    result.properties = gj.properties || null
    result

MapPLZ.prototype.reverse_path = (path) ->
  path_pts = path.slice 0
  for pt in path_pts
    pt.reverse
  return path_pts

MapItem = ->
MapItem.prototype.toGeoJson = ->
  if this.type == "point"
    gj_geo = { type: "Point", coordinates: [this.lng, this.lat] }
  else if this.type == "line"
    linepath = MapPLZ.prototype.reverse_path(this.path)
    gj_geo = { type: "LineString", coordinates: linepath }
  else if this.type == 'polygon'
    polypath = [MapPLZ.prototype.reverse_path(this.path[0])]
    gj_geo = { type: "Polygon", coordinates: polypath }

  JSON.parse { type: "Feature", geometry: gj_geo, properties: this.properties }

if exports
  exports.MapPLZ = MapPLZ
