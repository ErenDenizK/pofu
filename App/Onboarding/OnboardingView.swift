import PofuCompanion
import PofuCore
import PofuDesignSystem
import SwiftUI

/// The first run, kept minimal: meet Pofu, put Pofu at the door, name it.
///
/// With the live Screen Time gate (the `PofuLive` build), the door is one
/// permission and the app picker (ADR-0013); the Shortcuts setup stays
/// available as a fallback and later as "Live Pofu". Without it, the user
/// picks apps and sets up the first automation (user flows, section 1).
struct OnboardingView: View {
    let model: AppModel

    private enum Step: Int, CaseIterable {
        case welcome
        case screenTime
        case apps
        case name
        case setup
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var step: Step = .welcome
    @State private var chosen: [ProtectedApp] = []
    @State private var name = UserProfile.defaultName
    /// The user chose the Shortcuts soft gate over Screen Time.
    @State private var choseShortcuts = false

    /// Whether onboarding ends in the Shortcuts setup guide.
    private var usesShortcuts: Bool {
        !model.screenTime.isAvailable || choseShortcuts
    }

    var body: some View {
        ZStack {
            PofuColor.dayWash.ignoresSafeArea()
            // During the cross-fade the incoming step is stacked above the
            // outgoing one (steps only move forward), and the outgoing one
            // stops taking touches, so a quick tap always lands on the new
            // step and is never swallowed by the old one.
            ForEach(Step.allCases, id: \.self) { item in
                if item == step {
                    view(for: item)
                        .zIndex(Double(item.rawValue))
                        .transition(AnyTransition.asymmetric(
                            insertion: AnyTransition.opacity,
                            removal: AnyTransition.opacity.combined(with: AnyTransition.disablesHitTesting)
                        ))
                }
            }
        }
        .animation(PofuMotion.respecting(reduceMotion, PofuMotion.snappy), value: step)
        .sensoryFeedback(.selection, trigger: step)
    }

    // MARK: Steps

    @ViewBuilder
    private func view(for item: Step) -> some View {
        switch item {
        case .welcome: welcome
        case .screenTime: screenTime
        case .apps: apps
        case .name: naming
        case .setup: setup
        }
    }

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
            Button("Hi, Pofu") { step = model.screenTime.isAvailable ? .screenTime : .apps }
                .buttonStyle(PofuPrimaryButtonStyle())
        }
        .padding(PofuSpacing.screen)
    }

    private var screenTime: some View {
        ScreenTimeSetupView(
            model: model,
            onFinish: { step = .name },
            onUseShortcuts: {
                choseShortcuts = true
                step = .apps
            }
        )
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
                            // The icon stays; selection adds a checkmark
                            // badge on it, so the label never moves. Long
                            // names wrap rather than shrink.
                            HStack(spacing: PofuSpacing.s) {
                                Image(systemName: app.symbolName)
                                    .frame(width: 24)
                                    .overlay(alignment: .topTrailing) {
                                        if isChosen {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundStyle(PofuColor.onAccent, PofuColor.accent)
                                                .offset(x: 6, y: -6)
                                                .transition(.scale.combined(with: .opacity))
                                        }
                                    }
                                Text(verbatim: app.displayName)
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer(minLength: 0)
                            }
                            .animation(PofuMotion.respecting(reduceMotion, PofuMotion.pop), value: isChosen)
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
            Text("What would you like to call me?")
                .font(PofuFont.largeTitle)
                .foregroundStyle(PofuColor.textPrimary)
                .multilineTextAlignment(.center)
            TextField(text: $name, prompt: Text(verbatim: UserProfile.defaultName)) {
                Text("Name")
            }
            .pofuDisplayFont(size: 30)
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
                if usesShortcuts {
                    step = .setup
                } else {
                    model.completeOnboarding()
                }
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
            SetupGuideView(
                model: model,
                onboarding: .init(
                    finish: { model.completeOnboarding() },
                    later: { model.completeOnboarding() }
                )
            )
        }
    }
}

/// Turns hit testing off for the life of a transition: a view on its way
/// out never takes a tap meant for the one coming in.
private struct HitTesting: ViewModifier {
    let isEnabled: Bool

    func body(content: Content) -> some View {
        content.allowsHitTesting(isEnabled)
    }
}

extension AnyTransition {
    fileprivate static var disablesHitTesting: AnyTransition {
        .modifier(active: HitTesting(isEnabled: false), identity: HitTesting(isEnabled: true))
    }
}
