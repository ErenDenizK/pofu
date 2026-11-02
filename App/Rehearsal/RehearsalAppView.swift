import PofuCore
import PofuDesignSystem
import SwiftUI

/// Inside a guarded app, in Rehearsal mode: a stand-in feed, the time the
/// pass has left, and the way home. While it is on screen the pass's
/// monitor runs, so the shield comes back the moment the pass ends.
struct RehearsalAppView: View {
    let model: AppModel
    let app: ProtectedApp

    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()
            VStack(spacing: PofuSpacing.m) {
                RehearsalBadge(text: Text("Rehearsal: a stand-in for the app"))
                    .padding(.top, PofuSpacing.s)
                header
                passTimer
                feed
                Button {
                    model.rehearsalGoHome()
                } label: {
                    Text("Back to the Home Screen")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PofuSecondaryButtonStyle())
                .padding(.bottom, PofuSpacing.s)
            }
            .padding(.horizontal, PofuSpacing.screen)
        }
        .task {
            // The pass's monitor: checks every second for its end.
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                model.rehearsalTick()
            }
        }
    }

    private var header: some View {
        HStack(spacing: PofuSpacing.s) {
            Image(systemName: app.symbolName)
                .font(PofuFont.title3)
                .accessibilityHidden(true)
            Text(verbatim: app.displayName)
                .font(PofuFont.title2)
            Spacer()
        }
        .foregroundStyle(PofuColor.textPrimary)
    }

    /// The pass or quick check that let the user in, counting down.
    @ViewBuilder private var passTimer: some View {
        if let rehearsal = model.rehearsal, let shielded = rehearsal.system.shieldedApp(for: app) {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let now = model.modelTime(at: context.date)
                if let lift = rehearsal.system.activeLift(for: shielded, at: now) {
                    let remaining = Int(max(0, lift.until.timeIntervalSince(now)).rounded(.up))
                    Label {
                        Text(verbatim: String(format: "%d:%02d", remaining / 60, remaining % 60))
                            .monospacedDigit()
                    } icon: {
                        Image(systemName: "hourglass")
                    }
                    .font(PofuFont.headline)
                    .foregroundStyle(PofuColor.accent)
                    .accessibilityLabel(Text("\(remaining / 60) min left"))
                }
            }
            .id(rehearsal.jumps)
        }
    }

    private var feed: some View {
        ScrollView {
            VStack(spacing: PofuSpacing.m) {
                ForEach(0..<6, id: \.self) { index in
                    RoundedRectangle(cornerRadius: PofuRadius.medium, style: .continuous)
                        .fill(PofuColor.sunken)
                        .frame(height: index.isMultiple(of: 2) ? 220 : 120)
                }
            }
        }
        .scrollIndicators(.hidden)
        .accessibilityHidden(true)
    }
}
