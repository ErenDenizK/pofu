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
        (key.minute, palette(of: ColourScript.cell(key.cell), sun: key.sun))
    }

    /// The palette at a minute of the local day. Dark appearance and the
    /// bedtime window draw the night (dark mode is a night meadow, design
    /// language §3); dark mode keeps a trace of the hour. `unwell` (0…1)
    /// turns the sky overcast: cooler, slightly darker, lower in chroma,
    /// never brighter than the hour's (the colour script's unwell state).
    public static func palette(minuteOfDay: Double, isDark: Bool = false, isBedtime: Bool = false, unwell: Double = 0) -> SkyPalette {
        var palette: SkyPalette
        if isBedtime {
            palette = night
        } else {
            let minute = minuteOfDay.isFinite ? min(max(minuteOfDay, 0), 24 * 60) : 12 * 60
            palette = keyframes.last?.palette ?? night
            for (a, b) in zip(keyframes, keyframes.dropFirst()) where minute >= a.minute && minute <= b.minute {
                let span = b.minute - a.minute
                palette = SkyPalette.mix(a.palette, b.palette, span > 0 ? (minute - a.minute) / span : 0)
                break
            }
            if isDark {
                palette = SkyPalette.mix(palette, night, 0.82)
            }
        }
        return unwell > 0 ? palette.overcast(ColourScript.unwell, amount: unwell) : palette
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

/// One cloud of the living sky: where it sits and how it moves.
public struct SkyCloud: Hashable, Sendable {
    /// Which lobe pattern to draw.
    public var seed: Int
    /// Width in points.
    public var width: Double
    /// The cloud's top, as a fraction of the screen's height.
    public var top: Double
    /// Points a second.
    public var speed: Double
    /// Its left edge at time zero, as a fraction of the screen's width.
    public var phase: Double
    public var opacity: Double

    public init(seed: Int, width: Double, top: Double, speed: Double, phase: Double, opacity: Double) {
        self.seed = seed
        self.width = width
        self.top = top
        self.speed = speed
        self.phase = phase
        self.opacity = opacity
    }

    /// Far clouds: small, faint, slow, high (parallax ×0.3).
    public static let far: [SkyCloud] = [
        SkyCloud(seed: 1, width: 92, top: 0.15, speed: 2.2, phase: 0.08, opacity: 0.55),
        SkyCloud(seed: 2, width: 70, top: 0.235, speed: 2.6, phase: 0.62, opacity: 0.5),
        SkyCloud(seed: 3, width: 84, top: 0.31, speed: 2.0, phase: 0.36, opacity: 0.45),
        SkyCloud(seed: 4, width: 64, top: 0.19, speed: 2.4, phase: 1.02, opacity: 0.45),
    ]

    /// Near clouds: larger, brighter, a little faster (parallax ×0.6).
    public static let near: [SkyCloud] = [
        SkyCloud(seed: 5, width: 168, top: 0.255, speed: 4.6, phase: -0.18, opacity: 0.9),
        SkyCloud(seed: 6, width: 132, top: 0.36, speed: 5.2, phase: 0.66, opacity: 0.85),
        SkyCloud(seed: 7, width: 150, top: 0.43, speed: 4.2, phase: 0.28, opacity: 0.7),
    ]
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
