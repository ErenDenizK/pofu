import Foundation

// The payoff at the door (ui-v3 section 3b, the-door section 2 "Payoff, not
// a screen"). The next time the app opens after resisted reaches, Home shows
// the resists as wax seals pressed on the round door's plaque, one by one,
// then the world settles. It never blocks input, any tap skips it, it plays
// at most once per open, and with Reduce Motion the plaque simply fades in
// already stamped. This file is the pure timeline and the once-per-open
// rule; the overlay is below.

/// The timeline of one door stamp. Pure, so the promises are tested.
public struct DoorStamp: Equatable, Sendable {
    /// The whole moment, in seconds.
    public static let duration: TimeInterval = 2.0
    /// The plaque eases in before the first seal.
    public static let leadIn: TimeInterval = 0.3
    /// One seal's press, and the gap between seals.
    public static let sealInterval: TimeInterval = 0.18
    /// The plaque fades out over the last stretch.
    public static let fadeOut: TimeInterval = 0.4
    /// More resists than this show as `+n`.
    public static let maxSeals = 5

    /// Resists since the last payoff, at least one.
    public let resists: Int

    public init(resists: Int) {
        self.resists = max(1, resists)
    }

    public var sealCount: Int { min(resists, Self.maxSeals) }
    public var overflow: Int { max(resists - Self.maxSeals, 0) }

    /// When seal `index` starts to press.
    public func sealStart(of index: Int) -> TimeInterval {
        Self.leadIn + Self.sealInterval * Double(min(max(index, 0), sealCount - 1))
    }

    /// Seal `index`'s press at `time`, `0...1`.
    public func sealProgress(of index: Int, at time: TimeInterval) -> Double {
        min(max((time - sealStart(of: index)) / Self.sealInterval, 0), 1)
    }

    /// When the last seal has landed.
    public var stampedAt: TimeInterval { sealStart(of: sealCount - 1) + Self.sealInterval }

    /// The plaque's opacity at `time`, in over the lead-in, out over the
    /// last `fadeOut` seconds.
    public func plaqueOpacity(at time: TimeInterval) -> Double {
        let fadeIn = min(max(time / Self.leadIn, 0), 1)
        let out = min(max((Self.duration - time) / Self.fadeOut, 0), 1)
        return min(fadeIn, out)
    }

    /// With Reduce Motion: a static fade, the plaque already stamped.
    public func reducedOpacity(at time: TimeInterval) -> Double {
        let fadeIn = min(max(time / 0.2, 0), 1)
        let out = min(max((Self.duration - time) / Self.fadeOut, 0), 1)
        return min(fadeIn, out)
    }

    /// Times at which a soft impact haptic plays: one per seal, or a single
    /// one for the static fade.
    public func hapticTimes(reduceMotion: Bool) -> [TimeInterval] {
        reduceMotion ? [0.2] : (0..<sealCount).map { sealStart(of: $0) }
    }

    /// Pofu hops proud when the last seal lands.
    public var hopAt: TimeInterval { stampedAt }
}

/// The once-per-open rule. An open is one stretch of the app in the
/// foreground; `reset()` is called when it goes to the background. The
/// caller checks `isSpent` before consuming the unseen count, so a resist is
/// never taken from the ledger without being shown.
public struct DoorStampOpen: Equatable, Sendable {
    public private(set) var isSpent = false

    public init() {}

    /// The stamp owed for `unseen` resists, or `nil` when there are none or
    /// this open has already had its payoff.
    public mutating func claim(unseen: Int) -> DoorStamp? {
        guard !isSpent, unseen > 0 else { return nil }
        isSpent = true
        return DoorStamp(resists: unseen)
    }

    public mutating func reset() {
        isSpent = false
    }
}

#if canImport(SwiftUI)
import SwiftUI

/// A door stamp that is playing.
public struct DoorStampRun: Equatable, Sendable {
    public let id = UUID()
    public let stamp: DoorStamp
    public let start: Date

    public init(stamp: DoorStamp, start: Date = Date()) {
        self.stamp = stamp
        self.start = start
    }

    public func time(at date: Date) -> TimeInterval {
        date.timeIntervalSince(start)
    }
}

/// The plaque of the round door with the day's seals. Never takes touches;
/// the root skips it with a simultaneous tap. `frozenAt` pins the clock for
/// screenshots.
public struct DoorStampOverlay: View {
    let run: DoorStampRun
    let frozenAt: TimeInterval?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.pofuNight) private var night
    @Environment(\.colorScheme) private var scheme

    public init(run: DoorStampRun, frozenAt: TimeInterval? = nil) {
        self.run = run
        self.frozenAt = frozenAt
    }

    public var body: some View {
        TimelineView(.animation(paused: frozenAt != nil)) { context in
            let time = frozenAt ?? min(run.time(at: context.date), DoorStamp.duration)
            plaque(at: time)
        }
        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Skipped \(run.stamp.resists) times today"))
    }

    private func plaque(at time: TimeInterval) -> some View {
        let stamp = run.stamp
        let palette = PofuKitStyleResolver(night: night, scheme: scheme, contrast: .standard).palette
        let opacity = reduceMotion ? stamp.reducedOpacity(at: time) : stamp.plaqueOpacity(at: time)
        let lift = reduceMotion ? 0 : (1 - min(max(time / DoorStamp.leadIn, 0), 1)) * 12
        return ZStack {
            Circle()
                .fill(LinearGradient(colors: [palette.woodTop, palette.woodBottom], startPoint: .top, endPoint: .bottom))
            Circle().strokeBorder(palette.edge.opacity(0.55), lineWidth: 3)
            Circle().strokeBorder(palette.stitch, style: StrokeStyle(lineWidth: 1.4, dash: [4, 4])).padding(11)
            HStack(spacing: 6) {
                ForEach(0..<stamp.sealCount, id: \.self) { index in
                    let progress = reduceMotion ? 1 : stamp.sealProgress(of: index, at: time)
                    DoorWaxSeal(palette: palette)
                        .frame(width: 34, height: 34)
                        .scaleEffect(1 + 0.6 * (1 - Self.press(progress)))
                        .opacity(progress > 0 ? min(progress * 4, 1) : 0)
                        .overlay {
                            if !reduceMotion, progress > 0, progress < 1 {
                                Circle()
                                    .stroke(Color.white.opacity(0.5 * (1 - progress)), lineWidth: 2)
                                    .scaleEffect(1 + progress * 0.9)
                            }
                        }
                }
                if stamp.overflow > 0 {
                    Text(verbatim: "+\(stamp.overflow)")
                        .font(.system(.title3, design: .rounded, weight: .heavy))
                        .foregroundStyle(palette.onPaper)
                        .opacity(reduceMotion || time >= stamp.stampedAt ? 1 : 0)
                }
            }
        }
        .frame(width: 252, height: 252)
        .shadow(color: palette.edge.opacity(0.35), radius: 14, y: 6)
        .opacity(opacity)
        .offset(y: lift)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .offset(y: -60)
    }

    /// A press: overshoots a little before it rests.
    private static func press(_ t: Double) -> Double {
        let c = 1.7
        let u = t - 1
        return 1 + (c + 1) * u * u * u + c * u * u
    }
}

/// A resisted reach as a wax seal. The batch-61 `seal-resist` picture takes
/// over when it lands; until then it is drawn in code.
struct DoorWaxSeal: View {
    let palette: PofuKitPalette

    private static let wax = PofuKitPalette.rgb(0xB5483B)
    private static let waxDark = PofuKitPalette.rgb(0x8E3329)

    var body: some View {
        PofuKitFace(.sealResist) {
            ZStack {
                Circle().fill(RadialGradient(colors: [Self.wax, Self.waxDark], center: .topLeading, startRadius: 1, endRadius: 30))
                Circle().strokeBorder(Color.white.opacity(0.28), lineWidth: 1.4).padding(4)
                Image(systemName: "leaf.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.85))
            }
            .shadow(color: palette.edge.opacity(0.3), radius: 2, y: 1)
        }
        .accessibilityHidden(true)
    }
}
#endif
