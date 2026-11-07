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
    /// The world's grade: plates and stations, with the island's fitted
    /// LUTs (look pipeline v2, `LookLUT`).
    public var grade: WorldGrade
    /// The sky's and the cloud sea's grade: only the overlays (wellbeing,
    /// calm, weather, the screen haze). Their colours in the colour script
    /// are final colours, measured from the references (look pipeline v2),
    /// so the hour's own grade never touches them again.
    public var backdropGrade: WorldGrade = .neutral
    /// The colour script's cell weights at this hour (they sum to 1).
    public var cellWeights: [ColourCell.Name: Double] = [:]
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
    public static func at(
        hour: Double,
        wellbeing: Double,
        calm: Double,
        isBedtime: Bool = false
    ) -> WorldLight {
        var weights = cellWeights(hour: hour)
        if isBedtime {
            weights = [.night: 1]
        }
        let (day, golden, night) = phases(weights)
        let unwell = smooth(min(max((55 - wellbeing) / 25, 0), 1))
        let glow = smooth(min(max((calm - 1.6) / 0.4, 0), 1)) * (1 - unwell)

        let cell = ColourScript.blend(weights)
        let state = ColourScript.unwell
        let lut = LookLUT.Blend(group: .island, cells: weights)
        let grade = cell.grade
            .layered(with: state.grade, amount: unwell)
            .layered(with: .calmGlow, amount: glow)
            .with(lut: lut)
        let backdrop = WorldGrade.neutral
            .layered(with: state.grade, amount: unwell)
            .layered(with: .calmGlow, amount: glow)
        var character = cell.character
            .layered(with: state.character, amount: unwell)
            .layered(with: .calmGlow, amount: glow * 0.5)
        // At night the pop comes from real light (`LightField`), so the
        // separate lift shrinks to a small readability exposure. Gain only,
        // so Pofu keeps his hue and saturation.
        character.gain = nightExposed(character.gain, night: night)
        character.lut = lut.for(.characters)
        let practicals = Practicals(
            ember: cell.practicals.ember,
            window: max(cell.practicals.window, state.windowFloor * unwell)
        )

        // The sun sinks and warms toward golden hour; the moon sits high
        // on the right at night.
        let sunX = (0.24 * day + 0.16 * golden + 0.78 * night)
        let sunY = (0.12 * day + 0.30 * golden + 0.14 * night)
        var light = WorldLight(
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
        light.backdropGrade = backdrop
        light.cellWeights = weights
        return light
    }

    /// The light for a world snapshot, at the snapshot's clock in
    /// `calendar`'s time zone, or at `hourOverride`.
    public static func resolve(
        world: WorldSnapshot,
        calendar: Calendar,
        hourOverride: Double? = nil
    ) -> WorldLight {
        let hour = hourOverride ?? world.clock.map { date in
            let c = calendar.dateComponents([.hour, .minute], from: date)
            return Double(c.hour ?? 12) + Double(c.minute ?? 0) / 60
        } ?? 12
        return at(
            hour: hour,
            wellbeing: world.wellbeing,
            calm: world.calm,
            isBedtime: world.isBedtime
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

    /// A gain scaled by the night's shrink and readability exposure.
    static func nightExposed(_ gain: GradeRGB, night: Double) -> GradeRGB {
        let k = 1 - LookTuning.nightCharacterShrink * night + LookTuning.nightReadabilityExposure * night
        return GradeRGB(gain.r * k, gain.g * k, gain.b * k)
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

    /// Half the depth of field's in-focus slab when nothing is focused, in
    /// depth units around Pofu (depth 54): it reaches past the lawn's back
    /// edge (depth about -87) and the stations on it, so the whole island
    /// is sharp and the blur only takes what lies beyond it (concept match,
    /// `docs/research/concept-match.md`: the concepts' back row keeps 0.8
    /// to 1.4x the front row's local contrast; at a 34 slab the game kept
    /// 0.42x).
    public static let islandSharpSlab = 150.0

    /// How long the effects stay live after the scene appears (a visit),
    /// in seconds; after that the settled frame is cached.
    public static let visitSeconds = 2.5

    // MARK: Sky and fog (sky and weather v1 §2.1, §2.3). Starting values; tuned on device.

    /// Depth fog by tier, front to farthest: how far a layer is mixed
    /// toward the current horizon colour (`FogModel`).
    public static let fogTiers: [Double] = [0, 0.18, 0.38, 0.55]
    /// The distance (`FarSkyLayout.Element.distance`, 0 front to 1
    /// farthest) each tier sits at; between them the fog interpolates.
    public static let fogTierDistances: [Double] = [0, 0.4, 0.7, 1]
    /// Added to every tier behind the front one in mist (`mist` 1).
    public static let fogMistExtra = 0.15
    /// Shadows mix this much more fog than lights, so contrast collapses
    /// with distance.
    public static let fogShadowFactor = 1.25
    /// Fog never reaches full cover, even on a shadow in mist.
    public static let fogMaximum = 0.92

    /// Height fog cards: their peak opacity in clear weather and in full
    /// mist, their drift at 1x (points a second; the cards move at 1x, 2x
    /// and 3.5x of it) and their wrap speed multiples.
    public static let fogCardClearOpacity = 0.30
    public static let fogCardMistOpacity = 0.75
    public static let fogCardDrift = 0.8
    public static let fogCardSpeedMultiples: [Double] = [1, 2, 3.5]

    /// Clouds in three layers: the parallax multiples against the base
    /// (far 1x, mid 1.8x, near 3x), the base share of the peek, how many
    /// L* the shade takes off the zenith per layer, and how often the tint
    /// may be recomputed (seconds).
    public static let cloudParallaxMultiples: [Double] = [1, 1.8, 3]
    public static let cloudParallaxBase = 0.3
    public static let cloudShadeDarkening: [Double] = [15, 20, 25]
    public static let cloudTintSeconds = 3.0
    /// The fastest a cloud drifts at the 30 Hz tier, points a second.
    public static let cloudMaxSpeed = 3.0

    /// Night stays luminous: the zenith never falls below this L*.
    public static let nightZenithFloor = 12.0
    /// Look pipeline v2: the night relight starts above this night share
    /// (dusk is 0.5) and is full at night.
    public static let nightRelightFrom = 0.2
    /// The light field's sources as relight practicals: their reach on a
    /// character (times the pool's reach) and their gain.
    public static let nightRelightReach = 1.6
    public static let nightRelightSourceGain = 0.9
    /// The contact pad (look pipeline v2, look lab §4): its wide falloff
    /// and its core, and a station's pad strength (was 0.20, 0.16 and 1.9;
    /// the references' contact is lighter and softer).
    public static let padOuterOpacity = 0.15
    public static let padCoreOpacity = 0.08
    public static let stationPadStrength = 1.4
    /// How much of the cloud sea's light colour the front fog card takes
    /// over the sky's horizon (look pipeline v2).
    public static let frontFogSeaShare = 0.6
    /// Stars: how many, and how fast they twinkle (Hz).
    public static let starCount = 36
    public static let starTwinkleHz: ClosedRange<Double> = 0.1...0.3
    /// The moon's halo, as a share of the screen width.
    public static let moonHaloRadius = 0.2

    /// Koke at stage 0 (§2.4), by stage (stages 3 and 4 are clear): value
    /// over chroma. The depth fog stays light so the island keeps its
    /// contrast; the shade grade (a multiply toward a deep blue-violet, light
    /// at the lit rim and full below), the contrast and the deeper sky behind
    /// give it value; one warm shaft lands on the sprout.
    public static let kokeFogAmount: [Double] = [0.08, 0.05, 0.02, 0, 0]
    public static let kokeShaftAlpha: [Double] = [0.18, 0.12, 0.08, 0, 0]
    public static let kokeShade: [Double] = [0.40, 0.26, 0.10, 0, 0]
    public static let kokeContrast: [Double] = [1.18, 1.10, 1.04, 1, 1]
    public static let kokeCardOpacity: [Double] = [0.60, 0.35, 0.12, 0, 0]
    /// How many L* the sky behind Koke deepens (and a push toward blue).
    public static let kokeSkyDeepen: [Double] = [9, 5, 2, 0, 0]

    // MARK: Light field (experience v1 §2). Starting values; tuned on device.

    /// The calm lantern's strength at calm ×1.0 and ×2.0.
    public static let lanternMinimum = 0.4
    public static let lanternMaximum = 1.0
    /// The lantern's slot relative to Pofu's feet, in world units, and its
    /// height; `HomeSlots.lantern` must match.
    public static var lanternOffsetX: Double { HomeSlots.lanternEmitterOffset.x }
    public static var lanternOffsetY: Double { HomeSlots.lanternEmitterOffset.y }
    public static let lanternHeight = 40.0
    /// Pool reaches along the ground, in world units.
    public static let lanternReach = 64.0
    public static let windowSpillReach = 46.0
    public static let lampReach = 52.0
    public static let pondReach = 56.0
    /// How much a source's height tilts the light direction (height to
    /// ground-plane depth).
    public static let heightToDepth = 0.5
    /// At night, how much of the characters' separate lift is taken away
    /// (the pop now comes from real light) and the small readability
    /// exposure that stays.
    public static let nightCharacterShrink = 0.22
    public static let nightReadabilityExposure = 0.08
    /// How much of a source's strength becomes the character's key, the
    /// bounce on the lower third and the readability floor's lift (the
    /// characters' night shadows are `ShadowTuning`'s).
    public static let keyGain = 0.6
    public static let bounceGain = 0.5
    public static let floorGain = 0.5
    /// How strongly a pool of the baked light map glows: the glow-ground-pool
    /// art's opacity at full source strength; the pool is alpha over the
    /// lawn, so it cannot add more than this much of its colour.
    public static let poolArtOpacity = 0.45
    /// The window spill art (`glow-window-spill`): the square art's side as a
    /// multiple of the source's reach, and its opacity at full strength.
    public static let windowSpillArtScale = 1.15
    public static let windowSpillOpacity = 0.6
    /// The pond's shimmer art (`glow-pond-shimmer`) at full strength.
    public static let pondShimmerOpacity = 0.5
    /// A halo's art (`glow-warm-halo`) draws this much wider than the radius
    /// the bloom fades out at: the painted disc has a soft rim.
    public static let warmHaloArtScale = 1.15
    /// A field source's halo (lantern, path lamp, window) reaches this many
    /// times its core radius, at this opacity at full strength: the liked
    /// night references' lamp halos spread 3 to 4 times the lamp's body and
    /// lift the air around it (ADR-0021, `docs/research/reference-look.md`
    /// principle 11). Was 3x at 0.22.
    public static let fieldHaloSpread = 4.0
    public static let fieldHaloOpacity = 0.3
    /// The fireflies (`firefly-1...4`, four frames of one bug: belly dim,
    /// warming, bright, dim): how many, how wide in world units, the halo's
    /// radius, and the frame a blink 0.25...1 shows.
    public static let fireflyCount = 18
    public static let fireflyWidth = 9.0
    public static let fireflyHaloRadius = 10.0
    public static func fireflyFrame(blink: Double) -> Int {
        blink < 0.45 ? 0 : blink < 0.75 ? 1 : 2
    }
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
