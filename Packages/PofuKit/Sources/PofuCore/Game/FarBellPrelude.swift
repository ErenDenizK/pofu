import Foundation

/// The far bell's road: days 17 to 20 of the tester's path, one more of
/// Pofu's four notes comes back from far off each day, and the bell on
/// day 21 is the fifth day of the same thread (docs/design/days-17-21-v1.md,
/// D1 and D2). Nothing is saved: the step is a pure function of the
/// snapshot, so a day not played keeps its step for the next day played
/// and a player who heals late hears only the last steps, then the bell.
public enum FarBellPrelude {
    /// The steps before the bell: the hum, then one more note back each day.
    public static let steps = 4

    /// The step due on a day, or `nil`: both islands healed, the bell still
    /// silent, and one to `steps` tended days left before it can ring.
    public static func step(tendedDays: Int, bothHealed: Bool, bell: FarBellStatus) -> Int? {
        guard bothHealed, bell == .silent else { return nil }
        let left = FarBell.tendedDays - tendedDays
        guard (1...steps).contains(left) else { return nil }
        return steps - left + 1
    }

    public static func step(in world: WorldSnapshot) -> Int? {
        step(tendedDays: world.tendedDays, bothHealed: world.koke.isHealed && world.caglayan.isHealed, bell: world.bell)
    }

    /// The bell's own day: it rang (or was heard) on the tended day the rule names.
    public static func isBellDay(in world: WorldSnapshot) -> Bool {
        world.bell != .silent && world.tendedDays == FarBell.tendedDays
    }
}

/// The notes of the road, as data: which ladder step, when, and whether it
/// is far off (the answer) or Pofu's own hum. The app plays them as single
/// `SoundCue.bloom(step:)` notes; the logo file stays rationed (sound
/// identity §4.3). Tunable numbers live here.
public enum FarBellTune {
    public struct Note: Hashable, Sendable {
        /// The pentatonic ladder step of `SoundCue.bloom(step:)`: 0 is D4, 5 is D5.
        public var step: Int
        /// Seconds from the start of the tune.
        public var at: TimeInterval
        /// A far note (the answer) rather than Pofu's hum.
        public var isFar: Bool

        public init(step: Int, at: TimeInterval, isFar: Bool) {
            self.step = step
            self.at = at
            self.isFar = isFar
        }
    }

    /// Pofu's four notes, D5 F#5 A5 B5.
    public static let hum = [5, 7, 8, 9]
    /// The far answer, an octave down.
    public static let farSong = [0, 2, 3, 4]
    /// What the third far note is on day 20: E4, not A4.
    public static let wrongThird = 1
    /// The bell's fifth note.
    public static let oneMore = 5
    /// How many far notes come back on each step.
    public static let answered = [0, 1, 2, 4]
    public static let humGap = 0.34
    public static let farGap = 0.46
    /// The breath between the hum and the answer.
    public static let breath = 0.9
    /// The bell plays this long after its card comes up.
    public static let bellLead = 1.4

    /// A step's tune: Pofu's four notes, then the far notes that came back.
    public static func prelude(step: Int) -> [Note] {
        guard (1...FarBellPrelude.steps).contains(step) else { return [] }
        var notes = hum.enumerated().map { Note(step: $1, at: Double($0) * humGap, isFar: false) }
        let first = 3 * humGap + breath
        for index in 0..<answered[step - 1] {
            let wrong = step == FarBellPrelude.steps && index == 2
            notes.append(Note(step: wrong ? wrongThird : farSong[index], at: first + Double(index) * farGap, isFar: true))
        }
        return notes
    }

    /// The bell: the song right, then one note more.
    public static func bell() -> [Note] {
        (farSong + [oneMore]).enumerated().map { Note(step: $1, at: bellLead + Double($0) * farGap, isFar: true) }
    }

    /// When the last note starts; 0 for no notes.
    public static func length(of notes: [Note]) -> TimeInterval {
        notes.map(\.at).max() ?? 0
    }
}
