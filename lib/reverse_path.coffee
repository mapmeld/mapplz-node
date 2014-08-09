module.exports = (path) ->
  path_pts = path.slice(0)
  for p, pt in path_pts
    path_pts[pt] = path_pts[pt].slice(0).reverse()
  path_pts