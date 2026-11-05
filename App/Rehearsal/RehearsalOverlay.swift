import PofuDesignSystem
import PofuSound
import PofuTuning
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
            if !model.needsOnboarding {
                #if DEBUG
                if TuningLab.session.isOpen {
                    TuningLabPanel(model: model, store: TuningLab.store, session: TuningLab.session)
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
        #if DEBUG
        .onChange(of: TuningLab.store.values.sound, initial: true) { _, volumes in
            SoundEngine.shared.volumes = volumes
        }
        .animation(PofuMotion.respecting(reduceMotion, PofuMotion.snappy), value: TuningLab.session.isOpen)
        #endif
    }
}
