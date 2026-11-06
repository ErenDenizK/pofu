import CoreHaptics
import Foundation

/// The "Nefeste titreşim" setting (UI v3 section 4, lead decision
/// 2026-11-06): the Core Haptics swell during the breath. On by default;
/// the founder feels it on a device before release.
enum BreathHapticsSetting {
    static let key = "breath.haptics"

    static var isOn: Bool {
        get { UserDefaults.standard.object(forKey: key) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }
}

/// The sounds of the breath room. Hook only: the air pad and the wooden
/// chime land with batch-62; until then a handler may be set and nothing
/// plays.
@MainActor
enum BreathSound {
    enum Cue { case airOpens, airCloses, chime }

    static var handler: ((Cue) -> Void)?

    static func play(_ cue: Cue) {
        handler?(cue)
    }
}

/// A continuous haptic that swells with the in-breath (0.12 to 0.40,
/// sharpness 0.10), turns with a soft transient and falls back over the
/// out-breath. One player for the whole breath, so it can never drift from
/// the ring.
@MainActor
final class BreathHaptics {
    static let shared = BreathHaptics()

    private var engine: CHHapticEngine?
    private var player: CHHapticAdvancedPatternPlayer?

    private init() {}

    /// Starts the swell; does nothing when the setting is off or the
    /// device has no haptic engine.
    func swell(inhale: Double, exhale: Double) {
        guard BreathHapticsSetting.isOn, CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        cancel()
        do {
            let engine = try readyEngine()
            let total = inhale + exhale
            let hum = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1),
                ],
                relativeTime: 0,
                duration: total
            )
            let turn = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.35),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2),
                ],
                relativeTime: inhale
            )
            let swell = CHHapticParameterCurve(
                parameterID: .hapticIntensityControl,
                controlPoints: [
                    .init(relativeTime: 0, value: 0.12),
                    .init(relativeTime: inhale, value: 0.40),
                    .init(relativeTime: total, value: 0.12),
                ],
                relativeTime: 0
            )
            let pattern = try CHHapticPattern(events: [hum, turn], parameterCurves: [swell])
            let player = try engine.makeAdvancedPlayer(with: pattern)
            self.player = player
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            player = nil
        }
    }

    /// Stops the swell (skipping the breath, leaving the room).
    func cancel() {
        try? player?.stop(atTime: CHHapticTimeImmediate)
        player = nil
    }

    private func readyEngine() throws -> CHHapticEngine {
        if let engine { return engine }
        let engine = try CHHapticEngine()
        engine.isAutoShutdownEnabled = true
        engine.resetHandler = { [weak engine] in
            try? engine?.start()
        }
        try engine.start()
        self.engine = engine
        return engine
    }
}
