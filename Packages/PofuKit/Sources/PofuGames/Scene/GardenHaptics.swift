#if os(iOS)
import UIKit

/// The garden's haptics: one pattern per moment, rationed.
///
/// | Moment | Feedback | Why |
/// |---|---|---|
/// | Lift | light impact 0.5 | The plot leaves the tray |
/// | Snap to a new cell | selection, at most every 60 ms, 0 with Reduce Motion off-board | Felt like detents, never a buzz |
/// | Plant | medium impact 0.75 | The landing, with the squash |
/// | Bloom | rigid impact, 0.45–1 by lines and combo (`GardenFeel.bloomHaptic`) | The payoff; stronger as it escalates |
/// | Seed in the cheeks | soft impact 0.35, once per bloom | The gulp |
/// | Round end | success notification (from SwiftUI, on the card) | — |
///
/// Generators are made against the scene's view (iOS 17.5's view-bound
/// feedback), and prepared on lift so the plant lands on the frame.
@MainActor
final class GardenHaptics {
    private var light: UIImpactFeedbackGenerator?
    private var medium: UIImpactFeedbackGenerator?
    private var rigid: UIImpactFeedbackGenerator?
    private var soft: UIImpactFeedbackGenerator?
    private var selection: UISelectionFeedbackGenerator?
    private var lastTick: TimeInterval = -1

    func attach(to view: UIView) {
        light = UIImpactFeedbackGenerator(style: .light, view: view)
        medium = UIImpactFeedbackGenerator(style: .medium, view: view)
        rigid = UIImpactFeedbackGenerator(style: .rigid, view: view)
        soft = UIImpactFeedbackGenerator(style: .soft, view: view)
        selection = UISelectionFeedbackGenerator(view: view)
    }

    func lift() {
        light?.impactOccurred(intensity: 0.5)
        medium?.prepare()
        selection?.prepare()
    }

    func tick(at time: TimeInterval) {
        guard time - lastTick >= GardenFeel.tickInterval else { return }
        lastTick = time
        selection?.selectionChanged()
        selection?.prepare()
    }

    func plant() {
        medium?.impactOccurred(intensity: 0.75)
        rigid?.prepare()
    }

    func bloom(intensity: Double) {
        rigid?.impactOccurred(intensity: CGFloat(intensity))
        soft?.prepare()
    }

    func cheek() {
        soft?.impactOccurred(intensity: 0.35)
    }
}
#endif
