import FamilyControls
import PofuCompanion
import PofuDesignSystem
import PofuScreenTime
import SwiftUI
import UserNotifications

/// The zero-setup gate (ADR-0013): one system permission, then the app
/// picker. Used in onboarding when the live gate is available, and from
/// Settings to change the apps.
struct ScreenTimeSetupView: View {
    let model: AppModel
    /// Continue once the shield stands in front of something.
    var onFinish: () -> Void
    /// Fall back to the Shortcuts soft gate; `nil` hides the option.
    var onUseShortcuts: (() -> Void)?

    @State private var isPickerPresented = false
    @State private var picked = FamilyActivitySelection()
    @State private var couldNotAsk = false
    @State private var isAsking = false

    private var gate: ScreenTimeGate { model.screenTime }

    private enum Stage {
        case permission
        case denied
        case pick
        case ready
    }

    private var stage: Stage {
        switch gate.authorization {
        case .notDetermined: .permission
        case .denied: .denied
        case .approved: gate.selection.isEmpty ? .pick : .ready
        }
    }

    var body: some View {
        VStack(spacing: PofuSpacing.l) {
            Spacer()
            CompanionView(vitality: 0.8, energy: 0.3)
                .frame(maxWidth: 200)
            Text(title)
                .font(PofuFont.largeTitle)
                .foregroundStyle(PofuColor.textPrimary)
                .multilineTextAlignment(.center)
            Text(message)
                .font(PofuFont.body)
                .foregroundStyle(PofuColor.textSecondary)
                .multilineTextAlignment(.center)
            if couldNotAsk {
                Text("I couldn't ask iOS right now. Try again?")
                    .font(PofuFont.footnote)
                    .foregroundStyle(PofuColor.warning)
                    .multilineTextAlignment(.center)
            }
            Spacer()
            actions
        }
        .padding(PofuSpacing.screen)
        .familyActivityPicker(isPresented: $isPickerPresented, selection: $picked)
        .onChange(of: isPickerPresented) { _, isPresented in
            guard !isPresented else { return }
            savePicked()
        }
        .onAppear {
            gate.refreshStatus()
            picked = gate.pickedSelection()
        }
    }

    private var title: LocalizedStringKey {
        switch stage {
        case .permission: "Let me stand at the door"
        case .denied: "Screen Time is off for Pofu"
        case .pick: "Pick the apps that pull you in"
        case .ready: "I'm at the door"
        }
    }

    private var message: LocalizedStringKey {
        switch stage {
        case .permission:
            "When you reach for a feed, I'll be there first. iOS asks once if Pofu may use Screen Time; nothing leaves this iPhone."
        case .denied:
            "You can turn it on in Settings, Screen Time, or let me jump in through Shortcuts instead."
        case .pick:
            "I'll stand in front of them. You can change this any time in Settings."
        case .ready:
            "Open one of them to see me. Tap Talk to Pofu there and I'll answer with a notification."
        }
    }

    @ViewBuilder
    private var actions: some View {
        VStack(spacing: PofuSpacing.s) {
            switch stage {
            case .permission:
                Button("Allow Screen Time") { ask() }
                    .buttonStyle(PofuPrimaryButtonStyle())
                    .disabled(isAsking)
            case .denied:
                Button("Try again") { ask() }
                    .buttonStyle(PofuPrimaryButtonStyle())
                    .disabled(isAsking)
            case .pick:
                Button("Choose apps") { isPickerPresented = true }
                    .buttonStyle(PofuPrimaryButtonStyle())
            case .ready:
                Button("Done") { onFinish() }
                    .buttonStyle(PofuPrimaryButtonStyle())
                Button("Change apps") { isPickerPresented = true }
                    .buttonStyle(PofuQuietButtonStyle())
            }
            if let onUseShortcuts, stage != .ready {
                Button("Use Shortcuts instead") { onUseShortcuts() }
                    .buttonStyle(PofuQuietButtonStyle())
            }
        }
    }

    private func ask() {
        isAsking = true
        couldNotAsk = false
        Task {
            do {
                try await gate.requestAuthorization()
            } catch {
                couldNotAsk = true
            }
            isAsking = false
        }
    }

    private func savePicked() {
        do {
            try gate.applyPicked(picked)
        } catch {
            Log.screenTime.error("Saving the picked apps failed: \(String(describing: error), privacy: .public)")
            return
        }
        guard gate.isOn else { return }
        // "Talk to Pofu" on the shield answers with a notification.
        Task {
            _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
        }
    }
}
