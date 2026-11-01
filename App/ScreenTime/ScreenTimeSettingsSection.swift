import FamilyControls
import PofuDesignSystem
import SwiftUI

/// Settings for the Screen Time gate: whether it is on, the picked apps,
/// and today's measured guarded time. Shown only in the live build.
struct ScreenTimeSettingsSection: View {
    let model: AppModel

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
                Label("Shield", systemImage: "hand.raised")
            }
            .onAppear { gate.refreshStatus() }
            if gate.authorization == .approved {
                ChooseAppsRow(gate: gate)
                LabeledContent {
                    Text(usageText)
                } label: {
                    Label("Guarded time today", systemImage: "hourglass")
                }
            } else {
                AllowScreenTimeRow(model: model)
            }
        } header: {
            Text("Screen Time")
                .pofuSectionHeader()
        } footer: {
            Text("Measured by Screen Time, in 15-minute steps.")
        }
        .listRowBackground(PofuColor.card)
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

    var body: some View {
        Button {
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
