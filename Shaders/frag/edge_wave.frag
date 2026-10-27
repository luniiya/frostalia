#version 450

// Soft audio waves rising from the screen edges (wallpaper visualizer). The spectrum
// runs around the border as one loop, in `lobes` mirrored copies (lows in the middle of
// each, highs where two meet) sliding slowly by `drift`; edges meeting at a corner sit
// at the same point of the loop, so their waves meet there at the same height. A milky
// body with a thin light rim on the crest; a fainter, shifted wave fades out underneath.

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
  float lobes;       // copies of the spectrum around the border
  float drift;       // how far they have slid, in turns
  float frame;       // wave floor all round, as a share of waveHeight (0 in silence)
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

// Amplitude at a point of the border loop (0..1, clockwise from the top-left corner)
float amplitude(float loop) {
  float u = fract(loop * lobes + drift * lobes);
  float idx = abs(u - 0.5) * 2.0 * max(count - 1.0, 1.0);
  float i = floor(idx);
  float t = idx - i;
  return clamp(cubicHermite(fetchData(i - 1.0), fetchData(i), fetchData(i + 1.0), fetchData(i + 2.0), t), 0.0, 1.0);
}

// The frame, then the band's wave in the height left above it
float crest(float loop, float scale) {
  return waveHeight * scale * (frame + (1.0 - frame) * amplitude(loop));
}

// Distance from the front wave's crest at `depth` pixels from its edge (negative inside
// the wave), measured across the slope so the rim keeps its width on steep peaks; and the
// crest's height. `perimeter` in pixels, for the slope
vec2 frontWave(float loop, float depth, float perimeter) {
  float h = crest(loop, 1.0);
  float e = 1.5 / perimeter;
  float slope = (crest(loop + e, 1.0) - crest(loop - e, 1.0)) / 3.0;
  return vec2((depth - h) / sqrt(1.0 + slope * slope), h);
}

// The back wave: shifted, lower, no rim, fading out from the edge toward its crest
float lowerWave(float loop, float depth) {
  float h = crest(fract(loop + 0.13 / lobes), 0.75);
  float body = 1.0 - smoothstep(-min(waveHeight * 0.25, h), 0.5, depth - h);
  return body * (1.0 - clamp(depth / max(h, 1.0), 0.0, 1.0));
}

void main() {
  vec2 px = qt_TexCoord0 * size;
  float perimeter = 2.0 * (size.x + size.y);
  // [point of the loop, depth] per edge, clockwise: top left to right, right top to
  // bottom, bottom right to left, left bottom to top
  vec2 lanes[4] = vec2[4](vec2(px.x / perimeter, px.y),
                          vec2((2.0 * size.x + size.y - px.x) / perimeter, size.y - px.y),
                          vec2((2.0 * size.x + size.y + size.y - px.y) / perimeter, px.x),
                          vec2((size.x + px.y) / perimeter, size.x - px.x));
  // The edges' waves are one shape: its crest is whichever edge's crest is nearest, so
  // where two waves cross, neither's rim shows through the other's body
  float front = 1e6;
  float h = 0.0;
  float depth = 1e6;
  float back = 0.0;
  for (int i = 0; i < 4; i++) {
    if (edges[i] < 0.5 || lanes[i].y > waveHeight * 1.3)
      continue;
    vec2 wave = frontWave(lanes[i].x, lanes[i].y, perimeter);
    if (wave.x < front) {
      front = wave.x;
      h = wave.y;
      depth = lanes[i].y;
    }
    back = max(back, lowerWave(lanes[i].x, lanes[i].y));
  }
  // The milky body, softening inward from the crest (less in quiet waves), a bit denser
  // toward the crest; a thin rim on the crest
  float glow = max(min(waveHeight * softness, h * 0.6), 0.5);
  // Nothing past the rim: the body softens inward only, and ends at the crest
  float inside = 1.0 - smoothstep(-0.75, 0.75, front);
  float body = (1.0 - smoothstep(-glow, 0.0, front)) * inside * (0.5 + 0.2 * clamp(depth / max(h, 1.0), 0.0, 1.0));
  float line = h > 0.5 ? exp(-pow(front / 1.6, 2.0)) : 0.0;
  // The back wave only shows inside the front one
  back *= inside;
  // Milky tints of the wave color; layered back, body, rim (premultiplied "over")
  vec3 bodyColor = mix(fillColor.rgb, vec3(1.0), whiteness);
  vec3 rimColor = mix(bodyColor, vec3(1.0), 0.7);
  float backA = back * backWave * fillColor.a;
  float bodyA = body * fillColor.a;
  float rimA = line * rim;
  vec3 rgb = bodyColor * backA;
  float a = backA;
  rgb = bodyColor * bodyA + rgb * (1.0 - bodyA);
  a = bodyA + a * (1.0 - bodyA);
  rgb = rimColor * rimA + rgb * (1.0 - rimA);
  a = rimA + a * (1.0 - rimA);
  fragColor = vec4(rgb, a) * qt_Opacity;
}
