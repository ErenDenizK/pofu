import Foundation
import PofuCore
import Testing
@testable import PofuPersistence

/// A game played for two weeks survives the store: the demo's relaunch
/// promise (game-solid spec, PR 1), through the same `PofuStore` the app
/// uses, with the state a real fortnight leaves behind.
@Suite("Game save")
struct GameSaveTests {
    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Istanbul") ?? .current
        return calendar
    }

    /// `hour:minute` local on the `day`-th day (0-based) after 2026-11-02.
    func at(day: Int, _ hour: Int, _ minute: Int = 0) throws -> Date {
        let components = DateComponents(year: 2026, month: 11, day: 2 + day, hour: hour, minute: minute)
        return try #require(calendar.date(from: components))
    }

    /// Fourteen days: a sign of life and a resisted reach at 10:00, seeds
    /// collected and Koke called on at 20:00, the cheapest affordable level
    /// built at 20:05.
    func fortnight() throws -> GameState {
        let clock = WorldClock(calendar: calendar)
        var game = GameState()
        clock.advance(&game, to: try at(day: 0, 9), applying: [.signOfLife(at: try at(day: 0, 9))])
        for day in 0..<14 {
            let morning = try at(day: day, 10)
            clock.advance(&game, to: morning, applying: [.signOfLife(at: morning), .resisted(at: morning)])
            let evening = try at(day: day, 20)
            clock.advance(&game, to: evening, applying: [
                GameEvent(at: evening, kind: .foregroundBegan),
                GameEvent(at: evening, kind: .tendedWonder(.koke)),
            ])
            _ = clock.collect(&game, at: evening)
            let build = try at(day: day, 20, 5)
            let options = clock.snapshot(of: game).stations.filter { $0.isOpen && $0.nextCost != nil && !$0.isCapped }
            if let cheapest = options.min(by: { ($0.nextCost ?? 0) < ($1.nextCost ?? 0) }), cheapest.canAfford {
                try clock.build(cheapest.id, in: &game, at: build)
            }
            clock.advance(&game, to: try at(day: day, 20, 10), applying: [GameEvent(at: try at(day: day, 20, 10), kind: .foregroundEnded)])
        }
        return game
    }

    @Test func aMidGameSnapshotSurvivesTheStore() throws {
        let directory = try TemporaryDirectory()
        var snapshot = try sampleSnapshot()
        let game = try fortnight()
        snapshot.game = game
        // The fortnight left something in every part the demo relies on.
        #expect(game.tendedDays >= 13)
        #expect(game.stations.levels.values.reduce(0, +) > 0)
        #expect(game.stations.arrivalOrder.contains(.harbor))
        #expect(game.wonders[.koke].rumouredOn != nil)

        try PofuStore(location: StorageLocation(directory: directory.url)).save(snapshot)

        // A new store instance stands in for a new process.
        guard case .loaded(let loaded) = PofuStore(location: StorageLocation(directory: directory.url)).load() else {
            Issue.record("Expected the saved snapshot")
            return
        }
        #expect(loaded == snapshot)
        let loadedGame = try #require(loaded.game, "the saved game came back empty")
        #expect(loadedGame == game)
        #expect(loadedGame.tendedDays == game.tendedDays)
        #expect(loadedGame.stations == game.stations)
        #expect(loadedGame.wonders == game.wonders)
        #expect(loadedGame.visitors == game.visitors)
    }
}
