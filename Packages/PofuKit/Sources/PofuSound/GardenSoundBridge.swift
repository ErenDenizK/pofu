import PofuGames

/// Maps the garden's cues onto sound cues. Pure, so it is tested on Linux.
public enum GardenSoundMap {
    public static func cues(for cue: GardenSoundCue) -> [SoundCue] {
        switch cue {
        case .lift: [.piecePickup]
        case .snap: [.pieceSnap]
        case .plant: [.pieceDrop]
        case .putBack: [.piecePutBack]
        case .bloom(let midi): [.bloom(step: SoundPitch.bloomStep(midi: midi))]
        case .comboRise(let level): [.comboRise(level: level)]
        case .cheek: [.cheek]
        case .deal: [.deal]
        case .roundEnd: [.roundEnd]
        }
    }
}

#if canImport(AVFoundation)
/// The garden's `GameSoundPlaying`, backed by the shared engine.
public final class GardenSoundBridge: GameSoundPlaying {
    public init() {}

    @MainActor public func play(_ cue: GardenSoundCue) {
        for mapped in GardenSoundMap.cues(for: cue) {
            SoundEngine.shared.play(mapped)
        }
    }
}
#endif
