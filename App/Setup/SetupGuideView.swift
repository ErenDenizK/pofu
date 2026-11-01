import PofuCore
import PofuDesignSystem
import SwiftUI

/// How to invite Pofu to an app's door: one Shortcuts personal automation
/// per app (ADR-0008). iOS does not let apps create automations, so this
/// is a guide, then a test that proves it works.
///
/// The labels quote the Shortcuts app in English (iOS 26); the Turkish
/// labels follow the user flows and still need checking on a device.
struct SetupGuideView: View {
    let model: AppModel

    @State private var selected: ProtectedApp?
    @State private var testFailed = false

    private var apps: [ProtectedApp] {
        let chosen = model.profile.protectedApps
        return chosen.isEmpty ? [.instagram, .youtube, .tiktok] : chosen
    }

    private var app: ProtectedApp {
        selected ?? model.unverifiedApps.first ?? apps.first ?? .instagram
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PofuSpacing.xl) {
                VStack(alignment: .leading, spacing: PofuSpacing.s) {
                    Text("About a minute per app, once.")
                        .font(PofuFont.subheadline)
                        .foregroundStyle(PofuColor.accent)
                    Text("iPhone only lets me appear if you invite me in the Shortcuts app. Make one automation for each app you want me at.")
                        .font(PofuFont.body)
                        .foregroundStyle(PofuColor.textPrimary)
                }

                appPicker

                VStack(alignment: .leading, spacing: PofuSpacing.m) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { item in
                        StepRow(number: item.offset + 1, text: item.element)
                    }
                }
                .pofuCard()

                status

                VStack(spacing: PofuSpacing.s) {
                    Button {
                        Task { await AppOpener.openShortcuts() }
                    } label: {
                        Text("Open Shortcuts")
                    }
                    .buttonStyle(PofuPrimaryButtonStyle())

                    if app.canBeOpenedByPofu {
                        Button {
                            Task {
                                testFailed = !(await AppOpener.open(app))
                            }
                        } label: {
                            Text("Test it: open \(app.objectName)")
                        }
                        .buttonStyle(PofuQuietButtonStyle())
                    }
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
        .navigationTitle(Text("Set up Hop!"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var appPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: PofuSpacing.s) {
                ForEach(apps) { item in
                    Button {
                        selected = item
                        testFailed = false
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

    private var steps: [Text] {
        let name = app.displayName
        return [
            Text("Open Shortcuts and tap **Automation** at the bottom."),
            Text("Tap **+** (or **New Automation**)."),
            Text("Scroll down and tap **App**."),
            Text("Tap **Choose**, pick **\(name)**, then **Done**. Keep **Is Opened** selected."),
            Text("Pick **Run Immediately** and turn **Notify When Run** off. Tap **Next**."),
            Text("Tap **New Blank Automation**, then **Add Action**. Search **Pofu** and tap **Hop in**."),
            Text("Tap **App** in the action and pick **\(name)**. Tap **Done**, then come back to me."),
        ]
    }
}

private struct StepRow: View {
    let number: Int
    let text: Text

    var body: some View {
        HStack(alignment: .top, spacing: PofuSpacing.m) {
            Text(number, format: .number)
                .font(PofuFont.headline.monospacedDigit())
                .foregroundStyle(PofuColor.accent)
                .frame(width: 28, height: 28)
                .background(Circle().fill(PofuColor.accentTint))
            text
                .font(PofuFont.body)
                .foregroundStyle(PofuColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}
