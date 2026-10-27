#version 460 core
#include <flutter/runtime_effect.glsl>

// Sonora glass overlay — DARK by design.
// Adds only: a hairline top highlight, a barely visible diagonal sheen and
// film grain. The actual glass fill is painted in Dart with a dark translucent
// colour, so text always keeps its contrast.
//
// Uniforms (setFloat indices):
//   0,1  uSize      widget size in px
//   2    uTime      seconds (grain animation)
//   3    uParams.x  noise amount 0..1
//   4    uParams.y  highlight strength 0..1
//   5    uParams.z  pressed 0..1 (brighter edge)
//   6    uParams.w  sheen amount 0..1
//   7..10 uTint     rgb unused, a = global scale

uniform vec2 uSize;
uniform float uTime;
uniform vec4 uParams;
uniform vec4 uTint;

out vec4 fragColor;

float hash21(vec2 p) {
  p = fract(p * vec2(123.34, 456.21));
  p += dot(p, p + 45.32);
  return fract(p.x * p.y);
}

void main() {
  vec2 uv = FlutterFragCoord().xy / max(uSize, vec2(1.0));

  // hairline bright edge at the top: "light hits the glass"
  float top = smoothstep(0.05, 0.0, uv.y) * 0.22 * uParams.y;
  top *= 1.0 + uParams.z * 0.6;

  // faint diagonal sheen — never more than 4% white
  float sheen = smoothstep(0.0, 1.0, 1.0 - (uv.x * 0.5 + uv.y)) *
                0.04 * uParams.w;

  // film grain
  float n = hash21(uv * uSize + vec2(uTime * 3.0, uTime * 2.0)) - 0.5;
  n *= uParams.x * 0.03;

  float a = (top + sheen + n) * uTint.a;
  fragColor = vec4(vec3(1.0), clamp(a, 0.0, 0.30));
}
