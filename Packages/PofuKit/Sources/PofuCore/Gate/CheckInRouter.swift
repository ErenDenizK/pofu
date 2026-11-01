import Foundation

/// Where an open of a protected app should go, decided before anything is
/// recorded.
public enum CheckInRoute: Hashable, Sendable {
    /// A valid pass covers the open: complete in the background, silently.
    case passThrough(Pass)
    /// Hop! is already on screen for this app: the automation fired again
    /// for the same reach, so nothing new happens.
    case alreadyPresenting
    /// Pofu needs the foreground to run Hop!.
    case hop
}

/// What `CheckInIntent` does with a route, given where it is running.
public enum CheckInPlan: Hashable, Sendable {
    /// Record the pass-through and finish without showing anything.
    case completeSilently(Pass)
    /// Nothing to do.
    case ignore
    /// Already in the foreground: start Hop! right away.
    case startHop
    /// Ask the system to bring Pofu forward, then start Hop!.
    case continueInForegroundThenStartHop
    /// Hop! is needed but the system does not allow Pofu to come forward
    /// right now. Nothing is recorded as an attempt: no reach was shown.
    case cannotStartHop
}

/// The soft gate's routing logic, factored out of `CheckInIntent` so it
/// can be tested without the App Intents runtime (ADR-0008).
///
/// Order matters: a valid pass wins over everything, so reopening an app
/// during a pass never flashes Pofu, even when a Hop! for it is somehow
/// still on screen.
public struct CheckInRouter: Sendable {
    public init() {}

    /// Routes an open of `app` at `date`.
    ///
    /// - Parameter presenting: The app whose Hop! is on screen, if any.
    public func route(
        for app: ProtectedApp,
        at date: Date,
        passes: PassLedger,
        presenting: ProtectedApp?
    ) -> CheckInRoute {
        if let pass = passes.validPass(for: app.target, at: date) {
            return .passThrough(pass)
        }
        if presenting == app {
            return .alreadyPresenting
        }
        return .hop
    }

    /// Turns a route into the intent's plan for its current runtime mode.
    ///
    /// - Parameters:
    ///   - isForeground: Whether the intent already runs in the foreground.
    ///   - canContinueInForeground: Whether the system allows a transition
    ///     to the foreground (`systemContext.currentMode`).
    public func plan(
        for route: CheckInRoute,
        isForeground: Bool,
        canContinueInForeground: Bool
    ) -> CheckInPlan {
        switch route {
        case .passThrough(let pass):
            return .completeSilently(pass)
        case .alreadyPresenting:
            return .ignore
        case .hop:
            if isForeground {
                return .startHop
            }
            return canContinueInForeground ? .continueInForegroundThenStartHop : .cannotStartHop
        }
    }
}
