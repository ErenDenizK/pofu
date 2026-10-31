import Foundation

/// The complete persisted domain state of one user.
public struct PofuState: Hashable, Sendable, Codable {
    public var wallet: Wallet
    public var ladder: FrictionLadder
    public var passes: PassLedger
    public var checkIns: [CheckInRecord]

    public init(
        wallet: Wallet = Wallet(),
        ladder: FrictionLadder = FrictionLadder(),
        passes: PassLedger = PassLedger(),
        checkIns: [CheckInRecord] = []
    ) {
        self.wallet = wallet
        self.ladder = ladder
        self.passes = passes
        self.checkIns = checkIns
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
public struct Gatekeeper: Sendable {
    public let economy: Economy

    public init(economy: Economy) {
        self.economy = economy
    }

    public func beginCheckIn(
        for target: TargetGroupID,
        at date: Date,
        state: inout PofuState,
        attemptID: UUID = UUID()
    ) -> CheckInDecision {
        economy.openDay(&state.wallet, at: date)
        state.passes.removeExpired(at: date)
        if let pass = state.passes.validPass(for: target, at: date) {
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
    /// - Throws: `CheckInError` when the choice is not available on the
    ///   attempt's rung or the payment fails. Nothing is recorded then, so
    ///   the app can offer another choice.
    @discardableResult
    public func resolve(
        _ attempt: CheckInAttempt,
        with choice: CheckInChoice,
        at date: Date,
        state: inout PofuState,
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
        }

        if let pass = outcome.pass {
            state.passes.grant(pass)
        }
        let record = CheckInRecord(
            id: attempt.id,
            target: attempt.target,
            attemptedAt: attempt.attemptedAt,
            resolvedAt: date,
            rung: attempt.rung,
            outcome: outcome
        )
        state.checkIns.append(record)
        return record
    }
}
