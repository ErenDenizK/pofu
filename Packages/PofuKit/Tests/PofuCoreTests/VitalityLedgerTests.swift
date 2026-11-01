import Foundation
import Testing
@testable import PofuCore

@Suite("Vitality while blind")
struct VitalityLedgerTests {
    let model = VitalityModel()
    let day1 = LocalDay(year: 2026, month: 11, day: 1)

    let goodDay = VitalityInput(
        distractingMinutes: 10,
        impulses: ImpulseMetrics(attempts: 10, resisted: 9, proceeded: 1),
        activityEnergy: 40
    )
    let badDay = VitalityInput(
        distractingMinutes: 150,
        impulses: ImpulseMetrics(attempts: 40, resisted: 2, proceeded: 38)
    )
    let blindDay = VitalityInput(isObserving: false)

    @Test func anUnobservedDayFreezesVitality() {
        for previous in [0.0, 0.2, 0.6, 1.0] {
            #expect(model.vitality(after: blindDay, from: previous) == previous)
        }
        // A blind day with everything "perfect" would otherwise raise it.
        let perfectButBlind = VitalityInput(distractingMinutes: 0, impulses: ImpulseMetrics(), activityEnergy: 100, isObserving: false)
        #expect(model.vitality(after: perfectButBlind, from: 0.3) == 0.3)
        #expect(model.trajectory(of: [blindDay, blindDay]) == [0.6, 0.6])
    }

    @Test func theFirstSettlementOnlyStartsTheLedger() {
        var ledger = VitalityLedger()
        ledger.settle(through: day1, model: model) { _ in
            Issue.record("No day should be settled on the first call")
            return VitalityInput()
        }
        #expect(ledger.settledThrough == day1)
        #expect(ledger.settled == 0.6)
        #expect(ledger.history.isEmpty)
    }

    @Test func settlesEachMissingDayInOrderAndCarriesBlindDaysForward() {
        var ledger = VitalityLedger()
        ledger.settle(through: day1, model: model) { _ in VitalityInput() }

        let inputs: [LocalDay: VitalityInput] = [
            day1.adding(days: 1): goodDay,
            day1.adding(days: 2): blindDay,
            day1.adding(days: 3): badDay,
        ]
        var visited: [LocalDay] = []
        ledger.settle(through: day1.adding(days: 3), model: model) { day in
            visited.append(day)
            return inputs[day] ?? VitalityInput()
        }

        #expect(visited == [day1.adding(days: 1), day1.adding(days: 2), day1.adding(days: 3)])
        let afterGood = model.vitality(after: goodDay, from: 0.6)
        let afterBad = model.vitality(after: badDay, from: afterGood)
        #expect(ledger.history.map(\.vitality) == [afterGood, afterGood, afterBad])
        #expect(ledger.history.map(\.isObserving) == [true, false, true])
        #expect(ledger.settled == afterBad)
        #expect(ledger.settledThrough == day1.adding(days: 3))
    }

    @Test func aDayIsNeverSettledTwiceEvenWhenTheClockMovesBackwards() {
        var ledger = VitalityLedger()
        ledger.settle(through: day1, model: model) { _ in VitalityInput() }
        ledger.settle(through: day1.adding(days: 1), model: model) { _ in goodDay }
        let settled = ledger
        ledger.settle(through: day1, model: model) { _ in
            Issue.record("Nothing should settle")
            return badDay
        }
        ledger.settle(through: day1.adding(days: 1), model: model) { _ in
            Issue.record("Nothing should settle")
            return badDay
        }
        #expect(ledger == settled)
    }

    @Test func aLongAbsenceIsBoundedAndKeepsHistoryShort() {
        var ledger = VitalityLedger()
        ledger.settle(through: day1, model: model) { _ in VitalityInput() }
        var calls = 0
        ledger.settle(through: day1.adding(days: 1_000), model: model) { _ in
            calls += 1
            return blindDay
        }
        #expect(calls <= VitalityLedger.maximumCatchUpDays + 1)
        #expect(ledger.history.count == VitalityLedger.historyLimit)
        #expect(ledger.settled == 0.6)
        #expect(ledger.settledThrough == day1.adding(days: 1_000))
    }

    @Test func liveVitalityHoldsWhileTodayIsBlind() {
        var ledger = VitalityLedger(initialVitality: 0.4)
        ledger.settle(through: day1, model: model) { _ in VitalityInput() }
        #expect(ledger.live(today: blindDay, model: model) == 0.4)
        #expect(ledger.live(today: goodDay, model: model) > 0.4)
    }

    @Test func theDayIsObservedOnlyWhenTheAutomationReported() throws {
        let calendar = Calendar.istanbul
        let economy = Economy(calendar: calendar)
        let gatekeeper = Gatekeeper(economy: economy)
        let noon = instant(2026, 11, 2, 12)
        let today = economy.day(of: noon)
        var state = PofuState()

        #expect(!VitalityInput.observed(on: today, in: state, calendar: calendar).isObserving)

        guard case .intervene(let attempt) = gatekeeper.beginCheckIn(for: testTarget, at: noon, state: &state) else {
            Issue.record("Expected an intervention")
            return
        }
        try gatekeeper.resolve(attempt, with: .proceed, at: noon, state: &state)
        // The reopen during the pass is a pass-through.
        _ = gatekeeper.beginCheckIn(for: testTarget, at: noon.adding(minutes: 1), state: &state)
        #expect(state.passThroughs.count == 1)

        let input = VitalityInput.observed(on: today, in: state, calendar: calendar)
        #expect(input.isObserving)
        #expect(input.impulses.attempts == 1)
        #expect(input.distractingMinutes == 5)

        // A day with only a pass-through still counts as observed.
        var passOnly = PofuState()
        passOnly.passThroughs = [PassThrough(target: testTarget, at: noon, passID: UUID())]
        #expect(VitalityInput.observed(on: today, in: passOnly, calendar: calendar).isObserving)
        #expect(!VitalityInput.observed(on: today.adding(days: 1), in: passOnly, calendar: calendar).isObserving)
    }
}
