standardize = require './standardize'
module.exports = (gj, callback) ->
  if gj.type == "FeatureCollection"
    results = []
    iter_callback = (feature_index) =>
      if feature_index < gj.features.length
        feature = @addGeoJson(gj.features[feature_index])
        @save feature, (err, saved) ->
          results.push saved
          iter_callback(feature_index + 1)
      else
        callback(null, results)
    iter_callback(0)

  else if gj.type == "Feature"
    geom = gj.geometry
    result = ""
    if geom.type == "Point"
      result = standardize({ lat: geom.coordinates[1], lng: geom.coordinates[0] })
      result.type = "point"
    else if geom.type == "LineString"
      result = standardize({ path: reverse_path(geom.coordinates) })
      result.type = "line"
    else if geom.type == "Polygon"
      result = standardize({ path: [reverse_path(geom.coordinates[0])] })
      result.type = "polygon"

    result.properties = gj.properties or {}
    result