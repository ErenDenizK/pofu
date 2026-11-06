import Foundation
import PofuCore

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
    /// At night, the shadows of the characters that stand in the reach of a
    /// light source, by caster id (`ShadowCasters`): they fall away from the
    /// source instead of the moon's direction. Empty by day.
    public var characters: [String: SourceShadow] = [:]

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
        public var characters: [String: SourceShadow]
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
            band: band,
            characters: characters
        )
    }

    /// This shadow with the direction, length, opacity and softness of a
    /// caster's own source shadow (the hue and the pad stay).
    func applying(_ source: SourceShadow) -> SunShadow {
        var copy = self
        let radians = Double(source.angle) * ShadowTuning.angleStep * .pi / 180
        copy.azimuth = WorldPoint(x: cos(radians), y: sin(radians))
        copy.direction = WorldPoint(x: copy.azimuth.x, y: copy.azimuth.y * ShadowTuning.groundForeshortening)
        copy.length = Double(source.length) * ShadowTuning.lengthStep
        copy.opacity = Double(source.opacity) * ShadowTuning.opacityStep
        copy.softness = ShadowTuning.sourceSoftness
        copy.characters = [:]
        return copy
    }

    /// The shadow for `light`. The sun's screen position places the shadow
    /// (the sun is behind the island, so the shadow always leans toward the
    /// viewer and away from the sun's side); its height sets the length.
    ///
    /// - Parameter world: With it, at night each character in the reach of
    ///   a light source casts away from that source (`characters`).
    public static func make(light: WorldLight, world: WorldSnapshot? = nil) -> SunShadow {
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
        let shadow = darkened(light.cell.shadow, to: ShadowTuning.tintLuminance)
        let moon = ShadowTuning.moonTint
        let tint = GradeRGB(mix(shadow.r, moon.r, night), mix(shadow.g, moon.g, night), mix(shadow.b, moon.b, night))
        let band: Band = night > 0.5 ? .night : (light.golden > light.day ? .golden : .day)
        var result = SunShadow(
            band: band,
            azimuth: azimuth,
            direction: direction,
            length: length,
            opacity: opacity,
            softness: softness,
            tint: tint,
            padOpacity: mix(ShadowTuning.padOpacityDay, ShadowTuning.padOpacityNight, night)
        )
        if band == .night, let world {
            result.characters = SourceShadow.characters(field: LightField.make(world: world, light: light), world: world)
        }
        return result
    }

    /// `colour` with its hue kept and its luminance set to `luminance`
    /// (Rec. 709 weights), each channel at most 1.
    static func darkened(_ colour: GradeRGB, to luminance: Double) -> GradeRGB {
        let lum = 0.2126 * colour.r + 0.7152 * colour.g + 0.0722 * colour.b
        guard lum > 1e-6 else { return GradeRGB(luminance, luminance, luminance) }
        let k = luminance / lum
        return GradeRGB(min(colour.r * k, 1), min(colour.g * k, 1), min(colour.b * k, 1))
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
