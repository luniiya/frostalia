.pragma library

// Outline of the Material 3 Expressive "cookie" shape: a circle whose radius
// waves `lobes` times around the centre. depth 0 gives a plain circle.
function points(cx, cy, radius, lobes, depth, steps) {
  var result = [];
  var count = Math.max(8, steps || 96);
  var inner = radius * (1 - depth);
  for (var i = 0; i <= count; i++) {
    var angle = (i / count) * Math.PI * 2 - Math.PI / 2;
    var wave = (1 + Math.cos(angle * lobes + Math.PI / 2 * lobes)) / 2;
    var r = inner + (radius - inner) * wave;
    result.push(Qt.point(cx + Math.cos(angle) * r, cy + Math.sin(angle) * r));
  }
  return result;
}
