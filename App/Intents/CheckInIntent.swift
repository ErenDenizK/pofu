import AppIntents
import PofuCore

/// The soft gate's entry point (ADR-0008). A Shortcuts personal automation
/// runs it whenever a protected app is opened ("App, Is Opened, Run
/// Immediately"), one automation per app.
///
/// It starts in the background. When a valid pass covers the open, it
/// records a pass-through and finishes there, so reopening the app during
/// a pass never flashes Pofu. Otherwise it asks the system to bring Pofu to
/// the foreground and starts Hop! for that app. The decision itself lives
/// in `CheckInRouter`, which is unit-tested.
struct CheckInIntent: AppIntent {
    static let title: LocalizedStringResource = "Hop in"
    static let description = IntentDescription(
        "Pofu hops in before the app opens. Add it to an automation that runs when the app is opened, and pick that same app here."
    )

    /// Background first; come forward only when Hop! is needed.
    static let supportedModes: IntentModes = [.background, .foreground(.dynamic)]

    @Parameter(title: "App", description: "The app this automation guards.")
    var app: TargetApp

    static var parameterSummary: some ParameterSummary {
        Summary("Hop in for \(\.$app)")
    }

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult {
        let model = AppModel.shared
        let target = app.protectedApp
        let mode = systemContext.currentMode
        let plan = model.planCheckIn(
            for: target,
            isForeground: mode == .foreground,
            canContinueInForeground: mode.canContinueInForeground
        )

        switch plan {
        case .completeSilently, .ignore, .cannotStartHop:
            return .result()

        case .startHop:
            model.startHop(for: target)
            return .result()

        case .continueInForegroundThenStartHop:
            do {
                // No confirmation: the automation already expresses the
                // user's consent, and a prompt would cost the 3-second skip.
                try await continueInForeground(nil, alwaysConfirm: false)
            } catch {
                model.hopCouldNotStart(for: target)
                return .result()
            }
            model.startHop(for: target)
            return .result()
        }
    }
}
