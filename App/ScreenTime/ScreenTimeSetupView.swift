import FamilyControls
import PofuCompanion
import PofuDesignSystem
import PofuScreenTime
import SwiftUI
import UIKit

/// The zero-setup gate (ADR-0013, gate v2 section 3, O2–O5): why Pofu
/// needs Screen Time, Apple's permission, a primer for Apple's picker, and
/// the picker. Used in onboarding when the live gate is available, and
/// from Settings to change the apps.
///
/// Every failure has a way out: a denial offers a retry, then the iOS
/// Settings path; an empty pick asks again; a whole category is named for
/// what it means.
struct ScreenTimeSetupView: View {
    let model: AppModel
    /// Continue once the shield stands in front of something.
    var onFinish: () -> Void
    /// Fall back to the Shortcuts soft gate; `nil` hides the option.
    var onUseShortcuts: (() -> Void)?
    /// Leave setup for now; `nil` hides the option.
    var onLater: (() -> Void)?

    @Environment(\.openURL) private var openURL
    @State private var isPickerPresented = false
    @State private var picked = FamilyActivitySelection()
    @State private var couldNotAsk = false
    @State private var isAsking = false
    /// Requests that came back denied, to switch to the Settings path when
    /// iOS stops showing its alert.
    @State private var denials = 0
    /// The picker came back empty at least once.
    @State private var pickedNothing = false
    /// The user saw the category note and kept the pick.
    @State private var keptCategory = false
    /// Rehearsal mode: the stand-ins for Apple's alert and picker.
    @State private var showsRehearsalAlert = false
    @State private var showsRehearsalPicker = false

    private var gate: ScreenTimeGate { model.screenTime }

    private enum Stage {
        case why
        case denied
        case primer
        case category
        case ready
    }

    private var stage: Stage {
        switch gate.authorization {
        case .notDetermined: return .why
        case .denied: return .denied
        case .approved:
            if gate.selection.isEmpty { return .primer }
            if !gate.selection.categories.isEmpty && !keptCategory { return .category }
            return .ready
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: PofuSpacing.l) {
                CompanionView(vitality: 0.8, energy: 0.3)
                    .frame(maxWidth: 120)
                    .padding(.top, PofuSpacing.l)
                    .accessibilityHidden(true)
                content
                if couldNotAsk {
                    Text("I couldn't ask iOS right now. Try again?")
                        .font(PofuFont.footnote)
                        .foregroundStyle(PofuColor.warning)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, PofuSpacing.screen)
        }
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom) {
            actions
                .padding(.horizontal, PofuSpacing.screen)
                .padding(.bottom, PofuSpacing.xs)
        }
        .familyActivityPicker(isPresented: $isPickerPresented, selection: $picked)
        .overlay {
            if showsRehearsalAlert {
                RehearsalPermissionAlert { approved in
                    showsRehearsalAlert = false
                    gate.answerRehearsalAuthorization(approved: approved)
                    if !approved {
                        denials += 1
                    }
                }
                .transition(.opacity)
            }
        }
        .sheet(isPresented: $showsRehearsalPicker) {
            RehearsalAppPicker(initial: gate.selection) { selection in
                saveRehearsalPick(selection)
            }
        }
        .onChange(of: isPickerPresented) { _, isPresented in
            guard !isPresented else { return }
            savePicked()
        }
        .onAppear {
            gate.refreshStatus()
            picked = gate.pickedSelection()
        }
        .onChange(of: stage) { _, newStage in
            if newStage == .ready {
                onFinish()
            }
        }
    }

    // MARK: Content

    @ViewBuilder private var content: some View {
        switch stage {
        case .why:
            heading("So I can stand at the door")
            VStack(alignment: .leading, spacing: PofuSpacing.m) {
                reason("hand.raised", "When you open an app you picked, I show up first.")
                reason("eye.slash", "I can't see what you do in there. Nothing leaves this iPhone.")
                reason("switch.2", "You can turn me off any time.")
            }
            footnote("The next screen is Apple's: tap **Continue**, then Face ID.")
        case .denied:
            heading("Okay, no pressure.")
            message("Without Screen Time I can't stand at the door. If you change your mind, I'm here.")
            if denials >= 2 {
                message("Settings → Screen Time → Apps with Screen Time Access → Pofu")
                    .fontWeight(.semibold)
            }
        case .primer:
            if pickedNothing {
                heading("Nobody at the door yet.")
                message("Pick at least one app; add the rest later.")
            } else {
                heading("Which ones pull you in most?")
                VStack(alignment: .leading, spacing: PofuSpacing.m) {
                    reason("chevron.right.circle", "Tap the arrow next to a category and tick the app itself.")
                    reason("bubble.left.and.bubble.right", "Pick all of Social and I'll stand at WhatsApp's door too.")
                }
                footnote("My suggestion: Instagram, YouTube, TikTok.")
            }
        case .category:
            heading("You picked a whole category.")
            message("I'll be at every app in it, messaging included.")
        case .ready:
            heading("I'm at the door")
        }
    }

    private func heading(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .font(PofuFont.title2)
            .foregroundStyle(PofuColor.textPrimary)
            .multilineTextAlignment(.center)
            .accessibilityAddTraits(.isHeader)
    }

    private func message(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .font(PofuFont.body)
            .foregroundStyle(PofuColor.textSecondary)
            .multilineTextAlignment(.center)
    }

    private func footnote(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .font(PofuFont.footnote)
            .foregroundStyle(PofuColor.textSecondary)
            .multilineTextAlignment(.center)
    }

    private func reason(_ symbol: String, _ key: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: PofuSpacing.m) {
            Image(systemName: symbol)
                .font(.system(size: 22))
                .foregroundStyle(PofuColor.accent)
                .frame(width: 28)
                .accessibilityHidden(true)
            Text(key)
                .font(PofuFont.body)
                .foregroundStyle(PofuColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    // MARK: Actions

    @ViewBuilder private var actions: some View {
        VStack(spacing: PofuSpacing.s) {
            switch stage {
            case .why:
                Button("Allow Screen Time") { ask() }
                    .buttonStyle(PofuPrimaryButtonStyle())
                    .disabled(isAsking)
            case .denied:
                if denials >= 2, !gate.isRehearsal {
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            openURL(url)
                        }
                    }
                    .buttonStyle(PofuPrimaryButtonStyle())
                    Button("Try again") { ask() }
                        .buttonStyle(PofuQuietButtonStyle())
                        .disabled(isAsking)
                } else {
                    Button("Try again") { ask() }
                        .buttonStyle(PofuPrimaryButtonStyle())
                        .disabled(isAsking)
                }
                if let onLater {
                    Button("Skip for now") { onLater() }
                        .buttonStyle(PofuQuietButtonStyle())
                }
            case .primer:
                Button(pickedNothing ? LocalizedStringKey("Pick again") : LocalizedStringKey("Choose apps")) { openPicker() }
                    .buttonStyle(PofuPrimaryButtonStyle())
                if pickedNothing, let onLater {
                    Button("I'll pick later") { onLater() }
                        .buttonStyle(PofuQuietButtonStyle())
                }
            case .category:
                Button("Keep it") { keptCategory = true }
                    .buttonStyle(PofuPrimaryButtonStyle())
                Button("Fix it") { openPicker() }
                    .buttonStyle(PofuQuietButtonStyle())
            case .ready:
                Button("Continue") { onFinish() }
                    .buttonStyle(PofuPrimaryButtonStyle())
            }
            if let onUseShortcuts, stage == .denied {
                Button("Set up with Shortcuts (advanced)") { onUseShortcuts() }
                    .font(PofuFont.footnote)
                    .buttonStyle(.plain)
                    .foregroundStyle(PofuColor.textSecondary)
                    .frame(minHeight: PofuSize.minimumTouch)
            }
        }
    }

    private func ask() {
        if gate.isRehearsal {
            couldNotAsk = false
            showsRehearsalAlert = true
            return
        }
        isAsking = true
        couldNotAsk = false
        Task {
            do {
                let status = try await gate.requestAuthorization()
                if status == .denied {
                    denials += 1
                }
            } catch {
                couldNotAsk = true
            }
            isAsking = false
        }
    }

    /// Apple's picker, or Rehearsal mode's stand-in.
    private func openPicker() {
        if gate.isRehearsal {
            showsRehearsalPicker = true
        } else {
            isPickerPresented = true
        }
    }

    private func saveRehearsalPick(_ selection: DistractionSelection) {
        do {
            try gate.applyRehearsalSelection(selection)
        } catch {
            Log.screenTime.error("Saving the rehearsal pick failed: \(String(describing: error), privacy: .public)")
            return
        }
        pickedNothing = gate.selection.isEmpty
        keptCategory = false
    }

    private func savePicked() {
        do {
            try gate.applyPicked(picked)
        } catch {
            Log.screenTime.error("Saving the picked apps failed: \(String(describing: error), privacy: .public)")
            return
        }
        pickedNothing = gate.selection.isEmpty
        keptCategory = false
    }
}
