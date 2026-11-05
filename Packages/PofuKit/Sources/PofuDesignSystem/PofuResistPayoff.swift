import Foundation

// The "I resisted" payoff (experience-v1 section 3.4). "Boş ver" closes the
// app and no notification follows; the next time the person sees Pofu, this
// plays: the day's skip pot blooms, one seed arcs into the jar, the resist
// haptic and chime play, and a line appears in the bubble. It is always
// exactly one second long, whether one resist or five: several resists play
// as one cascade, the pots blooming left to right.

/// The timeline of one payoff. Pure, so the one-second promise is tested.
public struct ResistPayoff: Equatable, Sendable {
    /// The fixed length, in seconds. The same every time.
    public static let duration: TimeInterval = 1.0
    /// How long one pot takes to bloom.
    public static let bloomDuration: TimeInterval = 0.4
    /// The seed leaves the pot and lands in the jar.
    public static let seedFlight: ClosedRange<TimeInterval> = 0.2...0.8
    /// The haptic and the chime play together.
    public static let feelAt: TimeInterval = 0.15
    /// The line in the bubble fades in.
    public static let lineAt: TimeInterval = 0.3
    /// The seed's burst plays as it lands, to the end.
    public static let burst: ClosedRange<TimeInterval> = 0.8...1.0
    /// More pots than this bloom as the same cascade (the island shows at
    /// most eight, `SkipPots.maxVisible`).
    public static let maxPots = 8

    /// Resists since the person last saw Pofu, at least one.
    public let resists: Int

    public init(resists: Int) {
        self.resists = max(1, resists)
    }

    /// Pots that bloom, left to right.
    public var potCount: Int { min(resists, Self.maxPots) }

    /// When pot `index` (0 is the leftmost bloom) starts to bloom. The
    /// cascade is spread so the last pot finishes with the payoff.
    public func bloomStart(of index: Int) -> TimeInterval {
        guard potCount > 1 else { return 0 }
        let span = Self.duration - Self.bloomDuration
        return span * Double(min(max(index, 0), potCount - 1)) / Double(potCount - 1)
    }

    /// Pot `index`'s bloom at `time`, `0...1`.
    public func bloomProgress(of index: Int, at time: TimeInterval) -> Double {
        let t = (time - bloomStart(of: index)) / Self.bloomDuration
        return min(max(t, 0), 1)
    }

    /// The seed's flight at `time`, `0...1`; `0` before it leaves.
    public func seedProgress(at time: TimeInterval) -> Double {
        let flight = Self.seedFlight
        return min(max((time - flight.lowerBound) / (flight.upperBound - flight.lowerBound), 0), 1)
    }

    /// The line's opacity at `time`: in over 0.2 s, held to the end.
    public func lineOpacity(at time: TimeInterval) -> Double {
        min(max((time - Self.lineAt) / 0.2, 0), 1)
    }

    /// The burst's progress at `time`, `0...1`; `0` before the seed lands.
    public func burstProgress(at time: TimeInterval) -> Double {
        let burst = Self.burst
        return min(max((time - burst.lowerBound) / (burst.upperBound - burst.lowerBound), 0), 1)
    }

    /// Every moment the payoff does something, in order, for tests and for
    /// whoever schedules the haptic and the chime.
    public enum Moment: Equatable, Sendable {
        case potBloomStarts(Int)
        case feel
        case lineAppears
        case seedLeaves
        case seedLands
    }

    public var moments: [(time: TimeInterval, moment: Moment)] {
        var all: [(TimeInterval, Moment)] = (0..<potCount).map { (bloomStart(of: $0), .potBloomStarts($0)) }
        all.append((Self.feelAt, .feel))
        all.append((Self.lineAt, .lineAppears))
        all.append((Self.seedFlight.lowerBound, .seedLeaves))
        all.append((Self.seedFlight.upperBound, .seedLands))
        return all.sorted { $0.0 < $1.0 }.map { (time: $0.0, moment: $0.1) }
    }

    /// When the last thing finishes. Always `duration`.
    public var end: TimeInterval {
        let lastBloom = bloomStart(of: potCount - 1) + Self.bloomDuration
        return max(lastBloom, Self.seedFlight.upperBound, Self.burst.upperBound, Self.lineAt + 0.2)
    }
}

#if canImport(SwiftUI)
import SwiftUI

/// A payoff that is playing: its timeline and when it began. Home's skip
/// pots read it from the environment to bloom with the overlay.
public struct ResistPayoffRun: Equatable, Sendable {
    public let id = UUID()
    public let payoff: ResistPayoff
    public let start: Date

    public init(payoff: ResistPayoff, start: Date = Date()) {
        self.payoff = payoff
        self.start = start
    }

    /// Seconds since the start at `date`.
    public func time(at date: Date) -> TimeInterval {
        date.timeIntervalSince(start)
    }

    public func isOver(at date: Date) -> Bool {
        time(at: date) >= ResistPayoff.duration
    }
}

private struct ResistPayoffRunKey: EnvironmentKey {
    static let defaultValue: ResistPayoffRun? = nil
}

extension EnvironmentValues {
    /// The payoff playing now, if one is.
    public var resistPayoff: ResistPayoffRun? {
        get { self[ResistPayoffRunKey.self] }
        set { self[ResistPayoffRunKey.self] = newValue }
    }
}

/// The payoff's overlay: one seed arcs from the lower middle of the screen
/// to the jar, a burst sparkles where it lands, and the line appears.
/// Decorative to VoiceOver apart from the line. `reward-seed-burst` is
/// code-drawn until the Codex art is baked into this package's resources
/// under that name, when the picture takes over.
public struct ResistPayoffOverlay: View {
    let run: ResistPayoffRun
    let line: String
    /// Where the jar sits, in unit coordinates of the screen.
    let jar: UnitPoint

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(run: ResistPayoffRun, line: String, jar: UnitPoint = UnitPoint(x: 0.88, y: 0.14)) {
        self.run = run
        self.line = line
        self.jar = jar
    }

    public var body: some View {
        TimelineView(.animation(paused: false)) { context in
            let time = min(run.time(at: context.date), ResistPayoff.duration)
            GeometryReader { proxy in
                let size = proxy.size
                let start = CGPoint(x: size.width * 0.5, y: size.height * 0.62)
                let end = CGPoint(x: size.width * jar.x, y: size.height * jar.y)
                let progress = run.payoff.seedProgress(at: time)
                ZStack {
                    if progress > 0, progress < 1 {
                        SeedGlyph()
                            .fill(PofuColor.accent)
                            .frame(width: 10, height: 16)
                            .rotationEffect(.degrees(18 + progress * 300))
                            .position(arc(from: start, to: end, at: reduceMotion ? 1 : progress))
                    }
                    let burst = run.payoff.burstProgress(at: time)
                    if burst > 0 {
                        SeedBurst(progress: burst)
                            .position(end)
                    }
                    Text(verbatim: line)
                        .font(.system(.title2, design: .rounded, weight: .heavy))
                        .foregroundStyle(Color(red: 0.24, green: 0.18, blue: 0.14))
                        .padding(.horizontal, PofuSpacing.xl)
                        .padding(.vertical, PofuSpacing.m)
                        .background { PofuPaperPanel() }
                        .opacity(run.payoff.lineOpacity(at: time))
                        .scaleEffect(0.96 + 0.04 * run.payoff.lineOpacity(at: time))
                        .position(x: size.width / 2, y: size.height * 0.5)
                        .accessibilityLabel(Text(verbatim: line))
                }
            }
        }
        .allowsHitTesting(false)
    }

    /// A quadratic curve that lifts the seed up and over.
    private func arc(from a: CGPoint, to b: CGPoint, at t: Double) -> CGPoint {
        let control = CGPoint(x: (a.x + b.x) / 2 + 40, y: min(a.y, b.y) - 120)
        let u = 1 - t
        return CGPoint(
            x: u * u * a.x + 2 * u * t * control.x + t * t * b.x,
            y: u * u * a.y + 2 * u * t * control.y + t * t * b.y
        )
    }
}

/// Six little seeds fly out and fade: the stand-in for `reward-seed-burst`.
private struct SeedBurst: View {
    let progress: Double

    var body: some View {
        ZStack {
            ForEach(0..<6, id: \.self) { index in
                let angle = Double(index) / 6 * 2 * .pi
                Capsule()
                    .fill(PofuPrimitive.honey400.rgb.color)
                    .frame(width: 4, height: 9)
                    .rotationEffect(.radians(angle))
                    .offset(x: cos(angle - .pi / 2) * 26 * progress, y: sin(angle - .pi / 2) * 26 * progress)
                    .opacity(1 - progress)
            }
        }
        .accessibilityHidden(true)
    }
}
#endif
