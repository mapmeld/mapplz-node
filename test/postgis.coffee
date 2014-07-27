assert = require('chai').assert
pg = require 'pg'

MapPLZ = require '../mapplz'
mapstore = new MapPLZ.MapPLZ

connString = "postgres://postgres:@localhost/travis_postgis";
pg.connect connString, (err, client, done) ->
  if err
    console.error 'error connecting to PostgreSQL'
    assert.equal(err, null)
  else
    mapstore.database = new MapPLZ.PostGIS client
    client.query 'CREATE TABLE mapplz (id SERIAL PRIMARY KEY, properties JSON, geom public.geometry)', (err, result) ->
      if err
        console.error 'error creating table'
        assert.equal(err, null)
      else
        assert.equal(runTests(), true)


runTests = ->
  describe 'count', ->
    it 'adds four items', ->
      mapstore.add [0, 1]
      mapstore.add [2, 3, 'hello world']
      mapstore.add { lat: 4, lng: 5, label: 'hello world' }
      mapstore.add { path: [[0, 1], [2, 3]], label: 'hello world' }

      assert.equal(mapstore.count(), 4)
  true
