/// The garden's sound hooks. The sound system (`PofuAudio`,
/// docs/design/sound-identity.md §5) is not built yet, so the scene calls
/// a `GameSoundPlaying` and the default plays nothing. When `PofuAudio`
/// lands, it conforms and maps each cue to a micro-sound; the cues and
/// their pitches are decided here so the game and the sound system agree.
public enum GardenSoundCue: Sendable, Equatable {
    /// A plot lifts from the tray (a soft paper "fff").
    case lift
    /// A plot finds a cell while dragging (the "station tok", quiet).
    case snap
    /// A plot is planted (a soil "pat", with the medium haptic).
    case plant
    /// A plot goes back to the tray (a wood "tok").
    case putBack
    /// A cell blooms: a kalimba note, `MIDI` from `PentatonicLadder`.
    case bloom(midi: Int)
    /// A seed lands in Pofu's cheeks (the "pomf", sound 9).
    case cheek
    /// A new tray is dealt (three small paper slides).
    case deal
    /// The round ends (the build's three rising kalimba notes).
    case roundEnd
}

public protocol GameSoundPlaying: AnyObject {
    @MainActor func play(_ cue: GardenSoundCue)
}

/// The stand-in until the sound system exists: silence, by design
/// (ambience and game sounds are off by default anyway).
public final class SilentGameSound: GameSoundPlaying {
    public init() {}
    @MainActor public func play(_ cue: GardenSoundCue) {}
}

/// D major pentatonic (D E F♯ A B), the one key every tonal Pofu sound
/// uses (sound identity §4.1), so blooms never clash with anything else.
/// A bloom sweep climbs the ladder cell by cell; a combo starts it higher,
/// so a streak is heard as rising, without louder or busier sound.
public enum PentatonicLadder {
    /// D4, E4, F♯4, A4, B4 as MIDI note numbers.
    public static let degrees = [62, 64, 66, 69, 71]

    /// The note for `step` steps up from D4, wrapping into higher octaves,
    /// capped at two octaves so it never squeals on a phone speaker.
    public static func midi(step: Int) -> Int {
        let step = min(max(0, step), degrees.count * 2)
        return degrees[step % degrees.count] + 12 * (step / degrees.count)
    }

    /// The note of the `index`-th cell of a bloom at combo `combo`.
    public static func bloomNote(index: Int, combo: Int) -> Int {
        midi(step: index / 2 + 2 * max(0, combo - 1))
    }
}
