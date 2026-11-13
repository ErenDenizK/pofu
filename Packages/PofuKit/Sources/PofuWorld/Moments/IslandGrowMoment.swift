import Foundation

/// "Ada büyüdü": the island level rose, and the player sees it happen. A pure
/// function of the time since the moment began, like `BuildMoment`, so a
/// screenshot or a test can stop it anywhere.
///
/// The old painting stays on screen until the cross-fade begins; the scene
/// draws the painting of a *presented* level that trails the true one
/// (`IslandLevelStage`) until `crossFade`.
///
/// | t (s) | Cue | What happens |
/// |---|---|---|
/// | 0 | `pullBack` | Any sheet closes, the station focus lets go and the camera travels to the whole island. The old painting is still on screen |
/// | 0.7 | `bloom` | The level-up sound and the growth haptic; a warm bloom rises from the island's centre |
/// | 0.8 | `crossFade` | The existing 1.4 s cross-fade to the new painting begins, in full view (it ends at 2.2) |
/// | 1.6 | `card` | The "Ada n" card rises above the island, Pofu's line under it |
/// | 4.6 | `end` | The card has left; the camera settles |
///
/// With Reduce Motion there is no camera move and no bloom: the cross-fade
/// and the card only. Low Power Mode draws no bloom. The sound and the
/// haptic are not motion, so they play either way.
public struct IslandGrowMoment: Hashable, Sendable {
    public enum Cue: Int, Hashable, Sendable, CaseIterable, Comparable {
        case pullBack
        case bloom
        case crossFade
        case card
        case end

        public static func < (lhs: Cue, rhs: Cue) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    /// The level the painting showed, and the level it grows to.
    public let fromLevel: Int
    public let toLevel: Int
    public let reduceMotion: Bool
    /// Low Power Mode: no bloom.
    public let lowPower: Bool

    public init(fromLevel: Int, toLevel: Int, reduceMotion: Bool, lowPower: Bool = false) {
        self.fromLevel = fromLevel
        self.toLevel = max(toLevel, fromLevel)
        self.reduceMotion = reduceMotion
        self.lowPower = lowPower
    }

    // MARK: - Timeline

    /// The painting's own cross-fade (`PlateHomeLayer.crossfade` takes it from here).
    public static let crossFadeLength = 1.4
    public static let bloomAt = 0.7
    public static let crossFadeAt = 0.8
    public static let cardAt = 1.6
    public static let endAt = 4.6
    /// The card fades in and out over this long.
    public static let cardFade = 0.35
    public static let cardLeave = 0.4
    /// The bloom rises to its peak, holds the peak's instant, then falls.
    public static let bloomRise = 0.6
    public static let bloomFall = 1.5
    public static let bloomPeak = 0.38

    /// When `cue` plays, or `nil` when it does not (Reduce Motion has no camera move).
    public func time(of cue: Cue) -> Double? {
        switch cue {
        case .pullBack: reduceMotion ? nil : 0
        case .bloom: Self.bloomAt
        case .crossFade: Self.crossFadeAt
        case .card: Self.cardAt
        case .end: Self.endAt
        }
    }

    public var duration: Double {
        Self.endAt
    }

    /// The cues in `(after, through]`, in time order; a cue at 0 plays for a start before 0.
    public func cues(after start: Double, through end: Double) -> [Cue] {
        Cue.allCases.filter { cue in
            guard let t = time(of: cue) else { return false }
            return (t > start || (t == 0 && start < 0)) && t <= end
        }
        .sorted { (time(of: $0) ?? 0, $0) < (time(of: $1) ?? 0, $1) }
    }

    // MARK: - The painting

    /// The level the scene draws at `t`: the old one until the cross-fade
    /// begins, the new one from then on. Never above `toLevel`.
    public func presentedLevel(at t: Double) -> Int {
        t >= Self.crossFadeAt ? toLevel : fromLevel
    }

    /// How far the new painting has faded in, 0...1 (the plate layer's own
    /// ease-in-out, for the tests and the screenshots).
    public func newPainting(at t: Double) -> Double {
        MomentCurves.smoothstep(MomentCurves.progress(t, from: Self.crossFadeAt, length: Self.crossFadeLength))
    }

    // MARK: - The bloom

    /// The warm light over the island, 0...1 of its peak, or 0 when there is
    /// none (Reduce Motion, Low Power Mode, outside its window).
    public func bloom(at t: Double) -> Double {
        guard !reduceMotion, !lowPower else { return 0 }
        let rise = MomentCurves.easeOut(MomentCurves.progress(t, from: Self.bloomAt, length: Self.bloomRise))
        let fall = MomentCurves.smoothstep(MomentCurves.progress(t, from: Self.bloomAt + Self.bloomRise, length: Self.bloomFall))
        return rise * (1 - fall)
    }

    /// The bloom's peak opacity, over the island.
    public var bloomOpacity: Double {
        Self.bloomPeak
    }

    // MARK: - The card

    /// The "Ada n" card: its opacity and how far it still has to rise, 0...1
    /// (1 just appeared, 0 settled), or `nil` while hidden. `leavesAt` is
    /// the moment's end, or an earlier time when a tap sends it away.
    public func card(at t: Double, leavesAt: Double? = nil) -> (opacity: Double, rise: Double)? {
        let out = min(leavesAt ?? Self.endAt, Self.endAt)
        guard t >= Self.cardAt, t < out else { return nil }
        let fadeIn = MomentCurves.progress(t, from: Self.cardAt, length: Self.cardFade)
        let fadeOut = MomentCurves.progress(t, from: out - Self.cardLeave, length: Self.cardLeave)
        let rise = reduceMotion ? 0 : 1 - MomentCurves.easeOut(fadeIn)
        return (fadeIn * (1 - fadeOut), rise)
    }

    /// Pofu's line is written for the levels the island can reach after the
    /// first; a level without one shows the title alone.
    public static let linedLevels = 2...8

    public static func hasLine(for level: Int) -> Bool {
        linedLevels.contains(level)
    }
}
