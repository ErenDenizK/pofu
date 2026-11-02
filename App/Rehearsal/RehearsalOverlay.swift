import PofuDesignSystem
import PofuGames
import SwiftUI

/// Everything Rehearsal mode puts over Pofu: the shield replica or the
/// simulated app while the user is "outside", and the Prova panel once
/// onboarding is done (onboarding's "Try it" has its own reach button).
struct RehearsalOverlay: View {
    let model: AppModel
    let rehearsal: RehearsalStage

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            switch rehearsal.screen {
            case .shield(_, _, let copy)?:
                ShieldReplicaView(model: model, copy: copy)
                    .transition(.opacity)
            case .app(let app)?:
                RehearsalAppView(model: model, app: app)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            case nil:
                EmptyView()
            }
            if rehearsal.isPlayingGarden {
                // Five earned rounds stand in for the ledger. The seeds are
                // not credited yet: rounds and their yield join PofuCore
                // with RoundLedger (docs/product/minigames.md §7).
                GardenGameView(roundsAvailable: 5) { _ in
                    rehearsal.isPlayingGarden = false
                }
                .transition(.opacity)
            } else if !model.needsOnboarding {
                #if DEBUG
                if Ayar.session.isOpen {
                    AyarPanel(model: model, store: Ayar.store, session: Ayar.session)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    RehearsalPanel(model: model, rehearsal: rehearsal)
                }
                #else
                RehearsalPanel(model: model, rehearsal: rehearsal)
                #endif
            }
        }
        .animation(PofuMotion.respecting(reduceMotion, PofuMotion.snappy), value: rehearsal.screen)
        .animation(PofuMotion.respecting(reduceMotion, PofuMotion.settle), value: rehearsal.isPlayingGarden)
        #if DEBUG
        .animation(PofuMotion.respecting(reduceMotion, PofuMotion.snappy), value: Ayar.session.isOpen)
        #endif
    }
}
