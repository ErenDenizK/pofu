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
