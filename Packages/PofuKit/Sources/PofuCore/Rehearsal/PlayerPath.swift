import Foundation

/// The tester's 21 days as the player meets them: the Prova panel's own
/// path (one resisted reach a day, collect, build the cheapest levels, play
/// the banked garden rounds, tend the wonders and the visitor, "Next day"),
/// played through the real `WorldClock`. On day 21 the far bell rings
/// (`FarBell`): the morning shows it, the visit hears it. The player-path screenshots
/// (`path-dNN-*`) and the tests that guard them draw from this one run, so
/// no frame is a hand-picked world. `DemoRunTests` checks it against its
/// own copy of the same path.
public enum PlayerPath {
    /// One day of the path.
    public struct Day: Sendable {
        /// 1-based.
        public var day: Int
        /// The world when the player opens Pofu at 09:00, the time away told.
        public var morning: WorldSnapshot
        /// The world at 09:07, after the wonders and the visitor were tended.
        public var visit: WorldSnapshot
        /// The world at 23:00, the phone picked up at bedtime.
        public var night: WorldSnapshot
        /// The visit moved Koke on a stage (or Koke arrived today).
        public var visitedKoke: Bool
        /// The visit moved Çağlayan on a stage (or it arrived today).
        public var visitedCaglayan: Bool
        /// A new island appeared today: the Map is worth a frame.
        public var mapChanged: Bool
        /// The first local day's 09:00, plus `day - 1` days.
        public var morningAt: Date
        public var visitAt: Date
        public var nightAt: Date
    }

    public static let horizon = 21

    /// Day 1 starts at 09:00 local on 2 November 2026, as the Prova panel
    /// does in `DemoRunTests`.
    public static func tester(days: Int = horizon, calendar: Calendar? = nil) -> [Day] {
        let calendar = calendar ?? Calendar.gregorianIn("Europe/Istanbul")
        let rules = GameRules()
        let clock = WorldClock(rules: rules, calendar: calendar)
        var state = GameState(rules: rules)
        let time = RehearsalTime(bedtime: rules.bedtime, calendar: calendar)
        var start = date(2026, 11, 2, 9, 0, in: calendar)
        var arrival: [GameEvent] = [.signOfLife(at: start), GameEvent(at: start, kind: .foregroundBegan)]
        var result: [Day] = []
        var previous = clock.snapshot(of: state)
        for day in 1...days {
            clock.advance(&state, to: start, applying: arrival)
            let morning = clock.snapshot(of: state)

            let reach = start.addingTimeInterval(60)
            clock.advance(&state, to: start.addingTimeInterval(5 * 60), applying: [
                .signOfLife(at: reach), .resisted(at: reach.addingTimeInterval(60)),
            ])
            let collectAt = start.addingTimeInterval(5 * 60)
            _ = clock.collect(&state, at: collectAt)
            var built = 0
            while built < 2 {
                let options = clock.snapshot(of: state).stations.filter { $0.isOpen && $0.nextCost != nil && !$0.isCapped }
                guard let cheapest = options.min(by: { ($0.nextCost ?? 0) < ($1.nextCost ?? 0) }), cheapest.canAfford else { break }
                guard (try? clock.build(cheapest.id, in: &state, at: collectAt)) != nil else { break }
                built += 1
            }
            let roundsAt = start.addingTimeInterval(6 * 60)
            clock.advance(&state, to: roundsAt)
            for _ in 0..<clock.playableRounds(in: state, at: roundsAt) {
                guard (try? clock.playRound(yield: 3, in: &state, at: roundsAt)) != nil else { break }
            }
            let tendAt = start.addingTimeInterval(7 * 60)
            clock.advance(&state, to: tendAt, applying: [
                GameEvent(at: tendAt, kind: .tendedWonder(.koke)),
                GameEvent(at: tendAt, kind: .tendedWonder(.caglayan)),
                GameEvent(at: tendAt, kind: .greetedVisitor),
                GameEvent(at: tendAt, kind: .openedGift),
                GameEvent(at: tendAt, kind: .helped),
                GameEvent(at: tendAt, kind: .heardBell),
            ])
            let visit = clock.snapshot(of: state)
            let leave = start.addingTimeInterval(10 * 60)
            clock.advance(&state, to: leave)

            // Bedtime: a copy of the game, so the path itself is untouched.
            let nightAt = date(2026, 11, 1 + day, 23, 0, in: calendar)
            var late = state
            clock.advance(&late, to: nightAt, applying: RehearsalTime.awayEvents(leaving: leave, returning: nightAt))
            let night = clock.snapshot(of: late)

            result.append(Day(
                day: day,
                morning: morning,
                visit: visit,
                night: night,
                visitedKoke: morning.koke.phase == .arrived && (visit.koke.stage > morning.koke.stage || previous.koke.phase != .arrived),
                visitedCaglayan: morning.caglayan.phase == .arrived && (visit.caglayan.stage > morning.caglayan.stage || previous.caglayan.phase != .arrived),
                mapChanged: morning.islands != previous.islands || morning.koke.phase != previous.koke.phase || morning.caglayan.phase != previous.caglayan.phase,
                morningAt: start,
                visitAt: tendAt,
                nightAt: nightAt
            ))
            previous = clock.snapshot(of: state)
            let next = time.destination(of: .nextDay, from: leave)
            arrival = RehearsalTime.awayEvents(leaving: leave, returning: next)
            start = next
        }
        return result
    }

    private static func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int, in calendar: Calendar) -> Date {
        let components = DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)
        return calendar.date(from: components) ?? Date(timeIntervalSinceReferenceDate: 815_000_000)
    }
}

extension Calendar {
    /// A Gregorian calendar in `identifier`'s time zone (Türkiye is UTC+3 all year).
    static func gregorianIn(_ identifier: String) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: identifier) ?? .gmt
        return calendar
    }
}
