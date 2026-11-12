import Foundation
import Testing
@testable import PofuCore

/// The flow audit (tracker, "Half-finished"): days 1 to 21 for three kinds
/// of player, played through the real game model by `GameScenarioTests.play`
/// (the minute-by-minute behaviour model of `tools/sim/island_economy.py`).
///
/// - typical: about ten resisted reaches a day (the economy brief's scale A);
/// - heavy scroller: few resists, low wellbeing;
/// - perfect: the monk (resists everything), who also greets each visitor.
///
/// Rules checked (home progression sections 3 and 11.1, game plan day table):
///
/// 1. the harbor opens on tended day 3;
/// 2. Koke's rumour comes after the fifth tended day with the harbor open,
///    and the island opens on the next day;
/// 3. Rule 3: no window of three tended days passes without a visible
///    change: a station level, an island level, a resident heart, a decor
///    piece, an island stage (Koke's rumour, arrival or healing stage) or
///    the harbor opening;
/// 4. nothing decays: no counter that the player sees ever falls;
/// 5. Çağlayan's rumour comes once Koke is healed, from the eighth tended day.
///
/// Days here count from 0 in the log lines and from 1 in the messages.
/// Each run prints one line per day so the pacing can be reviewed.
@Suite("Flow audit, days 1 to 21")
struct FlowAuditTests {
    enum Player: String, CaseIterable, Sendable {
        case typical
        case heavy
        case perfect

        var archetype: GameScenarioTests.Archetype {
            switch self {
            case .typical: .typical
            case .heavy: .heavy
            case .perfect: .monk
            }
        }
    }

    static let horizon = 21

    static let runs: [Player: [GameScenarioTests.DayLog]] = Dictionary(
        uniqueKeysWithValues: Player.allCases.map { player in
            let outcome = GameScenarioTests.play(player.archetype, seed: 7, greetsVisitors: true)
            return (player, Array(outcome.log.prefix(horizon)))
        }
    )

    static func log(_ player: Player) -> [GameScenarioTests.DayLog] {
        runs[player] ?? []
    }

    /// What is new on `index` compared with the day before.
    static func changes(_ log: [GameScenarioTests.DayLog], at index: Int) -> [String] {
        let now = log[index]
        let before = index > 0 ? log[index - 1] : nil
        var found: [String] = []
        if now.levels > (before?.levels ?? 0) { found.append("+\(now.levels - (before?.levels ?? 0)) lvl") }
        if now.islandLevel > (before?.islandLevel ?? 0) { found.append("IL\(now.islandLevel)") }
        if now.harborOpen, !(before?.harborOpen ?? false) { found.append("harbor") }
        if now.kokePhase.rawValue > (before?.kokePhase ?? .hidden).rawValue {
            found.append(now.kokePhase == .rumoured ? "Koke rumour" : "Koke arrives")
        }
        if now.kokeStage > (before?.kokeStage ?? 0) { found.append("Koke stage \(now.kokeStage)") }
        if now.caglayanPhase.rawValue > (before?.caglayanPhase ?? .hidden).rawValue {
            found.append(now.caglayanPhase == .rumoured ? "Çağlayan rumour" : "Çağlayan arrives")
        }
        if now.caglayanStage > (before?.caglayanStage ?? 0) { found.append("Çağlayan stage \(now.caglayanStage)") }
        if now.hearts > (before?.hearts ?? 0) { found.append("heart \(now.hearts)") }
        return found
    }

    /// The compact day-by-day log.
    static func render(_ player: Player) -> String {
        let log = Self.log(player)
        var lines = ["FLOW AUDIT \(player.rawValue)"]
        for index in log.indices {
            let day = log[index]
            let new = Self.changes(log, at: index)
            lines.append(
                "  d\(String(format: "%02d", index + 1)) tended \(String(format: "%2d", day.tendedDays))"
                    + " seeds \(String(format: "%3d", day.seeds)) resisted \(String(format: "%2d", day.resisted))"
                    + " levels \(String(format: "%2d", day.levels)) IL\(String(format: "%2d", day.islandLevel))"
                    + " hearts \(day.hearts) decor \(day.decor) koke \(day.kokePhase)/\(day.kokeStage)"
                    + " well \(String(format: "%3.0f", day.wellbeing))"
                    + (new.isEmpty ? "  . (nothing new)" : "  NEW: " + new.joined(separator: ", "))
            )
        }
        return lines.joined(separator: "\n")
    }

    /// Start days (1-based) of every window of `length` days with no change.
    static func deadWindows(_ log: [GameScenarioTests.DayLog], length: Int = 3) -> [ClosedRange<Int>] {
        guard log.count >= length else { return [] }
        let changed = log.indices.map { !Self.changes(log, at: $0).isEmpty }
        return (0...(log.count - length)).compactMap { start in
            changed[start..<(start + length)].contains(true) ? nil : (start + 1)...(start + length)
        }
    }

    /// The same windows if resident hearts did not count (a visit needs a
    /// greeting; the player may not bother): reported, not asserted.
    static func deadWindowsWithoutHearts(_ log: [GameScenarioTests.DayLog]) -> [ClosedRange<Int>] {
        let changed = log.indices.map { index in
            Self.changes(log, at: index).contains { !$0.hasPrefix("heart") }
        }
        guard log.count >= 3 else { return [] }
        return (0...(log.count - 3)).compactMap { start in
            changed[start..<(start + 3)].contains(true) ? nil : (start + 1)...(start + 3)
        }
    }

    @Test(arguments: Player.allCases)
    func printsTheDayByDayLog(player: Player) {
        let log = Self.log(player)
        #expect(log.count == Self.horizon)
        print(Self.render(player))
        let bare = Self.deadWindowsWithoutHearts(log).map { "\($0.lowerBound)-\($0.upperBound)" }
        print("  (info) \(player.rawValue): three-day windows with no level, island level, harbor or Koke change, hearts ignored: \(bare.isEmpty ? "none" : bare.joined(separator: ", "))")
    }

    @Test(arguments: Player.allCases)
    func theHarborOpensOnTendedDayThree(player: Player) throws {
        let log = Self.log(player)
        let opened = try #require(log.firstIndex { $0.harborOpen }, "\(player): the harbor never opened in 21 days")
        // A log line is the state at the end of a simulated day, after the
        // local-midnight roll into the next calendar day. Two completed
        // tended days mean the day in progress is the third: the fog lifts
        // when that day starts, never earlier (home progression section 3).
        #expect(log[opened].tendedDays == 2, "\(player): harbor opened with \(log[opened].tendedDays) completed tended days (the third day should be in progress)")
        #expect(opened == 1, "\(player): the fog lifted at the start of calendar day \(opened + 2), not day 3")
        #expect(log[0].harborOpen == false)
    }

    @Test(arguments: Player.allCases)
    func kokeRumourThenArrivalAsThePlanSays(player: Player) throws {
        let log = Self.log(player)
        let rumour = try #require(log.firstIndex { $0.kokePhase != .hidden }, "\(player): no Koke rumour in 21 days")
        let arrival = try #require(log.firstIndex { $0.kokePhase == .arrived }, "\(player): Koke never arrived in 21 days")
        #expect(log[rumour].tendedDays >= WonderIslands.rumourTendedDays, "\(player): rumour with \(log[rumour].tendedDays) tended days")
        #expect(log[rumour].harborOpen)
        #expect(arrival == rumour + 1, "\(player): rumour day \(rumour + 1), arrival day \(arrival + 1)")
        // The game plan day table: rumour about day 5, arrival day 6.
        if player == .typical {
            #expect((4...8).contains(rumour), "typical: rumour on day \(rumour + 1)")
        }
    }

    @Test(arguments: Player.allCases)
    func caglayanComesAfterKokeIsHealed(player: Player) throws {
        let log = Self.log(player)
        let rumour = try #require(log.firstIndex { $0.caglayanPhase != .hidden }, "\(player): no Çağlayan rumour in 21 days")
        let healed = try #require(log.firstIndex { $0.kokeStage >= WonderIslands.healedStage })
        #expect(rumour >= healed, "\(player): Çağlayan rumour on day \(rumour + 1), Koke healed on day \(healed + 1)")
        #expect(log[rumour].tendedDays >= WonderIslands.caglayanRumourTendedDays)
    }

    @Test(arguments: Player.allCases)
    func nothingEverDecaysAndTheIslandLevelNeverFalls(player: Player) {
        let log = Self.log(player)
        for (earlier, later) in zip(log, log.dropFirst()) {
            #expect(later.levels >= earlier.levels, "\(player): station levels fell on day \(later.day + 1)")
            #expect(later.islandLevel >= earlier.islandLevel, "\(player): island level fell on day \(later.day + 1)")
            #expect(later.hearts >= earlier.hearts, "\(player): hearts fell on day \(later.day + 1)")
            #expect(later.decor >= earlier.decor, "\(player): decor fell on day \(later.day + 1)")
            #expect(later.kokeStage >= earlier.kokeStage, "\(player): Koke's stage fell on day \(later.day + 1)")
            #expect(later.tendedDays >= earlier.tendedDays)
        }
    }

    @Test(arguments: Player.allCases)
    func noThreeTendedDaysPassWithoutAVisibleChange(player: Player) {
        let log = Self.log(player)
        let dead = Self.deadWindows(log)
        let list = dead.map { "days \($0.lowerBound) to \($0.upperBound)" }.joined(separator: "; ")
        #expect(dead.isEmpty, "FLOW AUDIT \(player): windows of three days with nothing new: \(list)\n\(Self.render(player))")
    }

    @Test func theHeavyScrollerStillGetsSomethingNewEveryThreeDays() {
        let log = Self.log(.heavy)
        // Day 1 builds; the heavy scroller never starves (a skipped day only pauses).
        #expect(log.first.map { $0.levels > 0 } ?? false)
        let dead = Self.deadWindows(log)
        #expect(dead.isEmpty, "heavy scroller dead windows: \(dead)")
        // Pofu is tired, never gone, and the world kept every gain.
        #expect(log.allSatisfy { $0.wellbeing >= 5 })
        #expect((log.last?.levels ?? 0) >= (log.dropLast().last?.levels ?? 0))
    }
}
