import SwiftUI

@main
struct PofuApp: App {
    /// The same instance `CheckInIntent` uses, so a Hop! started by the
    /// automation appears in this scene.
    private let model = AppModel.shared

    var body: some Scene {
        WindowGroup {
            RootView(model: model)
        }
    }
}
