#version 460 core
#include <flutter/runtime_effect.glsl>

// Sonora glass overlay.
// Draws the specular sheen, rim light and film grain that sit *on top* of the
// blurred backdrop. Uniform layout (setFloat indices):
//   0,1  uSize        widget size in logical pixels
//   2    uTime        seconds (grain animation)
//   3    uParams.x    noise amount 0..1
//   4    uParams.y    highlight strength 0..1
//   5    uParams.z    pressed 0..1 (boosts the sheen)
//   6    uParams.w    vertical sheen strength 0..1
//   7..10 uTint       rgb = highlight colour, a = overall opacity

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
  vec2 p = uv - vec2(0.5);
  vec2 q = p * vec2(1.0, 0.82);
  float d = length(q);

  // specular highlight in the top-left corner
  float spec = smoothstep(0.95, 0.0, distance(uv, vec2(0.12, 0.02)));
  spec = pow(spec, 1.7) * uParams.y;

  // rim light around the outer edge
  float rim = smoothstep(0.30, 0.52, d);

  // soft inner glow towards the centre
  float inner = smoothstep(0.52, 0.18, d) * 0.28;

  // animated film grain
  float n = hash21(uv * uSize * 0.9 + vec2(uTime * 7.0, uTime * 4.0)) - 0.5;
  n *= uParams.x * 0.09;

  vec3 col = uTint.rgb * (0.30 + spec * 0.95) + vec3(1.0) * spec * 0.30;
  float a = spec * 0.55 + rim * 0.28 + inner * 0.22 + n;

  // bottom-up sheen (keeps the parameter genuinely used, so the compiler
  // cannot drop the uniform and shift the float indices)
  float vsheen = smoothstep(0.0, 1.0, 1.0 - uv.y) * uParams.w;
  a += vsheen * 0.14;

  a *= 1.0 + uParams.z * 0.30;

  fragColor = vec4(col, clamp(a, 0.0, 1.0) * uTint.a);
}
