import Foundation

/// Pofu's idle breathing as a function of vitality.
///
/// Thriving Pofu breathes quicker and lighter; low Pofu breathes slowly and
/// deeply, like sighing. The breath is applied as a ground-anchored,
/// area-preserving scale: the body grows taller and slightly narrower on
/// the in-breath, and the feet never leave the floor.
public enum BreathingCurve {
    /// Seconds per breath: 4.6 at vitality 0, 3.3 at vitality 1.
    public static func period(vitality: Double) -> Double {
        lerp(4.6, 3.3, clampUnit(vitality))
    }

    /// Peak vertical scale change of a breath: 2.4% at vitality 0, 1.6% at 1.
    public static func amplitude(vitality: Double) -> Double {
        lerp(0.024, 0.016, clampUnit(vitality))
    }

    /// The breath signal in `-1...1` for a phase in radians: a raised
    /// cosine, so the turnarounds at full in- and out-breath are soft.
    public static func signal(phase: Double) -> Double {
        guard phase.isFinite else { return 0 }
        return -cos(phase)
    }

    /// Ground-anchored scales for one moment of breathing.
    public static func scales(phase: Double, vitality: Double) -> (x: Double, y: Double) {
        let breath = amplitude(vitality: vitality) * signal(phase: phase)
        return (x: 1 - breath * 0.55, y: 1 + breath)
    }
}

func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double {
    a + (b - a) * t
}

func clampUnit(_ value: Double) -> Double {
    value.isNaN ? 0 : min(max(value, 0), 1)
}

func smoothstep(_ edge0: Double, _ edge1: Double, _ x: Double) -> Double {
    let t = clampUnit((x - edge0) / (edge1 - edge0))
    return t * t * (3 - 2 * t)
}
