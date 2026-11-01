import SwiftUI

@main
struct PofuApp: App {
    /// The same instance `CheckInIntent` uses, so a Hop! started by the
    /// automation appears in this scene.
    private let model = AppModel.shared

    init() {
        // Before launch finishes, so a tap on the pass reminder that
        // launches Pofu is delivered.
        PassExpiryReminder.install()
    }

    var body: some Scene {
        WindowGroup {
            RootView(model: model)
        }
    }
}
