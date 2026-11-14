import PofuWorld
import SwiftUI

/// The frame meter switch of the Prova panel: lays `WorldLook.frameMeter`
/// over whatever look the world has, in Rehearsal mode only. Live (the
/// scene reads the look from the environment) and in every build
/// configuration, because stutter is judged on release builds too.
/// Off by default; kept on this device.
struct RehearsalFrameMeter: ViewModifier {
    static let key = "rehearsal.frameMeter"

    let model: AppModel
    @AppStorage(RehearsalFrameMeter.key) private var isOn = false

    func body(content: Content) -> some View {
        let show = isOn && model.rehearsal != nil && DeveloperFlag.isOn
        content.transformEnvironment(\.worldLook) { look in
            look.frameMeter = show
        }
    }
}
