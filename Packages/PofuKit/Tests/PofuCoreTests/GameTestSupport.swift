import Foundation
@testable import PofuCore

/// A game state and the clock that advances it, for tests.
struct World {
    let clock: WorldClock
    var state: GameState

    init(rules: GameRules = GameRules(), calendar: Calendar = .istanbul) {
        self.clock = WorldClock(rules: rules, calendar: calendar)
        self.state = GameState(rules: rules)
    }

    var rules: GameRules {
        clock.rules
    }

    var snapshot: WorldSnapshot {
        clock.snapshot(of: state)
    }

    @discardableResult
    mutating func advance(to date: Date, _ events: GameEvent...) -> WorldDelta {
        clock.advance(&state, to: date, applying: events)
    }

    @discardableResult
    mutating func advance(to date: Date, applying events: [GameEvent]) -> WorldDelta {
        clock.advance(&state, to: date, applying: events)
    }

    mutating func collect(at date: Date) -> SeedPouch? {
        clock.collect(&state, at: date)
    }

    @discardableResult
    mutating func build(_ station: StationID, at date: Date) throws -> BuildReceipt {
        try clock.build(station, in: &state, at: date)
    }

    /// Everything in the pouch and the jar.
    var seeds: Energy {
        state.stations.pending.total + state.stations.jar
    }
}

/// A pass of `minutes` for the test target, granted at `start`.
func gamePass(at start: Date, minutes: Int, source: PassSource = .free(.pause)) -> Pass {
    Pass(target: testTarget, grantedAt: start, minutes: minutes, source: source)
}

extension GameEvent {
    static func foregroundBegan(at date: Date) -> GameEvent {
        GameEvent(at: date, kind: .foregroundBegan)
    }

    static func foregroundEnded(at date: Date) -> GameEvent {
        GameEvent(at: date, kind: .foregroundEnded)
    }

    static func returned(at date: Date) -> GameEvent {
        GameEvent(at: date, kind: .returned)
    }

    static func endedEarly(_ pass: Pass, at date: Date) -> GameEvent {
        GameEvent(at: date, kind: .passEndedEarly(passID: pass.id))
    }

    static func measured(_ minutes: Int, at date: Date) -> GameEvent {
        GameEvent(at: date, kind: .usageMeasured(minutes: minutes))
    }
}

/// A random but reproducible script of gate events over `hours` from
/// `start`, for property tests.
func randomScript(seed: UInt64, from start: Date, hours: Int) -> [GameEvent] {
    var rng = SplitMix64(seed: seed)
    var events: [GameEvent] = [.signOfLife(at: start)]
    var cursor = start
    let end = start.adding(hours: Double(hours))
    var foreground = false
    while true {
        cursor = cursor.addingTimeInterval(Double(Int.random(in: 30...(90 * 60), using: &rng)))
        guard cursor < end else { break }
        switch Int.random(in: 0..<10, using: &rng) {
        case 0:
            events.append(.signOfLife(at: cursor))
        case 1, 2:
            events.append(.resisted(at: cursor))
        case 3, 4, 5:
            let minutes = [1, 2, 3, 3, 5, 5, 15, 30][Int.random(in: 0..<8, using: &rng)]
            let source: PassSource = Int.random(in: 0..<12, using: &rng) == 0 ? .emergency : .free(.intent)
            let pass = gamePass(at: cursor, minutes: minutes, source: source)
            events.append(.opened(pass))
            if Bool.random(using: &rng) {
                events.append(.endedEarly(pass, at: cursor.addingTimeInterval(Double(Int.random(in: 20...(minutes * 60), using: &rng)))))
            }
        case 6:
            events.append(foreground ? .foregroundEnded(at: cursor) : .foregroundBegan(at: cursor))
            foreground.toggle()
        case 7:
            events.append(.returned(at: cursor))
        case 8:
            events.append(.measured(Int.random(in: 0...120, using: &rng), at: cursor))
        default:
            break
        }
    }
    return events
}
