import Foundation

/// The sun's (and at night the moon's) shadow on the ground at one moment
/// (light and shadow v2, §2): which way it falls, how long it is, how dark,
/// soft and tinted, and the ambient pad every object keeps. Pure, so it is
/// tested on any platform; `ShadowBake` draws it.
///
/// Build it from the light that carries the sky's sun (`WorldLight.withSun`),
/// so the shadow follows the sun the player sees.
public struct SunShadow: Hashable, Sendable {
    public enum Band: Int, Hashable, Sendable {
        case day, golden, night
    }

    public var band: Band
    /// The unit ground direction away from the sun, before foreshortening
    /// (x to the right, y toward the viewer).
    public var azimuth: WorldPoint
    /// `azimuth` with y foreshortened (`ShadowTuning.groundForeshortening`):
    /// a point at height `h` casts its shadow `direction · length · h` away.
    public var direction: WorldPoint
    /// The shadow's length as a multiple of the object's height.
    public var length: Double
    public var opacity: Double
    /// 0 crisp … 1 very soft.
    public var softness: Double
    /// The shadow's hue (`cell.shadow`, blue at night).
    public var tint: GradeRGB
    /// The ambient pad's opacity at an object's base.
    public var padOpacity: Double

    /// What the baked shadow layer depends on; it rebuilds only when this
    /// changes: direction and length in 3° and 0.1 steps, the opacities
    /// and the tint in coarse steps, and the time band.
    public struct Key: Hashable, Sendable {
        public var angle: Int
        public var length: Int
        public var opacity: Int
        public var padOpacity: Int
        public var tint: [Int]
        public var band: Band
    }

    public var key: Key {
        let degrees = atan2(azimuth.y, azimuth.x) * 180 / .pi
        func steps(_ value: Double, _ step: Double) -> Int { Int((value / step).rounded()) }
        let n = ShadowTuning.tintSteps
        return Key(
            angle: steps(degrees, ShadowTuning.angleStep),
            length: steps(length, ShadowTuning.lengthStep),
            opacity: steps(opacity, ShadowTuning.opacityStep),
            padOpacity: steps(padOpacity, ShadowTuning.opacityStep),
            tint: [Int((tint.r * n).rounded()), Int((tint.g * n).rounded()), Int((tint.b * n).rounded())],
            band: band
        )
    }

    /// The shadow for `light`. The sun's screen position places the shadow
    /// (the sun is behind the island, so the shadow always leans toward the
    /// viewer and away from the sun's side); its height sets the length.
    public static func make(light: WorldLight) -> SunShadow {
        let night = clamp(light.night)
        let gx = 0.5 - light.sunX
        let gy = ShadowTuning.towardCamera
        let norm = max((gx * gx + gy * gy).squareRoot(), 1e-9)
        let azimuth = WorldPoint(x: gx / norm, y: gy / norm)
        let direction = WorldPoint(x: azimuth.x, y: azimuth.y * ShadowTuning.groundForeshortening)

        // Dawn is golden light with the sun on the left of the sky.
        let dawn = light.sunX < 0.5
        let goldenOpacity = dawn ? ShadowTuning.dawnOpacity : ShadowTuning.goldenOpacity
        let goldenSoftness = dawn ? ShadowTuning.dawnSoftness : ShadowTuning.goldenSoftness
        let sunWeight = max(light.day + light.golden, 1e-9)
        let sunOpacity = (light.day * ShadowTuning.dayOpacity + light.golden * goldenOpacity) / sunWeight
        let sunSoftness = (light.day * ShadowTuning.daySoftness + light.golden * goldenSoftness) / sunWeight

        let opacity = mix(sunOpacity, ShadowTuning.moonOpacity, night)
        let length = mix(length(forSunY: light.sunY), ShadowTuning.moonLength, night)
        let softness = mix(sunSoftness, ShadowTuning.moonSoftness, night)
        let shadow = light.cell.shadow
        let moon = ShadowTuning.moonTint
        let tint = GradeRGB(mix(shadow.r, moon.r, night), mix(shadow.g, moon.g, night), mix(shadow.b, moon.b, night))
        let band: Band = night > 0.5 ? .night : (light.golden > light.day ? .golden : .day)
        return SunShadow(
            band: band,
            azimuth: azimuth,
            direction: direction,
            length: length,
            opacity: opacity,
            softness: softness,
            tint: tint,
            padOpacity: mix(ShadowTuning.padOpacityDay, ShadowTuning.padOpacityNight, night)
        )
    }

    /// The length for a sun height, interpolated over `ShadowTuning.lengthBySunY`.
    public static func length(forSunY y: Double) -> Double {
        let table = ShadowTuning.lengthBySunY
        guard let first = table.first, let last = table.last else { return 1 }
        if !(y > first.sunY) { return first.length }
        if y >= last.sunY { return last.length }
        for (a, b) in zip(table, table.dropFirst()) where y <= b.sunY {
            return mix(a.length, b.length, (y - a.sunY) / (b.sunY - a.sunY))
        }
        return last.length
    }

    /// Where a point `height` above the ground at `anchor` casts its shadow
    /// on the ground, in world units.
    public func cast(from anchor: WorldPoint, height: Double) -> WorldPoint {
        WorldPoint(x: anchor.x + direction.x * length * height, y: anchor.y + direction.y * length * height)
    }

    private static func mix(_ a: Double, _ b: Double, _ t: Double) -> Double {
        a + (b - a) * clamp(t)
    }

    private static func clamp(_ t: Double) -> Double {
        min(max(t.isFinite ? t : 0, 0), 1)
    }
}
