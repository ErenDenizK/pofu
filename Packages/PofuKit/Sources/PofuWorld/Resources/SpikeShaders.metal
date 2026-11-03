// Graphics spike shaders (PofuWorld): code lighting from baked normal maps
// and depth of field from a depth map. Behind the tuning-lab toggles only.
//
// Like WorldShaders.metal, Xcode compiles this into default.metallib in the
// package's resource bundle; command-line `swift build` only copies it.

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

namespace pofuspike {

constexpr sampler spikeSampler(filter::linear, address::clamp_to_edge);

// The exponent the sampler applied to a texture whose pixel (0, 0) was
// authored as 0.5 in the red channel. The baker (tools/assets/normals.py)
// always leaves a normal map's border at the flat normal, and the depth map
// draws a 0.5 swatch there, so if the sampler returns sRGB-decoded colours
// the exponent undoes it and the data reads the same either way.
inline float decodeExponent(texture2d<half> tex) {
    float flat = float(tex.read(uint2(0, 0)).r);
    return clamp(log(max(flat, 0.02)) / log(0.5), 0.6, 3.5);
}

// RelightMath (PofuWorld/Look/RelightMath.swift) is this function's CPU twin.
inline float3 relight(
    float3 albedo, float3 n, float2 position,
    float3 L, float3 keyColour, float3 ambient, float3 rim,
    float4 p0, float3 c0, float4 p1, float3 c1, float strength
) {
    const float wrap = 0.35;
    float nl = dot(n, L);
    float d = saturate((nl + wrap) / (1.0 + wrap)) - saturate((L.z + wrap) / (1.0 + wrap));
    float3 rgb = albedo * (1.0 + strength * 1.6 * keyColour * d);
    rgb += albedo * ambient * (strength * 0.5 * n.y);
    float4 pts[2] = { p0, p1 };
    float3 cols[2] = { c0, c1 };
    for (int i = 0; i < 2; i++) {
        if (pts[i].w <= 0.0) { continue; }
        // y is up in the shader and down on screen.
        float3 v = float3(pts[i].x - position.x, -(pts[i].y - position.y), pts[i].z);
        float dist = max(length(v), 1e-4);
        float t = max(1.0 - dist / pts[i].w, 0.0);
        float ndl = max(dot(n, v / dist), 0.0);
        rgb += albedo * cols[i] * (t * t * ndl * strength * 1.4);
    }
    float edge = pow(max(1.0 - n.z, 0.0), 1.5);
    float side = saturate(dot(n.xy, L.xy) * 1.3 + 0.15);
    rgb += rim * (edge * side * strength);
    return saturate(rgb);
}

inline float cocRadius(float d, float4 lens, float behind) {
    float delta = d - lens.x;
    float excess = max(abs(delta) - lens.y, 0.0) * (delta < 0.0 ? behind : 1.0);
    float t = saturate(excess / max(lens.z, 1e-4));
    return lens.w * t * t * (3.0 - 2.0 * t);
}

// The depth at a point in the layer's points, or -1 where the map has no
// data (so nothing blurs there).
inline float depthAt(texture2d<half> tex, float2 position, float2 size, float exponent) {
    half4 s = tex.sample(spikeSampler, position / max(size, float2(1.0)));
    if (s.a < 0.5h) { return -1.0; }
    return pow(max(float(s.r), 0.0), 1.0 / exponent);
}

} // namespace pofuspike

// Relights one sprite (or the live companion) from its normal map.
//
// normalTex: the baked tangent-space normal map
// info:      (width pt, height pt, mode, unused); mode 1 shows the normals
// uvRect:    (u0, v0, du, dv): uv = (u0, v0) + position / size * (du, dv)
// key:       vector toward the key, x right, y up, z out
// p0, p1:    practicals (x, y, height, radius) in the view's points; radius
//            0 switches one off; c0, c1 are their colours times strength
[[ stitchable ]] half4 pofuRelight(
    float2 position,
    half4 color,
    texture2d<half> normalTex,
    float4 info,
    float4 uvRect,
    float3 key,
    float3 keyColour,
    float3 ambient,
    float3 rim,
    float4 p0,
    float3 c0,
    float4 p1,
    float3 c1,
    float strength
) {
    if (color.a <= 0.0h) {
        return color;
    }
    float2 uv = uvRect.xy + position / max(info.xy, float2(1.0)) * uvRect.zw;
    float g = pofuspike::decodeExponent(normalTex);
    float3 raw = float3(normalTex.sample(pofuspike::spikeSampler, uv).rgb);
    float3 t = pow(max(raw, float3(0.0)), float3(1.0 / g));
    float3 n = normalize(t * 2.0 - 1.0);
    if (info.z > 0.5) {
        return half4(half3(t) * color.a, color.a);
    }
    float3 albedo = float3(color.rgb) / float(color.a);
    float3 rgb = pofuspike::relight(albedo, n, position, normalize(key), keyColour, ambient, rim, p0, c0, p1, c1, strength);
    return half4(half3(rgb) * color.a, color.a);
}

// One pass of the separable, depth-aware blur. The scene's depth map is
// ground by screen row and flat per object (0 sky, 1 nearest); its
// top-left pixel is a 0.5 swatch. DepthOfField
// (PofuWorld/Depth/DepthOfField.swift) is the CPU twin of the radius.
// Two passes of 6 + 6 taps each keep the cost at 26 taps a pixel.
//
// lens:  (focus, slab, range, max radius pt); depths in the map's 0...1
// setup: (width pt, height pt, mode, behind bias); mode 2 shows the depth
// dir:   (1, 0) or (0, 1)
[[ stitchable ]] half4 pofuDepthBlur(
    float2 position,
    SwiftUI::Layer layer,
    texture2d<half> depthTex,
    float4 lens,
    float4 setup,
    float2 dir
) {
    float2 size = setup.xy;
    float g = pofuspike::decodeExponent(depthTex);
    float d = pofuspike::depthAt(depthTex, position, size, g);
    if (setup.z > 1.5) {
        half v = half(max(d, 0.0));
        return half4(v, v, v, 1.0h);
    }
    half4 centre = layer.sample(position);
    if (d < 0.0 || (position.x < 6.0 && position.y < 6.0)) {
        return centre;
    }
    float r = pofuspike::cocRadius(d, lens, setup.w);
    if (r < 0.35) {
        return centre;
    }

    const int taps = 6;
    float4 sum = float4(centre);
    float wsum = 1.0;
    for (int i = 1; i <= taps; i++) {
        float t = float(i) / float(taps);
        float gauss = exp(-2.0 * t * t);
        for (int s = -1; s <= 1; s += 2) {
            float2 p = position + dir * (r * t * float(s));
            float dt = pofuspike::depthAt(depthTex, p, size, g);
            float w = gauss;
            if (dt > d + 0.01) {
                // A nearer tap reaches this pixel only if its own blur
                // does: a sharp object never bleeds into what is behind it.
                float rt = pofuspike::cocRadius(dt, lens, setup.w);
                w *= saturate(rt / max(r * t, 0.5));
            }
            sum += float4(layer.sample(p)) * w;
            wsum += w;
        }
    }
    return half4(sum / wsum);
}
