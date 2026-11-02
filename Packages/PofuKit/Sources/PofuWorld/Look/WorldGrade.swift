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
///     x₁ = gain · (x + lift · (1 − x))        lift, gamma, gain per channel
///     x₂ = max(x₁, 0)^(1 / gamma)
///     x₃ = (x₂ − pivot) · contrast + pivot
///     x₄ = luma + (x₃ − luma) · saturation    Rec. 709 luma of x₃
///     out = x₄ · vignette(position)
///
/// It applies to the world layer only (sky, plates, stations, Pofu),
/// never to the UI.
public struct WorldGrade: Hashable, Sendable {
    public var lift: GradeRGB
    public var gamma: GradeRGB
    public var gain: GradeRGB
    public var contrast: Double
    public var pivot: Double
    public var saturation: Double
    /// How much the corners darken, 0…1.
    public var vignette: Double

    public init(
        lift: GradeRGB = .zero,
        gamma: GradeRGB = .one,
        gain: GradeRGB = .one,
        contrast: Double = 1,
        pivot: Double = 0.55,
        saturation: Double = 1,
        vignette: Double = 0
    ) {
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

    /// Night: moonlit blue, lower saturation; the emissive points carry
    /// the warmth.
    public static let night = WorldGrade(
        lift: GradeRGB(0, 0.02, 0.06),
        gamma: GradeRGB(0.92, 0.95, 1),
        gain: GradeRGB(0.46, 0.53, 0.76),
        contrast: 1.04,
        pivot: 0.4,
        saturation: 0.72,
        vignette: 0.40
    )

    /// Pofu unwell: a mild desaturation and a softer contrast, never grey
    /// or gloomy (ADR-0017: Pofu never dies). Layered over the hour's grade.
    public static let unwell = WorldGrade(
        lift: GradeRGB(0.02, 0.02, 0.025),
        gain: GradeRGB(0.97, 0.97, 0.98),
        contrast: 0.94,
        saturation: 0.72,
        vignette: 0.22
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
    /// parameters multiply, lift adds, vignette takes the stronger. An
    /// overlay over `neutral` at 1 is the overlay itself.
    public func layered(with overlay: WorldGrade, amount: Double) -> WorldGrade {
        let o = WorldGrade.mix(.neutral, overlay, amount)
        return WorldGrade(
            lift: lift + o.lift,
            gamma: gamma * o.gamma,
            gain: gain * o.gain,
            contrast: contrast * o.contrast,
            pivot: pivot,
            saturation: saturation * o.saturation,
            vignette: max(vignette, o.vignette)
        )
    }

    // MARK: - Reference implementation

    /// The grade of one gamma-encoded color, 0…1, before the vignette: the
    /// CPU twin of the shader, for tests and tools.
    public func apply(_ c: GradeRGB) -> GradeRGB {
        func channel(_ x: Double, _ lift: Double, _ gamma: Double, _ gain: Double) -> Double {
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
