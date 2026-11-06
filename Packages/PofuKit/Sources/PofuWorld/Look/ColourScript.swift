import Foundation
import PofuDesignSystem

/// Pofu's colour script (look round 3; `docs/design/colour-script.md`):
/// light carries the time of day, the grade only finishes it, and local
/// colour is protected by the material library. The numbers live in
/// `design/art/colour-script.json`; `tools/assets/colour_script.py`
/// generates `ColourScript+Generated.swift`, so Swift never hand-copies
/// them.
///
/// Five hour cells (dawn, day, golden, dusk, night) on one schedule that
/// the living sky and the world's light share, and the unwell state
/// layered over any hour.
public enum ColourScript {
    /// One key of the schedule: from this minute of the local day, this
    /// cell (blended linearly with the next key's), with the sun here when
    /// the key moves it.
    public struct Key: Hashable, Sendable {
        public var minute: Double
        public var cell: ColourCell.Name
        public var sun: SkyPoint?
    }

    /// A cell by name.
    public static func cell(_ name: ColourCell.Name) -> ColourCell {
        generatedCells[name] ?? generatedCells[.day] ?? .fallback
    }

    /// The schedule, minute 0 to 1440.
    public static var schedule: [Key] {
        generatedSchedule
    }

    /// The unwell state.
    public static var unwell: ColourState {
        generatedUnwell
    }

    /// A weather row or the screen haze by name (`design/art/colour-script.json`,
    /// states.weather); the identity-ish overcast row if the name is unknown.
    static func weather(named name: String) -> ColourState {
        generatedWeather[name] ?? generatedUnwell
    }

    /// How much of each cell lights a minute of the local day; the weights
    /// sum to 1.
    public static func weights(minuteOfDay minute: Double) -> [ColourCell.Name: Double] {
        let m = minute.isFinite ? min(max(minute, 0), 24 * 60) : 12 * 60
        let keys = schedule
        for (a, b) in zip(keys, keys.dropFirst()) where m >= a.minute && m <= b.minute {
            // A hold between two keys of one cell is exactly that cell.
            if a.cell == b.cell {
                return [a.cell: 1]
            }
            let span = b.minute - a.minute
            let t = span > 0 ? smooth((m - a.minute) / span) : 0
            return [a.cell: 1 - t, b.cell: t]
        }
        return [keys.last?.cell ?? .night: 1]
    }

    /// The cell at a minute of the local day: its neighbours blended.
    public static func cell(minuteOfDay minute: Double) -> ColourCell {
        blend(weights(minuteOfDay: minute))
    }

    /// Cells blended by weight.
    public static func blend(_ weights: [ColourCell.Name: Double]) -> ColourCell {
        var result: ColourCell?
        var total = 0.0
        for name in ColourCell.Name.allCases {
            guard let w = weights[name], w > 0 else { continue }
            let c = cell(name)
            total += w
            result = result.map { ColourCell.mix($0, c, w / total) } ?? c
        }
        return result ?? cell(.day)
    }

    static func smooth(_ t: Double) -> Double {
        let t = min(max(t, 0), 1)
        return t * t * (3 - 2 * t)
    }
}

/// One cell of the colour script: the hour's sky, its key, fill and rim
/// light, the practical lights, the fog on the far isles, the cloud sea,
/// the world's residual grade and the characters' light.
public struct ColourCell: Hashable, Sendable {
    public enum Name: String, CaseIterable, Hashable, Sendable {
        case dawn, day, golden, dusk, night
    }

    public var name: Name
    /// Where the sun (or the moon) sits, in unit screen coordinates.
    public var sun: SkyPoint
    public var sky: SkyColours
    /// The sun or the moon.
    public var key: ScriptLight
    /// The sky's colour in the shadows.
    public var fill: ScriptLight
    /// The hue shadows lean to (never neutral grey).
    public var shadow: GradeRGB
    /// The edge light on Pofu and the residents, toward the key or the
    /// nearest practical.
    public var rim: ScriptLight
    public var practicals: Practicals
    /// The light field's gains (experience v1 §2): how strongly the pools
    /// light the ground (0 by day), the floor of light every character
    /// keeps, and the thin cool moon rim between sources.
    public var poolGain: Double
    public var ambientFloor: Double
    public var moonRim: Double
    public var fog: ScriptFog
    public var sea: SeaColours
    /// The world's residual camera grade (plates and stations).
    public var grade: WorldGrade
    /// Pofu and the residents: the hour's key and fill, never the grade's
    /// saturation cut or contrast push (pro-game-craft §4.3).
    public var character: WorldGrade

    /// A straight blend of two cells; the name is the nearer one's.
    public static func mix(_ a: ColourCell, _ b: ColourCell, _ t: Double) -> ColourCell {
        let t = min(max(t.isFinite ? t : 0, 0), 1)
        if t == 0 { return a }
        if t == 1 { return b }
        func lerp(_ x: Double, _ y: Double) -> Double { x + (y - x) * t }
        return ColourCell(
            name: t < 0.5 ? a.name : b.name,
            sun: SkyPoint(x: lerp(a.sun.x, b.sun.x), y: lerp(a.sun.y, b.sun.y)),
            sky: .mix(a.sky, b.sky, t),
            key: .mix(a.key, b.key, t),
            fill: .mix(a.fill, b.fill, t),
            shadow: .mix(a.shadow, b.shadow, t),
            rim: .mix(a.rim, b.rim, t),
            practicals: Practicals(ember: lerp(a.practicals.ember, b.practicals.ember), window: lerp(a.practicals.window, b.practicals.window)),
            poolGain: lerp(a.poolGain, b.poolGain),
            ambientFloor: lerp(a.ambientFloor, b.ambientFloor),
            moonRim: lerp(a.moonRim, b.moonRim),
            fog: ScriptFog(colour: a.fog.colour.mixed(with: b.fog.colour, amount: t), far: lerp(a.fog.far, b.fog.far)),
            sea: SeaColours(
                light: a.sea.light.mixed(with: b.sea.light, amount: t),
                shade: a.sea.shade.mixed(with: b.sea.shade, amount: t),
                opacity: lerp(a.sea.opacity, b.sea.opacity)
            ),
            grade: .mix(a.grade, b.grade, t),
            character: .mix(a.character, b.character, t)
        )
    }

    static let fallback = ColourCell(
        name: .day,
        sun: SkyPoint(x: 0.5, y: 0.11),
        sky: SkyColours(
            zenith: PofuRGB(hex: 0xC4DEF2), horizon: PofuRGB(hex: 0xF8F0DF), glow: PofuRGB(hex: 0xFFF6DD), glowStrength: 0.62,
            cloudLight: PofuRGB(hex: 0xFFFFFF), cloudShade: PofuRGB(hex: 0xD8E3EF), cloudOpacity: 0.95, stars: 0, tint: PofuRGB(hex: 0xFFFFFF)
        ),
        key: ScriptLight(colour: GradeRGB(all: 1), intensity: 1),
        fill: ScriptLight(colour: GradeRGB(all: 0.8), intensity: 0.3),
        shadow: GradeRGB(all: 0.6),
        rim: ScriptLight(colour: GradeRGB(all: 1), intensity: 0),
        practicals: Practicals(ember: 0, window: 0),
        poolGain: 0,
        ambientFloor: 0,
        moonRim: 0,
        fog: ScriptFog(colour: PofuRGB(hex: 0xDCEAF4), far: 0.35),
        sea: SeaColours(light: PofuRGB(hex: 0xFFFFFF), shade: PofuRGB(hex: 0xD8E3EF), opacity: 0.95),
        grade: .neutral,
        character: .neutral
    )
}

/// The sky's colours in one cell.
public struct SkyColours: Hashable, Sendable {
    public var zenith: PofuRGB
    public var horizon: PofuRGB
    public var glow: PofuRGB
    public var glowStrength: Double
    public var cloudLight: PofuRGB
    public var cloudShade: PofuRGB
    public var cloudOpacity: Double
    public var stars: Double
    /// Multiplied over the painted world when the runtime grade is off.
    public var tint: PofuRGB

    static func mix(_ a: SkyColours, _ b: SkyColours, _ t: Double) -> SkyColours {
        func lerp(_ x: Double, _ y: Double) -> Double { x + (y - x) * t }
        return SkyColours(
            zenith: a.zenith.mixed(with: b.zenith, amount: t),
            horizon: a.horizon.mixed(with: b.horizon, amount: t),
            glow: a.glow.mixed(with: b.glow, amount: t),
            glowStrength: lerp(a.glowStrength, b.glowStrength),
            cloudLight: a.cloudLight.mixed(with: b.cloudLight, amount: t),
            cloudShade: a.cloudShade.mixed(with: b.cloudShade, amount: t),
            cloudOpacity: lerp(a.cloudOpacity, b.cloudOpacity),
            stars: lerp(a.stars, b.stars),
            tint: a.tint.mixed(with: b.tint, amount: t)
        )
    }
}

/// A light of the script: its colour, strength and, for the key, the
/// direction it comes from (unit screen vector, x right, y down).
public struct ScriptLight: Hashable, Sendable {
    public var colour: GradeRGB
    public var intensity: Double
    public var from: SkyPoint

    public init(colour: GradeRGB, intensity: Double, from: SkyPoint = SkyPoint(x: -0.7, y: -0.7)) {
        self.colour = colour
        self.intensity = intensity
        self.from = from
    }

    static func mix(_ a: ScriptLight, _ b: ScriptLight, _ t: Double) -> ScriptLight {
        ScriptLight(
            colour: .mix(a.colour, b.colour, t),
            intensity: a.intensity + (b.intensity - a.intensity) * t,
            from: SkyPoint(x: a.from.x + (b.from.x - a.from.x) * t, y: a.from.y + (b.from.y - a.from.y) * t)
        )
    }
}

/// How strongly each practical light burns, 0…1.
public struct Practicals: Hashable, Sendable {
    /// The ember under the çaydanlık.
    public var ember: Double
    /// The round window in the island's door.
    public var window: Double
}

/// Atmospheric perspective on the far isles: toward this colour, by this
/// much.
public struct ScriptFog: Hashable, Sendable {
    public var colour: PofuRGB
    public var far: Double
}

/// The cloud sea's light and shade.
public struct SeaColours: Hashable, Sendable {
    public var light: PofuRGB
    public var shade: PofuRGB
    public var opacity: Double
}

/// A wellbeing state layered over the hour.
public struct ColourState: Hashable, Sendable {
    /// Layered over the world's grade (`WorldGrade.layered`).
    public var grade: WorldGrade
    /// Layered over the characters' light: desaturated, still readable.
    public var character: WorldGrade
    /// The sky's value scale (never above 1: never brighter than the hour).
    public var skyValue: Double
    /// The sky's chroma scale.
    public var skyChroma: Double
    /// The overcast colour the sky leans to, and how far.
    public var skyToward: PofuRGB
    public var skyAmount: Double
    /// The key's intensity scale (overcast).
    public var keyIntensity: Double
    /// The fill's intensity scale (weather rows; 1 for the unwell state).
    public var fillIntensity: Double = 1
    /// Extra depth fog at every tier behind the front one (weather rows).
    public var fogExtra: Double = 0
    /// The door's window stays at least this lit (care is still here).
    public var windowFloor: Double
}

extension PofuRGB {
    /// This colour under the unwell sky at `amount`: darker, less chroma,
    /// leaning to the overcast colour; never lighter than it was.
    func overcast(_ state: ColourState, amount: Double) -> PofuRGB {
        let t = min(max(amount.isFinite ? amount : 0, 0), 1)
        guard t > 0 else { return self }
        let luma = 0.2126 * red + 0.7152 * green + 0.0722 * blue
        let chroma = 1 + (state.skyChroma - 1) * t
        let value = 1 + (state.skyValue - 1) * t
        let desaturated = PofuRGB(
            red: (luma + (red - luma) * chroma) * value,
            green: (luma + (green - luma) * chroma) * value,
            blue: (luma + (blue - luma) * chroma) * value
        )
        let toward = PofuRGB(red: state.skyToward.red * value, green: state.skyToward.green * value, blue: state.skyToward.blue * value)
        let leaned = desaturated.mixed(with: toward, amount: state.skyAmount * t)
        // Never brighter than the well sky.
        let k = min(1, luma / max(0.2126 * leaned.red + 0.7152 * leaned.green + 0.0722 * leaned.blue, 1e-6))
        return PofuRGB(red: leaned.red * k, green: leaned.green * k, blue: leaned.blue * k)
    }
}

extension WorldGrade {
    /// This grade without its vignette: the scene draws one vignette over
    /// the whole world instead of one per pass.
    public var withoutVignette: WorldGrade {
        var copy = self
        copy.vignette = 0
        return copy
    }

    /// A design-system colour through the grade (CPU), so flat colours such
    /// as the sky's are pre-graded instead of taking a shader pass.
    public func apply(_ c: PofuRGB) -> PofuRGB {
        let g = apply(GradeRGB(c.red, c.green, c.blue))
        return PofuRGB(red: g.r, green: g.g, blue: g.b)
    }
}
