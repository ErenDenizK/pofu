import os
import PofuCore
import PofuDesignSystem
import PofuSound
import PofuWorld
import SwiftUI
import UIKit

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
    /// The door stamp playing now: the day's seals on the round door's plaque.
    @State private var doorRun: DoorStampRun?
    /// Whether this open has had its door stamp (at most once per open).
    @State private var visit = DoorStampOpen()
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
        .environment(\.screenHazeClearing, model.hazeClearing)
        // Any tap skips the door stamp; the tap still reaches what it hit.
        .simultaneousGesture(TapGesture().onEnded { skipDoorStamp() })
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
            if let doorRun {
                DoorStampOverlay(run: doorRun)
                    .transition(.opacity)
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
                visit.reset()
                model.enteredBackground()
                // Swiping home from Hop! counts as skipping (ADR-0008).
                model.leaveHop()
            default:
                model.leftForeground()
            }
        }
    }

    /// Resists made at the shield sent no notification and left the app
    /// closed. The next time Pofu is on screen, once per open, the day's
    /// seals press on the round door's plaque for 2 s (ui-v3 section 3b):
    /// one soft haptic per seal, Pofu hops proud, the pots bloom and the
    /// screen haze parts. It never blocks input and any tap skips it.
    private func playPayoffIfOwed() {
        guard !model.needsOnboarding, model.hop == nil, model.rehearsal == nil, payoffRun == nil, doorRun == nil, !visit.isSpent else { return }
        let unseen = ResistPayoffStore().takeUnseen(resisted: model.reachesToday.resisted)
        guard let stamp = visit.claim(unseen: unseen) else { return }
        Task { @MainActor in
            // Let the launch curtain part and Home settle first.
            try? await Task.sleep(for: .milliseconds(700))
            guard model.hop == nil, doorRun == nil else { return }
            let reduce = UIAccessibility.isReduceMotionEnabled
            let run = DoorStampRun(stamp: stamp)
            withAnimation(.easeOut(duration: 0.2)) { doorRun = run }
            let bloom = ResistPayoffRun(payoff: ResistPayoff(resists: stamp.resists))
            payoffRun = bloom
            model.hazeClearing.part()
            var beats: [(time: TimeInterval, hop: Bool)] = stamp.hapticTimes(reduceMotion: reduce).map { ($0, false) }
            if !reduce { beats.append((stamp.hopAt, true)) }
            var elapsed: TimeInterval = 0
            for beat in beats + [(DoorStamp.duration, false)] {
                try? await Task.sleep(for: .seconds(max(beat.time - elapsed, 0)))
                elapsed = max(elapsed, beat.time)
                guard doorRun?.id == run.id else { return }
                if beat.time == DoorStamp.duration {
                    withAnimation(.easeOut(duration: 0.2)) { doorRun = nil }
                } else if beat.hop {
                    model.worldHome.hopProud()
                    SoundEngine.shared.play(.skipChime)
                } else {
                    PofuHaptics.shared.play(.land)
                }
            }
            if payoffRun?.id == bloom.id { payoffRun = nil }
        }
    }

    private func skipDoorStamp() {
        guard doorRun != nil else { return }
        withAnimation(.easeOut(duration: 0.2)) { doorRun = nil }
        payoffRun = nil
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
