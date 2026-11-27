import Foundation
import Testing

@testable import PofuCore

@Suite("Special days")
struct SpecialDaysTests {
    let table = SpecialDays.shipped
    let evening = 18 * 60

    @Test func theBundledTableDecodes() throws {
        _ = try SpecialDays.bundled()
        #expect(SpecialDays.shipped.lastDatedDay != nil)
    }

    @Test func newYearRunsFromTheEveningOf31DecemberAndAllOf1January() {
        let eve = LocalDay(year: 2026, month: 12, day: 31)
        let day = LocalDay(year: 2027, month: 1, day: 1)
        #expect(table.active(on: eve, at: evening) == [.newYear])
        #expect(table.active(on: day, at: 0) == [.newYear])
        #expect(table.active(on: day, at: 23 * 60 + 59) == [.newYear])
        #expect(table.active(on: day.adding(days: 1), at: 12 * 60).isEmpty)
        #expect(table.active(on: day.adding(days: 1), at: evening).isEmpty)
    }

    @Test func theEveningBeforeAlreadyShowsTheKit() {
        let before = LocalDay(year: 2026, month: 10, day: 30)
        #expect(table.active(on: before, at: evening - 1).isEmpty)
        #expect(table.active(on: before, at: evening) == [.halloween])
        #expect(table.active(on: before.adding(days: 1), at: 3 * 60) == [.halloween])
    }

    @Test func fixedDaysRepeatEveryYear() {
        #expect(table.active(on: LocalDay(year: 2029, month: 5, day: 6), at: 600) == [.hidirellez])
        #expect(table.active(on: LocalDay(year: 2031, month: 5, day: 5), at: 600) == [.hidirellez])
    }

    @Test func bayramsFollowTheirDatedRanges() {
        #expect(table.active(on: LocalDay(year: 2027, month: 3, day: 9), at: 600) == [.ramazanBayrami])
        #expect(table.active(on: LocalDay(year: 2027, month: 3, day: 11), at: 600) == [.ramazanBayrami])
        #expect(table.active(on: LocalDay(year: 2027, month: 3, day: 12), at: 600).isEmpty)
        #expect(table.active(on: LocalDay(year: 2027, month: 5, day: 19), at: 600) == [.kurbanBayrami])
        #expect(table.active(on: LocalDay(year: 2027, month: 5, day: 20), at: 600).isEmpty)
    }

    @Test func festivalNightIsTheLastEveningOfAnIslandSeason() {
        let first = LocalDay(year: 2027, month: 6, day: 1)
        let rules = IslandYear.Rules(seasonDays: 7, order: [.spring, .summer, .autumn, .winter])
        let last = first.adding(days: 6)
        #expect(table.active(on: last, at: evening, firstDay: first, rules: rules) == [.festivalNight])
        #expect(table.active(on: last, at: evening - 1, firstDay: first, rules: rules).isEmpty)
        #expect(table.active(on: first.adding(days: 5), at: evening, firstDay: first, rules: rules).isEmpty)
        #expect(table.active(on: last, at: evening).isEmpty)
    }

    /// Fails once the last bayram listed has passed: time to add the
    /// next years from Diyanet's published calendar (only 2027 was
    /// published when this was written; see `special-days.json`).
    @Test func theTableStillHasABayramAhead() throws {
        let last = try #require(table.lastDatedDay)
        let today = LocalDay(containing: Date(), in: Calendar(identifier: .gregorian))
        #expect(last >= today, "special-days.json has no bayram left: add the next years from Diyanet")
    }

    @Test func fireworksAreOnlyOnNewYearsNightFrom22To01() {
        let eve = LocalDay(year: 2026, month: 12, day: 31), day = LocalDay(year: 2027, month: 1, day: 1)
        #expect(!table.fireworks(on: eve, at: 21 * 60 + 59))
        #expect(table.fireworks(on: eve, at: 22 * 60))
        #expect(table.fireworks(on: eve, at: 23 * 60 + 59))
        #expect(table.fireworks(on: day, at: 0))
        #expect(table.fireworks(on: day, at: 59))
        #expect(!table.fireworks(on: day, at: 60))
        #expect(!table.fireworks(on: day, at: 12 * 60))
        // The kit shows from the evening of 30 December, the fireworks do not.
        let before = LocalDay(year: 2026, month: 12, day: 30)
        #expect(table.active(on: before, at: 19 * 60).contains(.newYear))
        #expect(!table.fireworks(on: before, at: 23 * 60))
        #expect(!table.fireworks(on: LocalDay(year: 2026, month: 10, day: 31), at: 23 * 60))
    }
}
