assert = require('chai').assert

MapPLZ = require('../mapplz').MapPLZ
mapstore = new MapPLZ

describe('add point', ->
  it('uses params: lat, lng', ->
    pt = mapstore.add(40, -70)
    assert.equal(pt.lat, 40)
    assert.equal(pt.lng, -70)
  )

  it('uses params: lat, lng, key_property', ->
    pt = mapstore.add(40, -70, 'key')
    assert.equal(pt.lat, 40)
    assert.equal(pt.lng, -70)
    assert.equal(pt.properties.property, 'key')
  )

  it('uses params: lat, lng, properties', ->
    pt = mapstore.add(40, -70, { hello: 'world' })
    assert.equal(pt.lat, 40)
    assert.equal(pt.lng, -70)
    assert.equal(pt.properties.hello, 'world')
  )

  it('uses params: [lat, lng]', ->
    pt = mapstore.add([40, -70])
    assert.equal(pt.lat, 40)
    assert.equal(pt.lng, -70)
  )

  it('uses params: [lat, lng, key_property]', ->
    pt = mapstore.add([40, -70, 'key'])
    assert.equal(pt.lat, 40)
    assert.equal(pt.lng, -70)
    assert.equal(pt.properties.property, 'key')
  )

  it('uses params: [lat, lng, properties]', ->
    pt = mapstore.add([40, -70, { hello: 'world' }])
    assert.equal(pt.lat, 40)
    assert.equal(pt.lng, -70)
    assert.equal(pt.properties.hello, 'world')
  )

  it('uses params: { lat: 40, lng: -70 }', ->
    pt = mapstore.add({ lat: 40, lng: -70})
    assert.equal(pt.lat, 40)
    assert.equal(pt.lng, -70)

    pt = mapstore.add({ lat: 40, lng: -70, color: "#f00" })
    assert.equal(pt.properties.color, "#f00")
  )

  it('uses JSON string: { "lat": 40, "lng": -70 }', ->
    pt = mapstore.add('{ "lat": 40, "lng": -70}')
    assert.equal(pt.lat, 40)
    assert.equal(pt.lng, -70)
  )
)

describe('add line', ->
  it('uses params: [[lat1, lng1], [lat2, lng2]]', ->
    line = mapstore.add([[40, -70], [22, -110]])
    assert.equal(line.type, 'line')
    first_pt = line.path[0]
    assert.equal(first_pt[0], 40)
    assert.equal(first_pt[1], -70)
  )

  it('uses params: { path: [[lat1, lng1], [lat2, lng2]] }', ->
    line = mapstore.add({ path: [[40, -70], [22, -110]] })
    assert.equal(line.type, 'line')
    first_pt = line.path[0]
    assert.equal(first_pt[0], 40)
    assert.equal(first_pt[1], -70)
  )

  it('adds properties: { path: [pt1, pt], key: "x" }', ->
    line = mapstore.add({ path: [[40, -70], [22, -110]], key: "x" })
    assert.equal(line.type, 'line')
    first_pt = line.path[0]
    assert.equal(first_pt[0], 40)
    assert.equal(first_pt[1], -70)
    assert.equal(line.properties.key, "x")
  )

  it('uses JSON string: { path: [[lat1, lng1], [lat2, lng2]] }', ->
    line = mapstore.add('{ "path": [[40, -70], [22, -110]] }')
    assert.equal(line.type, 'line')
    first_pt = line.path[0]
    assert.equal(first_pt[0], 40)
    assert.equal(first_pt[1], -70)
  )
)

describe('add polygon', ->
  it('uses params: [[[lat1, lng1], [lat2, lng2], [lat3, lng3], [lat1, lng1]]]', ->
    poly = mapstore.add([[[40, -70], [22, -110], [40, -110], [40, -70]]])
    assert.equal(poly.type, 'polygon')
    first_pt = poly.path[0][0]
    assert.equal(first_pt[0], 40)
    assert.equal(first_pt[1], -70)
  )

  it('uses params: { path: [[[lat1, lng1], [lat2, lng2], [lat3, lng3], [lat1, lng1]]] }', ->
    poly = mapstore.add({ path: [[[40, -70], [22, -110], [40, -110], [40, -70]]]})
    assert.equal(poly.type, 'polygon')
    first_pt = poly.path[0][0]
    assert.equal(first_pt[0], 40)
    assert.equal(first_pt[1], -70)
  )

  it('uses params to add properties', ->
    poly = mapstore.add({ path: [[[40, -70], [22, -110], [40, -110], [40, -70]]], key: "x" })
    assert.equal(poly.type, 'polygon')
    first_pt = poly.path[0][0]
    assert.equal(first_pt[0], 40)
    assert.equal(first_pt[1], -70)
    assert.equal(poly.properties.key, "x")
  )

  it('uses JSON string: { path: [[[lat1, lng1], [lat2, lng2], [lat3, lng3], [lat1, lng1]]] }', ->
    poly = mapstore.add('{"path": [[[40, -70], [22, -110], [40, -110], [40, -70]]]}')
    assert.equal(poly.type, 'polygon')
    first_pt = poly.path[0][0]
    assert.equal(first_pt[0], 40)
    assert.equal(first_pt[1], -70)
  )
)

describe('add GeoJSON', ->
  it('uses GeoJSON Feature', ->
    pt = mapstore.add({ type: "Feature", geometry: { type: "Point", coordinates: [-70, 40] } })
    assert.equal(pt.lat, 40)
    assert.equal(pt.lng, -70)
  )

  it('uses GeoJSON string', ->
    pt = mapstore.add('{ "type": "Feature", "geometry": { "type": "Point", "coordinates": [-70, 40] } }')
    assert.equal(pt.lat, 40)
    assert.equal(pt.lng, -70)
  )

  it('uses GeoJSON FeatureCollection', ->
    pts = mapstore.add({ type: "FeatureCollection", features: [{ type: "Feature", geometry: { type: "Point", coordinates: [-70, 40] } }]})
    pt = pts[0]
    assert.equal(pt.lat, 40)
    assert.equal(pt.lng, -70)
  )

  it('uses GeoJSON properties', ->
    pt = mapstore.add({ type: "Feature", geometry: { type: "Point", coordinates: [-70, 40] }, properties: { color: "#f00" } })
    assert.equal(pt.lat, 40)
    assert.equal(pt.lng, -70)
    assert.equal(pt.properties.color, "#f00")

    pt = mapstore.add('{ "type": "Feature", "geometry": { "type": "Point", "coordinates": [-70, 40] }, "properties": { "color": "#f00" } }')
    assert.equal(pt.lat, 40)
    assert.equal(pt.lng, -70)
    assert.equal(pt.properties.color, "#f00")
  )
)

describe('queries', ->
  it('returns a count of points added', (done) ->
    mapstore = new MapPLZ
    mapstore.add(40, -70)
    mapstore.add(40, -70)
    mapstore.count(null, (err, count) ->
      assert.equal(count, 2)
      done()
    )
  )
)
