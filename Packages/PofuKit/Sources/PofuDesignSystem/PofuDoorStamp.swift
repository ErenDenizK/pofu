import Foundation

// The payoff at the door (ui-v3 section 3b, the-door section 2 "Payoff, not
// a screen"). The next time the app opens after resisted reaches, Home shows
// the new resists as wax seals pressed on the earth beside Pofu's round door,
// one by one (the world draws them, `PofuWorld/Scene/ResistSeals.swift`, and
// they stay as the island's tally of the day), then the world settles. It never blocks input, any tap skips it, it plays
// at most once per open, and with Reduce Motion the plaque simply fades in
// already stamped. This file is the pure timeline and the once-per-open
// rule; the overlay is below.

/// The timeline of one door stamp. Pure, so the promises are tested.
public struct DoorStamp: Equatable, Sendable {
    /// The whole moment, in seconds.
    public static let duration: TimeInterval = 2.0
    /// The beat before the first seal.
    public static let leadIn: TimeInterval = 0.3
    /// One seal's press, and the gap between seals.
    public static let sealInterval: TimeInterval = 0.18
    /// The island shows at most this many seals; the last carries `+n`.
    public static let maxSeals = 8

    /// Resists since the last payoff, at least one.
    public let resists: Int

    public init(resists: Int) {
        self.resists = max(1, resists)
    }

    public var sealCount: Int { min(resists, Self.maxSeals) }

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

    /// With Reduce Motion: the new seals fade in over 0.2 s, already
    /// pressed, `0...1`.
    public func fadeProgress(at time: TimeInterval) -> Double {
        min(max((time - Self.leadIn) / 0.2, 0), 1)
    }

    /// Times at which a soft impact haptic plays: one per seal, or a single
    /// one for the static fade.
    public func hapticTimes(reduceMotion: Bool) -> [TimeInterval] {
        reduceMotion ? [Self.leadIn] : (0..<sealCount).map { sealStart(of: $0) }
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

/// A resisted reach as a wax seal. The batch-61 `seal-resist` picture takes
/// over when it lands; until then it is drawn in code.
public struct ResistWaxSeal: View {
    let night: Bool

    private static let wax = PofuKitPalette.rgb(0xB5483B)
    private static let waxDark = PofuKitPalette.rgb(0x8E3329)

    public init(night: Bool = false) {
        self.night = night
    }

    public var body: some View {
        let palette = night ? PofuKitPalette.night : PofuKitPalette.day
        PofuKitFace(.sealResist) {
            ZStack {
                Circle().fill(RadialGradient(colors: [Self.wax, Self.waxDark], center: .topLeading, startRadius: 1, endRadius: 30))
                Circle().strokeBorder(Color.white.opacity(0.28), lineWidth: 1.4).padding(4)
                Image(systemName: "leaf.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.85))
            }
            .shadow(color: palette.edge.opacity(0.3), radius: 2, y: 1)
        }
        .accessibilityHidden(true)
    }
}
#endif
