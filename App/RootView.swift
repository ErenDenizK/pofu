import os
import PofuCore
import SwiftUI

/// The root: onboarding until it is done, then Pofu's room, with Hop! as a
/// full-screen cover over everything.
struct RootView: View {
    let model: AppModel

    @Environment(\.scenePhase) private var scenePhase
    /// The Hop! the cover shows. It follows `model.hop`, but waits for a
    /// sheet over Home to finish dismissing, because UIKit cannot present
    /// while another presentation is in flight.
    @State private var presentedHop: HopCover?

    var body: some View {
        Group {
            if model.needsOnboarding {
                OnboardingView(model: model)
            } else {
                HomeView(model: model)
            }
        }
        .fullScreenCover(item: $presentedHop) { _ in
            HopView(model: model)
        }
        .onChange(of: model.hop?.id) { _, id in
            present(id)
        }
        .onAppear {
            present(model.hop?.id)
        }
        .onChange(of: scenePhase) { _, phase in
            Log.routing.debug("Scene phase: \(String(describing: phase), privacy: .public)")
            switch phase {
            case .active:
                model.refresh()
                // The notification delegate routes the shield's "Open with
                // Pofu"; this is the fallback for opening Pofu by hand
                // within the request's lifetime (notifications off).
                model.answerShieldRequest()
            case .background:
                model.enteredBackground()
                // Swiping home from Hop! counts as skipping (ADR-0008).
                model.leaveHop()
            default:
                model.leftForeground()
            }
        }
    }

    private func present(_ id: HopSession.ID?) {
        guard let id else {
            if presentedHop != nil {
                Log.routing.info("Hop! cover dismissed")
            }
            presentedHop = nil
            return
        }
        guard presentedHop?.id != id else { return }
        guard model.homeSheet != nil else {
            Log.routing.info("Presenting the Hop! cover")
            presentedHop = HopCover(id: id)
            return
        }
        Log.routing.info("Closing the \(model.homeSheet?.rawValue ?? "", privacy: .public) sheet before the Hop! cover")
        // Hop! takes the whole screen: the sheet over Home steps aside
        // first, and the cover follows once its dismissal has finished.
        model.homeSheet = nil
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(450))
            if model.hop?.id == id {
                Log.routing.info("Presenting the Hop! cover after the sheet")
                presentedHop = HopCover(id: id)
            } else {
                Log.routing.debug("Hop! ended before its cover could appear")
            }
        }
    }
}

/// The cover's identity: one per Hop!, so phase changes inside a Hop! do
/// not re-present it.
private struct HopCover: Identifiable {
    let id: UUID
}
