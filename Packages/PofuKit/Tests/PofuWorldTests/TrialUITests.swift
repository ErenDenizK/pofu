import Foundation
import PofuCore
import Testing

@testable import PofuWorld

/// The trial's Home UI: Pofu's daily line when no beat waits, a wonder
/// island's word on today, and Home's bubbles that never cover each other.
@Suite struct TrialUITests {
    // MARK: The daily line

    private func line(hour: Int, bedtime: Bool = false, skips: Int = 0, gift: Bool = false, guest: Bool = false, day: Int = 0) -> HomeDailyLine {
        HomeDailyLine.choose(hour: hour, isBedtime: bedtime, skipsToday: skips, giftIsNew: gift, guestWaiting: guest, dayIndex: day)
    }

    @Test func nightSaysWhatTheMorningBrings() {
        #expect(line(hour: 23) == .night(variant: 0))
        #expect(line(hour: 3, day: 1) == .night(variant: 1))
        // Bedtime wins over everything that happened today.
        #expect(line(hour: 20, bedtime: true, skips: 3, gift: true) == .night(variant: 0))
    }

    @Test func whatHappenedTodayComesBeforeTheHour() {
        #expect(line(hour: 9, skips: 2, gift: true, guest: true) == .giftArrived)
        #expect(line(hour: 9, skips: 2, guest: true) == .letGo(count: 2))
        #expect(line(hour: 9, guest: true) == .guest)
    }

    @Test func theHourPicksTheLineAndTheDayTurnsIt() {
        #expect(line(hour: 9) == .morning(variant: 0))
        #expect(line(hour: 9, day: 1) == .morning(variant: 1))
        #expect(line(hour: 13, day: 2) == .midday(variant: 0))
        #expect(line(hour: 19, day: 5) == .evening(variant: 1))
        #expect(line(hour: 19, day: -3) == .evening(variant: 1))
    }

    @Test func theWorldFeedsTheLine() {
        var world = IslandSamples.grownIsland()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        world.clock = calendar.date(from: DateComponents(year: 2026, month: 11, day: 16, hour: 9))
        world.isBedtime = false
        world.visitor = nil
        world.koke = WonderStatus()
        world.caglayan = WonderStatus()
        guard case .morning = HomeDailyLine.choose(world: world, skipsToday: 0, calendar: calendar) else {
            Issue.record("09:00 with nothing new is a morning line")
            return
        }
        #expect(HomeDailyLine.choose(world: world, skipsToday: 1, calendar: calendar) == .letGo(count: 1))
        world.koke = WonderStatus(phase: .arrived, stage: 4, giftIsNew: true)
        #expect(HomeDailyLine.choose(world: world, skipsToday: 1, calendar: calendar) == .giftArrived)
    }

    // MARK: A wonder island's today

    @Test func aWonderIslandSaysWhatATapDoesToday() {
        #expect(WonderToday(WonderStatus(phase: .arrived, stage: 1, canAdvance: true)) == .tapHelps)
        #expect(WonderToday(WonderStatus(phase: .arrived, stage: 2, tendedToday: true)) == .doneForToday)
        #expect(WonderToday(WonderStatus(phase: .arrived, stage: 1)) == .needsSkip)
        #expect(WonderToday(WonderStatus(phase: .arrived, stage: 1, canAdvance: true, isAsleep: true)) == .sleeping)
        #expect(WonderToday(WonderStatus(phase: .arrived, stage: 4)) == nil)
        #expect(WonderToday(WonderStatus(phase: .rumoured)) == nil)
    }

    // MARK: Home's bubbles

    private let screen = 402.0

    private func heartFrame(x: Double, y: Double) -> HomeBubbleLayout.Rect {
        HomeBubbleLayout.bubble(tipX: x, tipY: y, width: 30, height: 30, tail: 5, screenWidth: screen).frame
    }

    @Test func aTagWithNothingAroundStandsOverItsGift() {
        let tag = HomeBubbleLayout.tag(
            over: (200, 400), under: (200, 450), width: 140, height: 26, tail: 6,
            screenWidth: screen, placed: [], stations: []
        )
        #expect(!tag.isBelow)
        #expect(tag.tail == 6)
        #expect(tag.body.maxY + tag.tail == 400)
    }

    @Test func aTagNeverCoversTheGreetingHeart() {
        // Day 10 at 23:00: the guest's heart stood right over the moss.
        let heart = heartFrame(x: 170, y: 395)
        let tag = HomeBubbleLayout.tag(
            over: (190, 400), under: (190, 440), width: 140, height: 26, tail: 6,
            screenWidth: screen, placed: [heart], stations: []
        )
        #expect(tag.frame.overlap(heart) == 0)
    }

    @Test func aTagGivesWayToAStationsArt() {
        // A tea stall stands right behind and over the gift; the lawn under it is free.
        let stall = HomeBubbleLayout.Rect(minX: 120, minY: 300, maxX: 300, maxY: 405)
        let tag = HomeBubbleLayout.tag(
            over: (210, 400), under: (210, 430), width: 140, height: 26, tail: 6,
            screenWidth: screen, placed: [], stations: [stall]
        )
        #expect(tag.frame.overlap(stall) == 0)
        #expect(tag.isBelow)
    }

    @Test func aTagStaysUnderTheTopBar() {
        let tag = HomeBubbleLayout.tag(
            over: (200, 125), under: (200, 160), width: 140, height: 26, tail: 6,
            screenWidth: screen, placed: [], stations: []
        )
        #expect(tag.body.minY >= 120)
    }

    @Test func twoBubblesNeverShareSpace() {
        let a = HomeBubbleLayout.Rect(minX: 0, minY: 0, maxX: 10, maxY: 10)
        #expect(a.overlap(HomeBubbleLayout.Rect(minX: 5, minY: 5, maxX: 20, maxY: 20)) == 25)
        #expect(a.overlap(HomeBubbleLayout.Rect(minX: 10, minY: 0, maxX: 20, maxY: 10)) == 0)
    }
}
