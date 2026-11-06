import Foundation
import PofuGames

/// Which world moments earn a cue. Pure, so it is tested on Linux; the app
/// supplies the facts.
public enum WorldMoments {
    /// The tea stall's kettle: by morning light only.
    public static let kettleHours: Range<Int> = 6..<11

    /// The kettle whistles on the first morning visit of the day, once the
    /// tea stall is built.
    public static func shouldWhistleKettle(hour: Int, teaStallLevel: Int, alreadyToday: Bool) -> Bool {
        teaStallLevel > 0 && !alreadyToday && kettleHours.contains(hour)
    }

    /// The Pofu motif sounds when the island level went up since the last
    /// time we looked; the first look only remembers it.
    public static func islandLevelRose(from previous: Int?, to current: Int) -> Bool {
        guard let previous else { return false }
        return current > previous
    }
}

/// The flow game's cues on the sound cues: clicks and thunks borrow the
/// garden's wood, the trickle climbs the pentatonic ladder, the water is
/// its own.
public enum FlowSoundMap {
    /// The trickle's ladder stops here; a long pour does not shrill.
    public static let trickleTopStep = 6

    public static func cues(for cue: FlowSoundCue) -> [SoundCue] {
        switch cue {
        case .click: [.pieceSnap]
        case .thunk: [.pieceDrop]
        case .trickle(let step): [.bloom(step: min(max(step, 0), trickleTopStep))]
        case .wheelCreak: [.waterWheel]
        case .splash: [.waterSplash]
        case .pour: [.waterPour]
        }
    }
}

#if canImport(AVFoundation)
/// The flow game's `FlowSoundPlaying`, backed by the shared engine.
public final class FlowSoundBridge: FlowSoundPlaying {
    public init() {}

    @MainActor public func play(_ cue: FlowSoundCue) {
        for mapped in FlowSoundMap.cues(for: cue) {
            SoundEngine.shared.play(mapped)
        }
    }
}
#endif
