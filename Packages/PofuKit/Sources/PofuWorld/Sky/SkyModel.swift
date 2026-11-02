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

    static let night = SkyPalette(
        zenith: PofuRGB(hex: 0x1C2242),
        horizon: PofuRGB(hex: 0x3E3659),
        glow: PofuRGB(hex: 0xD9D2F5),
        glowStrength: 0.22,
        sun: SkyPoint(x: 0.76, y: 0.16),
        cloudLight: PofuRGB(hex: 0x6F6A92),
        cloudShade: PofuRGB(hex: 0x3A3759),
        cloudOpacity: 0.7,
        grade: PofuRGB(red: 0.74, green: 0.76, blue: 0.92),
        stars: 1
    )

    static let dawn = SkyPalette(
        zenith: PofuRGB(hex: 0xBCD3EC),
        horizon: PofuRGB(hex: 0xFAD9C6),
        glow: PofuRGB(hex: 0xFFDCBC),
        glowStrength: 0.6,
        sun: SkyPoint(x: 0.16, y: 0.30),
        cloudLight: PofuRGB(hex: 0xFFF4EE),
        cloudShade: PofuRGB(hex: 0xE6C5C6),
        cloudOpacity: 0.95,
        grade: PofuRGB(red: 1.0, green: 0.95, blue: 0.94),
        stars: 0
    )

    static func day(sun: SkyPoint) -> SkyPalette {
        SkyPalette(
            zenith: PofuRGB(hex: 0xC4DEF2),
            horizon: PofuRGB(hex: 0xF8F0DF),
            glow: PofuRGB(hex: 0xFFF6DD),
            glowStrength: 0.62,
            sun: sun,
            cloudLight: PofuRGB(hex: 0xFFFFFF),
            cloudShade: PofuRGB(hex: 0xD8E3EF),
            cloudOpacity: 0.95,
            grade: PofuRGB(red: 1, green: 1, blue: 1),
            stars: 0
        )
    }

    static let golden = SkyPalette(
        zenith: PofuRGB(hex: 0x9C90D2),
        horizon: PofuRGB(hex: 0xF8BC8C),
        glow: PofuRGB(hex: 0xFFC983),
        glowStrength: 0.72,
        sun: SkyPoint(x: 0.84, y: 0.30),
        cloudLight: PofuRGB(hex: 0xFFE7D3),
        cloudShade: PofuRGB(hex: 0xC99BAA),
        cloudOpacity: 0.95,
        grade: PofuRGB(red: 1.0, green: 0.93, blue: 0.86),
        stars: 0
    )

    /// Minute of the day → palette. Bands: dawn 05:30–08:00, day
    /// 08:00–17:30, golden hour 17:30–20:30, night 20:30–05:30; each edge
    /// blends over the 30 minutes around it.
    static let keyframes: [(minute: Double, palette: SkyPalette)] = [
        (0, night),
        (5 * 60 + 15, night),
        (5 * 60 + 45, dawn),
        (7 * 60 + 45, dawn),
        (8 * 60 + 15, day(sun: SkyPoint(x: 0.22, y: 0.20))),
        (12 * 60 + 45, day(sun: SkyPoint(x: 0.50, y: 0.11))),
        (17 * 60 + 15, day(sun: SkyPoint(x: 0.78, y: 0.20))),
        (17 * 60 + 45, golden),
        (20 * 60 + 15, golden),
        (20 * 60 + 45, night),
        (24 * 60, night),
    ]

    /// The palette at a minute of the local day. Dark appearance and the
    /// bedtime window draw the night (dark mode is a night meadow, design
    /// language §3); dark mode keeps a trace of the hour.
    public static func palette(minuteOfDay: Double, isDark: Bool = false, isBedtime: Bool = false) -> SkyPalette {
        if isBedtime {
            return night
        }
        let minute = minuteOfDay.isFinite ? min(max(minuteOfDay, 0), 24 * 60) : 12 * 60
        var palette = keyframes.last?.palette ?? night
        for (a, b) in zip(keyframes, keyframes.dropFirst()) where minute >= a.minute && minute <= b.minute {
            let span = b.minute - a.minute
            palette = SkyPalette.mix(a.palette, b.palette, span > 0 ? (minute - a.minute) / span : 0)
            break
        }
        return isDark ? SkyPalette.mix(palette, night, 0.82) : palette
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
        let base = 4 + Int(g.next() * 2.99)
        for i in 0..<base {
            let t = (Double(i) + 0.5) / Double(base)
            let r = 0.10 + 0.05 * g.next()
            lobes.append(Lobe(x: 0.08 + t * 0.84, y: 0.5 - r, r: r))
        }
        let crown = 1 + Int(g.next() * 1.99)
        for i in 0..<crown {
            let x = crown == 1 ? 0.42 + 0.16 * g.next() : (i == 0 ? 0.33 : 0.62) + 0.06 * g.next()
            let r = 0.17 + 0.06 * g.next() - (crown == 2 && i == 1 ? 0.04 : 0)
            lobes.append(Lobe(x: x, y: 0.5 - r * 1.25, r: r))
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
