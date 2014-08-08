addGeoJson = require './addGeoJson'

class PostGIS
  constructor: (@client) ->
  save: (item, callback) ->
    if item.id
      @client.query "UPDATE mapplz SET geom = ST_GeomFromText('#{item.toWKT()}'), properties = '#{JSON.stringify(item.properties)}' WHERE id = #{item.id * 1}", (err, result) ->
        console.error err if err
        callback(err, item.id)
    else
      @client.query "INSERT INTO mapplz (properties, geom) VALUES ('#{JSON.stringify(item.properties)}', ST_GeomFromText('#{item.toWKT()}')) RETURNING id", (err, result) ->
        console.error err if err
        callback(err, result.rows[0].id or null)

  delete: (item, callback) ->
    @client.query "DELETE FROM mapplz WHERE id = #{item.id * 1}", (err) ->
      item = null
      callback(err)

  count: (query, callback) ->
    condition = "1=1"
    if query and query.length
      condition = query
      where_prop = condition.trim().split(' ')[0]
      condition = condition.replace(where_prop, "json_extract_path_text(properties, '#{where_prop}')")

    @client.query "SELECT COUNT(*) AS count FROM mapplz WHERE #{condition}", (err, result) ->
      callback(err, result.rows[0].count or null)

  processResults: (err, db, result, callback) ->
    if err
      console.error err
      callback(err, [])
    else
      results = []
      for row in result.rows
        geo = JSON.parse(row.geo)
        result = addGeoJson { type: "Feature", geometry: geo, properties: row.properties }
        result.id = row.id
        result.database = db
        results.push result
      callback(err, results)

  query: (query, callback) ->
    condition = "1=1"
    if query and query.length
      condition = query
      where_prop = condition.trim().split(' ')[0]
      condition = condition.replace(where_prop, "json_extract_path_text(properties, '#{where_prop}')")

    @client.query "SELECT ST_AsGeoJSON(geom) AS geo, properties FROM mapplz WHERE #{condition}", (err, result) =>
      @processResults(err, @, result, callback)

  near: (nearpt, count, callback) ->
    @client.query "SELECT id, ST_AsGeoJSON(geom) AS geo, properties, ST_Distance(start.geom::geography, ST_GeomFromText('#{nearpt.toWKT()}')::geography) AS distance FROM mapplz AS start ORDER BY distance LIMIT #{count}", (err, results) =>
      @processResults(err, @, results, callback)

  inside: (withinpoly, callback) ->
    @client.query "SELECT id, ST_AsGeoJSON(geom) AS geo, properties FROM mapplz AS start WHERE ST_Contains(ST_GeomFromText('#{withinpoly.toWKT()}'), start.geom)", (err, results) =>
      @processResults(err, @, results, callback)

module.exports = PostGIS