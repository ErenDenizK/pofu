import Foundation
import Testing

@testable import PofuCore

/// The trial's core facts the Home UI reads: a wonder island tended today,
/// the apps the picker offers, and the player path's real reaches and minutes.
@Suite struct TrialCoreTests {
    @Test func aWonderIslandKnowsItWasTendedToday() {
        let day = LocalDay(year: 2026, month: 11, day: 16)
        var game = GameState(rules: GameRules())
        game.wonders.islands[.koke] = WonderIslandState(arrivedOn: day, stage: 2, lastAdvanceDay: day)
        let status = WonderIslands.status(of: .koke, game: game, day: day)
        #expect(status.tendedToday)
        #expect(!status.canAdvance)
        let tomorrow = LocalDay(year: 2026, month: 11, day: 17)
        #expect(!WonderIslands.status(of: .koke, game: game, day: tomorrow).tendedToday)
    }

    @Test func thePickerOffersOnlyTheTargetedApps() {
        #expect(ProtectedApp.offered == [.instagram, .youtube, .tiktok])
        // The enum keeps every case, so a stored choice still decodes.
        #expect(ProtectedApp.allCases.count > ProtectedApp.offered.count)
    }

    @Test func thePathCarriesTheDaysReachesAndMinutes() {
        let path = PlayerPath.tester(days: 3)
        for day in path {
            #expect(day.beads == [true], "day \(day.day): one reach, let go")
            #expect(day.morning.guardedMinutesToday == 0, "day \(day.day): 09:00 comes before any use")
            #expect(day.night.guardedMinutesToday == PlayerPath.usageMinutes, "day \(day.day): 23:00 shows the day's minutes")
        }
    }
}
