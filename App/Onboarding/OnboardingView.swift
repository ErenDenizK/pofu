import PofuCompanion
import PofuCore
import PofuDesignSystem
import SwiftUI
import UserNotifications

/// The first run, kept minimal: meet Pofu, put Pofu at the door.
///
/// With the live Screen Time gate (the `PofuLive` build, gate v2 section
/// 3), the door is one permission and the app picker (ADR-0013), then a
/// primed notification permission (the open path depends on it), and
/// onboarding ends on the real shield: "Open Instagram now." The first
/// "Skip it" there is "Yakaladım!". There is no naming step; renaming
/// lives in Settings. The Shortcuts setup stays available as a fallback.
/// Without the live gate, the user picks apps, names Pofu, and sets up the
/// first automation (user flows, section 1).
struct OnboardingView: View {
    let model: AppModel

    private enum Step: Int, CaseIterable {
        case welcome
        case screenTime
        case apps
        case name
        case setup
        case notifications
        case tryIt
        case caught
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var step: Step = .welcome
    @State private var chosen: [ProtectedApp] = []
    @State private var name = UserProfile.defaultName
    /// The user chose the Shortcuts soft gate over Screen Time.
    @State private var choseShortcuts = false
    @Environment(\.scenePhase) private var scenePhase
    /// When "Try it" began, to find the shield the user just met.
    @State private var demoStartedAt: Date?
    /// The user left Pofu during "Try it" (to open the app).
    @State private var leftForDemo = false
    /// Back from the app, but no shield was recorded.
    @State private var missedShield = false
    @State private var caughtCount = 0

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
        .sensoryFeedback(.success, trigger: caughtCount)
        .onChange(of: model.rehearsal?.isAway ?? false) { _, isAway in
            // Rehearsal mode: the shield replica stands in for leaving
            // Pofu to open the app, and closing it for coming back.
            guard step == .tryIt, model.rehearsal != nil else { return }
            if isAway {
                leftForDemo = true
            } else {
                checkDemo()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            guard step == .tryIt, model.rehearsal == nil else { return }
            switch phase {
            case .background:
                leftForDemo = true
            case .active:
                checkDemo()
            default:
                break
            }
        }
    }

    /// Back from the guarded app during "Try it": a shield recorded since
    /// the step began (shown, skipped, or anything else) passes.
    private func checkDemo() {
        guard let started = demoStartedAt, leftForDemo else { return }
        model.refresh()
        if model.hasShieldReach(since: started) {
            caught()
        } else {
            missedShield = true
        }
    }

    private func caught() {
        missedShield = false
        caughtCount += 1
        step = .caught
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
        case .notifications: notifications
        case .tryIt: tryIt
        case .caught: caughtStep
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
            onFinish: {
                if step == .screenTime {
                    step = .notifications
                }
            },
            // Rehearsal mode keeps the Shortcuts setup to Settings.
            onUseShortcuts: shortcutsFallback,
            onLater: { model.completeOnboarding() }
        )
    }

    /// The Shortcuts fallback on a denial; none in Rehearsal mode, which
    /// keeps the Shortcuts setup to Settings.
    private var shortcutsFallback: (() -> Void)? {
        if model.screenTime.isRehearsal {
            return nil
        }
        return {
            choseShortcuts = true
            step = .apps
        }
    }

    // MARK: Live gate: O6–O8

    /// O6: notifications, primed with the one reason Pofu writes.
    private var notifications: some View {
        VStack(spacing: PofuSpacing.l) {
            Spacer()
            Image(systemName: "bell.badge")
                .font(.system(size: 44))
                .foregroundStyle(PofuColor.accent)
                .accessibilityHidden(true)
            Text("When you really need it")
                .font(PofuFont.title2)
                .foregroundStyle(PofuColor.textPrimary)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
            Text("Say **I need it** at the door and I'll answer with a notification. That's the only time I write, never to pull you back.")
                .font(PofuFont.body)
                .foregroundStyle(PofuColor.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
            Button("Allow notifications") {
                Task {
                    _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
                    startDemo()
                }
            }
            .buttonStyle(PofuPrimaryButtonStyle())
            Button("Continue without") { startDemo() }
                .buttonStyle(PofuQuietButtonStyle())
        }
        .padding(PofuSpacing.screen)
    }

    private func startDemo() {
        demoStartedAt = model.currentTime()
        leftForDemo = false
        missedShield = false
        step = .tryIt
    }

    /// O7: onboarding ends on the real shield.
    private var tryIt: some View {
        VStack(spacing: PofuSpacing.l) {
            Spacer()
            CompanionView(vitality: 0.8, energy: 0.3)
                .frame(maxWidth: 220)
            if missedShield {
                Text("I couldn't see the shield. Did you see me when the app opened?")
                    .font(PofuFont.title3)
                    .foregroundStyle(PofuColor.textPrimary)
                    .multilineTextAlignment(.center)
            } else {
                Text("Try it.")
                    .pofuDisplayFont(size: 36)
                    .foregroundStyle(PofuColor.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                Text("Open Instagram now. You'll see me at the door. Tap **Skip it**, then come back to me.")
                    .font(PofuFont.body)
                    .foregroundStyle(PofuColor.textSecondary)
                    .multilineTextAlignment(.center)
                if model.rehearsal != nil {
                    rehearsalReach
                }
            }
            Spacer()
            if missedShield {
                Button("I saw it") {
                    Log.screenTime.notice("Demo: the user saw the shield, but no record arrived")
                    caught()
                }
                .buttonStyle(PofuPrimaryButtonStyle())
                Button("I didn't") {
                    Log.screenTime.notice("Demo: the user did not see the shield")
                    model.completeOnboarding()
                    model.requestHomeSheet(.settings)
                }
                .buttonStyle(PofuQuietButtonStyle())
            } else {
                Button("I'll try later") { model.completeOnboarding() }
                    .buttonStyle(PofuQuietButtonStyle())
            }
        }
        .padding(PofuSpacing.screen)
    }

    /// Rehearsal mode's stand-in for opening Instagram from the Home
    /// Screen.
    private var rehearsalReach: some View {
        VStack(spacing: PofuSpacing.s) {
            Button {
                model.rehearsalReach(for: .instagram)
            } label: {
                Label {
                    Text("Reach for Instagram")
                } icon: {
                    Image(systemName: ProtectedApp.instagram.symbolName)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(PofuSecondaryButtonStyle())
            RehearsalBadge(text: Text("Rehearsal: this button stands in for opening the app"))
        }
        .padding(.top, PofuSpacing.s)
    }

    /// O8: "Yakaladım!"
    private var caughtStep: some View {
        VStack(spacing: PofuSpacing.l) {
            Spacer()
            CompanionView(vitality: 0.9, energy: 0.4)
                .frame(maxWidth: 260)
            Text("Got you!")
                .pofuDisplayFont(size: 40)
                .foregroundStyle(PofuColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Text("I'm at the door. That was your first skip. The rest runs by itself.")
                .font(PofuFont.body)
                .foregroundStyle(PofuColor.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
            Button("OK") { model.completeOnboarding() }
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
