import Foundation
import PofuCore

/// What the next island level's line says, before it is worded
/// (`WorldStrings.nextIslandLevel`): the levels still to build, the days
/// still to pass, or that the level is ready.
public enum GoalLine: Hashable, Sendable {
    case levels(island: Int, left: Int)
    case days(island: Int, left: Int)
    case ready(island: Int)

    public init(_ requirement: IslandLevelRequirement) {
        if requirement.isMet {
            self = .ready(island: requirement.level)
        } else if requirement.levelsLeft > 0 {
            self = .levels(island: requirement.level, left: requirement.levelsLeft)
        } else {
            self = .days(island: requirement.level, left: requirement.tendedDaysLeft)
        }
    }
}

/// A wonder island's state under its name (`WorldStrings.wonderState`).
public enum WonderState: Hashable, Sendable {
    case asleep
    case healing(stage: Int)
    case healed

    public init(stage: Int) {
        switch stage {
        case ..<1: self = .asleep
        case WonderIslands.healedStage...: self = .healed
        default: self = .healing(stage: stage)
        }
    }
}

/// What a wonder island's stop says about today, under its state
/// (`WorldStrings.wonderToday`): a tap helps it today, today's tap is done,
/// it waits for one skipped reach today, or it sleeps for the night. A
/// healed island, or one not arrived yet, says nothing more.
public enum WonderToday: Hashable, Sendable {
    case tapHelps
    case doneForToday
    case needsSkip
    case sleeping

    public init?(_ status: WonderStatus) {
        guard status.isArrived, !status.isHealed else { return nil }
        if status.isAsleep {
            self = .sleeping
        } else if status.canAdvance {
            self = .tapHelps
        } else if status.tendedToday {
            self = .doneForToday
        } else {
            self = .needsSkip
        }
    }
}

/// Pofu's line on Home when no beat is waiting (`WorldStrings.dailyLine`):
/// what happened today first (a gift, the reaches let go, a guest), else
/// the hour's line, two of each turned by the day, so the line is worth a
/// look tomorrow too. At night the island sleeps and the line says what the
/// morning brings.
public enum HomeDailyLine: Hashable, Sendable {
    case night(variant: Int)
    case giftArrived
    case letGo(count: Int)
    case guest
    case morning(variant: Int)
    case midday(variant: Int)
    case evening(variant: Int)

    /// Lines for each hour, turned by the day.
    public static let variants = 2

    /// - Parameters:
    ///   - hour: The local hour, 0 to 23.
    ///   - dayIndex: Any day count; it only turns the hour's lines.
    public static func choose(
        hour: Int,
        isBedtime: Bool,
        skipsToday: Int,
        giftIsNew: Bool,
        guestWaiting: Bool,
        dayIndex: Int
    ) -> HomeDailyLine {
        let variant = ((dayIndex % variants) + variants) % variants
        if isBedtime || hour >= 22 || hour < 5 {
            return .night(variant: variant)
        }
        if giftIsNew {
            return .giftArrived
        }
        if skipsToday > 0 {
            return .letGo(count: skipsToday)
        }
        if guestWaiting {
            return .guest
        }
        switch hour {
        case 5..<11: return .morning(variant: variant)
        case 11..<17: return .midday(variant: variant)
        default: return .evening(variant: variant)
        }
    }

    /// The line for this world and today.
    public static func choose(world: WorldSnapshot, skipsToday: Int, calendar: Calendar = .current) -> HomeDailyLine {
        let now = world.clock ?? Date()
        let hour = calendar.component(.hour, from: now)
        let day = calendar.ordinality(of: .day, in: .era, for: now) ?? 0
        let guest = world.visitor.map { $0.state == .arriving || $0.state == .present } ?? false
        return choose(
            hour: hour,
            isBedtime: world.isBedtime,
            skipsToday: skipsToday,
            giftIsNew: world.koke.giftIsNew || world.caglayan.giftIsNew,
            guestWaiting: guest,
            dayIndex: day
        )
    }
}
