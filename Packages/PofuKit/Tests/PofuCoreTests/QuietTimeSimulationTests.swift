import Foundation
import Testing
import PofuCore

/// Runs weeks of synthetic opens, resists, passes, early endings, silent
/// stretches, and app visits through the gate, and checks quiet-time
/// earning against an independent minute-by-minute reference model.
@Suite("Quiet time simulation")
struct QuietTimeSimulationTests {
    let calendar = Calendar.istanbul
    let firstDay = instant(2026, 11, 2, 0, 0, 0)
    let days = 16
    /// Days without a single open or automation run: longer than the
    /// observation window, so seeds are held and silent time is lost.
    let silentDays = 6...9

    static let bedtimes = [
        SpendingRules().bedtime,
        DailyWindow(start: LocalTime(hour: 0), end: LocalTime(hour: 0)),
        DailyWindow(start: LocalTime(hour: 0, minute: 30), end: LocalTime(hour: 7, minute: 30)),
    ]

    enum Event {
        case open(minute: Int, target: TargetGroupID)
        case automationOnly(minute: Int)
        case endEarly(minute: Int)
        case foreground(minute: Int)

        var minute: Int {
            switch self {
            case .open(let minute, _), .automationOnly(let minute), .endEarly(let minute), .foreground(let minute):
                minute
            }
        }
    }

    @Test(arguments: Self.bedtimes, [UInt64(1), 9, 77, 2_026])
    func matchesAMinuteByMinuteReference(bedtime: DailyWindow, seed: UInt64) throws {
        var rng = SplitMix64(seed: seed)
        var configuration = EconomyConfiguration()
        configuration.spending.bedtime = bedtime
        let economy = Economy(configuration: configuration, calendar: calendar)
        let gatekeeper = Gatekeeper(economy: economy)
        let rules = configuration.quietTime

        var state = PofuState()
        var signals: [Int] = []
        var passMinutes: [UUID: (start: Int, end: Int)] = [:]
        var allowances = Energy.zero
        var spent = Energy.zero
        var refunds = Energy.zero
        var collected = QuietCollection(quietSeeds: .zero, sleepBonus: .zero)
        var sawHeldSeeds = false

        for event in events(using: &rng) {
            let at = date(event.minute)
            allowances += economy.openDay(&state.wallet, at: at)
            switch event {
            case .open(let minute, let target):
                signals.append(minute)
                guard case .intervene(let attempt) = gatekeeper.beginCheckIn(for: target, at: at, state: &state) else {
                    continue
                }
                let record = try resolve(attempt, at: at, gatekeeper: gatekeeper, state: &state, rng: &rng)
                if let pass = record.outcome.pass {
                    passMinutes[pass.id] = (minute, minute + pass.durationMinutes)
                    if case .purchased(let price) = pass.source {
                        spent += price
                    }
                }

            case .automationOnly(let minute):
                signals.append(minute)
                gatekeeper.noteAutomationRan(at: at, state: &state)

            case .endEarly(let minute):
                guard let pass = state.passes.passes.first(where: { $0.isValid(at: at) }) else { continue }
                let ending = try #require(gatekeeper.endPass(id: pass.id, at: at, state: &state))
                refunds += ending.refund
                if let interval = passMinutes[pass.id] {
                    passMinutes[pass.id] = (interval.start, min(interval.end, minute))
                }

            case .foreground:
                gatekeeper.advanceQuietTime(to: at, state: &state)
                let holding = gatekeeper.quietTime.isHolding(state.quietTime, at: at)
                sawHeldSeeds = sawHeldSeeds || holding
                if Bool.random(using: &rng) {
                    let result = gatekeeper.collectQuietSeeds(at: at, state: &state)
                    if holding {
                        #expect(result == nil)
                    }
                    if let result {
                        collected = QuietCollection(
                            quietSeeds: collected.quietSeeds + result.quietSeeds,
                            sleepBonus: collected.sleepBonus + result.sleepBonus
                        )
                    }
                }
            }

            // Invariants after every event.
            #expect(state.wallet.balance >= .zero)
            #expect(state.wallet.balance == allowances - spent + refunds + collected.total)
            for (_, seeds) in state.quietTime.quietSeedsByDay {
                #expect(seeds <= rules.dailyCap)
            }
        }

        let end = date(days * 1_440)
        gatekeeper.advanceQuietTime(to: end, state: &state)
        let expected = reference(
            signals: signals,
            passes: Array(passMinutes.values),
            bedtime: bedtime,
            rules: rules
        )
        #expect(collected.quietSeeds + state.quietTime.pendingQuietSeeds == expected.quietSeeds)
        #expect(collected.sleepBonus + state.quietTime.pendingSleepBonus == expected.sleepBonus)
        #expect(expected.quietSeeds > .zero)
        #expect(sawHeldSeeds)
    }

    // MARK: - Synthetic days

    func date(_ minute: Int) -> Date {
        firstDay.adding(minutes: Double(minute))
    }

    /// Events at whole minutes. The first day starts after the first night,
    /// so the reference never needs to know what came before.
    func events(using rng: inout SplitMix64) -> [Event] {
        var events: [Event] = []
        for day in 0..<days {
            let base = day * 1_440
            let earliest = day == 0 ? 8 * 60 : 0
            func someMinute(_ rng: inout SplitMix64) -> Int {
                base + Int.random(in: earliest..<1_440, using: &rng)
            }
            for _ in 0..<Int.random(in: 2...6, using: &rng) {
                events.append(.foreground(minute: someMinute(&rng)))
            }
            guard !silentDays.contains(day) else { continue }
            for _ in 0..<Int.random(in: 3...20, using: &rng) {
                let target: TargetGroupID = Bool.random(using: &rng) ? "instagram" : "youtube"
                events.append(.open(minute: someMinute(&rng), target: target))
            }
            for _ in 0..<Int.random(in: 0...2, using: &rng) {
                events.append(.endEarly(minute: someMinute(&rng)))
            }
            if Int.random(in: 0..<3, using: &rng) == 0 {
                events.append(.automationOnly(minute: someMinute(&rng)))
            }
        }
        return events.sorted { $0.minute < $1.minute }
    }

    func resolve(
        _ attempt: CheckInAttempt,
        at date: Date,
        gatekeeper: Gatekeeper,
        state: inout PofuState,
        rng: inout SplitMix64
    ) throws -> CheckInRecord {
        if Double.random(in: 0..<1, using: &rng) < 0.55 {
            return try gatekeeper.resolve(attempt, with: .resist, at: date, state: &state)
        }
        if attempt.rung.isFree {
            return try gatekeeper.resolve(attempt, with: .proceed, at: date, state: &state)
        }
        let minutes = Bool.random(using: &rng) ? 5 : 10
        if let record = try? gatekeeper.resolve(attempt, with: .pay(minutes: minutes), at: date, state: &state) {
            return record
        }
        return try gatekeeper.resolve(attempt, with: .resist, at: date, state: &state)
    }

    // MARK: - Reference model

    /// Quiet seeds and sleep bonuses, recomputed one minute at a time from
    /// the raw history: a minute counts when Pofu observed it (a sign of
    /// life in the 72 hours before), no pass ran, and it is not bedtime.
    func reference(
        signals: [Int],
        passes: [(start: Int, end: Int)],
        bedtime: DailyWindow,
        rules: QuietTimeRules
    ) -> QuietCollection {
        let total = days * 1_440
        let window = Int(rules.observationWindow / 60)
        var passRunning = [Bool](repeating: false, count: total)
        for pass in passes {
            for minute in max(0, pass.start)..<min(total, max(pass.start, pass.end)) {
                passRunning[minute] = true
            }
        }
        let sortedSignals = signals.sorted()
        var observed = [Bool](repeating: false, count: total)
        var signalIndex = 0
        var lastSignal: Int?
        for minute in 0..<total {
            while signalIndex < sortedSignals.count && sortedSignals[signalIndex] <= minute {
                lastSignal = sortedSignals[signalIndex]
                signalIndex += 1
            }
            if let lastSignal, minute < lastSignal + window {
                observed[minute] = true
            }
        }
        let night = (0..<total).map { bedtime.contains(date($0), in: calendar) }

        var quietSeeds = Energy.zero
        var perDay: [LocalDay: Energy] = [:]
        var run = 0
        for minute in 0..<total {
            guard observed[minute], !passRunning[minute], !night[minute] else {
                run = 0
                continue
            }
            run += 1
            guard run == rules.blockMinutes else { continue }
            run = 0
            let day = LocalDay(containing: date(minute - rules.blockMinutes + 1), in: calendar)
            let room = max(rules.dailyCap - perDay[day, default: .zero], .zero)
            let credited = min(rules.seedsPerBlock, room)
            perDay[day, default: .zero] += credited
            quietSeeds += credited
        }

        var sleepBonus = Energy.zero
        var minute = 0
        while minute < total {
            guard night[minute] else {
                minute += 1
                continue
            }
            let start = minute
            while minute < total && night[minute] {
                minute += 1
            }
            // Only whole nights that ended inside the simulation.
            guard start > 0, minute < total else { continue }
            if (start..<minute).allSatisfy({ observed[$0] && !passRunning[$0] }) {
                sleepBonus += rules.sleepBonus
            }
        }
        return QuietCollection(quietSeeds: quietSeeds, sleepBonus: sleepBonus)
    }
}
