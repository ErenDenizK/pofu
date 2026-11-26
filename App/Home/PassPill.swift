import PofuCore
import PofuDesignSystem
import SwiftUI

/// A running pass on the world Home: a small glass pill with the app that
/// is open and the minutes left. Tapping it asks once, then ends the pass
/// and gives back the unused whole minutes. Shown only while a pass runs.
struct PassPill: View {
    let app: ProtectedApp?
    let fallbackName: String
    let minutesLeft: Int
    /// What ending now would give back; zero for a free pass.
    let refund: Energy
    let onEnd: () -> Void

    @State private var asking = false

    private var name: String { app?.displayName ?? fallbackName }

    var body: some View {
        Button {
            asking = true
        } label: {
            HStack(spacing: PofuSpacing.xs) {
                Image(systemName: app?.symbolName ?? "app")
                    .font(PofuFont.footnote)
                    .foregroundStyle(PofuColor.accent)
                    .accessibilityHidden(true)
                Text("\(name) · \(minutesLeft) min")
                    .font(PofuFont.footnote.monospacedDigit())
                    .foregroundStyle(PofuColor.textPrimary)
                    .lineLimit(1)
            }
            .padding(.horizontal, PofuSpacing.s)
            .frame(minHeight: PofuSize.minimumTouch)
            .glassEffect(.regular.interactive(), in: Capsule(style: .continuous))
            .contentShape(Capsule(style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("\(name) pass, \(minutesLeft) minutes left"))
        .accessibilityHint(Text("Ends the pass"))
        .confirmationDialog(Text("End the \(name) pass?"), isPresented: $asking, titleVisibility: .visible) {
            Button(role: .destructive, action: onEnd) {
                if refund > .zero {
                    Text("End now · +\(refund.units)")
                } else {
                    Text("End now")
                }
            }
            Button("Keep going", role: .cancel) {}
        }
    }
}

/// Home's pass pill, fed by the model: the soonest-ending running pass,
/// counting down. Nothing is drawn while no pass runs.
struct HomePassPill: View {
    let model: AppModel

    @State private var ended = 0

    var body: some View {
        TimelineView(.periodic(from: .now, by: 10)) { context in
            let date = model.modelTime(at: context.date)
            if let pass = model.activePasses.first(where: { $0.expiresAt > date }) {
                let remaining = max(0, pass.expiresAt.timeIntervalSince(date))
                PassPill(
                    app: ProtectedApp(rawValue: pass.target.rawValue),
                    fallbackName: pass.target.rawValue,
                    minutesLeft: max(1, Int((remaining / 60).rounded(.up))),
                    refund: model.economy.refund(for: pass, endingAt: date)
                ) {
                    model.endPass(pass)
                    ended += 1
                }
                .transition(.opacity)
            }
        }
        .sensoryFeedback(.success, trigger: ended)
    }
}
