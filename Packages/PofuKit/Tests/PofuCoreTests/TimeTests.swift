import Foundation
import Testing
import PofuCore

@Suite("LocalDay")
struct LocalDayTests {
    @Test func dayBoundaryFollowsTheCalendarTimeZone() {
        // 23:30 in Istanbul is 20:30 UTC, the same date.
        let lateEvening = instant(2026, 10, 31, 23, 30)
        #expect(LocalDay(containing: lateEvening, in: .istanbul) == LocalDay(year: 2026, month: 10, day: 31))
        // 01:30 in Istanbul on Nov 1 is still Oct 31 in UTC.
        let afterMidnight = instant(2026, 11, 1, 1, 30)
        #expect(LocalDay(containing: afterMidnight, in: .istanbul) == LocalDay(year: 2026, month: 11, day: 1))
        #expect(LocalDay(containing: afterMidnight, in: .utc) == LocalDay(year: 2026, month: 10, day: 31))
    }

    @Test func midnightBelongsToTheNewDay() {
        let lastSecond = instant(2026, 11, 1, 23, 59, 59)
        let midnight = instant(2026, 11, 2, 0, 0, 0)
        #expect(LocalDay(containing: lastSecond, in: .istanbul) == LocalDay(year: 2026, month: 11, day: 1))
        #expect(LocalDay(containing: midnight, in: .istanbul) == LocalDay(year: 2026, month: 11, day: 2))
    }

    @Test func labelsAreGregorianWhateverTheUserCalendar() {
        var buddhist = Calendar(identifier: .buddhist)
        buddhist.timeZone = Calendar.istanbul.timeZone
        let date = instant(2026, 10, 31)
        #expect(LocalDay(containing: date, in: buddhist) == LocalDay(year: 2026, month: 10, day: 31))
    }

    @Test(arguments: [
        (LocalDay(year: 2026, month: 10, day: 31), 1, LocalDay(year: 2026, month: 11, day: 1)),
        (LocalDay(year: 2026, month: 12, day: 31), 1, LocalDay(year: 2027, month: 1, day: 1)),
        (LocalDay(year: 2028, month: 2, day: 28), 1, LocalDay(year: 2028, month: 2, day: 29)),
        (LocalDay(year: 2027, month: 2, day: 28), 1, LocalDay(year: 2027, month: 3, day: 1)),
        (LocalDay(year: 2026, month: 11, day: 3), -7, LocalDay(year: 2026, month: 10, day: 27)),
        (LocalDay(year: 2026, month: 3, day: 29), 0, LocalDay(year: 2026, month: 3, day: 29)),
    ])
    func addingDays(start: LocalDay, offset: Int, expected: LocalDay) {
        #expect(start.adding(days: offset) == expected)
    }

    @Test func ordering() {
        let days = [
            LocalDay(year: 2027, month: 1, day: 1),
            LocalDay(year: 2026, month: 12, day: 31),
            LocalDay(year: 2026, month: 2, day: 28),
        ]
        #expect(days.sorted() == days.reversed())
    }

    @Test func startIsLocalMidnight() throws {
        let start = try #require(LocalDay(year: 2026, month: 11, day: 2).start(in: .istanbul))
        #expect(start == instant(2026, 11, 2, 0, 0, 0))
    }

    @Test func descriptionIsISO8601() {
        #expect(LocalDay(year: 2026, month: 3, day: 7).description == "2026-03-07")
    }

    @Test func codableRoundTrip() throws {
        let day = LocalDay(year: 2026, month: 11, day: 2)
        let decoded = try JSONDecoder().decode(LocalDay.self, from: JSONEncoder().encode(day))
        #expect(decoded == day)
    }
}

@Suite("LocalTime and DailyWindow")
struct DailyWindowTests {
    let bedtime = DailyWindow(start: LocalTime(hour: 23), end: LocalTime(hour: 6))
    let afternoon = DailyWindow(start: LocalTime(hour: 13, minute: 30), end: LocalTime(hour: 17))

    @Test func localTimeClampsOutOfRangeValues() {
        #expect(LocalTime(hour: 25, minute: 75) == LocalTime(hour: 23, minute: 59))
        #expect(LocalTime(hour: -1, minute: -5) == LocalTime(hour: 0, minute: 0))
        #expect(LocalTime(hour: 6, minute: 5).description == "06:05")
        #expect(LocalTime(hour: 23).minutesSinceMidnight == 1380)
    }

    @Test func localTimeDecodingClampsAndDefaultsMinute() throws {
        let decoded = try JSONDecoder().decode(LocalTime.self, from: Data(#"{"hour": 30}"#.utf8))
        #expect(decoded == LocalTime(hour: 23, minute: 0))
    }

    @Test(arguments: [
        (22 * 60 + 59, false),
        (23 * 60, true),
        (23 * 60 + 59, true),
        (0, true),
        (2 * 60, true),
        (5 * 60 + 59, true),
        (6 * 60, false),
        (12 * 60, false),
    ])
    func bedtimeCrossesMidnight(minute: Int, expected: Bool) {
        #expect(bedtime.crossesMidnight)
        #expect(bedtime.contains(minuteOfDay: minute) == expected)
    }

    @Test(arguments: [
        (13 * 60 + 29, false),
        (13 * 60 + 30, true),
        (16 * 60 + 59, true),
        (17 * 60, false),
    ])
    func sameDayWindow(minute: Int, expected: Bool) {
        #expect(!afternoon.crossesMidnight)
        #expect(afternoon.contains(minuteOfDay: minute) == expected)
    }

    @Test func emptyWindowNeverMatches() {
        let off = DailyWindow(start: LocalTime(hour: 22), end: LocalTime(hour: 22))
        #expect(off.isEmpty)
        #expect(off.durationMinutes == 0)
        #expect((0..<1440).allSatisfy { !off.contains(minuteOfDay: $0) })
    }

    @Test func durations() {
        #expect(bedtime.durationMinutes == 7 * 60)
        #expect(afternoon.durationMinutes == 3 * 60 + 30)
    }

    @Test func containsUsesLocalTimeOfTheCalendar() {
        let lateIstanbul = instant(2026, 11, 2, 23, 15)
        #expect(bedtime.contains(lateIstanbul, in: .istanbul))
        // The same instant is 20:15 UTC: not bedtime there.
        #expect(!bedtime.contains(lateIstanbul, in: .utc))
    }

    @Test func dstTransitionNightInBerlin() {
        // On 2026-10-25 Berlin falls back from 03:00 CEST to 02:00 CET.
        let beforeFallBack = instant(2026, 10, 25, 1, 30, in: .berlin)
        let afterFallBack = beforeFallBack.adding(hours: 2) // 02:30 CET
        let morning = instant(2026, 10, 25, 6, 0, in: .berlin)
        #expect(bedtime.contains(beforeFallBack, in: .berlin))
        #expect(bedtime.contains(afterFallBack, in: .berlin))
        #expect(!bedtime.contains(morning, in: .berlin))
        // On 2026-03-29 Berlin springs forward from 02:00 to 03:00.
        let springNight = instant(2026, 3, 29, 1, 45, in: .berlin).adding(minutes: 30) // 03:15 CEST
        #expect(bedtime.contains(springNight, in: .berlin))
    }
}

@Suite("WallClock")
struct WallClockTests {
    @Test func fixedClockReturnsItsInstant() {
        let now = instant(2026, 11, 2, 9)
        #expect(FixedWallClock(now: now).now == now)
    }

    @Test func systemClockIsCloseToNow() {
        let reading = SystemWallClock().now
        #expect(abs(reading.timeIntervalSinceNow) < 60)
    }
}
