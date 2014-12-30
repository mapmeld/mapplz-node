rethinkdb = require 'rethinkdb'
addGeoJson = require './addGeoJson'
class RethinkDB
  constructor: (@connection) ->

  save: (item, callback) ->
    saveobj = {}
    saveobj = JSON.parse(JSON.stringify(item.properties)) if item.properties
    saveobj.geo = rethinkdb.geojson(JSON.parse(item.toGeoJson()).geometry)
    if item.id
      rethinkdb.table('mapplz').get(item.id).update(saveobj, { returnChanges: true, nonAtomic: true }).run @connection, (err) ->
        console.error err if err
        callback(err, item.id)
    else
      rethinkdb.table('mapplz').insert(saveobj, { returnChanges: true }).run @connection, (err, results) ->
        console.error err if err
        result = results.generated_keys[0]
        item.id = result
        callback(err, result or null)

  delete: (item, callback) ->
    rethinkdb.table('mapplz').get(item.id).delete().run @connection, (err) ->
      item = null
      callback(err)

  count: (query, callback) ->
    if query
      conditions = rethinkdb.table('mapplz')
      for condition of query
        conditions = conditions(condition).count(query[condition])
      conditions.run @connection, (err, count) ->
        callback(err, count or 0)
    else
      rethinkdb.table('mapplz').count().run @connection, (err, count) ->
        callback(err, count or 0)

  query: (query, callback) ->
    conditions = query or {}
    db = this
    rethinkdb.table('mapplz').filter(conditions).run @connection, (err, cursor) ->
      if err
        callback(err, [])
      else
        cursor.toArray (err, results) ->
          output = []
          for result in results
            excluded = {}
            for key of result
              if key != "geom"
                excluded[key] = result[key]
            out = addGeoJson { type: "Feature", geometry: result.geo, properties: excluded }
            out.id = result.id
            out.database = db
            output.push out
          callback(err, output)

  near: (nearpt, count, callback) ->
    center = rethinkdb.point(nearpt.lng, nearpt.lat)
    nearOpts = { index: 'geo', maxResults: count, maxDist: 9103126 }
    db = this
    rethinkdb.table('mapplz').getNearest(center, nearOpts).run @connection, (err, cursor) ->
      if err
        callback(err, [])
      else
        cursor.toArray (err, results) ->
          output = []
          for response in results
            result = response.doc
            excluded = {}
            for key of result
              if key != "geom"
                excluded[key] = result[key]
            out = addGeoJson { type: "Feature", geometry: result.geo, properties: excluded }
            out.id = result.id
            out.database = db
            output.push out
          callback(err, output)

  inside: (withinpoly, callback) ->
    polygon = rethinkdb.geojson(JSON.parse(withinpoly.toGeoJson()).geometry)
    db = this
    rethinkdb.table('mapplz').getIntersecting(polygon, { index: 'geo' }).run @connection, (err, cursor) ->
      if err
        callback(err, [])
      else
        cursor.toArray (err, results) ->
          output = []
          for result in results
            excluded = {}
            for key of result
              if key != "geom"
                excluded[key] = result[key]
            out = addGeoJson { type: "Feature", geometry: result.geo, properties: excluded }
            out.id = result.id
            out.database = db
            output.push out
          callback(err, output)

module.exports = RethinkDB
