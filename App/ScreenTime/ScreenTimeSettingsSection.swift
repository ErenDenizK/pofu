import FamilyControls
import PofuCore
import PofuDesignSystem
import SwiftUI
import UIKit
import UserNotifications

/// Settings for the Screen Time gate: whether it is on, the picked apps,
/// today's measured guarded time, the daily hour, whether Pofu can answer
/// "Açmam lazım" with a notification, and the founder's readout. Shown
/// only in the live build.
struct ScreenTimeSettingsSection: View {
    let model: AppModel

    @Environment(\.openURL) private var openURL
    @State private var notifications: NotificationHealth = .unknown

    /// Whether "Open with Pofu" can reach the user (gate v2, section 9).
    enum NotificationHealth: Sendable {
        case unknown
        case allowed
        case focusMayHide
        case off
    }

    private var gate: ScreenTimeGate { model.screenTime }

    var body: some View {
        Section {
            LabeledContent {
                if gate.isOn {
                    Text("On")
                        .foregroundStyle(PofuColor.success)
                } else {
                    Text("Off")
                        .foregroundStyle(PofuColor.textSecondary)
                }
            } label: {
                Label {
                    Text("Shield")
                } icon: {
                    PofuDuoIcon(.duoShield, size: 26, fallback: "hand.raised")
                }
            }
            .onAppear { gate.refreshStatus() }
            if gate.authorization == .approved {
                ChooseAppsRow(gate: gate)
                LabeledContent {
                    Text(usageText)
                } label: {
                    Label("Guarded time today", systemImage: "hourglass")
                }
                Stepper(
                    value: Binding(
                        get: { model.gateRules.dailyHourMinutes },
                        set: { model.setDailyHour(minutes: $0) }
                    ),
                    in: ScreenTimeGateRules.dailyHourRange,
                    step: 15
                ) {
                    LabeledContent {
                        Text("\(model.gateRules.dailyHourMinutes) min")
                    } label: {
                        Label("Daily hour", systemImage: "wind")
                    }
                }
                notificationRow
                NavigationLink {
                    DeveloperReadout(model: model)
                } label: {
                    Label("Readout", systemImage: "list.number")
                }
            } else {
                AllowScreenTimeRow(model: model)
            }
        } header: {
            Group {
                if gate.isRehearsal {
                    Text("Screen Time (rehearsal)")
                } else {
                    Text("Screen Time")
                }
            }
            .pofuSectionHeader()
        } footer: {
            Text("Measured by Screen Time, in 15-minute steps. Past the daily hour, every open starts with a breath.")
        }
        .settingsRow()
        .task { await checkNotifications() }
    }

    @ViewBuilder private var notificationRow: some View {
        switch notifications {
        case .unknown, .allowed:
            EmptyView()
        case .off:
            VStack(alignment: .leading, spacing: PofuSpacing.xs) {
                Label("Notifications are off", systemImage: "bell.slash")
                Text("After \"I need it\" I can't reach you; open me yourself within 10 minutes. The quick check still works.")
                    .font(PofuFont.footnote)
                    .foregroundStyle(PofuColor.textSecondary)
                Button("Open Settings") { openSettings() }
                    .buttonStyle(PofuTextButtonStyle())
            }
        case .focusMayHide:
            VStack(alignment: .leading, spacing: PofuSpacing.xs) {
                Label("With Focus on, my notification may not arrive.", systemImage: "moon")
                Button("Open Settings") { openSettings() }
                    .buttonStyle(PofuTextButtonStyle())
            }
        }
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
            openURL(url)
        }
    }

    private func checkNotifications() async {
        notifications = await Self.notificationHealth()
    }

    private nonisolated static func notificationHealth() async -> NotificationHealth {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return settings.timeSensitiveSetting == .disabled ? .focusMayHide : .allowed
        case .denied:
            return .off
        case .notDetermined:
            return .unknown
        @unknown default:
            return .unknown
        }
    }

    private var usageText: LocalizedStringKey {
        let minutes = model.measuredGuardedMinutesToday ?? 0
        if minutes == 0 {
            return "under 15 min"
        }
        return "at least \(minutes) min"
    }
}

/// Opens the system app picker and saves what the user picks.
private struct ChooseAppsRow: View {
    let gate: ScreenTimeGate

    @State private var isPickerPresented = false
    @State private var picked = FamilyActivitySelection()
    @State private var showsRehearsalPicker = false

    var body: some View {
        Button {
            if gate.isRehearsal {
                showsRehearsalPicker = true
                return
            }
            picked = gate.pickedSelection()
            isPickerPresented = true
        } label: {
            LabeledContent {
                Text(verbatim: "\(gate.selectionCount)")
            } label: {
                Label("Choose apps", systemImage: "square.grid.2x2")
            }
        }
        .familyActivityPicker(isPresented: $isPickerPresented, selection: $picked)
        .onChange(of: isPickerPresented) { _, isPresented in
            guard !isPresented else { return }
            do {
                try gate.applyPicked(picked)
            } catch {
                Log.screenTime.error("Saving the picked apps failed: \(String(describing: error), privacy: .public)")
            }
        }
        .sheet(isPresented: $showsRehearsalPicker) {
            RehearsalAppPicker(initial: gate.selection) { selection in
                do {
                    try gate.applyRehearsalSelection(selection)
                } catch {
                    Log.screenTime.error("Saving the rehearsal pick failed: \(String(describing: error), privacy: .public)")
                }
            }
        }
    }
}

/// Asks for Screen Time access, then the picker, in a sheet.
private struct AllowScreenTimeRow: View {
    let model: AppModel

    @State private var isSettingUp = false

    var body: some View {
        Button {
            isSettingUp = true
        } label: {
            Label("Allow Screen Time", systemImage: "hand.raised")
        }
        .sheet(isPresented: $isSettingUp) {
            ZStack {
                PofuColor.dayWash.ignoresSafeArea()
                ScreenTimeSetupView(model: model, onFinish: { isSettingUp = false }, onUseShortcuts: nil)
            }
        }
    }
}
