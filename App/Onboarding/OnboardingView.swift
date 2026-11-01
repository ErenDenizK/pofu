import PofuCompanion
import PofuCore
import PofuDesignSystem
import SwiftUI

/// The first run, kept minimal for this slice: meet Pofu, pick the apps,
/// name Pofu, then set up the first automation (user flows, section 1).
struct OnboardingView: View {
    let model: AppModel

    private enum Step: Int, CaseIterable {
        case welcome
        case apps
        case name
        case setup
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var step: Step = .welcome
    @State private var chosen: [ProtectedApp] = []
    @State private var name = UserProfile.defaultName

    var body: some View {
        ZStack {
            PofuColor.dayWash.ignoresSafeArea()
            Group {
                switch step {
                case .welcome: welcome
                case .apps: apps
                case .name: naming
                case .setup: setup
                }
            }
            .transition(.opacity)
        }
        .animation(PofuMotion.respecting(reduceMotion, PofuMotion.settle), value: step)
        .sensoryFeedback(.selection, trigger: step)
    }

    // MARK: Steps

    private var welcome: some View {
        VStack(spacing: PofuSpacing.l) {
            Spacer()
            CompanionView(vitality: 0.8, energy: 0.3)
                .frame(maxWidth: 280)
            Text("Hi, I'm Pofu.")
                .pofuDisplayFont(size: 40)
                .foregroundStyle(PofuColor.textPrimary)
                .multilineTextAlignment(.center)
            Text("I'm a hamster who gets fluffier every time you pick real life over the feed.")
                .font(PofuFont.body)
                .foregroundStyle(PofuColor.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
            Button("Hi, Pofu") { step = .apps }
                .buttonStyle(PofuPrimaryButtonStyle())
        }
        .padding(PofuSpacing.screen)
    }

    private var apps: some View {
        VStack(alignment: .leading, spacing: PofuSpacing.l) {
            Text("Which ones pull you in?")
                .font(PofuFont.largeTitle)
                .foregroundStyle(PofuColor.textPrimary)
                .padding(.top, PofuSpacing.xl)
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: PofuSpacing.s) {
                    ForEach(ProtectedApp.allCases) { app in
                        let isChosen = chosen.contains(app)
                        Button {
                            if isChosen {
                                chosen.removeAll { $0 == app }
                            } else {
                                chosen.append(app)
                            }
                        } label: {
                            HStack(spacing: PofuSpacing.s) {
                                Image(systemName: isChosen ? "checkmark.circle.fill" : app.symbolName)
                                Text(verbatim: app.displayName)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                Spacer(minLength: 0)
                            }
                            .padding(.vertical, PofuSpacing.s)
                        }
                        .buttonStyle(PofuChoiceStyle(isSelected: isChosen, cornerRadius: PofuRadius.large))
                        .accessibilityAddTraits(isChosen ? .isSelected : [])
                    }
                }
                Text("We'll set them up one at a time, starting with your first pick. You can change these any time.")
                    .font(PofuFont.footnote)
                    .foregroundStyle(PofuColor.textSecondary)
                    .padding(.top, PofuSpacing.s)
            }
            Button("Continue") {
                // In the user's order: the first pick is set up first.
                model.setProtectedApps(chosen)
                step = .name
            }
            .buttonStyle(PofuPrimaryButtonStyle())
            .disabled(chosen.isEmpty)
        }
        .padding(PofuSpacing.screen)
        .sensoryFeedback(.selection, trigger: chosen)
    }

    private var naming: some View {
        VStack(spacing: PofuSpacing.l) {
            Spacer()
            CompanionView(vitality: 0.8, energy: 0.3)
                .frame(maxWidth: 220)
            Text("What should we call me?")
                .font(PofuFont.largeTitle)
                .foregroundStyle(PofuColor.textPrimary)
                .multilineTextAlignment(.center)
            TextField(text: $name, prompt: Text(verbatim: UserProfile.defaultName)) {
                Text("Name")
            }
            .font(PofuFont.title2)
            .multilineTextAlignment(.center)
            .textInputAutocapitalization(.words)
            .submitLabel(.done)
            .padding(PofuSpacing.m)
            .background(RoundedRectangle(cornerRadius: PofuRadius.medium, style: .continuous).fill(PofuColor.raised))
            HStack(spacing: PofuSpacing.s) {
                ForEach(suggestions, id: \.self) { suggestion in
                    Button {
                        name = suggestion
                    } label: {
                        Text(verbatim: suggestion)
                    }
                    .buttonStyle(PofuChoiceStyle(isSelected: name == suggestion, cornerRadius: PofuSize.minimumTouch / 2))
                }
            }
            Spacer()
            Button("That's me") {
                model.setCompanionName(name)
                step = .setup
            }
            .buttonStyle(PofuPrimaryButtonStyle())
        }
        .padding(PofuSpacing.screen)
    }

    private var suggestions: [String] {
        AppLanguage.isTurkish ? ["Pofu", "Fıstık", "Lokum", "Pamuk"] : ["Pofu", "Peanut", "Mochi", "Biscuit"]
    }

    private var setup: some View {
        NavigationStack {
            SetupGuideView(model: model)
                .pofuFooter {
                    VStack(spacing: PofuSpacing.xs) {
                        Button("Done") { model.completeOnboarding() }
                            .buttonStyle(PofuPrimaryButtonStyle())
                        Button("I'll do it later") { model.completeOnboarding() }
                            .font(PofuFont.headline)
                            .foregroundStyle(PofuColor.accent)
                            .frame(minHeight: PofuSize.minimumTouch)
                    }
                }
        }
    }
}
