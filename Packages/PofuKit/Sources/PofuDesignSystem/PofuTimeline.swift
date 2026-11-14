import Foundation

// The one rule for continuous redraws. A `TimelineView(.animation)` without an
// interval runs at the display rate, 120 Hz on a ProMotion iPhone, and a
// still painting that redraws that often warms the phone. Every continuous
// timeline in PofuWorld, PofuCompanion and PofuDesignSystem goes through
// `PofuTimeline`, which asks for a rate matched to what moves and stops when
// nothing should move. `PofuFrameRuleTests` scans the sources for a bare
// `TimelineView(.animation`.

/// The rates (frames per second) the app asks for, by what moves.
public enum PofuFrameRate {
    /// Slow drift: clouds under 5 pt a second, bobbing isles, twinkling stars, fog.
    public static let drift = 15.0
    /// Breath and blink of a resting figure; glow pulses; sways.
    public static let idle = 20.0
    /// Rain, rings, seals and other short, readable events.
    public static let event = 30.0
    /// A gesture or a camera move the finger drives.
    public static let direct = 60.0
}

/// Whether and how fast a timeline runs. Pure, so tests pin it.
public enum PofuFrameRule {
    /// Ambient motion is decoration: it stops under Reduce Motion and Low
    /// Power Mode. Essential motion is feedback the person asked for (a tap, a
    /// payoff, a loading curtain): it keeps running there, at its rate.
    public enum Kind: Sendable { case ambient, essential }

    public static func isPaused(
        kind: Kind, requested: Bool, active: Bool, reduceMotion: Bool, lowPower: Bool
    ) -> Bool {
        if requested || !active { return true }
        switch kind {
        case .ambient: return reduceMotion || lowPower
        case .essential: return false
        }
    }

    /// The `TimelineView` interval for a rate: never above `PofuFrameRate.direct`.
    public static func interval(hz: Double) -> Double {
        1 / min(max(hz, 1), PofuFrameRate.direct)
    }
}

#if canImport(SwiftUI)
import SwiftUI

/// A continuous timeline at a chosen rate that pauses by `PofuFrameRule`.
public struct PofuTimeline<Content: View>: View {
    private let hz: Double
    private let paused: Bool
    private let kind: PofuFrameRule.Kind
    private let content: (TimelineViewDefaultContext) -> Content

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        hz: Double,
        paused: Bool = false,
        kind: PofuFrameRule.Kind = .ambient,
        @ViewBuilder content: @escaping (TimelineViewDefaultContext) -> Content
    ) {
        self.hz = hz
        self.paused = paused
        self.kind = kind
        self.content = content
    }

    public var body: some View {
        let stopped = PofuFrameRule.isPaused(
            kind: kind,
            requested: paused,
            active: scenePhase == .active,
            reduceMotion: reduceMotion,
            lowPower: ProcessInfo.processInfo.isLowPowerModeEnabled
        )
        TimelineView(.animation(minimumInterval: PofuFrameRule.interval(hz: hz), paused: stopped), content: content)
    }
}
#endif
