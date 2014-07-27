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

// add lines
mapstore.add([[40, -70], [33, -110]]);

// add polygons
mapstore.add([[[40, -70], [33, -110], [22, -90], [40, -70]]]);

// GeoJSON objects or strings
mapstore.add({ "type": "Feature", "geometry": { "type": "Point", "coordinates": [-70, 40] } });
mapstore.add('{ "type": "Feature", "geometry": { "type": "Point", "coordinates": [-70, 40] } }');

// add properties
pt = mapstore.add({ "type": "Feature", "geometry": { "type": "Point", "coordinates": [-70, 40] }, "properties": { "color": "#0f0" }});
pt.properties.color == "#0f0";

pt2 = mapstore.add({ lat: 40, lng: -70, color: "blue" });
pt3 = mapstore.add(40, -70, { color: "blue" });
```

Each feature is added to a database and returned as a MapItem

```
pt = mapstore.add(40, -70);
line = mapstore.add([[40, -70], [50, 20]], { "color": "red" });

pt.lat == 40
pt.toGeoJson() == '{ "type": "Feature", "geometry": { "type": "Point", "coordinates": [-70, 40] }}'

mapstore.count() == 2

// export all with mapstore.ToGeoJson()

line.type == "line"
line.path == [[40, -70], [50, 20]]
line.properties.color
```

## Databases

If you want to store geodata in a database, you can use Postgres/PostGIS or MongoDB.

MapPLZ simplifies geodata management and queries.

### Setting up PostGIS
```
```

## License

Free BSD License
