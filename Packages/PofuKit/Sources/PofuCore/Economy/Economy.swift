import Foundation

/// A priced offer for one unlock window, valid at the instant it was quoted.
public struct UnlockQuote: Hashable, Sendable {
    public let minutes: Int
    public let quotedAt: Date
    /// `minutes × pricePerMinute`, before multipliers.
    public let basePrice: Energy
    /// Paid unlocks inside the rolling escalation window before this one.
    public let escalationSteps: Int
    /// Whether the quote falls inside the bedtime window.
    public let isNight: Bool
    /// What the unlock costs: the base price times every multiplier,
    /// rounded up to a whole unit.
    public let price: Energy
}

/// Why spending failed.
public enum SpendError: Error, Hashable, Sendable {
    /// The requested window length is not on offer.
    case unsupportedDuration(minutes: Int)
    /// The balance cannot cover the price.
    case insufficientBalance(required: Energy, available: Energy)
}

/// The rules of Pofu's economy, applied to a `Wallet`.
///
/// `Economy` is stateless: a configuration plus the calendar that defines
/// local days and the bedtime window. Every operation takes the time it
/// happens at explicitly. The rules are documented in
/// `docs/product/economy.md`.
public struct Economy: Sendable {
    public let configuration: EconomyConfiguration
    public let calendar: Calendar

    /// Days of per-day history kept in the wallet. Activities and step
    /// totals for older days are not credited.
    public static let historyRetentionDays = 7

    public init(configuration: EconomyConfiguration = .standard, calendar: Calendar) {
        self.configuration = configuration
        self.calendar = calendar
    }

    /// The local day containing `date`.
    public func day(of date: Date) -> LocalDay {
        LocalDay(containing: date, in: calendar)
    }

    // MARK: - Daily allowance

    /// Grants the daily allowance if `date` falls on a later local day than
    /// the last grant, and prunes old history.
    ///
    /// Every mutating operation calls this first, so the allowance arrives
    /// with the first interaction of each day. Days the user was away are
    /// not back-filled: the allowance is a floor that keeps the user from
    /// being stuck, not income that accrues. A clock that moves backwards
    /// never grants twice.
    ///
    /// - Returns: The energy granted, zero when already granted today.
    @discardableResult
    public func openDay(_ wallet: inout Wallet, at date: Date) -> Energy {
        let today = day(of: date)
        if let last = wallet.lastAllowanceDay, today <= last {
            return .zero
        }
        wallet.lastAllowanceDay = today
        wallet.balance += max(configuration.dailyAllowance, .zero)
        pruneHistory(of: &wallet, newestDay: today)
        return max(configuration.dailyAllowance, .zero)
    }

    // MARK: - Earning

    /// What `session` is worth before the honor cap.
    public func grossEnergy(for session: ActivitySession) -> Energy {
        let rules = configuration.earning
        let multiplier = session.verification.isVerified ? rules.verifiedMultiplier : 1
        let value = Double(session.wholeMinutes) * rules.energyPerMinute * multiplier
        return Energy(max(0, Rounding.down(value)))
    }

    /// Credits a completed activity to the day it ended on.
    ///
    /// Honor-system activities are capped per day; what exceeds the cap is
    /// forfeited and reported in the result. Verified activities are never
    /// capped.
    @discardableResult
    public func earn(_ session: ActivitySession, into wallet: inout Wallet) -> EarningResult {
        openDay(&wallet, at: session.endedAt)
        let creditDay = self.day(of: session.endedAt)
        guard !isStale(creditDay, in: wallet) else {
            return EarningResult(earned: .zero, wasStale: true)
        }

        let gross = grossEnergy(for: session)
        var earned = gross
        if session.verification == .honor {
            let already = wallet.honorEnergy(on: creditDay)
            let room = max(configuration.earning.honorDailyCap - already, .zero)
            earned = min(gross, room)
            wallet.honorEarnedByDay[creditDay] = already + earned
        }
        credit(earned, on: creditDay, to: &wallet)
        return EarningResult(earned: earned, forfeitedToCap: gross - earned)
    }

    /// Credits passively counted steps.
    ///
    /// `dailyTotal` is the cumulative step count of the local day containing
    /// `date`, as health data reports it. Only the energy not yet credited
    /// for that day is granted, so the same total can be reported any number
    /// of times. A total that shrinks (a data correction) never takes energy
    /// back. Steps are passive by nature and are not subject to the honor
    /// cap or the verified multiplier; their rate is `stepsPerEnergy`.
    ///
    /// - Returns: The energy granted by this call.
    @discardableResult
    public func creditSteps(dailyTotal: Int, on date: Date, into wallet: inout Wallet) -> Energy {
        openDay(&wallet, at: date)
        let stepDay = self.day(of: date)
        guard !isStale(stepDay, in: wallet) else {
            return .zero
        }
        let owed = Energy(max(0, dailyTotal) / max(1, configuration.earning.stepsPerEnergy))
        let already = wallet.stepEnergyByDay[stepDay, default: .zero]
        guard owed > already else {
            return .zero
        }
        wallet.stepEnergyByDay[stepDay] = owed
        let grant = owed - already
        credit(grant, on: stepDay, to: &wallet)
        return grant
    }

    // MARK: - Spending

    /// Paid unlocks in the rolling escalation window ending at `date`:
    /// purchases at instants in `(date - window, date]`.
    public func escalationSteps(for wallet: Wallet, at date: Date) -> Int {
        let windowStart = date.addingTimeInterval(-configuration.spending.escalationWindow)
        return wallet.unlockPurchases.filter { $0 > windowStart && $0 <= date }.count
    }

    /// Whether `date` falls inside the bedtime window.
    public func isBedtime(_ date: Date) -> Bool {
        configuration.spending.bedtime.contains(date, in: calendar)
    }

    /// Prices an unlock window of `minutes` at `date`.
    ///
    /// `price = ⌈minutes × pricePerMinute × escalation^steps × night⌉`,
    /// where rounding up happens once, after every multiplier.
    public func quote(minutes: Int, at date: Date, for wallet: Wallet) throws -> UnlockQuote {
        let rules = configuration.spending
        guard minutes > 0, rules.unlockDurations.contains(minutes) else {
            throw SpendError.unsupportedDuration(minutes: minutes)
        }
        let basePrice = Energy(minutes * max(rules.pricePerMinute.units, 0))
        let steps = escalationSteps(for: wallet, at: date)
        let night = isBedtime(date)
        var multiplier = pow(max(rules.escalationMultiplier, 0), Double(steps))
        if night {
            multiplier *= max(rules.nightMultiplier, 0)
        }
        let price = Energy(max(0, Rounding.up(Double(basePrice.units) * multiplier)))
        return UnlockQuote(
            minutes: minutes,
            quotedAt: date,
            basePrice: basePrice,
            escalationSteps: steps,
            isNight: night,
            price: price
        )
    }

    /// Quotes for every window on offer, shortest first.
    public func quotes(at date: Date, for wallet: Wallet) -> [UnlockQuote] {
        Set(configuration.spending.unlockDurations)
            .sorted()
            .compactMap { try? quote(minutes: $0, at: date, for: wallet) }
    }

    /// The cheapest unlock on offer at `date`, or `nil` when none is
    /// configured.
    public func cheapestQuote(at date: Date, for wallet: Wallet) -> UnlockQuote? {
        quotes(at: date, for: wallet).min { $0.price < $1.price }
    }

    /// Whether the balance at `date`, including today's allowance if not yet
    /// granted, covers at least one unlock window.
    public func canAffordAnyUnlock(_ wallet: Wallet, at date: Date) -> Bool {
        var projected = wallet
        openDay(&projected, at: date)
        guard let cheapest = cheapestQuote(at: date, for: projected) else {
            return false
        }
        return projected.balance >= cheapest.price
    }

    /// Buys an unlock window of `minutes` for `target`, starting at `date`.
    ///
    /// - Throws: `SpendError` when the duration is not on offer or the
    ///   balance cannot cover the price. The wallet is not charged then,
    ///   although today's allowance may have been granted.
    public func purchaseUnlock(
        minutes: Int,
        for target: TargetGroupID,
        at date: Date,
        from wallet: inout Wallet,
        passID: UUID = UUID()
    ) throws -> Pass {
        openDay(&wallet, at: date)
        let offer = try self.quote(minutes: minutes, at: date, for: wallet)
        guard wallet.balance >= offer.price else {
            throw SpendError.insufficientBalance(required: offer.price, available: wallet.balance)
        }
        wallet.balance -= offer.price
        wallet.unlockPurchases.append(date)
        let windowStart = date.addingTimeInterval(-configuration.spending.escalationWindow)
        wallet.unlockPurchases.removeAll { $0 <= windowStart }
        return Pass(
            id: passID,
            target: target,
            grantedAt: date,
            minutes: minutes,
            source: .purchased(price: offer.price)
        )
    }

    // MARK: - Emergency pass

    /// Whether the free emergency pass can be used at `date`: once per
    /// local day, and never twice when the clock moves backwards.
    public func isEmergencyPassAvailable(in wallet: Wallet, at date: Date) -> Bool {
        guard configuration.friction.emergencyPassMinutes > 0 else { return false }
        guard let last = wallet.lastEmergencyPassDay else { return true }
        return day(of: date) > last
    }

    /// The first local day on which the emergency pass is available again.
    public func nextEmergencyPassDay(for wallet: Wallet, at date: Date) -> LocalDay {
        let today = day(of: date)
        guard let last = wallet.lastEmergencyPassDay, !isEmergencyPassAvailable(in: wallet, at: date) else {
            return today
        }
        return max(today, last).adding(days: 1)
    }

    /// Grants the free emergency pass for `target` at `date`, or returns
    /// `nil` when today's pass is already used. It costs nothing and does
    /// not count toward price escalation.
    public func grantEmergencyPass(
        for target: TargetGroupID,
        at date: Date,
        from wallet: inout Wallet,
        passID: UUID = UUID()
    ) -> Pass? {
        openDay(&wallet, at: date)
        guard isEmergencyPassAvailable(in: wallet, at: date) else { return nil }
        wallet.lastEmergencyPassDay = day(of: date)
        return Pass(
            id: passID,
            target: target,
            grantedAt: date,
            minutes: configuration.friction.emergencyPassMinutes,
            source: .emergency
        )
    }

    // MARK: - Refunds

    /// What ending `pass` at `date` gives back: every unused whole minute at
    /// the per-minute price actually paid, rounded down.
    ///
    /// `refund = ⌊unusedWholeMinutes × price ÷ minutes⌋`. Only purchased
    /// passes refund; free, friend-approved, and emergency passes return
    /// nothing. A pass that is not valid at `date` refunds nothing.
    public func refund(for pass: Pass, endingAt date: Date) -> Energy {
        guard case .purchased(let price) = pass.source, pass.isValid(at: date) else {
            return .zero
        }
        let minutes = pass.durationMinutes
        guard minutes > 0, price > .zero else { return .zero }
        // A millisecond of tolerance keeps exact minute boundaries whole
        // despite floating-point dates.
        let unused = min(minutes, Rounding.saturatingInt(((pass.remaining(at: date) + 0.001) / 60).rounded(.down)))
        return Energy(min(price.units, max(0, unused) * price.units / minutes))
    }

    /// Returns `energy` to the balance. Refunds are not activity: they
    /// neither feed vitality nor count toward the honor cap.
    func creditRefund(_ energy: Energy, to wallet: inout Wallet) {
        guard energy > .zero else { return }
        wallet.balance += energy
    }

    /// Undoes a purchase that never got used (the app could not be opened):
    /// the full price comes back and the purchase stops escalating prices.
    /// An emergency pass becomes available again.
    ///
    /// - Returns: The energy refunded.
    func void(_ pass: Pass, in wallet: inout Wallet) -> Energy {
        switch pass.source {
        case .purchased(let price):
            if let index = wallet.unlockPurchases.lastIndex(of: pass.grantedAt) {
                wallet.unlockPurchases.remove(at: index)
            }
            let refund = max(price, .zero)
            creditRefund(refund, to: &wallet)
            return refund
        case .emergency:
            if wallet.lastEmergencyPassDay == day(of: pass.grantedAt) {
                wallet.lastEmergencyPassDay = nil
            }
            return .zero
        case .free, .friendApproved:
            return .zero
        }
    }

    // MARK: - Private

    private func credit(_ energy: Energy, on day: LocalDay, to wallet: inout Wallet) {
        guard energy > .zero else { return }
        wallet.balance += energy
        wallet.activityEnergyByDay[day] = wallet.activityEnergy(on: day) + energy
    }

    /// A day is stale when it is older than the retained history, measured
    /// from the newest day the wallet has seen.
    private func isStale(_ day: LocalDay, in wallet: Wallet) -> Bool {
        guard let newest = wallet.lastAllowanceDay else { return false }
        return day < newest.adding(days: -Economy.historyRetentionDays)
    }

    private func pruneHistory(of wallet: inout Wallet, newestDay: LocalDay) {
        let cutoff = newestDay.adding(days: -Economy.historyRetentionDays)
        wallet.honorEarnedByDay = wallet.honorEarnedByDay.filter { $0.key >= cutoff }
        wallet.stepEnergyByDay = wallet.stepEnergyByDay.filter { $0.key >= cutoff }
        wallet.activityEnergyByDay = wallet.activityEnergyByDay.filter { $0.key >= cutoff }
    }
}
