import Foundation

/// Three channels of a grade parameter.
public struct GradeRGB: Hashable, Sendable {
    public var r: Double
    public var g: Double
    public var b: Double

    public init(_ r: Double, _ g: Double, _ b: Double) {
        self.r = r
        self.g = g
        self.b = b
    }

    public init(all value: Double) {
        self.init(value, value, value)
    }

    public static let zero = GradeRGB(all: 0)
    public static let one = GradeRGB(all: 1)

    static func mix(_ a: GradeRGB, _ b: GradeRGB, _ t: Double) -> GradeRGB {
        GradeRGB(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t)
    }

    static func * (a: GradeRGB, b: GradeRGB) -> GradeRGB {
        GradeRGB(a.r * b.r, a.g * b.g, a.b * b.b)
    }

    static func + (a: GradeRGB, b: GradeRGB) -> GradeRGB {
        GradeRGB(a.r + b.r, a.g + b.g, a.b + b.b)
    }
}

/// The world's runtime color grade: saturation, contrast and the value
/// range live here, not in the art files, so the look can be changed
/// without regenerating anything (look-dev decision A; the art is baked
/// with `lock-light`, `tools/imagegen/style_lock.json`).
///
/// The order matches the Metal shader (`pofuWorldGrade`) exactly:
///
///     x₀ = (x − black) / (white − black)      input levels
///     x₁ = gain · (x₀ + lift · (1 − x₀))      lift, gamma, gain per channel
///     x₂ = max(x₁, 0)^(1 / gamma)
///     x₃ = (x₂ − pivot) · contrast + pivot
///     x₄ = luma + (x₃ − luma) · saturation    Rec. 709 luma of x₃
///     out = x₄ · vignette(position)
///
/// It applies to the world layer only (sky, plates, stations, Pofu),
/// never to the UI. The sky takes the grade without its input levels
/// (`sky`): its palette is designed dark at night, and the levels that give
/// the high-key art its true darks would crush it to black.
///
/// **Why input levels (look round 2).** The art is high-key: its darkest
/// pixels sit near L* 50 (the island's p2 is 53). Round 1's night and
/// unwell grades scaled that down and lifted the blacks, so the whole
/// world sat in a narrow band of mid-greys: measured over the Home band,
/// night had p2 22, a range of 0.68 × day and local contrast 0.66 × day, which
/// reads as washed out. A black point moves the art's own darkest values
/// to true darks first, so the night is deep and keeps its contrast
/// (`design/art/harmony/grade-targets.json`, `tools/assets/frame_metrics.py`).
public struct WorldGrade: Hashable, Sendable {
    /// Input levels: this value and below become black, `white` and above
    /// white (0 and 1 change nothing).
    public var black: Double
    public var white: Double
    public var lift: GradeRGB
    public var gamma: GradeRGB
    public var gain: GradeRGB
    public var contrast: Double
    public var pivot: Double
    public var saturation: Double
    /// How much the corners darken, 0…1.
    public var vignette: Double

    public init(
        black: Double = 0,
        white: Double = 1,
        lift: GradeRGB = .zero,
        gamma: GradeRGB = .one,
        gain: GradeRGB = .one,
        contrast: Double = 1,
        pivot: Double = 0.55,
        saturation: Double = 1,
        vignette: Double = 0
    ) {
        self.black = black
        self.white = white
        self.lift = lift
        self.gamma = gamma
        self.gain = gain
        self.contrast = contrast
        self.pivot = pivot
        self.saturation = saturation
        self.vignette = vignette
    }

    // MARK: - Presets (data; tune here, never in the art)

    /// The identity: the art exactly as baked.
    public static let neutral = WorldGrade()

    /// Midday: a little more saturation and contrast than the files, so the
    /// world sits between today's pale look and "AI vivid".
    public static let day = WorldGrade(
        lift: GradeRGB(0, 0, 0.012),
        gain: GradeRGB(1, 1, 0.985),
        contrast: 1.10,
        saturation: 1.14,
        vignette: 0.16
    )

    /// Golden hour: warm highlights, slightly cool-lifted shadows.
    public static let goldenHour = WorldGrade(
        lift: GradeRGB(0.03, 0.008, -0.015),
        gamma: GradeRGB(1.02, 1, 0.97),
        gain: GradeRGB(1.07, 0.97, 0.85),
        contrast: 1.08,
        saturation: 1.16,
        vignette: 0.26
    )

    /// Night: deep moonlit blue-violet with true darks (the black point
    /// takes the art's L* 50 shadows down to about L* 5), no lifted blacks,
    /// and more contrast than day around a low pivot; saturation drops so
    /// the warm practicals (the ember, the door's window), drawn after the
    /// grade, carry the warmth and pop.
    public static let night = WorldGrade(
        black: 0.32,
        gamma: GradeRGB(0.80, 0.85, 0.97),
        gain: GradeRGB(0.44, 0.50, 0.90),
        contrast: 1.18,
        pivot: 0.2,
        saturation: 0.62,
        vignette: 0.40
    )

    /// Pofu unwell: cooler and about half as saturated, with deeper
    /// shadows instead of lifted ones, so contrast holds and Pofu stays
    /// readable; never grey fog (ADR-0017: Pofu never dies). Layered over
    /// the hour's grade.
    public static let unwell = WorldGrade(
        black: 0.14,
        gamma: GradeRGB(0.95, 0.96, 0.98),
        gain: GradeRGB(0.94, 0.97, 1.025),
        saturation: 0.55,
        vignette: 0.24
    )

    /// High calm: a gentle warm glow. Layered over the hour's grade.
    public static let calmGlow = WorldGrade(
        lift: GradeRGB(0.02, 0.015, 0),
        gamma: GradeRGB(1.05, 1.04, 1.02),
        gain: GradeRGB(1.03, 1.02, 0.99),
        contrast: 1.02,
        saturation: 1.10,
        vignette: 0.08
    )

    // MARK: - Blending

    /// A straight blend of every parameter.
    public static func mix(_ a: WorldGrade, _ b: WorldGrade, _ t: Double) -> WorldGrade {
        let t = min(max(t.isFinite ? t : 0, 0), 1)
        // The ends are exact, so a full phase is its preset.
        if t == 0 { return a }
        if t == 1 { return b }
        return WorldGrade(
            black: a.black + (b.black - a.black) * t,
            white: a.white + (b.white - a.white) * t,
            lift: .mix(a.lift, b.lift, t),
            gamma: .mix(a.gamma, b.gamma, t),
            gain: .mix(a.gain, b.gain, t),
            contrast: a.contrast + (b.contrast - a.contrast) * t,
            pivot: a.pivot + (b.pivot - a.pivot) * t,
            saturation: a.saturation + (b.saturation - a.saturation) * t,
            vignette: a.vignette + (b.vignette - a.vignette) * t
        )
    }

    /// This grade with `overlay` layered on at `amount`: multiplicative
    /// parameters multiply, lift adds, the levels and the vignette take the
    /// stronger. An overlay over `neutral` at 1 is the overlay itself.
    public func layered(with overlay: WorldGrade, amount: Double) -> WorldGrade {
        let o = WorldGrade.mix(.neutral, overlay, amount)
        return WorldGrade(
            black: max(black, o.black),
            white: min(white, o.white),
            lift: lift + o.lift,
            gamma: gamma * o.gamma,
            gain: gain * o.gain,
            contrast: contrast * o.contrast,
            pivot: pivot,
            saturation: saturation * o.saturation,
            vignette: max(vignette, o.vignette)
        )
    }

    /// The grade for the sky: the same without its input levels.
    public var sky: WorldGrade {
        var copy = self
        copy.black = 0
        copy.white = 1
        return copy
    }

    // MARK: - Reference implementation

    /// The grade of one gamma-encoded color, 0…1, before the vignette: the
    /// CPU twin of the shader, for tests and tools.
    public func apply(_ c: GradeRGB) -> GradeRGB {
        let span = max(white - black, 1e-3)
        func channel(_ x: Double, _ lift: Double, _ gamma: Double, _ gain: Double) -> Double {
            let x = (x - black) / span
            let x1 = gain * (x + lift * (1 - x))
            let x2 = pow(max(x1, 0), 1 / max(gamma, 0.01))
            return (x2 - pivot) * contrast + pivot
        }
        let x = GradeRGB(
            channel(c.r, lift.r, gamma.r, gain.r),
            channel(c.g, lift.g, gamma.g, gain.g),
            channel(c.b, lift.b, gamma.b, gain.b)
        )
        let luma = 0.2126 * x.r + 0.7152 * x.g + 0.0722 * x.b
        func clamp(_ v: Double) -> Double { min(max(v, 0), 1) }
        return GradeRGB(
            clamp(luma + (x.r - luma) * saturation),
            clamp(luma + (x.g - luma) * saturation),
            clamp(luma + (x.b - luma) * saturation)
        )
    }

    /// Whether the grade changes nothing (the shader can be skipped).
    public var isNeutral: Bool {
        self == .neutral
    }
}
