#version 450

// Soft audio waves rising from the screen edges (wallpaper visualizer). Each edge
// shows the spectrum mirrored around its middle: lows in the center, highs toward
// the corners, as a milky body with a thin light rim on the crest. A fainter,
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

// Crest height, tapered to nothing toward both ends so neighbouring edges never
// pile up into blobs in the corners
float crest(float along, float scale) {
  float taper = smoothstep(0.0, 0.12, along) * smoothstep(1.0, 0.88, along);
  return waveHeight * scale * (0.08 + 0.92 * amplitude(along)) * taper;
}

// The front wave at `depth` pixels from its edge, `length` pixels long: x is the
// milky body with a soft glow past the crest, y a thin light rim along the crest
vec2 frontWave(float along, float depth, float length) {
  float h = crest(along, 1.0);
  // Distance to the crest measured across the slope, so the rim keeps its width on steep peaks
  float e = 1.5 / length;
  float slope = (crest(along + e, 1.0) - crest(along - e, 1.0)) / 3.0;
  float distance = (depth - h) / sqrt(1.0 + slope * slope);
  float glow = max(waveHeight * 0.08, 2.0);
  float body = (1.0 - smoothstep(-glow, glow * 0.6, distance)) * (0.5 + 0.2 * clamp(depth / max(h, 1.0), 0.0, 1.0));
  float rim = h > 0.5 ? exp(-pow(distance / 1.6, 2.0)) : 0.0;
  return vec2(body, rim);
}

// The back wave: shifted, lower, no rim, fading out from the edge toward its crest
float backWave(float along, float depth) {
  float h = crest(fract(along + 0.13), 0.75);
  float body = 1.0 - smoothstep(-waveHeight * 0.25, 0.5, depth - h);
  return body * 0.35 * (1.0 - clamp(depth / max(h, 1.0), 0.0, 1.0));
}

void main() {
  vec2 px = qt_TexCoord0 * size;
  // [along, depth, length] per edge
  vec3 lanes[4] = vec3[4](vec3(qt_TexCoord0.x, px.y, size.x), vec3(qt_TexCoord0.x, size.y - px.y, size.x),
                          vec3(qt_TexCoord0.y, px.x, size.y), vec3(qt_TexCoord0.y, size.x - px.x, size.y));
  float body = 0.0;
  float rim = 0.0;
  float back = 0.0;
  for (int i = 0; i < 4; i++) {
    if (edges[i] < 0.5 || lanes[i].y > waveHeight * 1.3)
      continue;
    vec2 front = frontWave(lanes[i].x, lanes[i].y, lanes[i].z);
    body = max(body, front.x);
    rim = max(rim, front.y);
    back = max(back, backWave(lanes[i].x, lanes[i].y));
  }
  // Milky tints of the wave color; layered back, body, rim (premultiplied "over")
  vec3 bodyColor = mix(fillColor.rgb, vec3(1.0), 0.65);
  vec3 rimColor = mix(bodyColor, vec3(1.0), 0.7);
  float backA = back * fillColor.a;
  float bodyA = body * fillColor.a;
  float rimA = rim * 0.85;
  vec3 rgb = bodyColor * backA;
  float a = backA;
  rgb = bodyColor * bodyA + rgb * (1.0 - bodyA);
  a = bodyA + a * (1.0 - bodyA);
  rgb = rimColor * rimA + rgb * (1.0 - rimA);
  a = rimA + a * (1.0 - rimA);
  fragColor = vec4(rgb, a) * qt_Opacity;
}
