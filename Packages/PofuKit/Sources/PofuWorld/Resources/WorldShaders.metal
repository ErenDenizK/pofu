// The world's look shaders (PofuWorld, look-dev A and C).
//
// SwiftUI calls a [[stitchable]] color function once per pixel with the
// pixel's position in points and its premultiplied color; a layer function
// gets the rasterized layer to sample. Xcode compiles this file into
// default.metallib inside the package's resource bundle; command-line
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

// Signed distance to a rounded rectangle centred at the origin.
inline float roundedBox(float2 p, float2 halfSize, float radius) {
    float2 q = abs(p) - halfSize + radius;
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - radius;
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

// The terrarium's glass rim: within `rim.y` points of the screen's rounded
// edge the world is magnified outward a little, as through the thick edge
// of a curved glass, with a faint chromatic split and a thin highlight on
// the side facing the light (upper left).
//
// size:  the layer's size in points
// rim:   (corner radius, rim width, strength 0...1, max offset in points)
[[ stitchable ]] half4 pofuTerrariumRim(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float4 rim
) {
    float2 halfSize = size * 0.5;
    float2 p = position - halfSize;
    float d = pofuworld::roundedBox(p, halfSize, rim.x);   // 0 at the edge, < 0 inside
    float width = max(rim.y, 1.0);
    float e = saturate(1.0 + d / width);                    // 0 inside the rim, 1 at the edge
    if (e <= 0.0 || rim.z <= 0.0) {
        return layer.sample(position);
    }
    // The outward normal, from the distance field's gradient.
    float eps = 0.75;
    float2 n = float2(
        pofuworld::roundedBox(p + float2(eps, 0), halfSize, rim.x) - pofuworld::roundedBox(p - float2(eps, 0), halfSize, rim.x),
        pofuworld::roundedBox(p + float2(0, eps), halfSize, rim.x) - pofuworld::roundedBox(p - float2(0, eps), halfSize, rim.x)
    );
    n = length(n) > 1e-4 ? normalize(n) : float2(0.0);

    // A curved lip: the bend grows toward the edge (e²); sampling inward
    // magnifies what is under the rim outward.
    float bend = e * e * rim.z * rim.w;
    float2 base = position - n * bend;
    half4 c = layer.sample(base);
    half4 r = layer.sample(base - n * bend * 0.10);
    half4 b = layer.sample(base + n * bend * 0.10);
    c.r = r.r;
    c.b = b.b;

    // A thin specular line a few points inside the edge, brightest where
    // the rim faces the light, and a soft inner shade of the glass's
    // thickness opposite it.
    float facing = saturate(dot(-n, normalize(float2(0.7, 0.75))) * 0.5 + 0.5);
    float k = (e - 0.82) / 0.07;
    float spec = exp(-k * k);
    float shade = smoothstep(0.0, 1.0, e) * (1.0 - facing);
    half3 rgb = c.rgb;
    rgb += half3(half(spec *(0.10 + 0.22 * facing) * rim.z)) * c.a;
    rgb *= half(1.0 - 0.10 * shade * rim.z);
    return half4(rgb, c.a);
}
