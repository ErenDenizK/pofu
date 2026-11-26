import Foundation
import Testing

@testable import PofuCore

@Suite("Island year")
struct IslandYearTests {
    let first = LocalDay(year: 2026, month: 11, day: 26)
    let rules = IslandYear.Rules(seasonDays: 7, order: [.spring, .summer, .autumn, .winter])

    private func season(day n: Int, _ rules: IslandYear.Rules? = nil) -> Season {
        IslandYear.season(on: first.adding(days: n - 1), firstDay: first, rules: rules ?? self.rules)
    }

    @Test func dayOneIsSpringDayEightSummerDayTwentyNineSpring() {
        #expect(season(day: 1) == .spring)
        #expect(season(day: 7) == .spring)
        #expect(season(day: 8) == .summer)
        #expect(season(day: 15) == .autumn)
        #expect(season(day: 22) == .winter)
        #expect(season(day: 28) == .winter)
        #expect(season(day: 29) == .spring)
    }

    @Test func aDisabledSeasonIsSkipped() {
        let noWinter = IslandYear.Rules(seasonDays: 7, order: [.spring, .summer, .autumn, .winter], disabled: [.winter])
        #expect(season(day: 22, noWinter) == .spring)
        #expect(season(day: 21, noWinter) == .autumn)
        let nothing = IslandYear.Rules(seasonDays: 7, order: [.spring], disabled: [.spring])
        #expect(season(day: 9, nothing) == .spring)
    }

    @Test func theLengthIsData() {
        let three = IslandYear.Rules(seasonDays: 3, order: [.spring, .summer])
        #expect(season(day: 3, three) == .spring)
        #expect(season(day: 4, three) == .summer)
        #expect(season(day: 7, three) == .spring)
    }

    @Test func positionCountsTheDayOfTheSeason() {
        let p = IslandYear.position(on: first.adding(days: 13), firstDay: first, rules: rules)
        #expect(p.season == .summer)
        #expect(p.dayOfSeason == 7)
        #expect(p.isLastDayOfSeason)
    }

    @Test func acrossMonthsAndLeapYears() {
        let start = LocalDay(year: 2027, month: 12, day: 25)
        // 2028 is a leap year: 25 Dec 2027 + 70 days is 2 Mar 2028 (day 71).
        let later = start.adding(days: 70)
        #expect(later == LocalDay(year: 2028, month: 3, day: 4))
        #expect(IslandYear.position(on: later, firstDay: start, rules: rules).dayOfSeason == 1)
        #expect(later.epochDay - start.epochDay == 70)
    }

    @Test func aDayBeforeTheFirstCountsAsDayOne() {
        #expect(IslandYear.season(on: first.adding(days: -5), firstDay: first, rules: rules) == .spring)
    }

    @Test func namesFromTheTuningFileBecomeRules() {
        let r = IslandYear.Rules(seasonDays: 7, order: ["spring", "nope", "summer"], disabled: ["summer", "x"])
        #expect(r.cycle == [.spring])
    }
}
