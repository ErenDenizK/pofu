// The world's look shaders (PofuWorld, look-dev A).
//
// SwiftUI calls a [[stitchable]] color function once per pixel with the
// pixel's position in points and its premultiplied color. Xcode compiles
// this file into default.metallib inside the package's resource bundle;
// command-line
// `swift build` only copies it, so WorldShaders checks for the compiled
// library before using it.

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

namespace pofuworld {

// The grade itself; WorldGrade.apply is its CPU twin.
inline half3 grade(half3 x, float3 lift, float3 gamma, float3 gain, float contrast, float pivot, float saturation) {
    float3 c = float3(x);
    c = gain * (c + lift * (1.0 - c));
    c = pow(max(c, 0.0), 1.0 / max(gamma, float3(0.01)));
    c = (c - pivot) * contrast + pivot;
    float luma = dot(c, float3(0.2126, 0.7152, 0.0722));
    c = luma + (c - luma) * saturation;
    return half3(saturate(c));
}

} // namespace pofuworld

// The runtime color grade and the vignette, on the world layer only.
//
// lift, gamma, gain: per channel
// shape:             (contrast, pivot, saturation, vignette)
// size:              the layer's size in points
[[ stitchable ]] half4 pofuWorldGrade(
    float2 position,
    half4 color,
    float3 lift,
    float3 gamma,
    float3 gain,
    float4 shape,
    float2 size
) {
    if (color.a <= 0.0h) {
        return color;
    }
    half3 rgb = color.rgb / color.a;
    rgb = pofuworld::grade(rgb, lift, gamma, gain, shape.x, shape.y, shape.z);

    // An elliptical vignette, gentle in the middle third, a little warm.
    float2 uv = (position / max(size, float2(1.0)) - 0.5) * 2.0;
    float d = length(uv * float2(1.0, 0.9)) / 1.345;
    float v = 1.0 - shape.w * pow(saturate((d - 0.3) / 0.7), 1.6);
    rgb *= half3(half(v), half(mix(v, 1.0, 0.06)), half(mix(v, 1.0, 0.02)));
    return half4(rgb * color.a, color.a);
}
