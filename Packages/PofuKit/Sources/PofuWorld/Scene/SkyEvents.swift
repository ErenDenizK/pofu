import Foundation

/// New Year's fireworks (island calendar v1, C3): the one sky event of the kit, drawn by code.
///
/// Calm and few. At most two bursts are alive at once, one over the left half of the sky and one over the right,
/// each a ring of soft sparks that opens, droops and fades in under three seconds, then a pause. Nothing flashes: no
/// spark is brighter than `peak`, none appears at full strength, and nothing fills the screen. The pure function
/// `bursts(at:)` says what stands where at a time; `SkyFireworksLayer` draws it, and draws a still glow under Reduce
/// Motion and Low Power.
public enum SkyFireworks {
    /// Seconds from one burst of a slot to the next.
    public static let period = 5.0
    /// Seconds a burst lives.
    public static let life = 3.0
    /// The brightest a spark gets (0 to 1).
    public static let peak = 0.8
    /// Sparks in a ring.
    public static let sparks = 14
    /// The slots' phases in seconds: the left slot's bursts start at `period * n - 1.5`, the right's at
    /// `period * n + 1.0`, so a frame at time 0 already holds a burst opening and one fading.
    static let phases = [-1.5, 1.0]

    /// One burst at a time `t`.
    public struct Burst: Hashable, Sendable {
        /// 0 for the left slot, 1 for the right.
        public var slot: Int
        /// Where it opens, as a share of the sky band's width and height.
        public var x: Double
        public var y: Double
        /// 0 at its start to 1 at its end.
        public var age: Double
        /// The ring's final radius, as a share of the width.
        public var radius: Double
        /// 0 honey, 1 rose, 2 cream.
        public var tone: Int
        /// The ring's turn, so no two look alike.
        public var turn: Double
    }

    /// The bursts alive at `t` seconds: at most one per slot.
    public static func bursts(at t: Double) -> [Burst] {
        var alive: [Burst] = []
        for (slot, phase) in phases.enumerated() {
            let n = ((t - phase) / period).rounded(.down)
            let start = phase + n * period
            let age = (t - start) / life
            guard age >= 0, age < 1 else { continue }
            var seed = SplitMix(seed: UInt64(bitPattern: Int64(n)) &* 2 &+ UInt64(slot) &+ 0x51ED)
            // The left slot keeps to the left of the sky's middle and the right to the right, so two never overlap.
            let x = (slot == 0 ? 0.16 : 0.54) + seed.unit() * 0.30
            alive.append(Burst(
                slot: slot, x: x, y: 0.07 + seed.unit() * 0.15, age: age,
                radius: 0.10 + seed.unit() * 0.05, tone: Int(seed.unit() * 3) % 3, turn: seed.unit() * .pi
            ))
        }
        return alive
    }

    /// A spark's strength through its burst's age: it fades in over the first tenth, never reaches full, and is gone by
    /// the end.
    public static func strength(age: Double) -> Double {
        let rise = min(age / 0.12, 1)
        let fade = pow(max(1 - age, 0), 1.7)
        return peak * rise * rise * (3 - 2 * rise) * fade
    }

    /// How far the ring has opened (0 to 1): fast, then slowing.
    public static func opening(age: Double) -> Double {
        1 - pow(max(1 - min(age / 0.7, 1), 0), 2.2)
    }

    /// The still glow under Reduce Motion: where each of its blooms sits (share of width and band height) and its
    /// radius (share of width).
    public static let stillBlooms: [(x: Double, y: Double, radius: Double, tone: Int)] = [
        (0.30, 0.13, 0.15, 0), (0.70, 0.17, 0.13, 1)
    ]

    /// SplitMix64: a tiny seeded generator, so a burst is the same every time it is asked for.
    struct SplitMix {
        var state: UInt64
        init(seed: UInt64) { state = seed }
        mutating func next() -> UInt64 {
            state &+= 0x9E37_79B9_7F4A_7C15
            var z = state
            z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
            z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
            return z ^ (z >> 31)
        }
        mutating func unit() -> Double { Double(next() >> 11) / Double(1 << 53) }
    }
}

#if os(iOS)
import PofuDesignSystem
import SwiftUI

extension EnvironmentValues {
    /// Screenshots: pins the fireworks to a time in seconds, so every run draws the same frame.
    @Entry public var skyEventTime: Double?
}

/// The fireworks over the sky band of Home: soft sparks in a ring, a faint bloom at the centre, no flash. Under
/// Reduce Motion and Low Power a still glow stands in their place.
public struct SkyFireworksLayer: View {
    /// The sky above the island, from the top of the screen, in points.
    public var band: CGFloat
    /// Whether the fireworks are on (the night itself).
    public var isOn: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.skyEventTime) private var fixedTime

    public init(band: CGFloat, isOn: Bool) {
        self.band = band
        self.isOn = isOn
    }

    private static let tones: [Color] = [
        Color(red: 1.00, green: 0.86, blue: 0.56), Color(red: 1.00, green: 0.70, blue: 0.76), Color(red: 1.00, green: 0.96, blue: 0.84)
    ]

    public var body: some View {
        if isOn {
            Group {
                if reduceMotion || ProcessInfo.processInfo.isLowPowerModeEnabled {
                    canvas(time: nil)
                } else if let fixedTime {
                    canvas(time: fixedTime)
                } else {
                    PofuTimeline(hz: 30, kind: .ambient) { context in
                        canvas(time: context.date.timeIntervalSinceReferenceDate)
                    }
                }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }

    private func canvas(time: Double?) -> some View {
        Canvas { gc, size in
            gc.blendMode = .plusLighter
            let w = size.width, h = band
            if let time {
                for burst in SkyFireworks.bursts(at: time) {
                    draw(burst, in: &gc, width: w, height: h)
                }
            } else {
                for bloom in SkyFireworks.stillBlooms {
                    glow(&gc, at: CGPoint(x: bloom.x * w, y: bloom.y * h), radius: bloom.radius * w, tone: bloom.tone, opacity: 0.30)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func draw(_ burst: SkyFireworks.Burst, in gc: inout GraphicsContext, width w: CGFloat, height h: CGFloat) {
        let centre = CGPoint(x: burst.x * w, y: burst.y * h)
        let strength = SkyFireworks.strength(age: burst.age)
        let open = SkyFireworks.opening(age: burst.age)
        let radius = burst.radius * w * open
        // The bloom at the centre: soft, strongest early, never white.
        glow(&gc, at: centre, radius: burst.radius * w * 0.7, tone: burst.tone, opacity: 0.22 * strength * (1 - open * 0.6))
        for i in 0..<SkyFireworks.sparks {
            let angle = burst.turn + Double(i) / Double(SkyFireworks.sparks) * 2 * .pi
            // Each spark droops a little as it ages, as if the air were thick.
            let droop = burst.age * burst.age * burst.radius * w * 0.35
            let p = CGPoint(x: centre.x + CGFloat(cos(angle)) * radius, y: centre.y + CGFloat(sin(angle)) * radius + droop)
            // A short trail: three smaller, fainter dots back toward the centre.
            for step in 0..<3 {
                let back = 1 - CGFloat(step + 1) * 0.07
                let q = CGPoint(x: centre.x + (p.x - centre.x) * back, y: centre.y + (p.y - centre.y - droop) * back + droop * back)
                glow(&gc, at: q, radius: 3.4 - CGFloat(step), tone: burst.tone, opacity: strength * 0.28 / CGFloat(step + 1))
            }
            glow(&gc, at: p, radius: 4.2, tone: burst.tone, opacity: strength)
        }
    }

    private func glow(_ gc: inout GraphicsContext, at p: CGPoint, radius: CGFloat, tone: Int, opacity: Double) {
        let colour = Self.tones[tone % Self.tones.count]
        let rect = CGRect(x: p.x - radius, y: p.y - radius, width: radius * 2, height: radius * 2)
        gc.fill(
            Path(ellipseIn: rect),
            with: .radialGradient(
                Gradient(colors: [colour.opacity(opacity), colour.opacity(opacity * 0.35), colour.opacity(0)]),
                center: p, startRadius: 0, endRadius: radius
            )
        )
    }
}
#endif
