import Testing
@testable import PofuCore

@Suite("Hop question")
struct HopQuestionTests {
    @Test func middayIsNeverTheLateNightLine() {
        // A stale bedtime flag on a daytime screen (the hour the scene shows is day) must not say "late".
        for rung in [FrictionRung.pause, .intent] {
            for past in [false, true] {
                let q = HopQuestion.choose(sessionIsBedtime: true, shownHourIsDark: false, rung: rung, isPastDailyHour: past)
                #expect(q != .late)
            }
        }
        #expect(HopQuestion.choose(sessionIsBedtime: false, shownHourIsDark: false, rung: .pause, isPastDailyHour: false) == .quickCheckIn)
        #expect(HopQuestion.choose(sessionIsBedtime: true, shownHourIsDark: false, rung: .intent, isPastDailyHour: false) == .intent)
    }

    @Test func bedtimeOnANightScreenIsLate() {
        #expect(HopQuestion.choose(sessionIsBedtime: true, shownHourIsDark: true, rung: .pause, isPastDailyHour: false) == .late)
    }
}
