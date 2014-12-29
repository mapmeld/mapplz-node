rethinkdb = require 'rethinkdb'
addGeoJson = require './addGeoJson'
class RethinkDB
  constructor: (@connection) ->

  save: (item, callback) ->
    saveobj = {}
    saveobj = JSON.parse(JSON.stringify(item.properties)) if item.properties
    saveobj.geo = JSON.parse(item.toGeoJson()).geometry
    if item.id
      saveobj.id = item.id
      rethinkdb.table('mapplz').update(saveobj, { returnChanges: true }).run @connection, (err) ->
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
        callback(err, cursor)
      else
        cursor.toArray (err, results) ->
          output = []
          for result in results
            excluded = {}
            for key of result
              if key != "_id" and key != "geom"
                excluded[key] = result[key]
            out = addGeoJson { type: "Feature", geometry: result.geo, properties: excluded }
            out.id = result.id
            out.database = db
            output.push out
          callback(err, output)

  near: (nearpt, count, callback) ->
    callback()

  inside: (withinpoly, callback) ->
    callback()

module.exports = RethinkDB
