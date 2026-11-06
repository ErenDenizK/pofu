#if os(iOS)
import UIKit

/// The flow game's haptics, on the garden's levels: a tap is a soft click,
/// a newly wet tile is light, a wheel or mouth reached is medium, solved
/// is the success pattern (from SwiftUI, on the card). A tap on a fixed
/// tile gives none.
@MainActor
final class FlowHaptics {
    private var soft: UIImpactFeedbackGenerator?
    private var light: UIImpactFeedbackGenerator?
    private var medium: UIImpactFeedbackGenerator?

    func attach(to view: UIView) {
        soft = UIImpactFeedbackGenerator(style: .soft, view: view)
        light = UIImpactFeedbackGenerator(style: .light, view: view)
        medium = UIImpactFeedbackGenerator(style: .medium, view: view)
        soft?.prepare()
        light?.prepare()
    }

    func tap() {
        soft?.impactOccurred(intensity: 0.6)
        light?.prepare()
    }

    func wet() {
        light?.impactOccurred(intensity: 0.4)
        medium?.prepare()
    }

    func target() {
        medium?.impactOccurred(intensity: 0.8)
    }
}
#endif
