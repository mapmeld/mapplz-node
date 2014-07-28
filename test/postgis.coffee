assert = require('chai').assert
pg = require 'pg'

MapPLZ = require '../mapplz'
mapstore = new MapPLZ.MapPLZ

connString = "postgres://postgres:@localhost/travis_postgis"


connect = (callback) ->
  pg.connect connString, (err, client, done) ->
    if err
      console.error 'error connecting to PostgreSQL'
      assert.equal(err, null)
    else
      mapstore.database = new MapPLZ.PostGIS
      mapstore.database.client = client
      client.query 'DROP TABLE IF EXISTS mapplz', (err, result) ->
        console.error err if err
        client.query 'CREATE TABLE mapplz (id SERIAL PRIMARY KEY, properties JSON, geom public.geometry)', (err, result) ->
          if err
            console.error 'error creating table'
            assert.equal(err, null)
          callback()

describe 'count', ->
  it 'adds four items', (done) ->
    connect ->
      assert.equal(mapstore.database == null, false)
      mapstore.add [0, 1]
      mapstore.add [2, 3, 'hello world']
      mapstore.add { lat: 4, lng: 5, label: 'hello world' }
      line = mapstore.add { path: [[5, 10], [15, 20]], label: 'hello world' }
      assert.equal(line.toWKT(), 'LINESTRING(10 5,20 15)')

      mapstore.count(null, (err, count) ->
        assert.equal(count, 4)
        done()
      )

describe 'saves to db', ->
  it 'saves to db', (done) ->
    connect ->
      assert.equal(mapstore.database == null, false)
      mapstore.add { lat: 2, lng: 3, label: 'hello world' }
      mapstore.query("", (err, results) ->
        firstpt = results[0]
        assert.equal(firstpt.lat, 2)
        assert.equal(firstpt.lng, 3)
        assert.equal(firstpt.type, 'point')
        assert.equal(firstpt.properties.label, 'hello world')
        done()
      )
