import Foundation
import PofuCore

/// A world played through the real game clock, for screenshots and tests:
/// collect and build here are `WorldClock.collect` and `WorldClock.build`.
public struct SampleGame: Sendable {
    public let clock: WorldClock
    public var state: GameState
    /// The moment the sample is looked at.
    public var now: Date
    /// Today's reaches, in order (`true` when skipped), as the gate logged
    /// them.
    public var beads: [Bool]

    public var snapshot: WorldSnapshot {
        clock.snapshot(of: state)
    }

    public var today: TodaySummary {
        let world = snapshot
        return TodaySummary(beads: beads, guardedMinutes: world.guardedMinutesToday, dailyHourMinutes: world.dailyHourMinutes)
    }

    @discardableResult
    public mutating func collect() -> SeedPouch? {
        clock.collect(&state, at: now)
    }

    @discardableResult
    public mutating func build(_ station: StationID) -> BuildReceipt? {
        try? clock.build(station, in: &state, at: now)
    }

    /// Builds the cheapest affordable level until none is left.
    mutating func spend() {
        while case .build(let station, _)? = VisitQueue.affordableBuild(in: snapshot, seeds: snapshot.jar) {
            guard build(station) != nil else { return }
        }
    }
}

extension IslandSamples {
    /// The fifth morning of a good first week, played minute by minute
    /// through `WorldClock` under the Screen Time measurement. Pofu was
    /// tended every day; the player visited morning and evening, collected,
    /// and built the cheapest level the seeds covered. This morning: three
    /// skips and one three-minute quick check (a quarter hour of guarded
    /// time); at 10:40 the night's seeds are waiting.
    public static func playedWeek(calendar: Calendar = .current) -> SampleGame {
        let rules = GameRules(measurement: .screenTime)
        let clock = WorldClock(rules: rules, calendar: calendar)
        func at(_ day: Int, _ hour: Int, _ minute: Int) -> Date {
            // From Monday 26 October 2026, local time.
            let components = DateComponents(year: 2026, month: 10, day: 26 + day, hour: hour, minute: minute)
            return calendar.date(from: components)
                ?? Date(timeIntervalSinceReferenceDate: 815_000_000 + Double(day) * 86_400 + Double(hour * 3600 + minute * 60))
        }

        var state = GameState(rules: rules)
        clock.start(&state, at: at(0, 9, 0), lastSignal: at(0, 9, 0))
        var game = SampleGame(clock: clock, state: state, now: at(0, 9, 0), beads: [])
        for day in 0..<4 {
            if day > 0 {
                // The morning visit.
                game.now = at(day, 8, 30)
                game.collect()
                game.spend()
            }
            clock.advance(&game.state, to: at(day, 21, 0), applying: [
                .signOfLife(at: at(day, 9, 5)),
                .resisted(at: at(day, 11, 20)),
                .resisted(at: at(day, 16, 45)),
            ])
            // The evening visit.
            game.now = at(day, 21, 0)
            game.collect()
            game.spend()
        }

        let target: TargetGroupID = "instagram"
        let quickCheck = Pass(target: target, grantedAt: at(4, 9, 40), minutes: 3, source: .free(.pause))
        clock.advance(&game.state, to: at(4, 10, 40), applying: [
            .signOfLife(at: at(4, 8, 50)),
            .resisted(at: at(4, 8, 52)),
            .resisted(at: at(4, 9, 21)),
            .opened(quickCheck),
            GameEvent(at: at(4, 9, 44), kind: .usageMeasured(minutes: 15)),
            .resisted(at: at(4, 10, 15)),
        ])
        game.now = at(4, 10, 40)
        game.beads = [true, true, false, true]
        return game
    }
}
