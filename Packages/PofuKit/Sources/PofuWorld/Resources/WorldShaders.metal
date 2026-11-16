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
inline half3 grade(half3 x, float2 levels, float3 lift, float3 gamma, float3 gain, float contrast, float pivot, float saturation) {
    float3 c = float3(x);
    c = (c - levels.x) / max(levels.y - levels.x, 1e-3);
    c = gain * (c + lift * (1.0 - c));
    c = pow(max(c, 0.0), 1.0 / max(gamma, float3(0.01)));
    c = (c - pivot) * contrast + pivot;
    float luma = dot(c, float3(0.2126, 0.7152, 0.0722));
    c = luma + (c - luma) * saturation;
    return half3(saturate(c));
}

constexpr sampler lutSampler(filter::linear, address::clamp_to_edge);

// One fitted LUT (look pipeline v2, LookLUT.swift), baked by
// tools/looklab/bake_luts.py as an (n*n) x (n+1) strip: row 0 is a 0.5 grey
// calibration row, row 1 + g, column b * n + r holds LUT[r, g, b]. Bilinear
// in red and green inside a blue slice, linear across the two nearest
// slices. Like the normal maps, the calibration texel undoes an sRGB decode
// if the texture was given one.
inline float3 lookLUT(texture2d<half> lut, float3 c) {
    const float n = 17.0;
    float g = clamp(log(max(float(lut.read(uint2(0, 0)).r), 0.02)) / log(0.5), 0.6, 3.5);
    float3 p = saturate(c) * (n - 1.0);
    float b0 = floor(p.b);
    float b1 = min(b0 + 1.0, n - 1.0);
    float fb = p.b - b0;
    float2 size = float2(n * n, n + 1.0);
    float2 uv0 = float2(b0 * n + p.r + 0.5, 1.0 + p.g + 0.5) / size;
    float2 uv1 = float2(b1 * n + p.r + 0.5, 1.0 + p.g + 0.5) / size;
    float3 s0 = float3(lut.sample(lutSampler, uv0).rgb);
    float3 s1 = float3(lut.sample(lutSampler, uv1).rgb);
    float3 v = mix(s0, s1, fb);
    return pow(max(v, float3(0.0)), float3(1.0 / g));
}

} // namespace pofuworld

// The runtime color grade and the vignette, on the world layer only.
//
// levels:            (black, white) input levels
// lift, gamma, gain: per channel
// shape:             (contrast, pivot, saturation, vignette)
// size:              the layer's size in points
// lut0...lut2:       the fitted LUTs after the grade (LookLUT), mixed by
//                    lutWeights; weights sum to at most 1, the rest is the
//                    graded colour itself. A zero weight samples nothing.
[[ stitchable ]] half4 pofuWorldGrade(
    float2 position,
    half4 color,
    float2 levels,
    float3 lift,
    float3 gamma,
    float3 gain,
    float4 shape,
    float2 size,
    texture2d<half> lut0,
    texture2d<half> lut1,
    texture2d<half> lut2,
    float3 lutWeights
) {
    if (color.a <= 0.0h) {
        return color;
    }
    half3 rgb = color.rgb / color.a;
    rgb = pofuworld::grade(rgb, levels, lift, gamma, gain, shape.x, shape.y, shape.z);
    float total = lutWeights.x + lutWeights.y + lutWeights.z;
    if (total > 0.001) {
        float3 c = float3(rgb);
        float3 mixed = c * (1.0 - total);
        if (lutWeights.x > 0.0) { mixed += pofuworld::lookLUT(lut0, c) * lutWeights.x; }
        if (lutWeights.y > 0.0) { mixed += pofuworld::lookLUT(lut1, c) * lutWeights.y; }
        if (lutWeights.z > 0.0) { mixed += pofuworld::lookLUT(lut2, c) * lutWeights.z; }
        rgb = half3(saturate(mixed));
    }

    // An elliptical vignette, gentle in the middle third, a little warm.
    float2 uv = (position / max(size, float2(1.0)) - 0.5) * 2.0;
    float d = length(uv * float2(1.0, 0.9)) / 1.345;
    float v = 1.0 - shape.w * pow(saturate((d - 0.3) / 0.7), 1.6);
    rgb *= half3(half(v), half(mix(v, 1.0, 0.06)), half(mix(v, 1.0, 0.02)));
    return half4(rgb * color.a, color.a);
}

// The thin lens's level blend (build spec WP11, D10; NearLensViews.swift). The island is drawn at
// four blur levels (0, 2, 6, 14 pt); this colour function weights one of them per pixel by the
// lens's radius there, so the levels add up to one picture. Self-contained: WP13's region shaders
// live beside it.
//
// depth:  the state's depth rows (NearDepthTexture): r the encoded row, g a standing thing's share
//         over the ground; texel (0, 0) is a 0.5 grey calibration texel
// map:    (screen x, screen y of plate pixel 0,0 in this layer, points per plate pixel, front cap)
// lens:   (focus row, world depth per row, N * s, D)              ThinLens's twin
// radii:  the four levels' radii
// pick:   (this level, lip row, row range low, row range high)
// limits: (plate width, plate height, skip radius, cap)
namespace pofulens {

constexpr sampler depthSampler(filter::linear, address::clamp_to_edge);

// ThinLens.radius: capped at `cap` behind the focal plane, at `frontCap` in front of it.
inline float radius(float row, float4 lens, float cap, float frontCap) {
    float delta = (lens.x - row) * lens.y;
    float limit = delta < 0.0 ? frontCap : cap;
    float d = lens.w + delta;
    if (d <= 1e-4) { return limit; }
    return min(lens.z * abs(delta) / d, limit);
}

// BlurLevels.effective, then BlurLevels.weight.
inline float weight(float r, float4 radii, int level, float skip, float cap) {
    float x = r <= skip ? 0.0 : (r >= radii.y ? min(r, cap) : (r - skip) * radii.y / (radii.y - skip));
    float at = radii[level];
    if (x == at) { return 1.0; }
    if (x < at) {
        if (level == 0) { return 1.0; }
        float below = radii[level - 1];
        return saturate((x - below) / (at - below));
    }
    if (level == 3) { return 1.0; }
    float above = radii[level + 1];
    return saturate((above - x) / (above - at));
}

} // namespace pofulens

[[ stitchable ]] half4 pofuLensLevel(
    float2 position,
    half4 color,
    texture2d<half> depth,
    float4 map,
    float4 lens,
    float4 radii,
    float4 pick,
    float4 limits
) {
    if (color.a <= 0.0h) {
        return color;
    }
    float2 plate = (position - map.xy) / max(map.z, 1e-4);
    float g = clamp(log(max(float(depth.read(uint2(0, 0)).r), 0.02)) / log(0.5), 0.6, 3.5);
    half4 t = depth.sample(pofulens::depthSampler, plate / limits.xy);
    float encoded = pow(max(float(t.r), 0.0), 1.0 / g);
    float share = pow(max(float(t.g), 0.0), 1.0 / g);
    float ground = min(plate.y, pick.y);
    float standing = pick.z + encoded * (pick.w - pick.z);
    float row = mix(ground, standing, saturate(share));
    float r = pofulens::radius(row, lens, limits.w, map.w);
    float w = pofulens::weight(r, radii, int(pick.x), limits.z, limits.w);
    return color * half(w);
}
