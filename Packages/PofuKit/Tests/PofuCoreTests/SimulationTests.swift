import Foundation
import Testing
import PofuCore

/// Runs synthetic weeks through the whole domain (allowance, earning,
/// steps, the soft gate, spending, passes, metrics, vitality) and checks
/// the invariants that must hold whatever the user does.
@Suite("Economy simulation")
struct SimulationTests {
    /// How a synthetic user behaves.
    struct Persona: Sendable, CustomStringConvertible {
        var name: String
        /// Reflexive opens per day.
        var opensPerDay: ClosedRange<Int>
        /// Chance of resisting on any rung.
        var resistChance: Double
        /// Self-reported activity sessions per day.
        var honorSessionsPerDay: ClosedRange<Int>
        /// Verified focus sessions per day.
        var focusSessionsPerDay: ClosedRange<Int>
        /// Steps walked per day.
        var stepsPerDay: ClosedRange<Int>

        var description: String { name }

        static let resister = Persona(
            name: "resister",
            opensPerDay: 10...25,
            resistChance: 0.8,
            honorSessionsPerDay: 1...3,
            focusSessionsPerDay: 1...2,
            stepsPerDay: 4_000...12_000
        )
        static let scroller = Persona(
            name: "scroller",
            opensPerDay: 40...80,
            resistChance: 0.1,
            honorSessionsPerDay: 0...1,
            focusSessionsPerDay: 0...1,
            stepsPerDay: 1_000...5_000
        )
        /// Tries to farm energy by logging far more honor time than the cap.
        static let farmer = Persona(
            name: "farmer",
            opensPerDay: 30...60,
            resistChance: 0.3,
            honorSessionsPerDay: 8...12,
            focusSessionsPerDay: 0...0,
            stepsPerDay: 0...2_000
        )
    }

    struct Outcome {
        var finalVitality: Double
        var totalResisted: Int
        var totalAttempts: Int
    }

    enum Event {
        case open(Date)
        case honor(Date, minutes: Int)
        case focus(Date, minutes: Int)
        case steps(Date, total: Int)
    }

    let calendar = Calendar.istanbul
    let firstDay = instant(2026, 11, 2, 0, 0, 0)

    @Test(arguments: [Persona.resister, Persona.scroller, Persona.farmer], [UInt64(1), 7, 42, 2_026])
    func invariantsHoldForEveryPersona(persona: Persona, seed: UInt64) throws {
        _ = try simulate(persona, days: 21, seed: seed)
    }

    @Test(arguments: [UInt64(3), 11, 99])
    func resistingKeepsPofuHealthierThanScrolling(seed: UInt64) throws {
        let resister = try simulate(.resister, days: 28, seed: seed)
        let scroller = try simulate(.scroller, days: 28, seed: seed)
        #expect(resister.finalVitality > scroller.finalVitality + 0.2)
        let model = VitalityModel()
        #expect([VitalityBand.content, .thriving].contains(model.band(for: resister.finalVitality)))
        #expect([VitalityBand.tired, .wilting].contains(model.band(for: scroller.finalVitality)))
    }

    // MARK: - Engine

    func simulate(_ persona: Persona, days: Int, seed: UInt64) throws -> Outcome {
        var rng = SplitMix64(seed: seed)
        let economy = Economy(calendar: calendar)
        let gatekeeper = Gatekeeper(economy: economy)
        let vitalityModel = VitalityModel(rules: economy.configuration.vitality)
        let cap = economy.configuration.earning.honorDailyCap

        var state = PofuState()
        var vitality = economy.configuration.vitality.initialVitality
        var allowances = Energy.zero
        var earned = Energy.zero
        var spent = Energy.zero
        var previousLadderRung: FrictionRung?
        var totals = Outcome(finalVitality: vitality, totalResisted: 0, totalAttempts: 0)

        for dayIndex in 0..<days {
            let dayStart = firstDay.adding(hours: Double(dayIndex) * 24)
            let today = economy.day(of: dayStart)
            var distractingMinutes = 0.0
            var activityToday = Energy.zero

            for event in events(for: persona, from: dayStart, using: &rng) {
                let at = time(of: event)
                allowances += economy.openDay(&state.wallet, at: at)

                switch event {
                case .open(let date):
                    switch gatekeeper.beginCheckIn(for: "feed", at: date, state: &state) {
                    case .covered(let pass):
                        #expect(pass.isValid(at: date))
                    case .intervene(let attempt):
                        if let previous = previousLadderRung {
                            #expect(attempt.ladderRung == .pause || attempt.ladderRung <= previous.next)
                        }
                        previousLadderRung = attempt.ladderRung
                        let record = try resolve(attempt, persona: persona, at: date, gatekeeper: gatekeeper, state: &state, rng: &rng)
                        if case .proceeded(let pass) = record.outcome, case .purchased(let price) = pass.source {
                            spent += price
                        }
                        if let pass = record.outcome.pass {
                            distractingMinutes += pass.expiresAt.timeIntervalSince(pass.grantedAt) / 60
                        }
                    }

                case .honor(let end, let minutes):
                    let result = economy.earn(session(Double(minutes), .honor, endingAt: end), into: &state.wallet)
                    earned += result.earned
                    if economy.day(of: end) == today { activityToday += result.earned }

                case .focus(let end, let minutes):
                    let result = economy.earn(session(Double(minutes), .structural, kind: .focus, endingAt: end), into: &state.wallet)
                    earned += result.earned
                    if economy.day(of: end) == today { activityToday += result.earned }

                case .steps(let date, let total):
                    let grant = economy.creditSteps(dailyTotal: total, on: date, into: &state.wallet)
                    earned += grant
                    if economy.day(of: date) == today { activityToday += grant }
                }

                // Invariants after every event.
                #expect(state.wallet.balance >= .zero)
                #expect(state.wallet.balance == allowances + earned - spent)
                for (_, honor) in state.wallet.honorEarnedByDay {
                    #expect(honor <= cap)
                }
            }

            let impulses = ImpulseMetrics.daily(on: today, from: state.checkIns, calendar: calendar)
            #expect(impulses.attempts == impulses.resisted + impulses.opened)
            if let ratio = impulses.resistedRatio {
                #expect(ratio >= 0 && ratio <= 1)
            }
            totals.totalAttempts += impulses.attempts
            totals.totalResisted += impulses.resisted

            vitality = vitalityModel.vitality(
                after: VitalityInput(distractingMinutes: distractingMinutes, impulses: impulses, activityEnergy: activityToday),
                from: vitality
            )
            #expect(vitality >= 0 && vitality <= 1)
        }

        totals.finalVitality = vitality
        return totals
    }

    func resolve(
        _ attempt: CheckInAttempt,
        persona: Persona,
        at date: Date,
        gatekeeper: Gatekeeper,
        state: inout PofuState,
        rng: inout SplitMix64
    ) throws -> CheckInRecord {
        let decide = date.adding(minutes: 0.5)
        if Double.random(in: 0..<1, using: &rng) < persona.resistChance {
            return try gatekeeper.resolve(attempt, with: .resist, at: decide, state: &state)
        }
        switch attempt.rung {
        case .pause, .intent:
            return try gatekeeper.resolve(attempt, with: .proceed, at: decide, state: &state)
        case .pay:
            let minutes = [5, 10, 15, 30].randomElement(using: &rng) ?? 5
            do {
                return try gatekeeper.resolve(attempt, with: .pay(minutes: minutes), at: decide, state: &state)
            } catch CheckInError.spend(.insufficientBalance) {
                // Cannot afford the chosen window: try the cheapest one, else give up.
                if let record = try? gatekeeper.resolve(attempt, with: .pay(minutes: 5), at: decide, state: &state) {
                    return record
                }
                return try gatekeeper.resolve(attempt, with: .resist, at: decide, state: &state)
            }
        case .askFriend:
            if Bool.random(using: &rng) {
                return try gatekeeper.resolve(attempt, with: .friendApproved(minutes: 10), at: decide, state: &state)
            }
            return try gatekeeper.resolve(attempt, with: .resist, at: decide, state: &state)
        }
    }

    /// One day of events in time order, from 07:00 until 01:00 the next
    /// night, so late opens cross midnight.
    func events(for persona: Persona, from dayStart: Date, using rng: inout SplitMix64) -> [Event] {
        var events: [Event] = []
        let awakeMinutes = 18 * 60
        func randomTime(_ rng: inout SplitMix64) -> Date {
            dayStart.adding(hours: 7).adding(minutes: Double(Int.random(in: 0..<awakeMinutes, using: &rng)))
        }
        for _ in 0..<Int.random(in: persona.opensPerDay, using: &rng) {
            events.append(.open(randomTime(&rng)))
        }
        for _ in 0..<Int.random(in: persona.honorSessionsPerDay, using: &rng) {
            let end = randomTime(&rng)
            let minutes = Int.random(in: 10...120, using: &rng)
            events.append(.honor(end, minutes: minutes))
        }
        for _ in 0..<Int.random(in: persona.focusSessionsPerDay, using: &rng) {
            let end = randomTime(&rng)
            let minutes = Int.random(in: 25...90, using: &rng)
            events.append(.focus(end, minutes: minutes))
        }
        let steps = Int.random(in: persona.stepsPerDay, using: &rng)
        for fraction in [0.25, 0.5, 0.75, 1.0] {
            // Health data reports cumulative totals during the day.
            events.append(.steps(dayStart.adding(hours: 9 + 12 * fraction), total: Int(Double(steps) * fraction)))
        }
        return events.sorted { time(of: $0) < time(of: $1) }
    }

    func time(of event: Event) -> Date {
        switch event {
        case .open(let date), .steps(let date, _):
            date
        case .honor(let date, _), .focus(let date, _):
            date
        }
    }
}
