#if DEBUG
import Observation
import PofuCompanion
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
    case colour, camera, depth, pofu, haptics, sound, seeds, garden

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
/// of day, the HD-2D switches, the grade trims blended by the light's
/// time-of-day weights, and (look round 4) the camera springs, the depth
/// strengths and Pofu's breath and blinks, all live. With the defaults it
/// changes nothing.
struct AyarLook: ViewModifier {
    let model: AppModel

    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        let rehearsing = model.rehearsal != nil
        content
            .environment(\.worldLook, rehearsing ? look : .standard)
            .environment(\.companionLife, rehearsing ? Self.life(Ayar.store.values.companion) : .standard)
    }

    /// The world's tunable feel from the Ayar values.
    static func tuning(_ values: TuningValues) -> WorldTuning {
        func spring(_ s: TuningValues.Spring) -> SpringSpec {
            SpringSpec(duration: s.duration, bounce: s.bounce)
        }
        let camera = values.camera
        return WorldTuning(
            springs: CameraSprings(
                travel: spring(camera.travel),
                far: spring(camera.far),
                release: spring(camera.release),
                focus: spring(camera.focus),
                buildPush: spring(camera.buildPush)
            ),
            parallax: values.depth.parallax,
            tiltShiftIsland: values.depth.tiltShiftIsland,
            tiltShiftHome: values.depth.tiltShiftHome
        )
    }

    /// Pofu's breath and blinks from the Ayar values.
    static func life(_ c: TuningValues.Companion) -> CompanionLife {
        CompanionLife(
            breathPeriodLow: c.breathPeriodLow,
            breathPeriodHigh: c.breathPeriodHigh,
            breathAmplitudeLow: c.breathAmplitudeLow,
            breathAmplitudeHigh: c.breathAmplitudeHigh,
            blinkIntervalMin: c.blinkIntervalMin,
            blinkIntervalMax: c.blinkIntervalMax
        )
    }

    private var look: WorldLook {
        let session = Ayar.session
        let trims = Ayar.store.values.grade
        var look = WorldLook(hd2d: session.hd2d, depthMotion: session.depthMotion, hourOverride: session.pinnedPhase?.hour)
        look.tuning = Self.tuning(Ayar.store.values)
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
