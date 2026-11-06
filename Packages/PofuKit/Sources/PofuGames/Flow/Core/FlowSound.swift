/// The flow game's sound hooks, like `GardenSoundCue`: the scene calls a
/// `FlowSoundPlaying`; the default plays nothing, and the app maps each cue
/// to a micro-sound under the sound identity's quiet ceiling. The game is
/// fully playable muted.
public enum FlowSoundCue: Sendable, Equatable {
    /// A stone clicks a quarter turn.
    case click
    /// A tap on a fixed tile: a soft thunk, no turn.
    case thunk
    /// A newly wet tile's trickle; `step` rises one note per tile in the
    /// same pour (a rising run on the pentatonic ladder, capped by the app).
    case trickle(step: Int)
    /// The wheel catches and creaks into a slow loop.
    case wheelCreak
    /// Water reaches a mouth: a splash.
    case splash
    /// The last connection: the full pour.
    case pour
}

public protocol FlowSoundPlaying: AnyObject {
    @MainActor func play(_ cue: FlowSoundCue)
}

public final class SilentFlowSound: FlowSoundPlaying {
    public init() {}
    @MainActor public func play(_ cue: FlowSoundCue) {}
}
