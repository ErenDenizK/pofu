import PofuCore
import PofuDesignSystem
import SwiftUI
import UIKit

/// How to invite Pofu to an app's door: one Shortcuts personal automation
/// per app (ADR-0008). iOS does not let apps create automations, so this
/// is a guide, then a test that proves it works.
///
/// v2 follows the founder's failed first attempt (decision audit, "First-
/// hand evidence"): he thought "if Instagram opens, then do X", searched
/// Shortcuts for "Insta" and "Pofu", and found actions instead of the
/// **App** trigger. So the guide frames the automation as that rule, says
/// up front not to search, shows each screen with its target highlighted,
/// and allows search only inside **Add Action**.
///
/// Every step has an image slot: a device screenshot named
/// `SetupStep-<step>` in the asset catalog replaces the drawn schematic
/// once it exists.
///
/// The English labels quote iOS 26. The Turkish ones come from Turkish
/// guides to the same flow; Apple's Turkish Shortcuts guide could not be
/// reached to confirm them, so the uncertain ones are marked
/// `VERIFY ON DEVICE` here and in `ShortcutsLabels.xcstrings`.
///
/// One primary action at a time: **Test it** until the automation has
/// fired, then the next app, and **Done** once every chosen app works.
struct SetupGuideView: View {
    let model: AppModel
    /// Set during onboarding: finishing the guide, or putting it off,
    /// completes onboarding. Elsewhere the guide dismisses itself.
    var onboarding: OnboardingExit?

    /// How the guide ends during onboarding.
    struct OnboardingExit {
        let finish: @MainActor () -> Void
        let later: @MainActor () -> Void
    }

    @Environment(\.dismiss) private var dismiss
    @State private var selected: ProtectedApp?
    @State private var testFailed = false

    private var apps: [ProtectedApp] {
        let chosen = model.profile.protectedApps
        return chosen.isEmpty ? [.instagram, .youtube, .tiktok] : chosen
    }

    private var app: ProtectedApp {
        selected ?? model.unverifiedApps.first ?? apps.first ?? .instagram
    }

    /// The one next step, which is the screen's only primary action. The
    /// guide never claims success before the automation has fired.
    private enum NextStep: Equatable {
        case test
        /// Pofu cannot open this app to test it, so Shortcuts stays the
        /// next real step.
        case openShortcuts
        case setUp(ProtectedApp)
        case finish
    }

    private var nextStep: NextStep {
        if model.profile.isVerified(app) {
            if let next = apps.first(where: { !model.profile.isVerified($0) }) {
                return .setUp(next)
            }
            return .finish
        }
        return app.canBeOpenedByPofu ? .test : .openShortcuts
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PofuSpacing.xl) {
                VStack(alignment: .leading, spacing: PofuSpacing.s) {
                    Text("About a minute per app, once.")
                        .font(PofuFont.subheadline)
                        .foregroundStyle(PofuColor.accent)
                    Text("We're making a rule: when \(app.displayName) opens, \(model.profile.companionName) hops in.")
                        .font(PofuFont.title3)
                        .foregroundStyle(PofuColor.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("iPhone only lets me appear if you invite me in the Shortcuts app. Make one automation for each app you want me at.")
                        .font(PofuFont.callout)
                        .foregroundStyle(PofuColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                appPicker

                ForEach(Array(SetupStep.allCases.enumerated()), id: \.element) { item in
                    SetupStepCard(number: item.offset + 1, step: item.element, app: app) {
                        if item.element == .openAutomation {
                            Button {
                                openShortcuts()
                            } label: {
                                Text("Open Shortcuts")
                            }
                            .buttonStyle(PofuQuietButtonStyle())
                        }
                    }
                }

                VStack(alignment: .leading, spacing: PofuSpacing.m) {
                    status
                    if testFailed {
                        Text("I couldn't open \(app.objectName). Is it still installed?")
                            .font(PofuFont.footnote)
                            .foregroundStyle(PofuColor.warning)
                    }
                }

                VStack(alignment: .leading, spacing: PofuSpacing.s) {
                    Text("If I don't show up")
                        .font(PofuFont.headline)
                        .foregroundStyle(PofuColor.textPrimary)
                    Text("Check that the automation is on, that it says Run Immediately (not Run After Confirmation), and that the Hop in action has the same app as the trigger.")
                        .font(PofuFont.callout)
                        .foregroundStyle(PofuColor.textSecondary)
                }
            }
            .padding(PofuSpacing.screen)
        }
        .background(PofuColor.canvas)
        .pofuFooter {
            VStack(spacing: PofuSpacing.xs) {
                primaryAction
                if let onboarding {
                    Button("I'll do it later") { onboarding.later() }
                        .font(PofuFont.headline)
                        .foregroundStyle(PofuColor.accent)
                        .frame(minHeight: PofuSize.minimumTouch)
                }
            }
        }
        .animation(PofuMotion.snappy, value: nextStep)
        .navigationTitle(Text("Set up Hop!"))
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Actions

    @ViewBuilder private var primaryAction: some View {
        switch nextStep {
        case .test:
            Button {
                test()
            } label: {
                Text("Test it: open \(app.objectName)")
            }
            .buttonStyle(PofuPrimaryButtonStyle())
        case .openShortcuts:
            Button {
                openShortcuts()
            } label: {
                Text("Open Shortcuts")
            }
            .buttonStyle(PofuPrimaryButtonStyle())
        case .setUp(let next):
            Button {
                select(next)
            } label: {
                Text("Next: \(next.displayName)")
            }
            .buttonStyle(PofuPrimaryButtonStyle())
        case .finish:
            Button {
                if let onboarding {
                    onboarding.finish()
                } else {
                    dismiss()
                }
            } label: {
                Text("Done")
            }
            .buttonStyle(PofuPrimaryButtonStyle())
        }
    }

    /// Opens Shortcuts on whatever tab it last showed. No documented URL
    /// opens the Automation tab: Apple's "Run shortcuts from a URL"
    /// lists only `create-shortcut`, `open-shortcut`, `run-shortcut`,
    /// `gallery`, and x-callback-url, so step 1 tells the user where to
    /// tap instead.
    private func openShortcuts() {
        Task {
            await AppOpener.openShortcuts()
        }
    }

    private func test() {
        Task {
            testFailed = !(await AppOpener.open(app))
        }
    }

    private func select(_ item: ProtectedApp) {
        selected = item
        testFailed = false
    }

    private var appPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: PofuSpacing.s) {
                ForEach(apps) { item in
                    Button {
                        select(item)
                    } label: {
                        HStack(spacing: PofuSpacing.xs) {
                            if model.profile.isVerified(item) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(PofuColor.success)
                            }
                            Text(verbatim: item.displayName)
                        }
                        .padding(.horizontal, PofuSpacing.s)
                    }
                    .buttonStyle(PofuChoiceStyle(isSelected: item == app, cornerRadius: PofuSize.minimumTouch / 2))
                    .fixedSize()
                    .accessibilityAddTraits(item == app ? .isSelected : [])
                }
            }
        }
    }

    @ViewBuilder private var status: some View {
        if let date = model.profile.lastCheckIn[app] {
            Label {
                Text("It works. I last hopped in at \(date.formatted(date: .omitted, time: .shortened)).")
            } icon: {
                Image(systemName: "checkmark.seal.fill")
            }
            .font(PofuFont.callout)
            .foregroundStyle(PofuColor.success)
        } else {
            Label {
                Text("Not working yet. After you set it up, test it once.")
            } icon: {
                Image(systemName: "circle.dashed")
            }
            .font(PofuFont.callout)
            .foregroundStyle(PofuColor.textSecondary)
        }
    }
}

// MARK: - Steps

/// The steps of the automation, in the order the Shortcuts app asks for
/// them on iOS 26.
enum SetupStep: String, CaseIterable, Identifiable {
    case openAutomation
    case newAutomation
    case appTrigger
    case chooseApp
    case runImmediately
    case addAction
    case setApp

    var id: String { rawValue }

    /// The asset that replaces the schematic once a device screenshot
    /// exists (localize it in the asset catalog for Turkish).
    var screenshotName: String { "SetupStep-\(rawValue)" }

    /// The instruction. Bold words quote the Shortcuts app; in Turkish
    /// they follow the iOS 26 labels in `ShortcutsLabels.xcstrings`.
    func text(for app: ProtectedApp) -> Text {
        let name = app.displayName
        switch self {
        case .openAutomation:
            // Turkish: Kestirmeler, Otomasyon (both in several Turkish guides).
            return Text("Open Shortcuts. Don't search: tap **Automation** at the bottom.")
        case .newAutomation:
            // Turkish: Yeni Otomasyon (in Turkish guides). VERIFY ON DEVICE
            return Text("Tap **New Automation**, or **+** at the top right.")
        case .appTrigger:
            // Turkish: Uygulama (in Turkish guides).
            return Text("Scroll down the list and tap **App**.")
        case .chooseApp:
            // Turkish: Seç, Bitti. VERIFY ON DEVICE ("Seç")
            return Text("Tap **Choose**, pick **\(name)**, then tap **Done**.")
        case .runImmediately:
            // Turkish: Açık (guides say "Açık" / "Kapalı"; the old guide
            // said "Açıldığında"), Hemen Çalıştır (confirmed by several
            // guides), Çalıştığında Bildir (guides also show "Çalıştırıldığında
            // Bildir"), Sonraki (or "İleri"). VERIFY ON DEVICE
            return Text("Keep **Is Opened** ticked. Choose **Run Immediately**, turn **Notify When Run** off, then tap **Next**.")
        case .addAction:
            // Turkish: Yeni Boş Otomasyon, Eylem Ekle (one guide says
            // "İşlem Ekle"). VERIFY ON DEVICE
            return Text("Tap **New Blank Automation**, then **Add Action**. Search here, and only here: type **Hop** and tap **Hop in**.")
        case .setApp:
            // "App" is the Hop in action's own parameter (Uygulama).
            return Text("In the action, tap **App** and pick **\(name)** again. Tap **Done**, then come back to me.")
        }
    }

    /// A short warning under the step, where users go wrong.
    var note: LocalizedStringKey? {
        switch self {
        case .openAutomation:
            "Search in Shortcuts finds actions, not rules. The rule starts in Automation."
        case .runImmediately:
            "Run After Confirmation asks you every time, and I'd arrive too late."
        default:
            nil
        }
    }
}

/// One step: its number, the instruction, a note where users slip, and
/// the picture of the screen.
private struct SetupStepCard<Accessory: View>: View {
    let number: Int
    let step: SetupStep
    let app: ProtectedApp
    @ViewBuilder let accessory: Accessory

    var body: some View {
        VStack(alignment: .leading, spacing: PofuSpacing.m) {
            HStack(alignment: .top, spacing: PofuSpacing.m) {
                Text(number, format: .number)
                    .font(PofuFont.headline.monospacedDigit())
                    .foregroundStyle(PofuColor.accent)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(PofuColor.accentTint))
                VStack(alignment: .leading, spacing: PofuSpacing.xs) {
                    step.text(for: app)
                        .font(PofuFont.body)
                        .foregroundStyle(PofuColor.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    if let note = step.note {
                        Label {
                            Text(note)
                        } icon: {
                            Image(systemName: "exclamationmark.circle")
                        }
                        .font(PofuFont.footnote)
                        .foregroundStyle(PofuColor.warning)
                        .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .accessibilityElement(children: .combine)

            SetupStepImage(step: step, app: app)
            accessory
        }
        .pofuCard()
    }
}

/// The image slot of a step: the device screenshot when the asset exists,
/// otherwise a drawn schematic of the screen with the target highlighted.
private struct SetupStepImage: View {
    let step: SetupStep
    let app: ProtectedApp

    var body: some View {
        Group {
            if let screenshot = UIImage(named: step.screenshotName) {
                Image(uiImage: screenshot)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: PofuRadius.medium, style: .continuous))
            } else {
                ShortcutsSchematic(step: step, app: app)
            }
        }
        .frame(maxWidth: .infinity)
        // The instruction above says the same thing in words.
        .accessibilityHidden(true)
    }
}

// MARK: - Schematics

/// A simplified drawing of the Shortcuts screen for a step, with the one
/// thing to tap ringed in Pofu's accent. Labels come from
/// `ShortcutsLabels.xcstrings`, the iOS 26 labels in each language.
private struct ShortcutsSchematic: View {
    let step: SetupStep
    let app: ProtectedApp

    var body: some View {
        VStack(alignment: .leading, spacing: PofuSpacing.s) {
            content
        }
        .font(PofuFont.footnote)
        .foregroundStyle(PofuColor.textPrimary)
        .padding(PofuSpacing.m)
        .frame(maxWidth: .infinity, minHeight: 132, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: PofuRadius.medium, style: .continuous)
                .fill(PofuColor.sunken)
        )
        .overlay(
            RoundedRectangle(cornerRadius: PofuRadius.medium, style: .continuous)
                .strokeBorder(PofuColor.hairline, lineWidth: 1)
        )
    }

    @ViewBuilder private var content: some View {
        switch step {
        case .openAutomation:
            HStack(spacing: PofuSpacing.xs) {
                Image(systemName: "magnifyingglass")
                ShortcutsLabel("Search")
                Spacer()
                Image(systemName: "xmark")
                    .foregroundStyle(PofuColor.warning)
            }
            .foregroundStyle(PofuColor.textTertiary)
            .padding(PofuSpacing.s)
            .background(Capsule(style: .continuous).fill(PofuColor.card))
            .opacity(0.6)
            Spacer(minLength: PofuSpacing.l)
            HStack(spacing: PofuSpacing.xs) {
                SchematicTab(symbol: "square.grid.2x2", label: "Shortcuts")
                SchematicTab(symbol: "checkmark.circle", label: "Automation")
                    .schematicTarget()
                SchematicTab(symbol: "square.stack", label: "Gallery")
            }
            .padding(PofuSpacing.xs)
            .background(Capsule(style: .continuous).fill(PofuColor.card))

        case .newAutomation:
            HStack {
                ShortcutsLabel("Automation")
                    .font(PofuFont.headline)
                Spacer()
                Image(systemName: "plus")
                    .font(PofuFont.headline)
                    .frame(width: 32, height: 32)
                    .schematicTarget()
            }
            Spacer(minLength: PofuSpacing.s)
            ShortcutsLabel("New Automation")
                .font(PofuFont.headline)
                .foregroundStyle(PofuColor.onAccent)
                .padding(.horizontal, PofuSpacing.m)
                .padding(.vertical, PofuSpacing.s)
                .background(Capsule(style: .continuous).fill(PofuColor.accent))
                .schematicTarget()
                .frame(maxWidth: .infinity)

        case .appTrigger:
            SchematicRow(symbol: "clock", label: "Time of Day")
            SchematicRow(symbol: "alarm", label: "Alarm")
            SchematicRow(symbol: "envelope", label: "Email")
            SchematicRow(symbol: "app", label: "App")
                .schematicTarget()

        case .chooseApp:
            HStack {
                ShortcutsLabel("App")
                Spacer()
                ShortcutsLabel("Choose")
                    .foregroundStyle(PofuColor.accent)
                    .schematicTarget()
            }
            .padding(PofuSpacing.s)
            .background(RoundedRectangle(cornerRadius: PofuRadius.small, style: .continuous).fill(PofuColor.card))
            HStack {
                Image(systemName: app.symbolName)
                Text(verbatim: app.displayName)
                Spacer()
                Image(systemName: "checkmark")
                    .foregroundStyle(PofuColor.accent)
            }
            .padding(PofuSpacing.s)
            .schematicTarget()
            HStack {
                Spacer()
                ShortcutsLabel("Done")
                    .font(PofuFont.headline)
                    .foregroundStyle(PofuColor.accent)
            }

        case .runImmediately:
            HStack(spacing: PofuSpacing.m) {
                SchematicCheck(label: "Is Opened", isOn: true)
                    .schematicTarget()
                SchematicCheck(label: "Is Closed", isOn: false)
            }
            SchematicRadio(label: "Run After Confirmation", isOn: false)
            SchematicRadio(label: "Run Immediately", isOn: true)
                .schematicTarget()
            HStack {
                ShortcutsLabel("Notify When Run")
                Spacer()
                Capsule(style: .continuous)
                    .fill(PofuColor.hairline)
                    .frame(width: 40, height: 24)
                    .overlay(alignment: .leading) {
                        Circle().fill(PofuColor.card).padding(2)
                    }
            }
            .padding(.horizontal, PofuSpacing.s)

        case .addAction:
            SchematicRow(symbol: "plus.square.dashed", label: "New Blank Automation")
            ShortcutsLabel("Add Action")
                .font(PofuFont.headline)
                .foregroundStyle(PofuColor.onAccent)
                .padding(.horizontal, PofuSpacing.m)
                .padding(.vertical, PofuSpacing.s)
                .background(Capsule(style: .continuous).fill(PofuColor.accent))
                .schematicTarget()
            HStack(spacing: PofuSpacing.xs) {
                Image(systemName: "magnifyingglass")
                Text(verbatim: "Hop")
                Spacer()
            }
            .padding(PofuSpacing.s)
            .background(Capsule(style: .continuous).fill(PofuColor.card))
            SchematicRow(symbol: "hare", label: "Hop in")
                .schematicTarget()

        case .setApp:
            HStack(spacing: PofuSpacing.xs) {
                Image(systemName: "hare")
                    .foregroundStyle(PofuColor.accent)
                ShortcutsLabel("Hop in")
                Text(verbatim: app.displayName)
                    .foregroundStyle(PofuColor.accent)
                    .padding(.horizontal, PofuSpacing.s)
                    .padding(.vertical, PofuSpacing.xxs)
                    .background(Capsule(style: .continuous).fill(PofuColor.accentTint))
                    .schematicTarget()
                Spacer(minLength: 0)
            }
            .padding(PofuSpacing.s)
            .background(RoundedRectangle(cornerRadius: PofuRadius.small, style: .continuous).fill(PofuColor.card))
            HStack {
                Spacer()
                ShortcutsLabel("Done")
                    .font(PofuFont.headline)
                    .foregroundStyle(PofuColor.accent)
            }
        }
    }
}

/// A label as the Shortcuts app shows it, from `ShortcutsLabels.xcstrings`.
///
/// Keys are plain strings, so Xcode does not also extract them into
/// `Localizable`, where "Done" already means Pofu's own button.
private struct ShortcutsLabel: View {
    let key: String

    init(_ key: String) {
        self.key = key
    }

    var body: some View {
        Text(LocalizedStringKey(key), tableName: "ShortcutsLabels")
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }
}

private struct SchematicTab: View {
    let symbol: String
    let label: String

    var body: some View {
        VStack(spacing: PofuSpacing.xxs) {
            Image(systemName: symbol)
            ShortcutsLabel(label)
                .font(PofuFont.caption)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, PofuSpacing.xs)
    }
}

private struct SchematicRow: View {
    let symbol: String
    let label: String

    var body: some View {
        HStack(spacing: PofuSpacing.s) {
            Image(systemName: symbol)
                .foregroundStyle(PofuColor.accent)
                .frame(width: 20)
            ShortcutsLabel(label)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(PofuColor.textTertiary)
        }
        .padding(PofuSpacing.s)
        .background(RoundedRectangle(cornerRadius: PofuRadius.small, style: .continuous).fill(PofuColor.card))
    }
}

private struct SchematicCheck: View {
    let label: String
    let isOn: Bool

    var body: some View {
        HStack(spacing: PofuSpacing.xs) {
            Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isOn ? PofuColor.accent : PofuColor.textTertiary)
            ShortcutsLabel(label)
        }
        .padding(PofuSpacing.xs)
    }
}

private struct SchematicRadio: View {
    let label: String
    let isOn: Bool

    var body: some View {
        HStack {
            ShortcutsLabel(label)
            Spacer()
            if isOn {
                Image(systemName: "checkmark")
                    .foregroundStyle(PofuColor.accent)
            }
        }
        .padding(PofuSpacing.s)
    }
}

private extension View {
    /// Rings the one thing to tap in a schematic.
    func schematicTarget() -> some View {
        padding(PofuSpacing.xxs)
            .background(
                RoundedRectangle(cornerRadius: PofuRadius.small, style: .continuous)
                    .fill(PofuColor.accentTint)
            )
            .overlay(
                RoundedRectangle(cornerRadius: PofuRadius.small, style: .continuous)
                    .strokeBorder(PofuColor.accent, lineWidth: 2)
            )
    }
}
