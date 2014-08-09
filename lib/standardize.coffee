MapItem = require './mapitem'
module.exports = (geo, props) ->
  result = new MapItem
  if typeof geo.lat != "undefined" and typeof geo.lng != "undefined"
    result.lat = geo.lat * 1
    result.lng = geo.lng * 1
  else if geo.path
    result.path = geo.path
  result.properties = props or {}
  result