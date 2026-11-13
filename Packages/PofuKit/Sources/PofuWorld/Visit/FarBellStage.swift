import Foundation
import Observation
import PofuCore

/// What the far bell's road asks the ears for.
public enum FarBellCue: Hashable, Sendable {
    /// A step's button was taken: Pofu hums, the far notes come back.
    case prelude(step: Int)
    /// The bell's card came up.
    case bell
}

public enum FarBellCues {
    /// The cue a change of the visit holds, or `nil`. A step plays when its
    /// button is taken; the bell plays when its card comes up.
    public static func cue(from old: VisitProgress, to new: VisitProgress) -> FarBellCue? {
        if old.plan == new.plan, new.played == old.played + 1, case .news(.farNotes(let step))? = old.current {
            return .prelude(step: step)
        }
        if new.current == .bell, old.current != .bell || old.plan != new.plan {
            return .bell
        }
        return nil
    }
}

/// Remembers which visit state the bell's song was cued for, so the cue
/// may fire from two places (the visit's change and the Home view's
/// appearing, for a cold launch straight onto the bell card) and never
/// plays twice for the same card.
public struct FarBellCueGuard: Sendable {
    private var cued: VisitProgress?

    public init() {}

    /// The visit changed: the usual cue, recorded when it is the bell.
    public mutating func cue(from old: VisitProgress, to new: VisitProgress) -> FarBellCue? {
        let cue = FarBellCues.cue(from: old, to: new)
        if cue == .bell {
            cued = new
        }
        return cue
    }

    /// Home appeared on `visit`: the bell, if its card is up and its song
    /// has not been cued for this very state.
    public mutating func cueOnAppear(_ visit: VisitProgress) -> FarBellCue? {
        guard visit.current == .bell, cued != visit else { return nil }
        cued = visit
        return .bell
    }
}

/// The tune that plays now (or is held for a frame), so the sky can draw
/// the notes the ears hear (`docs/design/days-17-21-v1.md`, PR 2).
@MainActor
@Observable
public final class FarBellStage {
    public static let shared = FarBellStage()

    public private(set) var notes: [FarBellTune.Note] = []
    public private(set) var start: Date?
    public private(set) var frozenAge: Double?
    /// The app's sound pass plays the notes here.
    @ObservationIgnored public var onPlay: (@MainActor ([FarBellTune.Note]) -> Void)?

    public init() {}

    /// A tune begins now. An empty tune is ignored.
    public func play(_ notes: [FarBellTune.Note], at start: Date = Date()) {
        guard !notes.isEmpty else { return }
        self.notes = notes
        self.start = start
        frozenAge = nil
        onPlay?(notes)
    }

    /// A tune held still at `age` seconds, for screenshots; nothing sounds.
    public func hold(_ notes: [FarBellTune.Note], age: Double) {
        self.notes = notes
        start = nil
        frozenAge = age
    }

    public func clear() {
        notes = []
        start = nil
        frozenAge = nil
    }

    /// Seconds into the tune, or `nil` when nothing plays or it has passed.
    public func age(at date: Date) -> Double? {
        guard !notes.isEmpty else { return nil }
        let age: Double
        if let frozenAge {
            age = frozenAge
        } else if let start {
            age = date.timeIntervalSince(start)
        } else {
            return nil
        }
        return age <= FarBellTune.length(of: notes) + 1.2 ? age : nil
    }
}
