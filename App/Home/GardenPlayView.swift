import PofuDesignSystem
import PofuGames
import PofuSound
import PofuTuning
import SwiftUI

/// The garden game over Home, shown as a full-screen cover by `HomeView`
/// (and by Rehearsal's panel, through `AppModel.playGarden()`). The earned
/// rounds make the set; each finished round's seeds go to the pouch
/// through the round ledger.
struct GardenPlayView: View {
    let model: AppModel

    var body: some View {
        ZStack {
            GardenGameView(
                roundsAvailable: model.gardenRounds,
                tuning: gardenTuning,
                sound: GardenSoundBridge(),
                onRoundEnd: { model.creditRound(seeds: $0.seeds) },
                onFinish: { _ in model.isPlayingGarden = false }
            )
            #if DEBUG
            if model.rehearsal != nil, DeveloperFlag.isOn {
                gardenTuningLab
            }
            #endif
        }
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
