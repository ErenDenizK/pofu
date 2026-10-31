// Deformation shaders for the illustrated companion (PofuCompanion).
//
// SwiftUI calls a [[stitchable]] distortion function once per pixel of the
// layer, with the pixel's position in points; it returns the position to
// sample from. Every effect here is therefore written as an inverse map,
// exactly like the WebGL prototype in design/prototypes/companion-motion.
//
// Xcode compiles this file into default.metallib inside the package's
// resource bundle. Command-line `swift build` only copies it, so
// CompanionShaders checks for the compiled library before using it.

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

namespace pofu {

// Smooth radial weight: 1 at the center, 0 at radius R, flat at both ends.
inline float falloff(float r, float R) {
    float t = saturate(1.0 - (r * r) / (R * R));
    return t * t;
}

inline float hash(float2 p) {
    return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
}

inline float noise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    float2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + float2(1, 0)), u.x),
               mix(hash(i + float2(0, 1)), hash(i + float2(1, 1)), u.x), u.y);
}

// Inverse bulge: sampling closer to the center makes the content grow.
inline float2 bulge(float2 p, float2 c, float R, float k) {
    float2 d = p - c;
    return c + d * (1.0 - k * falloff(length(d), R));
}

inline float2 rotate(float2 v, float a) {
    float c = cos(a);
    float s = sin(a);
    return float2(c * v.x - s * v.y, s * v.x + c * v.y);
}

} // namespace pofu

// Cheek pouches, tuft follow-through, and fur ripple in one pass.
//
// art:        the art rectangle inside the layer (x, y, width, height), points
// cheeks:     left and right pouch centers in unit art coordinates (lx, ly, rx, ry)
// cheekPuff:  (radius as a fraction of art width, inflation 0...0.6)
// tuft:       tuft center (x, y) and pivot (z, w) in unit art coordinates
// tuftMotion: (radius as a fraction of art width, angle in radians)
// body:       body ellipse center and radii in unit art coordinates
// ripple:     (time in seconds, strength 0...1)
[[ stitchable ]] float2 pofuCompanionDeform(
    float2 position,
    float4 art,
    float4 cheeks,
    float2 cheekPuff,
    float4 tuft,
    float2 tuftMotion,
    float4 body,
    float2 ripple
) {
    float2 origin = art.xy;
    float2 size = art.zw;
    float2 p = position;

    float cheekRadius = cheekPuff.x * size.x;
    p = pofu::bulge(p, origin + cheeks.xy * size, cheekRadius, cheekPuff.y);
    p = pofu::bulge(p, origin + cheeks.zw * size, cheekRadius, cheekPuff.y);

    // Tuft: rotate a soft region about its root, so it lags the body.
    float2 tuftCenter = origin + tuft.xy * size;
    float2 tuftPivot = origin + tuft.zw * size;
    float weight = pofu::falloff(length(p - tuftCenter), tuftMotion.x * size.x * 1.35);
    p = tuftPivot + pofu::rotate(p - tuftPivot, -tuftMotion.y * weight);

    // Fur ripple: slow noise wind on the outer ring of the body only.
    float2 u = (p - origin) / size;
    float ring = smoothstep(0.78, 1.02, length((u - body.xy) / body.zw));
    float scale = 23.5 / max(size.x, 1.0);
    float2 n = float2(pofu::noise(p * scale + float2(ripple.x * 0.7, 0.0)),
                      pofu::noise(p * scale + float2(0.0, ripple.x * 0.6) + 17.0)) - 0.5;
    p += n * (size.x * 0.013) * ring * ripple.y;
    return p;
}
