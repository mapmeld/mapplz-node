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

You can run several queries on the data, asynchronously:

```
mapstore.count(null, function(err, count) {
  // count == 2
});
mapstore.count("color = 'blue'", function(err, count) {
  // count == 1
});
```

## Databases

If you want to store geodata in a database, you can use Postgres/PostGIS or MongoDB.

MapPLZ simplifies geodata management and queries.

### Setting up PostGIS
```
```

## License

Free BSD License
