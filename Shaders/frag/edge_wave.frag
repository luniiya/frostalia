#version 450

// Soft audio waves rising from the screen edges (wallpaper visualizer). Each edge
// shows the spectrum mirrored around its middle: lows in the center, highs toward
// the corners, where neighbouring edges merge into one rounded wave. A milky body with a thin light rim on the crest. A fainter,
// shifted wave fades out underneath for depth.

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(binding = 1) uniform sampler2D dataSource;

layout(std140, binding = 0) uniform buf {
  mat4 qt_Matrix;
  float qt_Opacity;
  vec4 fillColor;
  float count;
  float texWidth;
  vec4 edges;        // top, bottom, left, right: 1 when the edge has a wave
  vec2 size;         // item size in pixels
  float waveHeight;  // tallest wave, in pixels
  float whiteness;   // how far the body is tinted toward white
  float rim;         // strength of the light rim on the crest
  float backWave;    // strength of the fainter wave underneath
  float softness;    // glow past the crest, as a share of waveHeight
};

float fetchData(float idx) {
  float i = clamp(idx, 0.0, texWidth - 1.0);
  float u = (floor(i) + 0.5) / texWidth;
  return texture(dataSource, vec2(u, 0.5)).r;
}

float cubicHermite(float y0, float y1, float y2, float y3, float t) {
  float m1 = (y2 - y0) * 0.25;
  float m2 = (y3 - y1) * 0.25;
  float t2 = t * t;
  float t3 = t2 * t;
  return (2.0 * t3 - 3.0 * t2 + 1.0) * y1
       + (t3 - 2.0 * t2 + t) * m1
       + (-2.0 * t3 + 3.0 * t2) * y2
       + (t3 - t2) * m2;
}

// Amplitude at a position along an edge (0..1), mirrored around the middle
float amplitude(float along) {
  float idx = abs(along - 0.5) * 2.0 * max(count - 1.0, 1.0);
  float i = floor(idx);
  float t = idx - i;
  return clamp(cubicHermite(fetchData(i - 1.0), fetchData(i), fetchData(i + 1.0), fetchData(i + 2.0), t), 0.0, 1.0);
}

// Crest height: nothing in silence. It runs all the way into the corners, where the
// two edges' waves are joined into one rounded curve (see smoothUnion)
float crest(float along, float scale) {
  return waveHeight * scale * amplitude(along);
}

// Smooth minimum of two distances: where two edges meet, their waves merge into
// one curve with a round fillet `k` pixels wide instead of a notch or a square
float smoothUnion(float a, float b, float k) {
  k = max(k, 0.001);
  float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
  return mix(b, a, h) - k * h * (1.0 - h);
}

// Width of the rounded join between two edges' waves: a share of the lower crest, and
// capped. Wide joins filled in blobs wherever both waves came close, far from the edge
float fillet(float crestA, float crestB) {
  return min(0.35 * min(crestA > 0.0 ? crestA : crestB, crestB), 0.15 * waveHeight);
}

// Distance from the front wave's crest at `depth` pixels from its edge, `length`
// pixels long (negative inside the wave), measured across the slope so the rim keeps
// its width on steep peaks
float frontDistance(float along, float depth, float length) {
  float h = crest(along, 1.0);
  float e = 1.5 / length;
  float slope = (crest(along + e, 1.0) - crest(along - e, 1.0)) / 3.0;
  return (depth - h) / sqrt(1.0 + slope * slope);
}

// Distance from the back wave's crest: shifted along the edge and lower
float backDistance(float along, float depth) {
  return depth - crest(fract(along + 0.13), 0.75);
}

void main() {
  vec2 px = qt_TexCoord0 * size;
  // [along, depth, length] per edge
  vec3 lanes[4] = vec3[4](vec3(qt_TexCoord0.x, px.y, size.x), vec3(qt_TexCoord0.x, size.y - px.y, size.x),
                          vec3(qt_TexCoord0.y, px.x, size.y), vec3(qt_TexCoord0.y, size.x - px.x, size.y));
  float glow = max(waveHeight * softness, 2.0);
  float front = 1e6;
  float back = 1e6;
  // Tallest crest at this pixel: the fillet and the rim scale with it, so quiet waves
  // don't round off into blobs in the corners and silence draws nothing at all
  float crestHere = 0.0;
  float backCrestHere = 0.0;
  // Distance to the nearest edge with a wave, for the body's shading from the edge out
  float depth = 1e6;
  for (int i = 0; i < 4; i++) {
    if (edges[i] < 0.5 || lanes[i].y > waveHeight * 1.5)
      continue;
    float h = crest(lanes[i].x, 1.0);
    float backH = crest(fract(lanes[i].x + 0.13), 0.75);
    front = smoothUnion(front, frontDistance(lanes[i].x, lanes[i].y, lanes[i].z), fillet(crestHere, h));
    back = smoothUnion(back, backDistance(lanes[i].x, lanes[i].y), fillet(backCrestHere, backH));
    crestHere = max(crestHere, h);
    backCrestHere = max(backCrestHere, backH);
    depth = min(depth, lanes[i].y);
  }
  // The milky body with a soft glow past the crest, a bit denser toward the crest; a
  // thin light rim along the crest; the back wave fading out from the edge
  float height = max(depth - front, 1.0);
  // The glow past the crest shrinks with the wave too, down to nothing in silence
  float soft = max(min(glow, crestHere * 0.6), 0.5);
  float body = (1.0 - smoothstep(-soft, soft * 0.6, front)) * (0.5 + 0.2 * clamp(depth / height, 0.0, 1.0)) * smoothstep(0.0, 2.0, crestHere);
  float rimLine = exp(-pow(front / 1.6, 2.0)) * smoothstep(0.5, 3.0, crestHere);
  float backHeight = max(depth - back, 1.0);
  float backBody = smoothstep(0.0, 2.0, backCrestHere) * (1.0 - smoothstep(-min(waveHeight * 0.25, backCrestHere), 0.5, back)) * backWave * (1.0 - clamp(depth / backHeight, 0.0, 1.0));
  // Milky tints of the wave color; layered back, body, rim (premultiplied "over")
  vec3 bodyColor = mix(fillColor.rgb, vec3(1.0), whiteness);
  vec3 rimColor = mix(bodyColor, vec3(1.0), 0.7);
  float backA = backBody * fillColor.a;
  float bodyA = body * fillColor.a;
  float rimA = rimLine * rim;
  vec3 rgb = bodyColor * backA;
  float a = backA;
  rgb = bodyColor * bodyA + rgb * (1.0 - bodyA);
  a = bodyA + a * (1.0 - bodyA);
  rgb = rimColor * rimA + rgb * (1.0 - rimA);
  a = rimA + a * (1.0 - rimA);
  fragColor = vec4(rgb, a) * qt_Opacity;
}
