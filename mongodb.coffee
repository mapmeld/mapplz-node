addGeoJson = require './addGeoJson'
class MongoDB
  constructor: (@collection) ->

  save: (item, callback) ->
    saveobj = {}
    saveobj = JSON.parse(JSON.stringify(item.properties)) if item.properties
    saveobj.geo = JSON.parse(item.toGeoJson()).geometry
    if item.id
      saveobj._id = item.id
      @collection.save saveobj, (err) ->
        console.error err if err
        callback(err, item.id)
    else
      @collection.insert saveobj, (err, results) ->
        console.error err if err
        result = results[0] or null
        callback(err, result._id or null)

  delete: (item, callback) ->
    @collection.remove { _id: item.id }, (err) ->
      item = null
      callback(err)

  count: (query, callback) ->
    condition = query or {}
    @collection.find query, (err, cursor) ->
      if err
        console.error err
        callback(err, null)
      else
        cursor.count (err, count) ->
          callback(err, count or 0)

  query: (query, callback) ->
    condition = query or {}
    db = this
    @collection.find(query).toArray (err, rows) ->
      if err
        console.error err
        callback(err, [])
      else
        results = []
        for row in rows
          excluded = {}
          for key of row
            if key != "_id" and key != "geom"
              excluded[key] = row[key]
          result = addGeoJson { type: "Feature", geometry: row.geo, properties: excluded }
          result.id = row._id
          result.database = db
          results.push result
        callback(err, results)

  near: (nearpt, count, callback) ->
    max = 40010000000
    nearquery = {
      geo: {
        $nearSphere: {
          $geometry: JSON.parse(nearpt.toGeoJson()).geometry,
        }
      }
    }

    @query nearquery, (err, results) ->
      callback(err, (results or []).slice(0, count))

  inside: (withinpoly, callback) ->
    withinquery = {
      geo: {
        $geoWithin: {
          $geometry: JSON.parse(withinpoly.toGeoJson()).geometry
        }
      }
    }
    @query withinquery, callback

module.exports = MongoDB