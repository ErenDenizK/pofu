import Foundation
import PofuCore

/// What lights the world at one moment: the colour script's cell for the
/// hour (look round 3), the world's grade and the characters' light, the
/// practical lights, and the strengths of the "painted HD-2D lite" layers
/// (bloom, light shafts, ambient particles). Pure, so it is tested on any
/// platform; `IslandScene` draws it.
///
/// It reads only the world's clock and Pofu's state, like the rest of the
/// scene: the hour picks the colour script's cell, low wellbeing layers the
/// unwell state over it, and high calm layers a warm glow.
public struct WorldLight: Hashable, Sendable {
    /// Time-of-day weights for the effects; they sum to 1 (dawn counts as
    /// golden light, dusk half golden, half night).
    public var day: Double
    public var golden: Double
    public var night: Double
    /// How much of the unwell state is layered on, 0…1.
    public var unwell: Double
    /// How much of the calm glow is layered on, 0…1.
    public var calmGlow: Double
    /// The colour script's cell for the hour, blended between its
    /// neighbours.
    public var cell: ColourCell
    /// The world's grade: plates and stations.
    public var grade: WorldGrade
    /// Pofu's and the residents' light: the cell's key and fill with the
    /// unwell state at a gentler strength, never the world's saturation cut
    /// or contrast push (pro-game-craft §4.3).
    public var characterGrade: WorldGrade
    /// The practical lights' strengths, 0…1.
    public var practicals: Practicals
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
        var weights = cellWeights(hour: hour)
        if isBedtime {
            weights = [.night: 1]
        } else if darkAppearance {
            let k = 0.82  // as SkyModel leans the sky
            weights = weights.mapValues { $0 * (1 - k) }
            weights[.night, default: 0] += k
        }
        let (day, golden, night) = phases(weights)
        let unwell = smooth(min(max((55 - wellbeing) / 25, 0), 1))
        let glow = smooth(min(max((calm - 1.6) / 0.4, 0), 1)) * (1 - unwell)

        let cell = ColourScript.blend(weights)
        let state = ColourScript.unwell
        let grade = cell.grade
            .layered(with: state.grade, amount: unwell)
            .layered(with: .calmGlow, amount: glow)
        let character = cell.character
            .layered(with: state.character, amount: unwell)
            .layered(with: .calmGlow, amount: glow * 0.5)
        let practicals = Practicals(
            ember: cell.practicals.ember,
            window: max(cell.practicals.window, state.windowFloor * unwell)
        )

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
            cell: cell,
            grade: grade,
            characterGrade: character,
            practicals: practicals,
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

    /// This light with the sun (or moon) at a unit screen point.
    public func withSun(x: Double, y: Double) -> WorldLight {
        var copy = self
        copy.sunX = x
        copy.sunY = y
        return copy
    }

    /// The colour script's cell weights at a local hour.
    public static func cellWeights(hour: Double) -> [ColourCell.Name: Double] {
        let h = (hour.isFinite ? hour : 12).truncatingRemainder(dividingBy: 24)
        return ColourScript.weights(minuteOfDay: (h < 0 ? h + 24 : h) * 60)
    }

    /// Day, golden and night weights for a local hour, on the colour
    /// script's schedule (the living sky's too): night until 5:15, dawn
    /// (golden light) 5:45–7:15, day 7:45–17:15, golden 17:45–19:15, dusk
    /// (half golden, half night) 19:45–20:15, night from 20:45, with
    /// half-hour blends between.
    public static func phaseWeights(hour: Double) -> (day: Double, golden: Double, night: Double) {
        phases(cellWeights(hour: hour))
    }

    static func phases(_ w: [ColourCell.Name: Double]) -> (day: Double, golden: Double, night: Double) {
        let dusk = w[.dusk] ?? 0
        return (w[.day] ?? 0, (w[.dawn] ?? 0) + (w[.golden] ?? 0) + dusk / 2, (w[.night] ?? 0) + dusk / 2)
    }

    private static func smooth(_ t: Double) -> Double {
        t * t * (3 - 2 * t)
    }
}

/// Per-framing tuning of the look (interaction spec §12; look-dev B).
public enum LookTuning {
    /// How much stronger the depth lens is than the plain rail lens: the
    /// HD-2D tilt-shift. 1 is the rail's own lens; the map stays sharp.
    public static func tiltShift(z: Double, island: Double = 1.7, home: Double = 1.3) -> Double {
        let z = min(max(z.isFinite ? z : 2, 0), 2)
        // Map 1.0 → Island 1.7 → Home 1.3 (the tuning lab panel tunes the two).
        if z <= 1 { return 1 + (island - 1) * z }
        return island + (home - island) * (z - 1)
    }

    /// How long the effects stay live after the scene appears (a visit),
    /// in seconds; after that the settled frame is cached.
    public static let visitSeconds = 2.5
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
