import PofuCore
import PofuDesignSystem
import SwiftUI

/// Settings: Pofu's name, the guarded apps and whether each automation
/// works, and the setup guide.
struct SettingsView: View {
    let model: AppModel

    @State private var name = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(text: $name, prompt: Text(verbatim: UserProfile.defaultName)) {
                        Text("Name")
                    }
                    .textInputAutocapitalization(.words)
                    .submitLabel(.done)
                    .onSubmit { model.setCompanionName(name) }
                } header: {
                    Text("Pofu")
                        .pofuSectionHeader()
                }
                .listRowBackground(PofuColor.card)

                Section {
                    ForEach(ProtectedApp.allCases) { app in
                        GuardedAppRow(model: model, app: app)
                    }
                    NavigationLink {
                        SetupGuideView(model: model)
                    } label: {
                        Label("Set up automations", systemImage: "bolt.badge.automatic")
                    }
                } header: {
                    Text("Guarded apps")
                        .pofuSectionHeader()
                } footer: {
                    Text("Turning an app off here doesn't remove its automation. Delete it in Shortcuts if you want me gone from that door.")
                }
                .listRowBackground(PofuColor.card)

                Section {
                    Label("Everything stays on this iPhone.", systemImage: "lock.shield")
                    if model.persistenceProblem {
                        Label("I couldn't save my last change. Free up some space?", systemImage: "exclamationmark.triangle")
                            .foregroundStyle(PofuColor.warning)
                    }
                } header: {
                    Text("Privacy")
                        .pofuSectionHeader()
                }
                .listRowBackground(PofuColor.card)
            }
            .navigationTitle(Text("Settings"))
            .pofuSheetChrome { model.setCompanionName(name) }
            .onAppear { name = model.profile.companionName }
            .onDisappear { model.setCompanionName(name) }
        }
    }
}

/// One app in the guarded list, with whether its automation works.
private struct GuardedAppRow: View {
    let model: AppModel
    let app: ProtectedApp

    @State private var isOn = false

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: PofuSpacing.xxs) {
                Text(verbatim: app.displayName)
                    .font(PofuFont.body)
                if isOn {
                    if model.profile.isVerified(app) {
                        Text("Working")
                            .font(PofuFont.footnote)
                            .foregroundStyle(PofuColor.success)
                    } else {
                        Text("Not set up yet")
                            .font(PofuFont.footnote)
                            .foregroundStyle(PofuColor.textSecondary)
                    }
                }
            }
        }
        .tint(PofuColor.accent)
        .onAppear { isOn = model.profile.protectedApps.contains(app) }
        .onChange(of: isOn) { _, value in
            model.setProtected(app, value)
        }
    }
}
