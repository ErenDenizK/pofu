import PofuCompanion
import PofuCore
import PofuDesignSystem
import PofuScreenTime
import SwiftUI

/// Placeholder home screen. It shows the economy running for real on the
/// simulated Screen Time service, with the motion-system prototype of Pofu
/// (placeholder art) whose cheeks fill with the energy balance.
struct RootView: View {
    let model: AppModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var celebrations = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PofuSpacing.l) {
                header
                CompanionView(vitality: 0.8, energy: cheekFill, celebrations: celebrations)
                    .frame(maxWidth: 260)
                    .frame(maxWidth: .infinity)
                balanceCard
                unlockCard
                screenTimeCard
                Text("Pofu's home is still being built. The numbers above already run on the real economy engine.")
                    .font(PofuFont.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, PofuSpacing.xs)
            }
            .padding(PofuSpacing.l)
        }
        .background(PofuColor.dayWash.ignoresSafeArea())
        .task {
            await model.refresh()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task { await model.refresh() }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: PofuSpacing.xs) {
            Text(verbatim: "Pofu")
                .font(PofuFont.largeTitle)
            Text("Engineering preview")
                .font(PofuFont.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.top, PofuSpacing.xl)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    private var balanceCard: some View {
        VStack(alignment: .leading, spacing: PofuSpacing.m) {
            Label("Today's balance", systemImage: "bolt.fill")
                .font(PofuFont.headline)
                .foregroundStyle(PofuColor.accent)
            HStack(alignment: .firstTextBaseline, spacing: PofuSpacing.s) {
                Text(model.balance.units, format: .number)
                    .font(PofuFont.numeral)
                    .contentTransition(.numericText())
                Text("energy")
                    .font(PofuFont.headline)
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            Text("Every day starts with \(model.dailyAllowance.units) energy on the house.")
                .font(PofuFont.caption)
                .foregroundStyle(.secondary)
            Text("You resisted \(model.impulsesToday.resisted) times today.")
                .font(PofuFont.caption)
                .foregroundStyle(.secondary)
            Button("Log a 20-minute walk", systemImage: "figure.walk") {
                withAnimation(PofuMotion.squish) {
                    model.logDemoWalk()
                }
                celebrations += 1
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, PofuSpacing.xs)
        }
        .pofuCard()
    }

    /// Cheek-pouch fill: the balance against two days of allowance.
    private var cheekFill: Double {
        let capacity = max(1, model.dailyAllowance.units * 2)
        return min(1, Double(max(0, model.balance.units)) / Double(capacity))
    }

    private var unlockCard: some View {
        VStack(alignment: .leading, spacing: PofuSpacing.s) {
            Label("Next unlock", systemImage: "lock.open.fill")
                .font(PofuFont.headline)
                .foregroundStyle(PofuColor.accent)
            if let quote = model.nextUnlock {
                Text("\(quote.minutes) minutes for \(quote.price.units) energy")
                    .font(PofuFont.body)
                if quote.isNight {
                    Text("Night pricing is on until morning.")
                        .font(PofuFont.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .pofuCard()
    }

    private var screenTimeCard: some View {
        HStack(alignment: .center, spacing: PofuSpacing.m) {
            VStack(alignment: .leading, spacing: PofuSpacing.xs) {
                Label("Screen Time", systemImage: "hourglass")
                    .font(PofuFont.headline)
                    .foregroundStyle(PofuColor.accent)
                Text(screenTimeStatusText)
                    .font(PofuFont.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: PofuSpacing.s)
            if model.screenTimeStatus == .notDetermined {
                Button("Connect") {
                    Task { await model.connectScreenTime() }
                }
                .buttonStyle(.bordered)
            }
        }
        .pofuCard()
    }

    private var screenTimeStatusText: LocalizedStringKey {
        switch model.screenTimeStatus {
        case .notDetermined:
            "Simulated, not connected yet"
        case .approved:
            "Simulated, connected"
        case .denied:
            "Simulated, access declined"
        }
    }
}

#Preview {
    RootView(model: AppModel())
}
