import PofuCore
import PofuDesignSystem
import PofuSound
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
                    SettingsHeader()
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)

                Section {
                    HStack(spacing: PofuSpacing.m) {
                        SettingsIcon(systemName: "pawprint.fill", tone: .honey)
                        TextField(text: $name, prompt: Text(verbatim: UserProfile.defaultName)) {
                            Text("Name")
                        }
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)
                        .onSubmit { model.setCompanionName(name) }
                    }
                } header: {
                    Text("Pofu")
                        .pofuSectionHeader()
                }
                .settingsRow()

                if model.screenTime.isAvailable {
                    ScreenTimeSettingsSection(model: model)
                }

                // The Shortcuts path is for the live build; Rehearsal has no doors to guard.
                if !model.screenTime.isRehearsal {
                    Section {
                        ForEach(ProtectedApp.offered) { app in
                            GuardedAppRow(model: model, app: app)
                        }
                        NavigationLink {
                            SetupGuideView(model: model)
                        } label: {
                            SettingsLabel("Set up automations", systemName: "wand.and.stars", tone: .moss)
                        }
                    } header: {
                        // With the shield, the Shortcuts gate is the optional,
                        // animated layer on top (ADR-0013).
                        if model.screenTime.isAvailable {
                            Text("Live Pofu (optional)")
                                .pofuSectionHeader()
                        } else {
                            Text("Guarded apps")
                                .pofuSectionHeader()
                        }
                    } footer: {
                        if model.screenTime.isAvailable {
                            Text("With a Shortcuts automation, I hop in with the full animation before the app opens. The shield stays as the safety net.")
                        } else {
                            Text("Turning an app off here doesn't remove its automation. Delete it in Shortcuts if you want me gone from that door.")
                        }
                    }
                    .settingsRow()
                }

                SoundSettingsSection()

                BreathSettingsSection()

                if DeveloperFlag.isOn {
                    RehearsalSettingsSection()
                }

                Section {
                    SettingsLabel("Everything stays on this iPhone.", systemName: "lock.fill", tone: .cocoa)
                    if model.persistenceProblem {
                        Label("I couldn't save my last change. Free up some space?", systemImage: "exclamationmark.triangle")
                            .foregroundStyle(PofuColor.warning)
                    }
                } header: {
                    Text("Privacy")
                        .pofuSectionHeader()
                }
                .settingsRow()
            }
            // The painted header carries the title; an empty bar title avoids a duplicate.
            .navigationTitle(Text(verbatim: ""))
            .navigationBarTitleDisplayMode(.inline)
            .settingsList()
            .pofuSheetChrome { model.setCompanionName(name) }
            .onAppear { name = model.profile.companionName }
            .onDisappear { model.setCompanionName(name) }
        }
    }
}

/// Pofu's tiny sounds: on by default; the Silent switch always wins.
private struct SoundSettingsSection: View {
    @State private var isOn = !SoundEngine.shared.settings.isMuted
    @State private var ambience = SoundEngine.shared.settings.isAmbienceOn

    var body: some View {
        Section {
            Toggle(isOn: Binding(
                get: { isOn },
                set: { value in
                    isOn = value
                    var settings = SoundEngine.shared.settings
                    settings.isMuted = !value
                    SoundEngine.shared.settings = settings
                }
            )) {
                SettingsLabel("Pofu's sounds", systemName: "speaker.wave.2.fill", tone: .honey)
            }
            Toggle(isOn: Binding(
                get: { ambience },
                set: { value in
                    ambience = value
                    var settings = SoundEngine.shared.settings
                    settings.isAmbienceOn = value
                    SoundEngine.shared.settings = settings
                }
            )) {
                SettingsLabel("Island ambience", systemName: "wind", tone: .honey)
            }
        } header: {
            Text("Sounds")
                .pofuSectionHeader()
        } footer: {
            Text("Tiny sounds while you play. Island ambience adds wind, crickets, rain and the breath's soft tone. They follow the Silent switch and stay under your music.")
        }
        .settingsRow()
    }
}

/// The breath: the Core Haptics swell during it (UI v3 section 4).
private struct BreathSettingsSection: View {
    @AppStorage(BreathHapticsSetting.key) private var breathHaptics = true

    var body: some View {
        Section {
            Toggle(isOn: $breathHaptics) {
                SettingsLabel("Breath haptics", systemName: "waveform.path", tone: .moss)
            }
        } header: {
            Text("Breath")
                .pofuSectionHeader()
        }
        .settingsRow()
    }
}

/// The developer switch for Rehearsal mode. It applies from the next
/// launch, because Rehearsal mode runs on its own store.
private struct RehearsalSettingsSection: View {
    @State private var isOn = RehearsalMode.isEnabled

    var body: some View {
        Section {
            Toggle(isOn: Binding(
                get: { isOn },
                set: { value in
                    isOn = value
                    RehearsalMode.setEnabled(value)
                }
            )) {
                SettingsLabel("Rehearsal mode", systemName: "theatermasks.fill", tone: .cocoa)
            }
            if isOn != RehearsalMode.isOnAtLaunch {
                Text("Close Pofu in the app switcher and open it again to switch.")
                    .font(PofuFont.footnote)
                    .foregroundStyle(PofuColor.warning)
            }
        } header: {
            Text("Developer")
                .pofuSectionHeader()
        } footer: {
            Text("Rehearsal mode simulates Screen Time inside Pofu: the permission, the app picker, the shield and usage. Its data is kept apart from live data and tagged as simulated.")
        }
        .settingsRow()
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
        .onAppear { isOn = model.profile.protectedApps.contains(app) }
        .onChange(of: isOn) { _, value in
            model.setProtected(app, value)
        }
    }
}
