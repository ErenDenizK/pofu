import PofuCore
import PofuDesignSystem
import SwiftUI

/// The passes sheet: what is open right now, ending a pass early for a
/// refund, and the price rules in plain words.
struct PassesSheet: View {
    let model: AppModel

    @State private var lastRefund: Energy?
    @State private var ended = 0

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        SeedPill(count: model.balance.units)
                        Spacer()
                        Text("in my cheeks")
                            .font(PofuFont.callout)
                            .foregroundStyle(PofuColor.textSecondary)
                    }
                    .listRowBackground(PofuColor.card)
                }

                Section {
                    if model.activePasses.isEmpty {
                        Text("No passes running. Every app is guarded.")
                            .font(PofuFont.body)
                            .foregroundStyle(PofuColor.textSecondary)
                    } else {
                        ForEach(model.activePasses) { pass in
                            PassRow(model: model, pass: pass) { refund in
                                lastRefund = refund
                                ended += 1
                            }
                        }
                    }
                    if let lastRefund {
                        Group {
                            if lastRefund > .zero {
                                Text("Pass ended. \(lastRefund.units) seeds came back.")
                            } else {
                                Text("Pass ended. The app is guarded again.")
                            }
                        }
                        .font(PofuFont.footnote)
                        .foregroundStyle(PofuColor.success)
                    }
                } header: {
                    Text("Running now")
                        .pofuSectionHeader()
                } footer: {
                    Text("Ending a pass early gives back every unused whole minute at the price you paid.")
                }
                .listRowBackground(PofuColor.card)
            }
            .navigationTitle(Text("Passes"))
            .pofuSheetChrome()
            .sensoryFeedback(.success, trigger: ended)
        }
    }
}

private struct PassRow: View {
    let model: AppModel
    let pass: Pass
    let onEnd: (Energy) -> Void

    private var app: ProtectedApp? {
        ProtectedApp(rawValue: pass.target.rawValue)
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let date = model.modelTime(at: context.date)
            let remaining = max(0, pass.expiresAt.timeIntervalSince(date))
            let refund = model.economy.refund(for: pass, endingAt: date)
            HStack(spacing: PofuSpacing.m) {
                Image(systemName: app?.symbolName ?? "app")
                    .foregroundStyle(PofuColor.accent)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(PofuColor.accentTint))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: PofuSpacing.xxs) {
                    Text(verbatim: app?.displayName ?? pass.target.rawValue)
                        .font(PofuFont.headline)
                        .foregroundStyle(PofuColor.textPrimary)
                    Text(Duration.seconds(remaining.rounded(.up)), format: .time(pattern: .minuteSecond))
                        .font(PofuFont.subheadline.monospacedDigit())
                        .foregroundStyle(PofuColor.textSecondary)
                }
                Spacer()
                Button {
                    onEnd(model.endPass(pass))
                } label: {
                    if refund > .zero {
                        Text("End now · +\(refund.units)")
                    } else {
                        Text("End now")
                    }
                }
                .buttonStyle(PofuSecondaryButtonStyle())
            }
        }
    }
}
