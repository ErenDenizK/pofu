import PofuGames
import PofuSound
import SwiftUI

/// Çağlayan's flow round over Home, shown as a full-screen cover by
/// `HomeView`: the stage's two boards, then "Done" advances the island one
/// stage (`AppModel.finishCaglayanFlow`). Leaving mid-way keeps the round on the
/// device (`AppModel.savedFlowRound`); nothing is lost and nothing expires.
/// Once the island is healed the same view is free play and pays nothing.
struct CaglayanFlowView: View {
    let model: AppModel

    var body: some View {
        let stage = model.flowStage
        let saved = model.savedFlowRound.flatMap { $0.stage == stage ? $0.round : nil }
        if let game = FlowGameView.caglayan(
            stage: stage,
            resuming: saved,
            sound: FlowSoundBridge(),
            onLeave: { round in
                model.savedFlowRound = (stage, round)
                model.isPlayingFlow = false
            },
            onFinish: { model.finishCaglayanFlow() }
        ) {
            game
        } else {
            Color.clear.onAppear { model.isPlayingFlow = false }
        }
    }
}
