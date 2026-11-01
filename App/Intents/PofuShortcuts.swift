import AppIntents

/// Makes "Hop in" discoverable in Shortcuts and Siri without any setup.
/// Phrases are localized in `AppShortcuts.xcstrings`.
struct PofuShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CheckInIntent(),
            phrases: [
                "Hop in with \(.applicationName)",
                "Ask \(.applicationName) to hop in for \(\.$app)",
            ],
            shortTitle: "Hop in",
            systemImageName: "hand.raised.fill"
        )
    }
}
