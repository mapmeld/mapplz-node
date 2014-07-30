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

describe 'queries db', ->
  it 'returns count', (done) ->
    connect ->
      assert.equal(mapstore.database == null, false)
      mapstore.add([0, 1], (err, pts) ->
        mapstore.add([2, 3, 'hello world'], (err, pt) ->
          mapstore.add({ lat: 4, lng: 5, label: 'hello world' }, (err, pt2) ->
            mapstore.add({ path: [[5, 10], [15, 20]], label: 'hello world' }, (err, line) ->
              assert.equal(line.toWKT(), 'LINESTRING(10 5,20 15)')
              mapstore.count(null, (err, count) ->
                assert.equal(count, 4)
                done()
              )
            )
          )
        )
      )

  it 'deletes a point', (done) ->
    connect ->
      mapstore.add(40, -70, (err, pt) ->
        pt.delete ->
          mapstore.count(null, (err, count) ->
            assert.equal(count, 0)
            done()
          )
      )

  it 'queries by property', (done) ->
    connect ->
      assert.equal(mapstore.database == null, false)
      mapstore.add({ lat: 2, lng: 3, color: 'blue' }, (err, pt) ->
        mapstore.add({ lat: 2, lng: 3, color: 'red' }, (err, pt2) ->
          mapstore.query("color = 'blue'", (err, results) ->
            assert.equal(results.length, 1)
            assert.equal(results[0].properties.color, "blue")
            done()
          )
        )
      )

  it 'counts by property', (done) ->
    connect ->
      assert.equal(mapstore.database == null, false)
      mapstore.add({ lat: 2, lng: 3, color: 'blue' }, (err, pt) ->
        mapstore.add({ lat: 2, lng: 3, color: 'red' }, (err, pt2) ->
          mapstore.count("color = 'blue'", (err, count) ->
            assert.equal(count, 1)
            done()
          )
        )
      )

  it 'finds nearest point', (done) ->
    connect ->
      mapstore.add { lat: 40, lng: -70 }, (err, pt) ->
        mapstore.add { lat: 35, lng: 110 }, (err, pt2) ->
          mapstore.near [30, -60], 1, (err, nearest) ->
            assert.equal(nearest.length, 1)
            response = nearest[0]
            assert.equal(response.lat, 40)
            assert.equal(response.lng, -70)
            done()

  it 'finds point in polygon', (done) ->
    connect ->
      mapstore.add { lat: 40, lng: -70 }, (err, pt) ->
        mapstore.add { lat: 35, lng: 110 }, (err, pt2) ->
          mapstore.inside [[[38, -72], [38, -68], [42, -68], [42, -72], [38, -72]]], (err, within) ->
            assert.equal(within.length, 1)
            response = within[0]
            assert.equal(response.lat, 40)
            assert.equal(response.lng, -70)
            done()

describe 'saves to db', ->
  it 'saves properties to db', (done) ->
    connect ->
      assert.equal(mapstore.database == null, false)
      mapstore.add({ lat: 2, lng: 3, label: 'hello world' }, (err, pt) ->
        mapstore.query("", (err, results) ->
          firstpt = results[0]
          assert.equal(firstpt.lat, 2)
          assert.equal(firstpt.lng, 3)
          assert.equal(firstpt.type, 'point')
          assert.equal(firstpt.properties.label, 'hello world')
          done()
        )
      )

  it 'updates properties in db', (done) ->
    connect ->
      assert.equal(mapstore.database == null, false)
      mapstore.add({ lat: 2, lng: 3, label: 'hello' }, (err, pt) ->
        pt.properties.label = 'world'
        pt.save (err, ptnew) ->
          mapstore.query("", (err, results) ->
            assert.equal(results.length, 1)
            assert.equal(results[0].properties.label, 'world')
            done()
          )
      )

  it 'updates locations in db', (done) ->
    connect ->
      assert.equal(mapstore.database == null, false)
      mapstore.add({ lat: 2, lng: 3 }, (err, pt) ->
        pt.lat = 5
        pt.save (err, ptnew) ->
          mapstore.query("", (err, results) ->
            assert.equal(results.length, 1)
            assert.equal(results[0].lat, 5)
            done()
          )
      )
