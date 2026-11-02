#if DEBUG
import Observation
import PofuTuning
import PofuWorld
import SwiftUI

/// Ayar: the tuning panel in Rehearsal mode (pro game craft §3.3,
/// upgrade 3). The founder turns the knobs on his phone and shares the
/// changes as JSON; the agent commits them as the new defaults in
/// `PofuTuning`'s `tuning.json`.
///
/// Debug builds only, and only reachable from the Prova panel, which only
/// exists in Rehearsal mode: never in the live product path.
@MainActor
enum Ayar {
    /// The live values, persisted on this device.
    static let store = TuningStore()
    /// The panel's own state.
    static let session = AyarSession()
}

/// What the panel shows and the look switches it holds; not tuning data.
@MainActor
@Observable
final class AyarSession {
    var isOpen = false
    var section: AyarSection = .colour
    /// The time of day pinned for the world, so a grade can be tuned at
    /// noon in the evening; `nil` follows the clock.
    var pinnedPhase: AyarPhase?
    /// Painted HD-2D lite and depth in motion (`WorldLook`), live.
    var hd2d = true
    var depthMotion = true
}

enum AyarSection: String, CaseIterable, Identifiable {
    case colour, camera, depth, pofu, haptics, seeds, garden

    var id: String { rawValue }
}

/// The colour script's times of day, as `WorldLight` weighs them.
enum AyarPhase: String, CaseIterable, Identifiable {
    case day, golden, night

    var id: String { rawValue }

    /// An hour inside the phase, for pinning.
    var hour: Double {
        switch self {
        case .day: 12
        case .golden: 18.5
        case .night: 22
        }
    }

    /// The key prefix of this phase's grade trim.
    var gradeKey: String { "grade.\(rawValue)" }
}

// MARK: - The look

/// Lays the Ayar look over the world in Rehearsal mode: the pinned time
/// of day, the HD-2D switches, and the grade trims blended by the light's
/// time-of-day weights. With the defaults it changes nothing.
struct AyarLook: ViewModifier {
    let model: AppModel

    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content.environment(\.worldLook, model.rehearsal == nil ? .standard : look)
    }

    private var look: WorldLook {
        let session = Ayar.session
        let trims = Ayar.store.values.grade
        var look = WorldLook(hd2d: session.hd2d, depthMotion: session.depthMotion, hourOverride: session.pinnedPhase?.hour)
        let untouched = trims.day == .identity && trims.golden == .identity && trims.night == .identity
        guard !untouched else { return look }
        let light = WorldLight.resolve(
            world: model.world,
            calendar: .current,
            hourOverride: look.hourOverride,
            darkAppearance: colorScheme == .dark
        )
        let trim = TuningValues.GradeTrim.blend([
            (trims.day, light.day),
            (trims.golden, light.golden),
            (trims.night, light.night),
        ])
        look.gradeOverride = light.grade.trimmed(by: trim)
        return look
    }
}

extension WorldGrade {
    /// This grade with an Ayar trim: exposure scales the gain, warmth
    /// leans it toward red or blue, saturation and contrast scale, and
    /// the vignette adds.
    func trimmed(by trim: TuningValues.GradeTrim) -> WorldGrade {
        var grade = self
        let lean = trim.warmth * 0.08
        grade.gain = GradeRGB(
            grade.gain.r * trim.exposure * (1 + lean),
            grade.gain.g * trim.exposure,
            grade.gain.b * trim.exposure * (1 - lean)
        )
        grade.saturation *= trim.saturation
        grade.contrast *= trim.contrast
        grade.vignette = min(max(grade.vignette + trim.vignette, 0), 1)
        return grade
    }
}
#endif
