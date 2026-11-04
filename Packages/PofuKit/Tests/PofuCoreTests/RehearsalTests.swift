import Foundation
import Testing
@testable import PofuCore

/// Rehearsal mode's pure parts: the simulated tag on logged events, the
/// time controls, and the simulated usage ladder.
@Suite("Rehearsal")
struct RehearsalTests {
    let noon = instant(2026, 11, 2, 12)
    let time = RehearsalTime(bedtime: SpendingRules().bedtime, calendar: .istanbul)

    // MARK: - Simulated events

    @Test func eventsAreLiveUnlessTagged() {
        let event = LoggedEvent(at: noon, event: .hopUnavailable(app: .instagram))
        #expect(event.source == .live)
        let simulated = event.tagged(.simulated)
        #expect(simulated.source == .simulated)
        #expect(simulated.id == event.id)
        #expect(simulated.at == event.at)
        #expect(simulated.event == event.event)
    }

    @Test func liveEventsEncodeWithoutATag() throws {
        let event = LoggedEvent(at: noon, event: .guardedUsageMeasured(minutes: 15))
        let json = try String(decoding: JSONEncoder().encode(event), as: UTF8.self)
        #expect(!json.contains("source"))
        #expect(try JSONDecoder().decode(LoggedEvent.self, from: Data(json.utf8)) == event)
    }

    @Test func simulatedEventsRoundTripWithTheirTag() throws {
        let event = LoggedEvent(at: noon, event: .guardedUsageMeasured(minutes: 15), source: .simulated)
        let data = try JSONEncoder().encode(event)
        #expect(String(decoding: data, as: UTF8.self).contains("\"source\":\"simulated\""))
        let decoded = try JSONDecoder().decode(LoggedEvent.self, from: data)
        #expect(decoded == event)
        #expect(decoded.source == .simulated)
    }

    @Test func aLineFromBeforeSourcesDecodesAsLive() throws {
        let old = LoggedEvent(at: noon, event: .hopUnavailable(app: .youtube))
        // The synthesized encoding of the old type: id, at, event.
        struct OldLine: Encodable {
            let id: UUID
            let at: Date
            let event: PofuEvent
        }
        let data = try JSONEncoder().encode(OldLine(id: old.id, at: old.at, event: old.event))
        let decoded = try JSONDecoder().decode(LoggedEvent.self, from: data)
        #expect(decoded == old)
    }

    @Test func theFilterKeepsEachSourceApart() {
        let live = LoggedEvent(at: noon, event: .hopUnavailable(app: .instagram))
        let simulated = LoggedEvent(at: noon.adding(minutes: 1), event: .hopUnavailable(app: .tiktok), source: .simulated)
        let log = [live, simulated]
        #expect(log.filtered(by: .all) == log)
        #expect(log.filtered(by: .live) == [live])
        #expect(log.filtered(by: .simulated) == [simulated])
        #expect(EventSourceFilter.allCases.count == 3)
    }

    // MARK: - Time controls

    @Test func anHourAheadIsAnHour() {
        #expect(time.destination(of: .quietHour, from: noon) == noon.adding(hours: 1))
    }

    @Test func nightLandsOnTheNextBedtime() {
        #expect(time.nightOrMorning(at: noon) == .night)
        #expect(time.destination(of: .night, from: noon) == instant(2026, 11, 2, 23))
        // Right at the start, the next night is tomorrow's.
        let eleven = instant(2026, 11, 2, 23)
        #expect(time.destination(of: .night, from: eleven) == instant(2026, 11, 3, 23))
    }

    @Test func morningEndsTheNightUnderWay() {
        let lateEvening = instant(2026, 11, 2, 23, 30)
        #expect(time.nightOrMorning(at: lateEvening) == .morning)
        #expect(time.destination(of: .morning, from: lateEvening) == instant(2026, 11, 3, 6))
        let smallHours = instant(2026, 11, 3, 2)
        #expect(time.nightOrMorning(at: smallHours) == .morning)
        #expect(time.destination(of: .morning, from: smallHours) == instant(2026, 11, 3, 6))
    }

    /// The panel's "Next day" is `.morning` at any hour: it lands on the next morning, never today's.
    @Test func morningFromTheDayIsTheNextDay() {
        #expect(time.destination(of: .morning, from: noon) == instant(2026, 11, 3, 6))
        let after = instant(2026, 11, 2, 6, 1)
        #expect(time.destination(of: .morning, from: after) == instant(2026, 11, 3, 6))
    }

    @Test func everyJumpMovesForward() {
        for hour in 0..<24 {
            let date = instant(2026, 11, 2, hour, 17)
            for jump in RehearsalJump.allCases {
                let destination = time.destination(of: jump, from: date)
                #expect(destination > date)
                #expect(destination.timeIntervalSince(date) <= 24 * 60 * 60)
            }
        }
    }

    @Test func jumpsFollowTheClockChange() {
        // Berlin leaves summer time on 2026-10-25 at 03:00.
        let berlin = RehearsalTime(bedtime: SpendingRules().bedtime, calendar: .berlin)
        let evening = instant(2026, 10, 24, 23, 30, in: .berlin)
        #expect(berlin.destination(of: .morning, from: evening) == instant(2026, 10, 25, 6, in: .berlin))
    }

    /// The point of the controls: an hour away from Pofu grows calm and
    /// gathers seeds, where an hour looking at Pofu does not (A20).
    @Test func anHourAwayGrowsTheIslandAndAnHourOnScreenDoesNot() {
        let rules = GameRules(measurement: .screenTime)
        var onScreen = World(rules: rules)
        onScreen.advance(to: noon, .signOfLife(at: noon), .foregroundBegan(at: noon))
        let looked = onScreen.advance(to: time.destination(of: .quietHour, from: noon))
        #expect(looked.calmSteps == 0)
        #expect(looked.gatheredSeeds == .zero)

        var away = World(rules: rules)
        away.advance(to: noon, .signOfLife(at: noon), .foregroundBegan(at: noon))
        let back = time.destination(of: .quietHour, from: noon)
        let delta = away.advance(to: back, applying: RehearsalTime.awayEvents(leaving: noon, returning: back))
        #expect(delta.awayMinutes == 60)
        #expect(delta.calmSteps > 0)
        #expect(delta.gatheredSeeds > .zero)
        #expect(away.state.calm.multiplier > onScreen.state.calm.multiplier)
        #expect(away.state.foregroundSince != nil)
    }

    // MARK: - Simulated usage

    @Test func usageAddsUpWithinADayAndStartsOverOnTheNext() {
        let today = LocalDay(containing: noon, in: .istanbul)
        var usage = RehearsalUsage()
        let first = usage.add(15, on: today)
        #expect(first.before == 0 && first.after == 15)
        let second = usage.add(15, on: today)
        #expect(second.before == 15 && second.after == 30)
        #expect(usage.minutes(on: today) == 30)
        #expect(usage.minutes(on: today.adding(days: 1)) == 0)
        let tomorrow = usage.add(15, on: today.adding(days: 1))
        #expect(tomorrow.before == 0 && tomorrow.after == 15)
        #expect(usage.minutes(on: today) == 0)
    }

    @Test func eachStepCrossedFiresOnce() {
        let steps = GuardedUsageLadder(dailyHourMinutes: 60).stepsMinutes
        #expect(RehearsalUsage.stepsCrossed(from: 0, to: 15, steps: steps) == [15])
        #expect(RehearsalUsage.stepsCrossed(from: 15, to: 30, steps: steps) == [30])
        #expect(RehearsalUsage.stepsCrossed(from: 0, to: 60, steps: steps) == [15, 30, 45, 60])
        #expect(RehearsalUsage.stepsCrossed(from: 60, to: 75, steps: steps).isEmpty)
        #expect(RehearsalUsage.stepsCrossed(from: 20, to: 20, steps: steps).isEmpty)
    }
}
