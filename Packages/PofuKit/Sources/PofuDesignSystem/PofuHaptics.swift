import Foundation

// The haptics palette (experience-v1 section 3.3). Ten named feelings; every
// call site names a feeling, never a generator. The data here is pure so
// the palette is tested on any platform; `PofuHaptics` below plays it.

/// What Pofu can make a hand feel. Haptics confirm; they never decorate and
/// never loop.
public enum PofuHapticName: String, CaseIterable, Sendable {
    /// Any world object or control.
    case tap
    /// The camera lands on a stop; a flight arrives.
    case land
    /// The rubber band at the end of a pan, once.
    case edge
    /// The check-in appears (Hop!).
    case nudge
    /// The resist payoff.
    case resist
    /// The seed count-up.
    case seed
    /// A build's level-up.
    case growth
    /// Cheeks full.
    case pouch
    /// Not enough seeds. Never `.error`: the user did nothing wrong.
    case warning
    /// Passive updates and bedtime: nothing at all.
    case quiet
}

/// One transient of a custom pattern.
public struct PofuHapticTransient: Equatable, Sendable {
    /// Seconds from the start of the pattern.
    public var time: TimeInterval
    public var intensity: Double
    public var sharpness: Double

    public init(time: TimeInterval, intensity: Double, sharpness: Double) {
        self.time = time
        self.intensity = intensity
        self.sharpness = sharpness
    }
}

/// How a feeling is played.
public enum PofuHapticSpec: Equatable, Sendable {
    public enum Weight: String, Sendable { case light, soft, rigid }

    /// Nothing, by design.
    case none
    /// The system selection tick.
    case selection
    /// A system impact.
    case impact(Weight, intensity: Double)
    /// The system warning notification.
    case warning
    /// Core Haptics: transients, then an optional soft continuous tail.
    case pattern([PofuHapticTransient], tail: TimeInterval)
    /// Selection ticks, rationed per second, then a soft impact.
    case ticks(maxPerSecond: Int, finale: Weight)
}

extension PofuHapticName {
    /// The feedback for this feeling (the table of section 3.3).
    public var spec: PofuHapticSpec {
        switch self {
        case .tap: .selection
        case .land: .impact(.soft, intensity: 0.4)
        case .edge: .impact(.rigid, intensity: 0.3)
        case .nudge: .impact(.light, intensity: 0.6)
        case .resist:
            // Two rising soft transients, 0.12 s apart.
            .pattern(
                [
                    PofuHapticTransient(time: 0, intensity: 0.45, sharpness: 0.25),
                    PofuHapticTransient(time: 0.12, intensity: 0.7, sharpness: 0.3),
                ],
                tail: 0
            )
        case .seed: .ticks(maxPerSecond: 6, finale: .soft)
        case .growth:
            // Three rising transients plus a soft tail.
            .pattern(
                [
                    PofuHapticTransient(time: 0, intensity: 0.4, sharpness: 0.3),
                    PofuHapticTransient(time: 0.12, intensity: 0.6, sharpness: 0.35),
                    PofuHapticTransient(time: 0.24, intensity: 0.85, sharpness: 0.45),
                ],
                tail: 0.4
            )
        case .pouch:
            // The pouch pop: a sharp transient, then a soft one.
            .pattern(
                [
                    PofuHapticTransient(time: 0, intensity: 0.9, sharpness: 0.8),
                    PofuHapticTransient(time: 0.06, intensity: 0.3, sharpness: 0.1),
                ],
                tail: 0.25
            )
        case .warning: .warning
        case .quiet: .none
        }
    }
}

/// Rations the seed count-up's ticks: at most `maxPerSecond` in any second.
public struct SeedTickLimiter: Sendable {
    public let maxPerSecond: Int
    private var recent: [TimeInterval] = []

    public init(maxPerSecond: Int = 6) {
        self.maxPerSecond = maxPerSecond
    }

    /// Whether a tick at `time` (seconds, non-decreasing) may play.
    public mutating func allows(at time: TimeInterval) -> Bool {
        recent.removeAll { time - $0 >= 1 }
        guard recent.count < maxPerSecond else { return false }
        recent.append(time)
        return true
    }
}

#if os(iOS)
import CoreHaptics
import SwiftUI
import UIKit

/// Plays the palette. System feedback for the simple feelings; Core Haptics
/// only for the custom patterns, falling back to a single impact on devices
/// without the engine.
@MainActor
public final class PofuHaptics {
    public static let shared = PofuHaptics()

    private var engine: CHHapticEngine?
    private var limiter = SeedTickLimiter()

    private init() {}

    /// The view the system ties feedback to (iOS 17.5): the foreground
    /// scene's key window. Without one there is nothing to feel.
    private var anchor: UIView? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }?
            .keyWindow
    }

    private func selectionTick() {
        guard let anchor else { return }
        UISelectionFeedbackGenerator(view: anchor).selectionChanged()
    }

    private func impact(_ weight: PofuHapticSpec.Weight, _ intensity: Double) {
        guard let anchor else { return }
        let style: UIImpactFeedbackGenerator.FeedbackStyle = switch weight {
        case .light: .light
        case .soft: .soft
        case .rigid: .rigid
        }
        UIImpactFeedbackGenerator(style: style, view: anchor).impactOccurred(intensity: intensity)
    }

    /// Plays `name`. `quiet` plays nothing.
    public func play(_ name: PofuHapticName) {
        switch name.spec {
        case .none:
            break
        case .selection:
            selectionTick()
        case .impact(let weight, let intensity):
            impact(weight, intensity)
        case .warning:
            if let anchor {
                UINotificationFeedbackGenerator(view: anchor).notificationOccurred(.warning)
            }
        case .ticks(_, let finale):
            impact(finale, 0.6)
        case .pattern(let transients, let tail):
            if !playPattern(transients, tail: tail) {
                let strongest = transients.map(\.intensity).max() ?? 0.5
                impact(.soft, strongest)
            }
        }
    }

    /// One tick of the seed count-up; rationed, so a long count is never a
    /// buzz. Pass `finished` for the last one.
    public func seedTick(at time: TimeInterval, finished: Bool = false) {
        if finished {
            impact(.soft, 0.6)
        } else if limiter.allows(at: time) {
            selectionTick()
        }
    }

    /// Resets the count-up's rationing before a new count.
    public func beginSeedCount() {
        limiter = SeedTickLimiter()
    }

    private func playPattern(_ transients: [PofuHapticTransient], tail: TimeInterval) -> Bool {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return false }
        do {
            let engine = try readyEngine()
            var events = transients.map { transient in
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(transient.intensity)),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: Float(transient.sharpness)),
                    ],
                    relativeTime: transient.time
                )
            }
            if tail > 0, let last = transients.last {
                events.append(
                    CHHapticEvent(
                        eventType: .hapticContinuous,
                        parameters: [
                            CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(last.intensity * 0.35)),
                            CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1),
                        ],
                        relativeTime: last.time,
                        duration: tail
                    )
                )
            }
            let player = try engine.makePlayer(with: CHHapticPattern(events: events, parameters: []))
            try player.start(atTime: CHHapticTimeImmediate)
            return true
        } catch {
            return false
        }
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

private struct PofuHapticModifier<Trigger: Equatable>: ViewModifier {
    let name: PofuHapticName
    let trigger: Trigger

    func body(content: Content) -> some View {
        content.onChange(of: trigger) {
            PofuHaptics.shared.play(name)
        }
    }
}

extension View {
    /// Plays the palette's feeling `name` whenever `trigger` changes.
    public func pofuHaptic<Trigger: Equatable>(_ name: PofuHapticName, trigger: Trigger) -> some View {
        modifier(PofuHapticModifier(name: name, trigger: trigger))
    }
}
#endif
