import Foundation
import PofuDesignSystem

/// A point in unit coordinates of the screen (0…1 on each axis).
public struct SkyPoint: Hashable, Sendable {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

/// The sky at one moment of the day (design language §12): the gradient,
/// the sun or moon glow, the clouds' light and shade, and the grade the
/// painted world takes (no night art is generated; game design §15).
public struct SkyPalette: Hashable, Sendable {
    public var zenith: PofuRGB
    public var horizon: PofuRGB
    /// The sun's (or the moon's) glow.
    public var glow: PofuRGB
    public var glowStrength: Double
    public var sun: SkyPoint
    public var cloudLight: PofuRGB
    public var cloudShade: PofuRGB
    public var cloudOpacity: Double
    /// Multiplied over the painted world.
    public var grade: PofuRGB
    /// 0 by day, 1 at night.
    public var stars: Double

    public static func mix(_ a: SkyPalette, _ b: SkyPalette, _ t: Double) -> SkyPalette {
        let t = MomentCurves.unit(t)
        func lerp(_ x: Double, _ y: Double) -> Double { x + (y - x) * t }
        return SkyPalette(
            zenith: a.zenith.mixed(with: b.zenith, amount: t),
            horizon: a.horizon.mixed(with: b.horizon, amount: t),
            glow: a.glow.mixed(with: b.glow, amount: t),
            glowStrength: lerp(a.glowStrength, b.glowStrength),
            sun: SkyPoint(x: lerp(a.sun.x, b.sun.x), y: lerp(a.sun.y, b.sun.y)),
            cloudLight: a.cloudLight.mixed(with: b.cloudLight, amount: t),
            cloudShade: a.cloudShade.mixed(with: b.cloudShade, amount: t),
            cloudOpacity: lerp(a.cloudOpacity, b.cloudOpacity),
            grade: a.grade.mixed(with: b.grade, amount: t),
            stars: lerp(a.stars, b.stars)
        )
    }
}

/// The living sky's rules: a palette that follows the snapshot's clock
/// through dawn, day, golden hour and night (design language §12, band
/// edges blending over 30 minutes), and deterministic cloud drift.
public enum SkyModel {
    // MARK: Keyframes

    /// A cell's sky as a palette, with the sun where the schedule key (or
    /// else the cell) puts it.
    static func palette(of cell: ColourCell, sun: SkyPoint? = nil) -> SkyPalette {
        SkyPalette(
            zenith: cell.sky.zenith,
            horizon: cell.sky.horizon,
            glow: cell.sky.glow,
            glowStrength: cell.sky.glowStrength,
            sun: sun ?? cell.sun,
            cloudLight: cell.sky.cloudLight,
            cloudShade: cell.sky.cloudShade,
            cloudOpacity: cell.sky.cloudOpacity,
            grade: cell.sky.tint,
            stars: cell.sky.stars
        )
    }

    static var night: SkyPalette {
        palette(of: ColourScript.cell(.night))
    }

    /// Minute of the day → palette, on the colour script's schedule (look
    /// round 3): night, dawn 05:45–07:15, day 07:45–17:15 with the sun
    /// crossing, golden hour 17:45–19:15, dusk (the blue hour) 19:45–20:15,
    /// night from 20:45; each edge blends over 30 minutes.
    static let keyframes: [(minute: Double, palette: SkyPalette)] = ColourScript.schedule.map { key in
        (minute: key.minute, palette: SkyModel.palette(of: ColourScript.cell(key.cell), sun: key.sun))
    }

    /// The palette at a minute of the local day. The bedtime
    /// window draws the night; the system's dark appearance does not (the
    /// world follows the clock only, dark mode changes the chrome). `unwell` (0…1)
    /// turns the sky overcast: cooler, slightly darker, lower in chroma,
    /// never brighter than the hour's (the colour script's unwell state).
    public static func palette(minuteOfDay: Double, isBedtime: Bool = false, unwell: Double = 0) -> SkyPalette {
        var palette: SkyPalette
        if isBedtime {
            palette = night
        } else {
            let minute = minuteOfDay.isFinite ? min(max(minuteOfDay, 0), 24 * 60) : 12 * 60
            palette = keyframes.last?.palette ?? night
            for (a, b) in zip(keyframes, keyframes.dropFirst()) where minute >= a.minute && minute <= b.minute {
                let span = b.minute - a.minute
                palette = SkyPalette.mix(a.palette, b.palette, ease(span > 0 ? (minute - a.minute) / span : 0))
                break
            }
        }
        let result = unwell > 0 ? palette.overcast(ColourScript.unwell, amount: unwell) : palette
        return result.luminousNight()
    }

    /// The cosine ease between two cells (sky and weather v1 §2.1): the
    /// blend leaves a cell and arrives at the next with no corner, never
    /// linear.
    public static func ease(_ t: Double) -> Double {
        let t = min(max(t.isFinite ? t : 0, 0), 1)
        return 0.5 - 0.5 * cos(Double.pi * t)
    }

    // MARK: Colour measures

    /// CIE L* (0…100) of an sRGB colour.
    public static func lightness(_ colour: PofuRGB) -> Double {
        func linear(_ c: Double) -> Double {
            let c = min(max(c, 0), 1)
            return c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        let y = 0.2126 * linear(colour.red) + 0.7152 * linear(colour.green) + 0.0722 * linear(colour.blue)
        return y > 216.0 / 24389.0 ? 116 * cbrt(y) - 16 : y * 24389.0 / 27.0
    }

    /// `colour` with its L* lowered by `amount`: it is mixed toward black
    /// until it lands there, so the hue is kept (the cloud shade's tint).
    public static func darkened(_ colour: PofuRGB, byLightness amount: Double) -> PofuRGB {
        let target = max(lightness(colour) - max(amount, 0), 0)
        return search(from: colour, to: PofuRGB(red: 0, green: 0, blue: 0), reaching: target)
    }

    /// `colour` lifted toward a luminous indigo until its L* is at least
    /// `minimum`; unchanged if it already is.
    public static func lifted(_ colour: PofuRGB, toLightness minimum: Double) -> PofuRGB {
        guard lightness(colour) < minimum else { return colour }
        return search(from: colour, to: PofuRGB(hex: 0x4A5598), reaching: minimum)
    }

    /// The mix of `a` toward `b` whose L* meets `target` (bisection).
    private static func search(from a: PofuRGB, to b: PofuRGB, reaching target: Double) -> PofuRGB {
        var low = 0.0, high = 1.0
        for _ in 0..<24 {
            let mid = (low + high) / 2
            let l = lightness(a.mixed(with: b, amount: mid))
            // Moving toward `b` raises L* when b is lighter, lowers it otherwise.
            if lightness(b) > lightness(a) ? l < target : l > target { low = mid } else { high = mid }
        }
        return a.mixed(with: b, amount: high)
    }

    // MARK: Stars

    /// One star of the night sky: where, how big, how bright, and how fast
    /// it twinkles.
    public struct Star: Hashable, Sendable {
        /// Unit coordinates, y within the upper sky.
        public var x: Double
        public var y: Double
        public var radius: Double
        public var brightness: Double
        public var hz: Double
        public var phase: Double
    }

    /// The fixed stars: `LookTuning.starCount` of them, the same every
    /// launch, twinkling at 0.1…0.3 Hz.
    public static let stars: [Star] = {
        var g = CloudShape.Generator(state: 977)
        let hz = LookTuning.starTwinkleHz
        return (0..<LookTuning.starCount).map { _ in
            Star(
                x: g.next(), y: g.next() * 0.42,
                radius: 0.6 + g.next() * 1.1, brightness: 0.45 + 0.5 * g.next(),
                hz: hz.lowerBound + (hz.upperBound - hz.lowerBound) * g.next(), phase: g.next() * 2 * Double.pi
            )
        }
    }()

    /// A star's brightness at `time`, 0…1: its own brightness, swelling and
    /// dimming by up to 40 % on its own sine. Deterministic; a still frame
    /// (time 0) and a settled one draw the same stars.
    public static func twinkle(_ star: Star, time: Double) -> Double {
        let t = time.isFinite ? time : 0
        let wave = 0.5 + 0.5 * sin(2 * Double.pi * star.hz * t + star.phase)
        return min(max(star.brightness * (0.6 + 0.4 * wave), 0), 1)
    }

    /// The minute of the local day of `date`.
    public static func minuteOfDay(_ date: Date, calendar: Calendar) -> Double {
        let parts = calendar.dateComponents([.hour, .minute, .second], from: date)
        return Double(parts.hour ?? 12) * 60 + Double(parts.minute ?? 0) + Double(parts.second ?? 0) / 60
    }

    // MARK: Clouds

    /// A cloud's left edge at `time`: it drifts right at `speed` points a
    /// second and wraps around a strip `span` points wide, entering from
    /// off screen. `phase` places it at time zero.
    public static func cloudX(time: Double, speed: Double, phase: Double, width: Double, span: Double) -> Double {
        let period = span + width
        guard period > 0, time.isFinite else { return phase }
        let raw = (phase + speed * time).truncatingRemainder(dividingBy: period)
        let wrapped = raw < 0 ? raw + period : raw
        return wrapped - width
    }
}

/// How far a layer of the sky's clouds sits (sky and weather v1 §2.1).
public enum SkyCloudLayer: Int, CaseIterable, Hashable, Sendable {
    case far, mid, near

    /// The share of the peek this layer moves: 1x, 1.8x and 3x of the base.
    public var parallax: Double {
        LookTuning.cloudParallaxBase * LookTuning.cloudParallaxMultiples[rawValue]
    }

    /// How many L* the shade takes off the zenith on this layer.
    public var shadeDarkening: Double {
        LookTuning.cloudShadeDarkening[rawValue]
    }

    public var clouds: [SkyCloud] {
        switch self {
        case .far: SkyCloud.far
        case .mid: SkyCloud.mid
        case .near: SkyCloud.near
        }
    }
}

/// One cloud of the living sky: which painted cloud, where it sits and how
/// it moves.
public struct SkyCloud: Hashable, Sendable {
    /// Identifies the cloud.
    public var seed: Int
    /// The painted cloud (`cloud-2`, `cloud-4`), from the world catalog.
    public var art: String
    /// Drawn flipped, for a fourth shape from two paintings.
    public var mirrored: Bool
    /// Width in points.
    public var width: Double
    /// The cloud's top, as a fraction of the screen's height.
    public var top: Double
    /// Points a second; every layer stays under `LookTuning.cloudMaxSpeed`.
    public var speed: Double
    /// Its left edge at time zero, as a fraction of the screen's width.
    public var phase: Double
    public var opacity: Double

    public init(seed: Int, art: String, mirrored: Bool = false, width: Double, top: Double, speed: Double, phase: Double, opacity: Double) {
        self.seed = seed
        self.art = art
        self.mirrored = mirrored
        self.width = width
        self.top = top
        self.speed = speed
        self.phase = phase
        self.opacity = opacity
    }

    /// Far clouds: small, faint, slow, high (parallax 1x).
    public static let far: [SkyCloud] = [
        SkyCloud(seed: 1, art: "cloud-4", width: 120, top: 0.15, speed: 1.1, phase: 0.08, opacity: 0.55),
        SkyCloud(seed: 2, art: "cloud-2", width: 70, top: 0.235, speed: 1.3, phase: 0.62, opacity: 0.5),
        SkyCloud(seed: 3, art: "cloud-4", mirrored: true, width: 100, top: 0.31, speed: 1.0, phase: 0.36, opacity: 0.45),
        SkyCloud(seed: 4, art: "cloud-2", mirrored: true, width: 56, top: 0.19, speed: 1.2, phase: 1.02, opacity: 0.45),
    ]

    /// Mid clouds: larger and brighter (parallax 1.8x).
    public static let mid: [SkyCloud] = [
        SkyCloud(seed: 5, art: "cloud-4", width: 170, top: 0.255, speed: 2.0, phase: -0.18, opacity: 0.8),
        SkyCloud(seed: 6, art: "cloud-2", width: 110, top: 0.36, speed: 2.3, phase: 0.66, opacity: 0.75),
        SkyCloud(seed: 7, art: "cloud-4", mirrored: true, width: 150, top: 0.43, speed: 1.9, phase: 0.28, opacity: 0.65),
    ]

    /// Near clouds: the largest, a little faster, the most parallax (3x).
    public static let near: [SkyCloud] = [
        SkyCloud(seed: 8, art: "cloud-2", mirrored: true, width: 150, top: 0.30, speed: 2.8, phase: 0.30, opacity: 0.8),
        SkyCloud(seed: 9, art: "cloud-4", width: 230, top: 0.45, speed: 2.6, phase: 0.85, opacity: 0.65),
    ]
}

/// What tints a layer's painted clouds (sky and weather v1 §2.1): the lit
/// side takes the cell's cloud light, the shade side the zenith darkened
/// 15…25 L*, and at the low sun the undersides catch the horizon glow.
/// A tint, not per-pixel work; recomputed only when the palette changes
/// (the scene's clock), never per frame.
public struct CloudTint: Hashable, Sendable {
    public var lit: PofuRGB
    public var shade: PofuRGB
    /// How much of the shade is the horizon's glow, 0…1.
    public var underglow: Double

    public init(palette: SkyPalette, layer: SkyCloudLayer) {
        lit = palette.cloudLight
        let dark = SkyModel.darkened(palette.zenith, byLightness: layer.shadeDarkening)
        // The glow is for the low sun: dawn, golden hour and dusk; none at
        // noon or in the full night.
        let low = MomentCurves.smoothstep(MomentCurves.progress(palette.sun.y, from: 0.15, length: 0.15))
        underglow = low * (1 - MomentCurves.unit(palette.stars)) * 0.7
        shade = dark.mixed(with: palette.horizon, amount: underglow)
    }

    /// The tint with each channel rounded to 1/64, so a drift of the clock
    /// does not redraw the clouds every minute.
    public func quantised() -> CloudTint {
        var copy = self
        func q(_ c: PofuRGB) -> PofuRGB {
            PofuRGB(red: (c.red * 64).rounded() / 64, green: (c.green * 64).rounded() / 64, blue: (c.blue * 64).rounded() / 64)
        }
        copy.lit = q(lit)
        copy.shade = q(shade)
        copy.underglow = (underglow * 32).rounded() / 32
        return copy
    }
}

/// The lobes of a cloud, in unit space (x 0…1 across, y 0…0.5 down), from
/// a seed: a flat-bottomed row of small lobes under one or two big ones.
public enum CloudShape {
    public struct Lobe: Hashable, Sendable {
        public var x: Double
        public var y: Double
        public var r: Double
    }

    /// A small deterministic generator, so a cloud is the same every launch.
    struct Generator {
        var state: UInt64

        mutating func next() -> Double {
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return Double((state >> 33) & 0xFFFF) / 65_535
        }
    }

    public static func lobes(seed: Int) -> [Lobe] {
        var g = Generator(state: UInt64(truncatingIfNeeded: seed &* 7919 &+ 17))
        var lobes: [Lobe] = []
        // A low, wide base of overlapping lobes (tapering to the ends) and
        // one or two big crowns, so the silhouette reads as one soft body.
        let base = 5 + Int(g.next() * 2.99)
        for i in 0..<base {
            let t = (Double(i) + 0.5) / Double(base)
            let taper = 1 - 0.45 * abs(t - 0.5) * 2
            let r = (0.09 + 0.035 * g.next()) * (0.75 + 0.5 * taper)
            lobes.append(Lobe(x: 0.14 + t * 0.72, y: 0.5 - r, r: r))
        }
        let crown = 1 + Int(g.next() * 1.99)
        for i in 0..<crown {
            let x = crown == 1 ? 0.44 + 0.12 * g.next() : (i == 0 ? 0.36 : 0.6) + 0.05 * g.next()
            let r = 0.19 + 0.05 * g.next() - (crown == 2 && i == 1 ? 0.05 : 0)
            lobes.append(Lobe(x: x, y: 0.5 - r * 1.05, r: r))
        }
        return lobes
    }

    /// The cloud sea's lobes along a strip `period` points long: big round
    /// lobes in a gently rising and falling row (positions in points; y is
    /// the lobe's centre above the strip's bottom).
    public static func seaLobes(period: Double) -> [Lobe] {
        var g = Generator(state: 4242)
        var lobes: [Lobe] = []
        var x = 0.0
        while x < period {
            let r = 34 + 22 * g.next()
            lobes.append(Lobe(x: x, y: 52 + 30 * g.next(), r: r))
            x += r * 1.15
        }
        return lobes
    }
}

extension SkyPalette {
    /// The night stays luminous (sky and weather v1 §2.1): the zenith is
    /// never darker than `LookTuning.nightZenithFloor` in L*, whatever the
    /// hour or the unwell state.
    func luminousNight() -> SkyPalette {
        var copy = self
        copy.zenith = SkyModel.lifted(zenith, toLightness: LookTuning.nightZenithFloor)
        return copy
    }

    /// The palette under the unwell state at `amount` (0…1).
    public func overcast(_ state: ColourState, amount: Double) -> SkyPalette {
        var copy = self
        copy.zenith = zenith.overcast(state, amount: amount)
        copy.horizon = horizon.overcast(state, amount: amount)
        copy.glow = glow.overcast(state, amount: amount)
        copy.cloudLight = cloudLight.overcast(state, amount: amount)
        copy.cloudShade = cloudShade.overcast(state, amount: amount)
        copy.glowStrength = glowStrength * (1 - 0.5 * min(max(amount, 0), 1))
        return copy
    }

    /// Every colour of the palette through `grade` on the CPU (look round
    /// 3): the sky is pre-graded, so it needs no full-screen shader pass of
    /// its own. The grade's input levels are not applied (`WorldGrade.sky`).
    public func graded(by grade: WorldGrade) -> SkyPalette {
        let g = grade.sky
        guard !g.withoutVignette.isNeutral else { return self }
        var copy = self
        copy.zenith = g.apply(zenith)
        copy.horizon = g.apply(horizon)
        copy.glow = g.apply(glow)
        copy.cloudLight = g.apply(cloudLight)
        copy.cloudShade = g.apply(cloudShade)
        return copy
    }
}
