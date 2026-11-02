import Foundation
import PofuCore

/// What lights the world at one moment: the time of day as weights, the
/// color grade, and the strengths of the "painted HD-2D lite" layers
/// (bloom, light shafts, ambient particles). Pure, so it is tested on any
/// platform; `IslandScene` draws it.
///
/// It reads only the world's clock and Pofu's state, like the rest of the
/// scene: time of day picks the hour's grade, low wellbeing layers the
/// mild `unwell` desaturation over it, and high calm layers a warm glow.
public struct WorldLight: Hashable, Sendable {
    /// Time-of-day weights; they sum to 1.
    public var day: Double
    public var golden: Double
    public var night: Double
    /// How much of the `unwell` grade is layered on, 0…1.
    public var unwell: Double
    /// How much of the calm glow is layered on, 0…1.
    public var calmGlow: Double
    public var grade: WorldGrade
    /// The emissive points' glow (sun, lanterns, windows), 0…~1.4.
    public var bloom: Double
    /// Light shafts from the sun, 0…1 (golden hour).
    public var shafts: Double
    /// Pollen by day, 0…1.
    public var pollen: Double
    /// Fireflies at night, 0…1.
    public var fireflies: Double
    /// The sun (or the moon at night) in unit screen coordinates.
    public var sunX: Double
    public var sunY: Double

    /// The light at a local hour (0…24) for Pofu's state.
    ///
    /// - Parameters:
    ///   - hour: Local time as hours, e.g. 18.5 for 18:30.
    ///   - wellbeing: Pofu's wellbeing, 5…100.
    ///   - calm: The calm multiplier, 1…2.
    ///   - isBedtime: The bedtime window; it is always night.
    ///   - darkAppearance: The system's dark mode, which leans the day
    ///     toward night as the living sky does.
    public static func at(
        hour: Double,
        wellbeing: Double,
        calm: Double,
        isBedtime: Bool = false,
        darkAppearance: Bool = false
    ) -> WorldLight {
        var (day, golden, night) = phaseWeights(hour: hour)
        if isBedtime {
            (day, golden, night) = (0, 0, 1)
        } else if darkAppearance {
            let k = 0.82  // as SkyModel leans the sky
            (day, golden, night) = (day * (1 - k), golden * (1 - k), night + (day + golden) * k)
        }
        let unwell = smooth(min(max((55 - wellbeing) / 25, 0), 1))
        let glow = smooth(min(max((calm - 1.6) / 0.4, 0), 1)) * (1 - unwell)

        let phase = WorldGrade.mix(
            WorldGrade.mix(.day, .goldenHour, golden / max(day + golden, 1e-9)),
            .night,
            night
        )
        let grade = phase
            .layered(with: .unwell, amount: unwell)
            .layered(with: .calmGlow, amount: glow)

        // The sun sinks and warms toward golden hour; the moon sits high
        // on the right at night.
        let sunX = (0.24 * day + 0.16 * golden + 0.78 * night)
        let sunY = (0.12 * day + 0.30 * golden + 0.14 * night)
        return WorldLight(
            day: day,
            golden: golden,
            night: night,
            unwell: unwell,
            calmGlow: glow,
            grade: grade,
            bloom: (0.55 * day + 1.0 * golden + 1.0 * night) * (1 - 0.3 * unwell) + 0.35 * glow,
            shafts: golden * (1 - 0.5 * unwell),
            pollen: (day + golden * 0.8) * (1 - 0.6 * unwell),
            fireflies: night * (1 - 0.5 * unwell),
            sunX: sunX,
            sunY: sunY
        )
    }

    /// The light for a world snapshot, at the snapshot's clock in
    /// `calendar`'s time zone, or at `hourOverride`.
    public static func resolve(
        world: WorldSnapshot,
        calendar: Calendar,
        hourOverride: Double? = nil,
        darkAppearance: Bool = false
    ) -> WorldLight {
        let hour = hourOverride ?? world.clock.map { date in
            let c = calendar.dateComponents([.hour, .minute], from: date)
            return Double(c.hour ?? 12) + Double(c.minute ?? 0) / 60
        } ?? 12
        return at(
            hour: hour,
            wellbeing: world.wellbeing,
            calm: world.calm,
            isBedtime: world.isBedtime,
            darkAppearance: darkAppearance && hourOverride == nil
        )
    }

    /// Day, golden and night weights for a local hour, on the living
    /// sky's keyframes (`SkyModel`): night until 5:15, dawn (golden light)
    /// 5:45–7:45, day 8:15–17:15, golden 17:45–20:15, night from 20:45,
    /// with half-hour blends between.
    public static func phaseWeights(hour: Double) -> (day: Double, golden: Double, night: Double) {
        let h = (hour.isFinite ? hour : 12).truncatingRemainder(dividingBy: 24)
        let hour = h < 0 ? h + 24 : h
        func ramp(_ a: Double, _ b: Double) -> Double { smooth(min(max((hour - a) / (b - a), 0), 1)) }
        switch hour {
        case ..<5.25: return (0, 0, 1)
        case ..<5.75:
            let t = ramp(5.25, 5.75)
            return (0, t, 1 - t)
        case ..<7.75: return (0, 1, 0)
        case ..<8.25:
            let t = ramp(7.75, 8.25)
            return (t, 1 - t, 0)
        case ..<17.25: return (1, 0, 0)
        case ..<17.75:
            let t = ramp(17.25, 17.75)
            return (1 - t, t, 0)
        case ..<20.25: return (0, 1, 0)
        case ..<20.75:
            let t = ramp(20.25, 20.75)
            return (0, 1 - t, t)
        default: return (0, 0, 1)
        }
    }

    private static func smooth(_ t: Double) -> Double {
        t * t * (3 - 2 * t)
    }
}

/// Per-framing tuning of the look (interaction spec §12; look-dev B, C).
public enum LookTuning {
    /// How much stronger the depth lens is than the plain rail lens: the
    /// HD-2D tilt-shift. 1 is the rail's own lens; the map stays sharp.
    public static func tiltShift(z: Double) -> Double {
        let z = min(max(z.isFinite ? z : 2, 0), 2)
        // Map 1.0 → Island 1.7 → Home 1.3.
        if z <= 1 { return 1 + 0.7 * z }
        return 1.7 - 0.4 * (z - 1)
    }

    /// The terrarium rim's strength: full at the Island and Map framings,
    /// gone at Home, where Pofu fills the screen.
    public static func terrariumRim(z: Double) -> Double {
        let z = z.isFinite ? z : 2
        return 1 - min(max((z - 1.05) / 0.45, 0), 1)
    }

    /// How long the effects stay live after the scene appears (a visit),
    /// in seconds; after that the settled frame is cached.
    public static let visitSeconds = 6.0
}

extension Lens {
    /// The lens with its depth of field strengthened by `strength`: the
    /// gain grows and the in-focus slab narrows by its square root, so the
    /// focus plane itself stays sharp.
    public func tiltShifted(by strength: Double) -> Lens {
        let k = max(strength.isFinite ? strength : 1, 0.01)
        return Lens(focus: focus, slab: slab / k.squareRoot(), gain: gain * k)
    }
}
