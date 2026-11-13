import Foundation

/// The far bell: the beat that closes Book One's first stretch (route
/// 2026-11-12 §6 step 10). Once Koke and Çağlayan are healed, on the
/// player's 21st tended day (20 behind them when it starts), a bell far
/// off plays Pofu's four notes and one more: the first rumour of Çanlar
/// (story map §4, lore bible M1, "every new island's first rumour is a
/// bell that knows a little more"). Pofu says it on the visit card; the
/// player's answer marks it heard. It never expires (ADR-0017): a bell
/// the player has not heard waits for the next visit.
public struct FarBellState: Hashable, Sendable, Codable {
    /// The day the bell first rang.
    public var rangOn: LocalDay?
    /// The day the player heard it (answered Pofu's line).
    public var heardOn: LocalDay?

    public init(rangOn: LocalDay? = nil, heardOn: LocalDay? = nil) {
        self.rangOn = rangOn
        self.heardOn = heardOn
    }
}

/// What the world shows of the far bell.
public enum FarBellStatus: Hashable, Sendable {
    /// Not yet.
    case silent
    /// It rang and Pofu has not told the player yet: the visit's beat.
    case ringing
    /// The player heard it.
    case heard
}

public enum FarBell {
    /// Tended days behind the player when the bell can ring: the day it
    /// rings is their 21st tended day, the last of Rehearsal's three weeks.
    public static let tendedDays = 20

    /// Starts `day`: the bell rings once both wonder islands are healed and
    /// `tendedDays` days were tended. It rings once.
    static func roll(_ state: inout FarBellState, to day: LocalDay, tendedDays: Int, wonders: WonderLedger) {
        guard state.rangOn == nil, tendedDays >= Self.tendedDays else { return }
        let healed = [WonderIslandID.koke, .caglayan].allSatisfy { wonders[$0].stage >= WonderIslands.healedStage }
        guard healed else { return }
        state.rangOn = day
    }

    /// The player answered Pofu's line on `day`: a bell that rang is heard.
    static func hear(_ state: inout FarBellState, on day: LocalDay) {
        guard state.rangOn != nil, state.heardOn == nil else { return }
        state.heardOn = day
    }

    public static func status(of state: FarBellState) -> FarBellStatus {
        if state.heardOn != nil { return .heard }
        return state.rangOn != nil ? .ringing : .silent
    }
}
