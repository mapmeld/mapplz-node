# MapPLZ-Node

[![Greenkeeper badge](https://badges.greenkeeper.io/mapmeld/mapplz-node.svg)](https://greenkeeper.io/)

[MapPLZ](http://mapplz.com) is a framework to make mapping quick and easy in
your favorite language.

<img src="https://raw.githubusercontent.com/mapmeld/mapplz-node/master/logo.jpg" width="140"/>

## Getting started

MapPLZ consumes many many types of geodata. It can process data for a script or dump
it into a database.

Adding some data:

```js
var MapPLZ = require('mapplz').MapPLZ;
var mapstore = new MapPLZ();


// add points
mapstore.add(40, -70);
mapstore.add([40, -70);
mapstore.add({ lat: 40, lng: -70 });

// assure items are added using callbacks
mapstore.add(40, -70, function(err, pt) {    });
mapstore.add([40, -70], function(err, pt) {    });

// add lines
mapstore.add([[40, -70], [33, -110]]);

// add polygons
mapstore.add([[[40, -70], [33, -110], [22, -90], [40, -70]]]);

// GeoJSON objects or strings
mapstore.add({ "type": "Feature", "geometry": { "type": "Point", "coordinates": [-70, 40] } });
mapstore.add('{ "type": "Feature", "geometry": { "type": "Point", "coordinates": [-70, 40] } }');

// add properties
mapstore.add({ "type": "Feature", "geometry": { "type": "Point", "coordinates": [-70, 40] }, "properties": { "color": "#0f0" }},
  function(err, pt) {
    pt.properties.color == "#0f0";
  });

mapstore.add({ lat: 40, lng: -70, color: "blue" }, function(err, pt2) {
  mapstore.add(40, -70, { color: "blue" }, function(err, pt3) {  
  });
});

// also: WKT, CSV strings, and MapPLZ code
mapstore.add('POINT(-70 40)');
mapstore.add('color,geo\nred,\'{"type":"Feature","geometry":{"type":"Point","coordinates":[-70,40]}}\'');

mapcode =  "map\n";
mapcode += "  marker\n";
mapcode += "    [40, -70]\n";
mapcode += "  plz\n";
mapcode += "plz\n";
mapstore.add(mapcode);
```

Each feature is returned as a MapItem, which is easy to retrieve data from.

```js
mapstore.add(40, -70, function(err, pt) {
  mapstore.add([[40, -70], [50, 20]], { "color": "red" }), function(err, line) {
    UsePtAndLine(pt, line);
  });
});

function UsePtAndLine(pt, line) {
  pt.lat == 40
  pt.toGeoJson() == '{ "type": "Feature", "geometry": { "type": "Point", "coordinates": [-70, 40] }}'

  line.type == "line"
  line.path == [[40, -70], [50, 20]]
  line.properties.color == "red"

  pt.delete();
  line.delete(function(err){
    // line is now deleted
  });
}
```

## Queries

You don't need a database to query data with MapPLZ, but you're able to use Postgres/PostGIS
or MongoDB for faster, more accurate queries. As of version 1, this library no longer supports RethinkDB.

MapPLZ simplifies geodata management and queries:

```js
mapstore.count("", function(err, count) {
  // count all, return integer
});
mapstore.query("", function(err, all_mapitems) {
  // query all, return [ MapItem ]
});
mapstore.near([lat, lng], 5, function(err, nearest) {
  // five nearest
  // can also send GeoJSON, { lat: Number, lng: Number }, or MapItem
});
mapstore.within([[[40, -70], [50, -80], [30, -80], [40, -70]]], function(err, within) {
  // all points within this polygon
  // can also send GeoJSON, { path: [[[]]] }, or MapItem
});

// with PostGIS
mapstore.count("color = 'blue'", function(err, count) {
  // count == 1
});
mapstore.query("color = 'blue'", function(err, blue_mapitems) {
  // blue_mapitems == [ MapItem ];
});

// with any setup other than PostGIS
mapstore.count({ color: "blue" }, function(err, count) {
  // count == 1
});
mapstore.query({ color: "blue" }, function(err, blue_mapitems) {
  // blue_mapitems == [ MapItem ];
});
```

### Setting up PostGIS
```js
const pg = require('pg');
const MapPLZ = require('mapplz');

var mapstore = new MapPLZ.MapPLZ();
var connString = "postgres://postgres:@localhost/travis_postgis";

var client = new pg.Client(connString);
client.connect(connString, function(err, client, done) {
  if(!err) {
    mapstore.database = new MapPLZ.PostGIS();
    mapstore.database.client = client;
  }
});
```

### Setting up MongoDB
```js
var MongoClient = require('mongodb').MongoClient;
var MapPLZ = require('mapplz');

var mapstore = new MapPLZ.MapPLZ();
var connString = "mongodb://localhost:27017/sample";

MongoClient.connect(connString, function(err, db) {
  db.collection('mapplz', function(err, collection) {
    mapstore.database = new MapPLZ.MongoDB();
    mapstore.database.collection = collection;
  });
});
```

## Interactive Maps

Export as an interactive HTML/JS map

```js
mapstore.add({lat: 40, lng: -70, label: "Popup text"}, function(err, pt) {
  // the map embed
  mapstore.embed_html(function(content){
  });

  // a whole page (including embed)
  mapstore.render_html(function(content){
  });
});
```

## Dependencies

All are installed when you run ```npm install mapplz```

* <a href="http://coffeescript.org/">coffee-script</a> (MIT license)
* <a href="https://github.com/manuelbieh/Geolib">geolib</a> (MIT license)
* <a href="https://github.com/brianc/node-postgres">node-postgres</a> (BSD license)
* <a href="http://mongodb.github.io/node-mongodb-native/">node-mongodb-native</a> (Apache license)
* <a href="http://c2fo.github.io/fast-csv/index.html">fast-csv</a> (MIT license)

## License

Free BSD License
