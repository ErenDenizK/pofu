import Foundation

/// The complete persisted domain state of one user.
public struct PofuState: Hashable, Sendable {
    public var wallet: Wallet
    public var ladder: FrictionLadder
    public var passes: PassLedger
    public var checkIns: [CheckInRecord]
    /// Opens a valid pass let through silently.
    public var passThroughs: [PassThrough]
    /// The companion's settled vitality and its daily history.
    public var vitality: VitalityLedger
    /// Quiet-time earning: the current quiet stretch and the seeds waiting
    /// in Pofu's cheeks (ADR-0014).
    public var quietTime: QuietTimeLedger

    public init(
        wallet: Wallet = Wallet(),
        ladder: FrictionLadder = FrictionLadder(),
        passes: PassLedger = PassLedger(),
        checkIns: [CheckInRecord] = [],
        passThroughs: [PassThrough] = [],
        vitality: VitalityLedger = VitalityLedger(),
        quietTime: QuietTimeLedger = QuietTimeLedger()
    ) {
        self.wallet = wallet
        self.ladder = ladder
        self.passes = passes
        self.checkIns = checkIns
        self.passThroughs = passThroughs
        self.vitality = vitality
        self.quietTime = quietTime
    }

    /// Days of check-in and pass-through history kept, which covers the
    /// free seven-day history with room to spare.
    public static let historyRetentionDays = 35

    /// Drops check-ins and pass-throughs older than the retained history,
    /// counted back from `day`.
    public mutating func pruneHistory(newestDay day: LocalDay, calendar: Calendar) {
        let cutoff = day.adding(days: -Self.historyRetentionDays)
        checkIns.removeAll { LocalDay(containing: $0.attemptedAt, in: calendar) < cutoff }
        passThroughs.removeAll { LocalDay(containing: $0.at, in: calendar) < cutoff }
    }
}

extension PofuState: Codable {
    private enum CodingKeys: String, CodingKey {
        case wallet, ladder, passes, checkIns, passThroughs, vitality, quietTime
    }

    /// Every field is optional on decode, so state written by an older
    /// version of the app always loads; missing parts start fresh.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            wallet: try container.decodeIfPresent(Wallet.self, forKey: .wallet) ?? Wallet(),
            ladder: try container.decodeIfPresent(FrictionLadder.self, forKey: .ladder) ?? FrictionLadder(),
            passes: try container.decodeIfPresent(PassLedger.self, forKey: .passes) ?? PassLedger(),
            checkIns: try container.decodeIfPresent([CheckInRecord].self, forKey: .checkIns) ?? [],
            passThroughs: try container.decodeIfPresent([PassThrough].self, forKey: .passThroughs) ?? [],
            vitality: try container.decodeIfPresent(VitalityLedger.self, forKey: .vitality) ?? VitalityLedger(),
            quietTime: try container.decodeIfPresent(QuietTimeLedger.self, forKey: .quietTime) ?? QuietTimeLedger()
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(wallet, forKey: .wallet)
        try container.encode(ladder, forKey: .ladder)
        try container.encode(passes, forKey: .passes)
        try container.encode(checkIns, forKey: .checkIns)
        try container.encode(passThroughs, forKey: .passThroughs)
        try container.encode(vitality, forKey: .vitality)
        try container.encode(quietTime, forKey: .quietTime)
    }
}

/// How ending a pass early went.
public struct PassEnding: Hashable, Sendable {
    /// The pass that ended.
    public let pass: Pass
    /// Energy returned to the balance.
    public let refund: Energy

    public init(pass: Pass, refund: Energy) {
        self.pass = pass
        self.refund = refund
    }
}

/// Runs the soft gate: decides whether an open is covered by a pass or
/// needs an intervention, and applies the user's choice.
///
/// The flow for every open of a protected app:
/// 1. `beginCheckIn` either returns `.covered(pass)` or records an attempt,
///    climbs the ladder, and returns `.intervene(attempt)`.
/// 2. The app runs the intervention for the attempt's rung.
/// 3. `resolve` applies the user's choice and records the outcome. If the
///    user leaves the intervention without choosing, the app resolves the
///    attempt with `.resist`: an attempt that did not open the app is an
///    impulse resisted (ADR-0008).
///
/// Resisting never earns energy. Paying for skips would turn the gate into
/// a slot machine (open, skip, collect); skips feed vitality instead.
///
/// The gate also keeps quiet time (ADR-0014) in step: every check-in is a
/// sign of life, every opened outcome breaks the quiet stretch, and the
/// next sign of life after the pass (or ending it early) resumes it.
public struct Gatekeeper: Sendable {
    public let economy: Economy
    public let quietTime: QuietTimeAccrual

    public init(economy: Economy) {
        self.economy = economy
        self.quietTime = QuietTimeAccrual(economy: economy)
    }

    public func beginCheckIn(
        for target: TargetGroupID,
        at date: Date,
        state: inout PofuState,
        attemptID: UUID = UUID()
    ) -> CheckInDecision {
        economy.openDay(&state.wallet, at: date)
        state.passes.removeExpired(at: date)
        state.pruneHistory(newestDay: economy.day(of: date), calendar: economy.calendar)
        quietTime.recordSignal(at: date, in: &state.quietTime, passes: state.passes)
        if let pass = state.passes.validPass(for: target, at: date) {
            state.passThroughs.append(PassThrough(target: target, at: date, passID: pass.id))
            return .covered(pass)
        }

        let ladderRung = state.ladder.registerAttempt(at: date, rules: economy.configuration.friction)
        let cheapest = economy.cheapestQuote(at: date, for: state.wallet)
        let canAfford = cheapest.map { state.wallet.balance >= $0.price } ?? false
        let attempt = CheckInAttempt(
            id: attemptID,
            target: target,
            attemptedAt: date,
            ladderRung: ladderRung,
            rung: FrictionLadder.effectiveRung(ladderRung: ladderRung, canAffordAnyUnlock: canAfford),
            cheapestPrice: cheapest?.price
        )
        return .intervene(attempt)
    }

    /// Applies the user's choice for `attempt` at `date`.
    ///
    /// - Parameter reason: The reason the user gave on the `intent` rung,
    ///   recorded with the outcome whatever the choice.
    /// - Throws: `CheckInError` when the choice is not available on the
    ///   attempt's rung, the payment fails, or today's emergency pass is
    ///   used. Nothing is recorded then, so the app can offer another
    ///   choice.
    @discardableResult
    public func resolve(
        _ attempt: CheckInAttempt,
        with choice: CheckInChoice,
        at date: Date,
        state: inout PofuState,
        reason: IntentReason? = nil,
        passID: UUID = UUID()
    ) throws -> CheckInRecord {
        let outcome: CheckInOutcome
        switch choice {
        case .resist:
            outcome = .resisted

        case .proceed:
            guard attempt.rung.isFree else {
                throw CheckInError.choiceNotAvailable(choice, rung: attempt.rung)
            }
            outcome = .proceeded(
                Pass(
                    id: passID,
                    target: attempt.target,
                    grantedAt: date,
                    minutes: economy.configuration.friction.freePassMinutes,
                    source: .free(attempt.rung)
                )
            )

        case .pay(let minutes):
            do {
                let pass = try economy.purchaseUnlock(
                    minutes: minutes,
                    for: attempt.target,
                    at: date,
                    from: &state.wallet,
                    passID: passID
                )
                outcome = .proceeded(pass)
            } catch let error as SpendError {
                throw CheckInError.spend(error)
            }

        case .friendApproved(let minutes):
            guard attempt.rung == .askFriend else {
                throw CheckInError.choiceNotAvailable(choice, rung: attempt.rung)
            }
            guard minutes > 0, economy.configuration.spending.unlockDurations.contains(minutes) else {
                throw CheckInError.spend(.unsupportedDuration(minutes: minutes))
            }
            outcome = .friendApproved(
                Pass(
                    id: passID,
                    target: attempt.target,
                    grantedAt: date,
                    minutes: minutes,
                    source: .friendApproved
                )
            )

        case .emergency:
            guard !attempt.rung.isFree else {
                throw CheckInError.choiceNotAvailable(choice, rung: attempt.rung)
            }
            guard
                let pass = economy.grantEmergencyPass(
                    for: attempt.target,
                    at: date,
                    from: &state.wallet,
                    passID: passID
                )
            else {
                throw CheckInError.emergencyPassUsed(
                    nextAvailable: economy.nextEmergencyPassDay(for: state.wallet, at: date)
                )
            }
            outcome = .proceeded(pass)
        }

        if let pass = outcome.pass {
            state.passes.grant(pass)
            quietTime.passStarted(pass, in: &state.quietTime)
        }
        let record = CheckInRecord(
            id: attempt.id,
            target: attempt.target,
            attemptedAt: attempt.attemptedAt,
            resolvedAt: date,
            rung: attempt.rung,
            outcome: outcome,
            reason: reason
        )
        state.checkIns.append(record)
        return record
    }

    /// Ends the pass with `id` at `date`, before it expires, and refunds its
    /// unused whole minutes (see `Economy.refund(for:endingAt:)`). Stopping
    /// early is exactly the behavior Pofu wants, so it never costs extra.
    ///
    /// - Returns: The ended pass and its refund, or `nil` when the ledger
    ///   does not hold the pass.
    @discardableResult
    public func endPass(id: UUID, at date: Date, state: inout PofuState) -> PassEnding? {
        economy.openDay(&state.wallet, at: date)
        guard let pass = state.passes.revoke(id: id) else { return nil }
        let refund = economy.refund(for: pass, endingAt: date)
        economy.creditRefund(refund, to: &state.wallet)
        quietTime.passEnded(at: date, in: &state.quietTime, remaining: state.passes)
        return PassEnding(pass: pass, refund: refund)
    }

    /// Voids the pass with `id` because it could never be used, for example
    /// when the app it opens is not installed: the full price comes back
    /// and the purchase stops escalating prices.
    @discardableResult
    public func voidPass(id: UUID, state: inout PofuState) -> PassEnding? {
        guard let pass = state.passes.revoke(id: id) else { return nil }
        let refund = economy.void(pass, in: &state.wallet)
        // The app never opened: quiet resumes from the moment of the grant.
        quietTime.passEnded(at: pass.grantedAt, in: &state.quietTime, remaining: state.passes)
        return PassEnding(pass: pass, refund: refund)
    }

    // MARK: - Quiet time

    /// The automation ran at `date`, whatever the gate then did (for
    /// example, when the system did not let Pofu come forward). A sign of
    /// life keeps Pofu observing and releases held seeds.
    public func noteAutomationRan(at date: Date, state: inout PofuState) {
        quietTime.recordSignal(at: date, in: &state.quietTime, passes: state.passes)
    }

    /// The user is back in Pofu at `date`: it came to the foreground, or
    /// they tapped the pass-expiry notification. Starts the quiet stretch
    /// an expired pass paused; it is not a sign of life from the
    /// automation, so observation and held seeds do not change.
    public func noteUserReturned(at date: Date, state: inout PofuState) {
        quietTime.userReturned(at: date, in: &state.quietTime, passes: state.passes)
    }

    /// Credits quiet time up to `date` into Pofu's cheeks.
    @discardableResult
    public func advanceQuietTime(to date: Date, state: inout PofuState) -> QuietAccrual {
        quietTime.advance(&state.quietTime, to: date)
    }

    /// Moves the seeds waiting in Pofu's cheeks to the balance.
    ///
    /// - Returns: What was collected, or `nil` when there is nothing to
    ///   collect or the seeds are held because Pofu is not observing.
    @discardableResult
    public func collectQuietSeeds(at date: Date, state: inout PofuState) -> QuietCollection? {
        economy.openDay(&state.wallet, at: date)
        return quietTime.collect(&state.quietTime, into: &state.wallet, at: date)
    }
}
