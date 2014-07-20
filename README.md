# MapPLZ-Node

[MapPLZ](http://mapplz.com) is a framework to make mapping quick and easy in
your favorite language.

<img src="https://raw.githubusercontent.com/mapmeld/mapplz-node/master/logo.jpg" width="140"/>

## Getting started

MapPLZ consumes many many types of geodata. It can process data for a script or dump
it into a database.

Adding some data:

```
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
pt = mapstore.Add({ "type": "Feature", "geometry": { "type": "Point", "coordinates": [-70, 40] }, "properties": { "color": "#0f0" }});
pt.properties.color == "#0f0";
```

Each feature is added to the mapstore and returned as a MapItem

```
pt = mapstore.add(40, -70);
line = mapstore.add([[40, -70], [50, 20]], { "color": "red" });

mapstore.count == 2

// export all with mapstore.ToGeoJson()

pt.lat == 40
pt.toGeoJson() == '{ "type": "Feature", "geometry": { "type": "Point", "coordinates": [-70, 40] }}'

line.type == "line"
line.path == [[40, -70], [50, 20]]
line.properties.color
```

## License

Free BSD License
