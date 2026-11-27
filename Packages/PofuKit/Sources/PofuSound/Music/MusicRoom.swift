import Foundation
import PofuTuning

/// What the music room tells the founder about a state he picked: the cell
/// the director would play first, or why it plays nothing. Pure, so the
/// room's wording never has to guess (music-system-v1 section 8, MU3).
public enum MusicRoomAnswer: Equatable, Sendable {
    /// The first phrase of a visit, and the range its following pause is drawn from.
    case phrase(MusicPhrase, pause: ClosedRange<Double>)
    case silence(MusicSilence)

    /// The stems that sound, in the director's order.
    public var stems: [MusicStem] {
        guard case .phrase(let phrase, _) = self else { return [] }
        return phrase.stems.map(\.stem)
    }
}

public enum MusicRoom {
    /// The seed the room's answers and its audition share, so what it shows is what plays first.
    public static let seed: UInt64 = 1

    /// The answer for `state`: a fresh director's first phrase for `seed`, or the silence and its reason.
    public static func answer(
        for state: MusicState, isMusicOn: Bool, index: MusicIndex,
        tuning: TuningValues.Sound = TuningValues.defaults.sound, seed: UInt64 = MusicRoom.seed
    ) -> MusicRoomAnswer {
        var director = MusicDirector(index: index, tuning: tuning, seed: seed)
        if let reason = director.silence(for: state, isMusicOn: isMusicOn) { return .silence(reason) }
        guard let phrase = director.next(for: state, isMusicOn: isMusicOn) else { return .silence(.noTune) }
        return .phrase(phrase, pause: director.pauseRange(for: state))
    }

    /// The stingers the spec lists (section 6). None is rendered before MU4,
    /// so the room shows them as coming and never plays anything for them.
    public enum Stinger: String, CaseIterable, Sendable {
        case stationBuilt, islandGrows
    }
}
