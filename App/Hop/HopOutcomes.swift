import PofuCompanion
import PofuCore
import PofuDesignSystem
import SwiftUI

/// The skip celebration: Pofu hops, a bead drops into today's row, and the
/// count rolls up. Resisting earns no seeds; it earns fluff.
struct HopSkipped: View {
    let model: AppModel
    let session: HopSession
    let skipsToday: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var celebrations = 0
    @State private var showsBeads = false

    var body: some View {
        VStack(spacing: PofuSpacing.l) {
            Spacer(minLength: PofuSpacing.l)
            VStack(spacing: PofuSpacing.xs) {
                Text("Skipped.")
                    .pofuDisplayFont()
                    .foregroundStyle(PofuColor.accent)
                Text("That's \(skipsToday) today.")
                    .font(PofuFont.title2)
                    .foregroundStyle(PofuColor.textPrimary)
                    .contentTransition(.numericText(value: Double(skipsToday)))
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)

            BeadRow(skipped: visibleBeads.map { $0 == .skipped })
                .padding(.horizontal, PofuSpacing.screen)
                .animation(PofuMotion.respecting(reduceMotion, PofuMotion.hop), value: showsBeads)

            Spacer(minLength: PofuSpacing.s)

            VStack(spacing: PofuSpacing.s) {
                SpeechBubble {
                    Text(session.isNight ? "Goodnight. See you in the morning." : PofuLines.skipped(skipsToday))
                }
                CompanionView(vitality: model.vitality, energy: model.cheekFill, celebrations: celebrations)
                    .frame(maxWidth: 240)
            }

            Spacer(minLength: PofuSpacing.l)

            HStack(spacing: PofuSpacing.s) {
                Button("Start a focus") {
                    model.dismissHop()
                    model.requestHomeSheet(.earn)
                }
                .buttonStyle(PofuQuietButtonStyle())
                Button("Back to my room") {
                    model.dismissHop()
                }
                .buttonStyle(PofuQuietButtonStyle())
            }
            .padding(.horizontal, PofuSpacing.screen)

            VStack(spacing: PofuSpacing.xxs) {
                Image(systemName: "chevron.up")
                    .accessibilityHidden(true)
                Text("Swipe up when you're ready.")
            }
            .font(PofuFont.footnote)
            .foregroundStyle(PofuColor.textSecondary)
            .padding(.bottom, PofuSpacing.s)
        }
        .sensoryFeedback(.success, trigger: celebrations)
        .task {
            // Night skips only smile; daytime skips hop (user flows).
            if !session.isNight {
                celebrations += 1
            }
            try? await Task.sleep(for: .milliseconds(250))
            showsBeads = true
        }
    }

    /// Today's beads; the newest one drops in after a beat.
    private var visibleBeads: [ImpulseBead] {
        let beads = model.beadsToday
        return showsBeads ? beads : Array(beads.dropLast())
    }
}

/// The hand-off: confirm the pass, then open the app.
struct HopHandoff: View {
    let model: AppModel
    let session: HopSession
    let pass: Pass

    @State private var opened = 0

    var body: some View {
        VStack(spacing: PofuSpacing.l) {
            Spacer()
            SpeechBubble {
                if session.app.canBeOpenedByPofu {
                    Text("Enjoy. See you in \(pass.durationMinutes) min.")
                } else {
                    Text("Go ahead and open it. Your pass is running.")
                }
            }
            CompanionView(vitality: model.vitality, energy: model.cheekFill)
                .frame(maxWidth: 220)
            HStack(spacing: PofuSpacing.s) {
                Image(systemName: session.app.symbolName)
                    .foregroundStyle(PofuColor.accent)
                Text("\(session.app.displayName) · \(pass.durationMinutes) min pass")
            }
            .font(PofuFont.headline)
            .foregroundStyle(PofuColor.textSecondary)
            .padding(.horizontal, PofuSpacing.l)
            .padding(.vertical, PofuSpacing.s)
            .background(Capsule(style: .continuous).fill(PofuColor.raised.opacity(0.8)))
            .accessibilityElement(children: .combine)
            Spacer()
            if !session.app.canBeOpenedByPofu {
                Button("Done") {
                    model.dismissHop()
                }
                .buttonStyle(PofuPrimaryButtonStyle())
                .padding(.horizontal, PofuSpacing.screen)
                .padding(.bottom, PofuSpacing.l)
            }
        }
        .sensoryFeedback(.selection, trigger: opened)
        .task {
            opened += 1
            // The first pass asks for notifications; hand off only once the
            // user has answered.
            await model.passReminderReady()
            guard session.app.canBeOpenedByPofu else { return }
            // A beat to read the line, then back to the app (user flows).
            try? await Task.sleep(for: .milliseconds(600))
            guard !Task.isCancelled else { return }
            if !(await AppOpener.open(session.app)) {
                model.handoffFailed(for: pass, app: session.app)
            }
        }
    }
}

/// The app could not be opened: say so plainly and give the seeds back.
struct HopHandoffFailed: View {
    let model: AppModel
    let session: HopSession
    let refund: Energy

    var body: some View {
        VStack(spacing: PofuSpacing.l) {
            Spacer()
            SpeechBubble {
                Text("I couldn't open \(session.app.objectName). Is it still installed?")
            }
            CompanionView(vitality: model.vitality, energy: model.cheekFill)
                .frame(maxWidth: 200)
            if refund > .zero {
                Text("Your \(refund.units) seeds are back in my cheeks.")
                    .font(PofuFont.callout)
                    .foregroundStyle(PofuColor.textSecondary)
            }
            Spacer()
            Button("Back to my room") {
                model.dismissHop()
            }
            .buttonStyle(PofuPrimaryButtonStyle())
            .padding(.horizontal, PofuSpacing.screen)
            .padding(.bottom, PofuSpacing.l)
        }
    }
}
