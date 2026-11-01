import PofuCore
import PofuDesignSystem
import SwiftUI

/// The pay rung: four windows priced by the economy, the balance before
/// and after, and the honest reason when prices are up.
struct PayRung: View {
    let model: AppModel
    let session: HopSession
    @Binding var selectedMinutes: Int?

    private var quotes: [UnlockQuote] {
        model.economy.quotes(at: model.now, for: model.state.wallet)
    }

    private var balance: Int { model.balance.units }

    private var selectedQuote: UnlockQuote? {
        Self.quote(model: model, selectedMinutes: selectedMinutes)
    }

    /// The window the spend action buys: the user's pick, else 10 minutes
    /// when affordable, else the longest affordable window.
    static func quote(model: AppModel, selectedMinutes: Int?) -> UnlockQuote? {
        let quotes = model.economy.quotes(at: model.now, for: model.state.wallet)
        let affordable = quotes.filter { $0.price <= model.balance }
        if let selectedMinutes, let pick = affordable.first(where: { $0.minutes == selectedMinutes }) {
            return pick
        }
        return affordable.first { $0.minutes == 10 } ?? affordable.last
    }

    var body: some View {
        VStack(spacing: PofuSpacing.m) {
            if let quote = selectedQuote {
                HStack(spacing: PofuSpacing.xs) {
                    SeedIcon(size: 14)
                    Text("\(balance) in my cheeks · \(balance - quote.price.units) after")
                }
                .font(PofuFont.subheadline)
                .foregroundStyle(PofuColor.textSecondary)
                .accessibilityElement(children: .combine)
            }

            HStack(spacing: PofuSpacing.s) {
                ForEach(quotes, id: \.minutes) { quote in
                    windowCard(quote)
                }
            }

            if let first = quotes.first, first.escalationSteps > 0 {
                Text("You bought a pass in the last 3 hours, so prices are up a bit.")
                    .font(PofuFont.footnote)
                    .foregroundStyle(PofuColor.textSecondary)
                    .multilineTextAlignment(.center)
            }
            if session.isNight {
                Label("Night prices until 06:00", systemImage: "moon.fill")
                    .font(PofuFont.footnote)
                    .foregroundStyle(PofuColor.textSecondary)
            }

            EmergencyPassButton(model: model)
        }
    }

    private func windowCard(_ quote: UnlockQuote) -> some View {
        let affordable = quote.price.units <= balance
        let isSelected = selectedQuote?.minutes == quote.minutes
        return Button {
            selectedMinutes = quote.minutes
        } label: {
            VStack(spacing: PofuSpacing.xs) {
                Text("\(quote.minutes) min")
                    .font(PofuFont.subheadline)
                HStack(spacing: PofuSpacing.xxs) {
                    SeedIcon(size: 13)
                    Text(quote.price.units, format: .number)
                        .font(PofuFont.title3.monospacedDigit())
                }
                if !affordable {
                    Text("need \(quote.price.units - balance) more")
                        .font(PofuFont.caption)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            .padding(.vertical, PofuSpacing.xs)
        }
        .buttonStyle(PofuChoiceStyle(isSelected: isSelected, cornerRadius: PofuRadius.medium))
        .disabled(!affordable)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// The ask-a-friend rung, before friends exist: an honest placeholder, the
/// way to earn seeds, the emergency pass, and when the gate is free again.
struct FriendRung: View {
    let model: AppModel
    let session: HopSession

    var body: some View {
        VStack(spacing: PofuSpacing.m) {
            HStack(alignment: .top, spacing: PofuSpacing.m) {
                Image(systemName: "person.2.fill")
                    .font(PofuFont.title3)
                    .foregroundStyle(PofuColor.accent)
                    .frame(width: 48, height: 48)
                    .background(Circle().fill(PofuColor.accentTint))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: PofuSpacing.xs) {
                    Text("Asking a friend is coming soon.")
                        .font(PofuFont.headline)
                        .foregroundStyle(PofuColor.textPrimary)
                    Text("Soon a friend you trust can say yes to a few minutes for you.")
                        .font(PofuFont.callout)
                        .foregroundStyle(PofuColor.textSecondary)
                }
            }
            .pofuCard()

            Button {
                model.skipHopAndEarn()
            } label: {
                Label {
                    Text("Or earn seeds with a focus")
                } icon: {
                    SeedIcon(size: 16)
                }
            }
            .font(PofuFont.headline)
            .foregroundStyle(PofuColor.accent)
            .frame(minHeight: PofuSize.minimumTouch)

            if let minutes = minutesUntilFree, minutes > 0 {
                Text("Free again in \(minutes) min.")
                    .font(PofuFont.footnote)
                    .foregroundStyle(PofuColor.textSecondary)
            }
        }
    }

    /// When the ladder resets to the free pause rung: one cooldown after
    /// this reach.
    private var minutesUntilFree: Int? {
        let cooldown = model.economy.configuration.friction.cooldown
        let resetsAt = session.attempt.attemptedAt.addingTimeInterval(cooldown)
        let seconds = resetsAt.timeIntervalSince(model.now)
        guard seconds > 0 else { return nil }
        return Int((seconds / 60).rounded(.up))
    }
}

/// The daily emergency pass, on the pay and ask-friend rungs.
struct EmergencyPassButton: View {
    let model: AppModel
    /// The friend rung's secondary action; elsewhere a quiet text button.
    var isProminent = false

    var body: some View {
        let minutes = model.economy.configuration.friction.emergencyPassMinutes
        if model.economy.isEmergencyPassAvailable(in: model.state.wallet, at: model.now) {
            if isProminent {
                button(minutes: minutes)
                    .buttonStyle(PofuQuietButtonStyle())
            } else {
                button(minutes: minutes)
                    .font(PofuFont.subheadline)
                    .foregroundStyle(PofuColor.accent)
                    .frame(minHeight: PofuSize.minimumTouch)
            }
        } else if minutes > 0 {
            Text("Today's emergency pass is used. It's back tomorrow.")
                .font(PofuFont.footnote)
                .foregroundStyle(PofuColor.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private func button(minutes: Int) -> some View {
        Button {
            model.openFromHop(with: .emergency)
        } label: {
            Text("Emergency: open for \(minutes) min, free")
        }
        .accessibilityHint(Text("Once a day, for when you really need the app."))
    }
}
