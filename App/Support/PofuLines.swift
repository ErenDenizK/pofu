import PofuCore
import SwiftUI

/// Pofu's own lines. Pofu speaks in the first person, short and warm; it
/// never shames an open (user flows, voice rules).
enum PofuLines {
    /// Home's speech bubble.
    static func home(skips: Int, attempts: Int, isBedtime: Bool, needsSetup: Bool) -> LocalizedStringKey {
        if needsSetup {
            return "I'm not at any door yet. One minute to set me up?"
        }
        if isBedtime {
            return "Shh. I'm sleeping. You could too."
        }
        if attempts == 0 {
            return "Quiet so far. I like it here."
        }
        if skips == 0 {
            return "Every reach is a fresh chance. The next one's ours."
        }
        return "\(skips) skips today. I'm getting so fluffy."
    }

    /// The celebration line after a skip, rotating so it is never the same
    /// twice in a row.
    static func skipped(_ index: Int) -> LocalizedStringKey {
        switch abs(index) % 3 {
        case 0: "Look at you. I feel fluffier already."
        case 1: "Ooh. That was a good one."
        default: "The wheel can spin without us."
        }
    }

    /// Pofu's answer to a reason on the intent rung.
    static func answer(to reason: IntentReason) -> LocalizedStringKey {
        switch reason {
        case .reply: "Go reply. I'll keep it short for you."
        case .lookUp: "Find it and come back to me."
        case .post: "Post it, don't scroll it."
        case .bored: "Bored is allowed. Be bored with me for a minute?"
        case .habit: "Thanks for being honest. That's the hard part."
        case .needBreak: "Fair. Want a better break? A minute outside?"
        }
    }

    /// The chip label for a reason.
    static func label(for reason: IntentReason) -> LocalizedStringKey {
        switch reason {
        case .reply: "Reply to someone"
        case .lookUp: "Look something up"
        case .post: "Post something"
        case .bored: "Just bored"
        case .habit: "Pure habit"
        case .needBreak: "Need a break"
        }
    }
}

extension ActivityKind {
    var label: LocalizedStringKey {
        switch self {
        case .focus: "Focus"
        case .study: "Study"
        case .exercise: "Workout"
        case .walk: "Walk"
        case .chores: "Chores"
        case .creative: "Creative"
        case .custom: "Custom"
        }
    }

    var symbolName: String {
        switch self {
        case .focus: "scope"
        case .study: "book"
        case .exercise: "dumbbell"
        case .walk: "figure.walk"
        case .chores: "sparkles"
        case .creative: "pencil"
        case .custom: "plus"
        }
    }
}
