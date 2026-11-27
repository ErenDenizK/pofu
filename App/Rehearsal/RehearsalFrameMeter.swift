import PofuCore
import PofuWorld
import SwiftUI

/// The frame meter switch of the Prova panel: lays `WorldLook.frameMeter`
/// over whatever look the world has, in Rehearsal mode only. Live (the
/// scene reads the look from the environment) and in every build
/// configuration, because stutter is judged on release builds too.
/// Off by default; kept on this device.
///
/// The season stepper (season-system-v1 S1) rides on the same look: `seasonKey` holds a season's name, and
/// `WorldLook.seasonOverride` makes the plate draw it at every state its data lists for it. Empty follows the island year.
struct RehearsalFrameMeter: ViewModifier {
    static let key = "rehearsal.frameMeter"
    static let seasonKey = "rehearsal.season"

    let model: AppModel
    @AppStorage(RehearsalFrameMeter.key) private var isOn = false
    @AppStorage(RehearsalFrameMeter.seasonKey) private var season = ""

    func body(content: Content) -> some View {
        let show = isOn && model.rehearsal != nil && DeveloperFlag.isOn
        content.transformEnvironment(\.worldLook) { look in
            look.frameMeter = show
            look.seasonOverride = model.rehearsal != nil && DeveloperFlag.isOn ? Season(rawValue: season) : nil
        }
    }
}
