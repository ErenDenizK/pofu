import Foundation
import PofuCore
import Testing
@testable import PofuPersistence

/// The game state in the snapshot (schema version 2): it survives a
/// relaunch, a store from before it loads without one, and an unreadable
/// game never costs the gate its state.
@Suite("Game in the snapshot")
struct GameSnapshotTests {
    // 2026-11-02 12:00 in Istanbul (UTC+3).
    let noon = Date(timeIntervalSince1970: 1_793_610_000)

    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Istanbul") ?? .current
        return calendar
    }

    /// A game after a day of reaches, opens, and quiet time.
    func playedGame() -> GameState {
        let clock = WorldClock(calendar: calendar)
        var game = GameState()
        let pass = Pass(target: "instagram", grantedAt: noon.addingTimeInterval(3_600), minutes: 5, source: .free(.pause))
        clock.advance(&game, to: noon.addingTimeInterval(30 * 3_600), applying: [
            .signOfLife(at: noon),
            .resisted(at: noon.addingTimeInterval(600)),
            .opened(pass),
            GameEvent(at: noon.addingTimeInterval(2 * 3_600), kind: .returned),
            GameEvent(at: noon.addingTimeInterval(3 * 3_600), kind: .foregroundBegan),
        ])
        return game
    }

    @Test func theGameSurvivesARelaunch() throws {
        let directory = try TemporaryDirectory()
        var snapshot = try sampleSnapshot()
        snapshot.game = playedGame()
        try PofuStore(location: StorageLocation(directory: directory.url)).save(snapshot)

        guard case .loaded(let loaded) = PofuStore(location: StorageLocation(directory: directory.url)).load() else {
            Issue.record("Expected the saved snapshot")
            return
        }
        #expect(loaded == snapshot)
        #expect(loaded.schemaVersion == 2)
        let game = try #require(loaded.game)
        #expect(game.stations.pending.total > .zero)
        #expect(game.foregroundSince != nil)
        #expect(game.lastSignalAt != nil)
    }

    @Test func aStoreFromBeforeTheGameLoadsWithoutOne() throws {
        let directory = try TemporaryDirectory()
        let store = PofuStore(location: StorageLocation(directory: directory.url))
        var old = try sampleSnapshot()
        old.schemaVersion = 1
        try store.save(old)
        // Version 1 never wrote a game key.
        let text = try String(contentsOf: store.snapshotURL, encoding: .utf8)
        #expect(!text.contains("\"game\""))

        guard case .loaded(let loaded) = store.load() else {
            Issue.record("Expected the snapshot")
            return
        }
        #expect(loaded.game == nil)
        #expect(loaded.state == old.state)
        #expect(loaded.profile == old.profile)
        #expect(loaded.schemaVersion == 1)
    }

    @Test func anUnreadableGameIsDroppedAndTheGateKeepsItsState() throws {
        let directory = try TemporaryDirectory()
        let store = PofuStore(location: StorageLocation(directory: directory.url))
        let json = #"{"schemaVersion":2,"profile":{"companionName":"Pamuk"},"game":{"version":99,"tendedDays":"lots"}}"#
        try Data(json.utf8).write(to: store.snapshotURL)
        guard case .loaded(let loaded) = store.load() else {
            Issue.record("Expected the snapshot")
            return
        }
        #expect(loaded.game == nil)
        #expect(loaded.profile.companionName == "Pamuk")
    }

    @Test func aGameFromANewerBuildIsRefusedNotMisread() throws {
        let data = Data(#"{"version":2,"tendedDays":3}"#.utf8)
        #expect(throws: GameStateError.unsupportedVersion(2)) {
            try PofuCoding.makeDecoder().decode(GameState.self, from: data)
        }
    }

    @Test func aGameWithMissingFieldsLoadsWithFreshValues() throws {
        let data = Data(#"{"version":1,"tendedDays":3,"calmNights":2}"#.utf8)
        let game = try PofuCoding.makeDecoder().decode(GameState.self, from: data)
        let fresh = GameState()
        #expect(game.tendedDays == 3)
        #expect(game.calmNights == 2)
        #expect(game.care == fresh.care)
        #expect(game.calm == fresh.calm)
        #expect(game.stations == fresh.stations)
        #expect(game.clock == nil)
    }
}
