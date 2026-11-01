import PofuCompanion
import PofuCore
import PofuDesignSystem
import SwiftUI

/// Pofu's room: the single home of the app (information architecture,
/// option C). Pofu with its mood and cheeks, the seed pouch, today's beads,
/// one primary action, and everything else as sheets.
struct HomeView: View {
    @Bindable var model: AppModel

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            PofuColor.dayWash.ignoresSafeArea()

            VStack(spacing: PofuSpacing.l) {
                topBar
                Spacer(minLength: 0)
                pofu
                Spacer(minLength: 0)
                TodayCard(model: model)
                    .onTapGesture { model.homeSheet = .passes }
                    .accessibilityAddTraits(.isButton)
                bottomActions
            }
            .padding(.horizontal, PofuSpacing.screen)
            .padding(.bottom, PofuSpacing.s)

            if model.activeSession != nil || model.earningResult != nil {
                FocusSessionView(model: model)
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .animation(PofuMotion.respecting(reduceMotion, PofuMotion.settle), value: model.activeSession != nil || model.earningResult != nil)
        .sheet(item: $model.homeSheet) { sheet in
            switch sheet {
            case .earn:
                EarnSheet(model: model)
                    .presentationDetents([.medium, .large])
            case .passes:
                PassesSheet(model: model)
                    .presentationDetents([.medium, .large])
            case .settings:
                SettingsView(model: model)
            case .setup:
                NavigationStack {
                    SetupGuideView(model: model)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") { model.homeSheet = nil }
                            }
                        }
                }
            }
        }
    }

    // MARK: Parts

    private var topBar: some View {
        HStack {
            Button {
                model.homeSheet = .passes
            } label: {
                SeedPill(count: model.balance.units)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("\(model.balance.units) seeds in my cheeks"))
            Spacer()
            Button {
                model.homeSheet = .settings
            } label: {
                Image(systemName: "gearshape")
                    .font(PofuFont.title3)
                    .frame(width: PofuSize.minimumTouch, height: PofuSize.minimumTouch)
            }
            .buttonStyle(.glass)
            .tint(PofuColor.textPrimary)
            .accessibilityLabel(Text("Settings"))
        }
        .padding(.top, PofuSpacing.s)
    }

    private var needsSetup: Bool {
        model.profile.protectedApps.isEmpty || model.profile.lastCheckIn.isEmpty
    }

    private var pofu: some View {
        VStack(spacing: PofuSpacing.s) {
            Button {
                if needsSetup {
                    model.homeSheet = .setup
                }
            } label: {
                SpeechBubble {
                    Text(
                        PofuLines.home(
                            skips: model.impulsesToday.resisted,
                            attempts: model.impulsesToday.attempts,
                            isBedtime: model.isBedtime,
                            needsSetup: needsSetup
                        )
                    )
                }
            }
            .buttonStyle(.plain)
            .disabled(!needsSetup)
            .accessibilityAddTraits(needsSetup ? .isButton : [])

            ZStack(alignment: .bottom) {
                Circle()
                    .fill(PofuColor.stage.opacity(0.55))
                    .frame(width: 280, height: 280)
                    .offset(y: 40)
                    .accessibilityHidden(true)
                CompanionView(vitality: model.vitality, energy: model.cheekFill)
                    .frame(maxWidth: 300)
                    .accessibilityLabel(Text(companionLabel))
            }
        }
    }

    private var companionLabel: String {
        let band = model.vitalityModel.band(for: model.vitality)
        let mood: String
        switch band {
        case .thriving: mood = String(localized: "thriving")
        case .content: mood = String(localized: "content")
        case .tired: mood = String(localized: "tired")
        case .wilting: mood = String(localized: "wilting")
        }
        return "\(model.profile.companionName), \(mood)"
    }

    private var bottomActions: some View {
        HStack(spacing: PofuSpacing.m) {
            Button {
                model.homeSheet = .earn
            } label: {
                Text("Fill my cheeks")
            }
            .buttonStyle(PofuPrimaryButtonStyle())

            Button {
                model.homeSheet = .passes
            } label: {
                Image(systemName: "ticket")
                    .font(PofuFont.title3)
                    .frame(width: PofuSize.buttonHeight, height: PofuSize.buttonHeight)
            }
            .buttonStyle(.glass)
            .tint(PofuColor.accent)
            .accessibilityLabel(Text("Passes"))
        }
    }
}

/// Today's north star: reaches skipped, as raw counts first, beads second,
/// and the ratio last.
private struct TodayCard: View {
    let model: AppModel

    var body: some View {
        let metrics = model.impulsesToday
        VStack(alignment: .leading, spacing: PofuSpacing.s) {
            HStack {
                Text("Today")
                    .font(PofuFont.subheadline)
                    .foregroundStyle(PofuColor.textSecondary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(PofuFont.footnote)
                    .foregroundStyle(PofuColor.textTertiary)
                    .accessibilityHidden(true)
            }
            if metrics.attempts == 0 {
                Text("No reaches yet today.")
                    .font(PofuFont.title3)
                    .foregroundStyle(PofuColor.textPrimary)
            } else {
                Text("\(metrics.resisted) of \(metrics.attempts) skipped")
                    .font(PofuFont.title2)
                    .foregroundStyle(PofuColor.textPrimary)
                    .contentTransition(.numericText(value: Double(metrics.resisted)))
                BeadRow(skipped: model.beadsToday.map { $0 == .skipped })
                if let ratio = metrics.resistedRatio {
                    Text("Goal: half. You're at \(ratio.formatted(.percent.precision(.fractionLength(0)).locale(AppLanguage.locale))).")
                        .font(PofuFont.footnote)
                        .foregroundStyle(PofuColor.textSecondary)
                }
            }
            if let pass = model.activePasses.first {
                Label {
                    Text("\(ProtectedApp(rawValue: pass.target.rawValue)?.displayName ?? "") pass running")
                } icon: {
                    Image(systemName: "ticket")
                }
                .font(PofuFont.footnote)
                .foregroundStyle(PofuColor.accent)
            }
        }
        .pofuCard()
        .accessibilityElement(children: .combine)
    }
}
