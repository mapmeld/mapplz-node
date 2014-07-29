# MapPLZ-Node

[MapPLZ](http://mapplz.com) is a framework to make mapping quick and easy in
your favorite language.

<img src="https://raw.githubusercontent.com/mapmeld/mapplz-node/master/logo.jpg" width="140"/>

## Getting started

MapPLZ consumes many many types of geodata. It can process data for a script or dump
it into a database.

Adding some data:

```
var MapPLZ = require('../mapplz').MapPLZ;
var mapstore = new MapPLZ();

mapstore = new MapPLZ();

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
```

Each feature is returned as a MapItem, which is easy to retrieve data from.

```
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
}
```

## Queries

You don't need a database to query data with MapPLZ, but you're welcome to use Postgres/PostGIS or MongoDB.

MapPLZ simplifies geodata management and queries:

```
mapstore.count("", function(err, count) {
  // count all, return integer
});
mapstore.query("", function(err, all_mapitems) {
  // query all, return [ MapItem ]
});

// without a DB or with MongoDB
mapstore.count({ color: "blue" }, function(err, count) {
  // count == 1
});
mapstore.query({ color: "blue" }, function(err, blue_mapitems) {
  blue_mapitems == [ MapItem ];
});

// with PostGIS
mapstore.count("color = 'blue'", function(err, count) {
  // count == 1
});
mapstore.query("color = 'blue'", function(err, blue_mapitems) {
  blue_mapitems == [ MapItem ];
});

// coming soon! simple near-point and within-polygon queries
```

### Setting up PostGIS
```
var pg = require('pg');
var MapPLZ = require('mapplz');

var mapstore = new MapPLZ.MapPLZ();
var connString = "postgres://postgres:@localhost/travis_postgis";

pg.connect(connString, function(err, client, done) {
  if(!err) {
    mapstore.database = new MapPLZ.PostGIS();
    mapstore.database.client = client;
  }
});
```

### Setting up MongoDB
```
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

## License

Free BSD License
