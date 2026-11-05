import os
import PofuCore
import PofuDesignSystem
import PofuSound
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
    /// The "I resisted" payoff playing now (experience v1 section 3.4).
    @State private var payoffRun: ResistPayoffRun?
    private let launchGate = LaunchGate.shared

    var body: some View {
        Group {
            if model.needsOnboarding {
                OnboardingView(model: model)
            } else {
                HomeView(model: model)
            }
        }
        .task {
            // Home's first frame: one frame after the content appears, the
            // world is up and the launch curtain may go.
            try? await Task.sleep(for: .milliseconds(34))
            launchGate.markWorldReady()
        }
        .environment(\.resistPayoff, payoffRun)
        #if DEBUG
        // Rehearsal mode's tuning lab panel tunes the world's look live.
        .modifier(TuningLabLook(model: model))
        #endif
        .overlay {
            // Rehearsal mode: the shield replica, the simulated app, and
            // the Prova panel, under any sheet and Hop!'s cover.
            if let rehearsal = model.rehearsal {
                RehearsalOverlay(model: model, rehearsal: rehearsal)
            }
        }
        .overlay {
            if let payoffRun {
                ResistPayoffOverlay(run: payoffRun, line: String(localized: "Skipped it. One seed."))
            }
        }
        .fullScreenCover(item: $presentedHop) { _ in
            HopView(model: model)
        }
        .overlay {
            // The honest loading screen: the dawn sky, and clouds only
            // while loading really runs.
            LaunchCurtain(isReady: launchGate.isReady)
        }
        .onChange(of: model.hop?.id) { _, id in
            present(id)
        }
        .onAppear {
            present(model.hop?.id)
            playPayoffIfOwed()
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
                playPayoffIfOwed()
            case .background:
                model.enteredBackground()
                // Swiping home from Hop! counts as skipping (ADR-0008).
                model.leaveHop()
            default:
                model.leftForeground()
            }
        }
    }

    /// Resists made at the shield sent no notification and left the app
    /// closed. The next time Pofu is on screen, they get one fixed 1.0 s
    /// payoff: the pots bloom, a seed arcs into the jar, the resist haptic
    /// and the chime play, and a line appears.
    private func playPayoffIfOwed() {
        guard !model.needsOnboarding, model.hop == nil, model.rehearsal == nil, payoffRun == nil else { return }
        let unseen = ResistPayoffStore().takeUnseen(resisted: model.reachesToday.resisted)
        guard unseen > 0 else { return }
        Task { @MainActor in
            // Let the launch curtain part and Home settle first.
            try? await Task.sleep(for: .milliseconds(700))
            guard model.hop == nil, payoffRun == nil else { return }
            let run = ResistPayoffRun(payoff: ResistPayoff(resists: unseen))
            payoffRun = run
            try? await Task.sleep(for: .seconds(ResistPayoff.feelAt))
            PofuHaptics.shared.play(.resist)
            SoundEngine.shared.play(.skipChime)
            try? await Task.sleep(for: .seconds(ResistPayoff.duration - ResistPayoff.feelAt))
            if payoffRun?.id == run.id {
                payoffRun = nil
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
        guard model.homeSheet != nil || model.island.hasSheet else {
            Log.routing.info("Presenting the Hop! cover")
            presentedHop = HopCover(id: id)
            return
        }
        Log.routing.info("Closing the \(model.homeSheet?.rawValue ?? "", privacy: .public) sheet before the Hop! cover")
        // Hop! takes the whole screen: the sheet over Home steps aside
        // first, and the cover follows once its dismissal has finished.
        model.homeSheet = nil
        model.island.dismissFocus()
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
