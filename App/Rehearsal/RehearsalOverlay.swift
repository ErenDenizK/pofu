import PofuDesignSystem
import PofuGames
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
            if rehearsal.isPlayingGarden {
                // The earned rounds make the set; each finished round's
                // seeds go to the pouch through the round ledger.
                GardenGameView(
                    roundsAvailable: rehearsal.gardenRounds,
                    tuning: gardenTuning,
                    sound: GardenSoundBridge(),
                    onRoundEnd: { model.creditRound(seeds: $0.seeds) },
                    onFinish: { _ in rehearsal.isPlayingGarden = false }
                )
                .transition(.opacity)
                #if DEBUG
                gardenTuningLab
                #endif
            } else if !model.needsOnboarding {
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
        .animation(PofuMotion.respecting(reduceMotion, PofuMotion.settle), value: rehearsal.isPlayingGarden)
        #if DEBUG
        .onChange(of: TuningLab.store.values.sound, initial: true) { _, volumes in
            SoundEngine.shared.volumes = volumes
        }
        .animation(PofuMotion.respecting(reduceMotion, PofuMotion.snappy), value: TuningLab.session.isOpen)
        #endif
    }

    /// The garden's feel: the tuning lab panel's live values in debug builds.
    private var gardenTuning: TuningValues.Garden {
        #if DEBUG
        TuningLab.store.values.garden
        #else
        TuningValues.defaults.garden
        #endif
    }

    #if DEBUG
    /// tuning lab over the garden: a small pill that opens the panel on the
    /// garden's values, which the game reads live.
    @ViewBuilder private var gardenTuningLab: some View {
        if TuningLab.session.isOpen {
            TuningLabPanel(model: model, store: TuningLab.store, session: TuningLab.session)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        } else {
            Button {
                TuningLab.session.section = .garden
                TuningLab.session.isOpen = true
            } label: {
                Label {
                    Text(verbatim: "Ayar")
                } icon: {
                    Image(systemName: "slider.horizontal.3")
                }
                .font(PofuFont.subheadline)
                .foregroundStyle(PofuColor.textPrimary)
                .padding(.horizontal, PofuSpacing.m)
                .frame(minHeight: PofuSize.minimumTouch)
                .contentShape(Capsule(style: .continuous))
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive(), in: Capsule(style: .continuous))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .padding(.top, 112)
            .padding(.trailing, PofuSpacing.l)
        }
    }
    #endif
}
