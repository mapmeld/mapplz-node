MapPLZ = ->

MapPLZ.standardize = (geo, props) ->
  result = new MapItem
  if typeof geo.lat != "undefined" && typeof geo.lng != "undefined"
    result.lat = geo.lat * 1
    result.lng = geo.lng * 1
  else if geo.path
    result.path = geo.path
  result.properties = props || {}
  result

MapPLZ.prototype.add = (param1, param2, param3, param4) ->
  this.mapitems = [] unless this.mapitems
  this.database = null unless this.database

  callback = (err, items) ->
  callback = param2 if typeof param2 == "function"
  callback = param3 if typeof param3 == "function"
  callback = param4 if typeof param4 == "function"

  # try for lat, lng point
  lat = param1 * 1
  lng = param2 * 1
  unless isNaN(lat) || isNaN(lng)
    pt = MapPLZ.standardize({ lat: lat, lng: lng })
    pt.type = "point"

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

    this.save pt, callback
    return

  if typeof param1 == 'string'
    # try JSON parse
    try
      param1 = JSON.parse param1
      if this.isGeoJson param1
        result = this.addGeoJson param1, callback
        this.save result, callback if result
        return
    catch

  if this.isArray param1
    # param1 is an array

    if param1.length >= 2
      lat = param1[0] * 1
      lng = param1[1] * 1
      unless isNaN(lat) || isNaN(lng)
        result = MapPLZ.standardize { lat: lat, lng: lng }
        result.type = 'point'
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

        this.save result, callback
        return

    if typeof param1[0] == 'object'
      if this.isArray param1[0]
        # param1 contains an array of arrays - probably coordinates
        if this.isArray param1[0][0]
          # polygon
          result = MapPLZ.standardize({ path: param1 })
          result.type = 'polygon'
        else
          # line
          result = MapPLZ.standardize({ path: param1 })
          result.type = 'line'

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

        this.save result, callback
        return
      else
        # param1 contains an array of objects to add
        results = []
        for obj in param1
          results.push this.add(obj)
        this.save results, callback
        return


  else if typeof param1 == 'object'
    # regular object
    if param1.lat && param1.lng
      result = MapPLZ.standardize({ lat: param1.lat, lng: param1.lng })
      result.type = "point"
      for key in Object.keys(param1)
        result.properties[key] = param1[key] unless key == 'lat' || key == 'lng'
      this.save result, callback
      return

    else if param1.path
      result = MapPLZ.standardize({ path: param1.path })
      if typeof param1.path[0][0] == 'object'
        result.type = 'polygon'
      else
        result.type = 'line'
      for key in Object.keys(param1)
        result.properties[key] = param1[key] unless key == 'path'

      this.save result, callback
      return

    else if this.isGeoJson param1
      results = this.addGeoJson param1, callback
      this.save results, callback if results
      return

MapPLZ.prototype.count = (query, callback) ->
  if this.database
    this.database.count(query, callback)
  else
    this.query query, (err, results) ->
      callback(err, results.length)

MapPLZ.prototype.query = (query, callback) ->
  if this.database
    this.database.query(query, callback)
  else
    callback(null, this.mapitems)

MapPLZ.prototype.where = (query, callback) ->
  return this.query(query, callback)

MapPLZ.prototype.save = (items, callback) ->
  if this.database
    if this.isArray(items)
      for item in items
        item.database = this.database
        item.save(callback)
    else
      items.database = this.database
      items.save(callback)
  else
    if this.isArray(items)
      this.mapitems.concat items
    else
      this.mapitems.push items
    callback(null, items)

MapPLZ.prototype.isArray = (inspect) ->
  return (typeof inspect == 'object' && typeof inspect.push == 'function')

MapPLZ.prototype.isGeoJson = (json) ->
  type = json.type
  return (type && (type == "Feature" || type == "FeatureCollection"))

MapPLZ.prototype.addGeoJson = (gj, callback) ->
  if gj.type == "FeatureCollection"
    results = []
    that = this
    iter_callback = (feature_index) ->
      if feature_index < gj.features.length
        feature = that.addGeoJson(gj.features[feature_index])
        that.save feature, (err, saved) ->
          results.push saved
          iter_callback(feature_index + 1)
      else
        callback(null, results)
    iter_callback(0)

  else if gj.type == "Feature"
    geom = gj.geometry
    result = ""
    if geom.type == "Point"
      result = MapPLZ.standardize({ lat: geom.coordinates[1], lng: geom.coordinates[0] })
      result.type = "point"
    else if geom.type == "LineString"
      result = MapPLZ.standardize({ path: this.reverse_path(geom.coordinates) })
      result.type = "line"
    else if geom.type == "Polygon"
      result = MapPLZ.standardize({ path: [this.reverse_path(geom.coordinates[0])] })
      result.type = "polygon"

    result.properties = gj.properties || {}
    result

MapPLZ.prototype.reverse_path = (path) ->
  path_pts = path.slice(0)
  for p, pt in path_pts
    path_pts[pt] = path_pts[pt].slice(0).reverse()
  path_pts

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
  JSON.stringify { type: "Feature", geometry: gj_geo, properties: this.properties }

MapItem.prototype.toWKT = ->
  if this.type == "point"
    "POINT(#{this.lng} #{this.lat})"
  else if this.type == "line"
    linepath = MapPLZ.prototype.reverse_path(this.path)
    for p, pt in linepath
      linepath[pt] = linepath[pt].join ' '
    linepath = linepath.join ','
    "LINESTRING(#{linepath})"
  else if this.type == 'polygon'
    polypath = [MapPLZ.prototype.reverse_path(this.path[0])]
    for p, pt in polypath
      polypath[pt] = polypath[pt].join ' '
    polypath = polypath.join ','
    "POLYGON((#{polypath}))"

MapItem.prototype.save = (callback) ->
  if this.database
    this.database.save(this, (err, id) ->
      this.id = id if id
      callback(err, this)
    )

PostGIS = ->
PostGIS.prototype.save = (item, callback) ->
  if item.id
    this.client.query "UPDATE mapplz SET geom = ST_GeomFromText('#{item.toWKT()}'), properties = '#{JSON.stringify(item.properties)}' WHERE id = #{item.id * 1}"
  else
    this.client.query "INSERT INTO mapplz (properties, geom) VALUES ('#{JSON.stringify(item.properties)}', ST_GeomFromText('#{item.toWKT()}')) RETURNING id", (err, result) ->
      console.error err if err
      callback(err, result.rows[0].id || null)
PostGIS.prototype.count = (query, callback) ->
  condition = "1=1"
  if query && query.length
    condition = query
    where_prop = condition.trim().split(' ')[0]
    condition = condition.replace(where_prop, "json_extract_path_text(properties, '#{where_prop}')")

  this.client.query "SELECT COUNT(*) AS count FROM mapplz WHERE #{condition}", (err, result) ->
    callback(err, result.rows[0].count || null)
PostGIS.prototype.query = (query, callback) ->
  condition = "1=1"
  if query && query.length
    condition = query
    where_prop = condition.trim().split(' ')[0]
    condition = condition.replace(where_prop, "json_extract_path_text(properties, '#{where_prop}')")

  this.client.query "SELECT ST_AsGeoJSON(geom) AS geom, properties FROM mapplz WHERE #{condition}", (err, result) ->
    if err
      console.error err
      callback(err, [])
    else
      results = []
      for row in result.rows
        geo = JSON.parse(row.geom)
        result = MapPLZ.prototype.addGeoJson { type: "Feature", geometry: geo, properties: row.properties }
        results.push result
      callback(err, results)

if exports
  exports.MapPLZ = MapPLZ
  exports.MapItem = MapItem
  exports.PostGIS = PostGIS
