import Foundation
import PofuCore
import PofuDesignSystem

/// Çağlayan drawn from its painted plates (ADR-0022): the first island besides Home. The same
/// `HomePlate` state type, placed by data: the plate's island box lands on the island's own
/// box on the world canvas (`CaglayanLayout.islandBox`), so the Island stop, the tap target and
/// the Map keep their geometry whether the plate or the sprite island is drawn.
///
/// What is painted (`design/art/plates/caglayan/objects.json`, `docs/state/plates.yaml`): the
/// day plate of every story stage (0 to 4), the night plates of stages 2 and 3, and the golden
/// hour and rain plates of stage 4. Every other state keeps the sprite island, as Home's
/// unpainted states do.
extension CaglayanLayout {
    /// Where the plate's island sits: the island's box, 212 units wide.
    public static var placement: HomePlate.Placement {
        .island(centre: center, width: plateSize.width)
    }
}

extension HomePlate {
    /// Çağlayan's plate data shipped in the package, if any.
    public static let caglayanIsland: PlateIsland? = PlateIsland.load("caglayan")

    /// The painted state for Çağlayan's story stage, hour and weather, or `nil` for the sprite
    /// island: the light of the hour (`lightBand`), clear skies (a rainbow's hour included: the
    /// stage 4 painting has one) or rain by day and at golden hour, and only where that light is
    /// painted at that stage.
    public static func caglayanState(
        in plate: PlateIsland,
        stage: Int,
        hour: Double,
        weather: WeatherConditions,
        isBedtime: Bool
    ) -> (light: String, stage: Int)? {
        guard let band = lightBand(hour: hour, isBedtime: isBedtime) else { return nil }
        let light: String
        switch weather.weather {
        case .clear:
            light = band
        case .lightRain:
            guard band != "night" else { return nil }
            light = "rain"
        case .overcast, .mist, .goldenHaze:
            return nil
        }
        let stage = min(max(stage, 0), CaglayanLayout.stages - 1)
        return plate.paints(light: light, stage: stage) ? (light, stage) : nil
    }

    /// Çağlayan's plate for this world and look now, or `nil` for the sprite island.
    public static func resolveCaglayan(
        _ island: PlateIsland? = caglayanIsland,
        world: WorldSnapshot,
        look: WorldLook,
        calendar: Calendar = .current
    ) -> HomePlate? {
        guard let island, look.homePlates, world.caglayan.isArrived else { return nil }
        let minute = look.hourOverride.map { $0 * 60 } ?? world.clock.map { SkyModel.minuteOfDay($0, calendar: calendar) } ?? 12 * 60
        let weather = look.weatherOverride
            ?? WeatherForecast.conditions(clock: world.clock, firstDay: world.firstDay, hour: minute / 60, calendar: calendar)
        guard let state = caglayanState(in: island, stage: world.caglayan.stage, hour: minute / 60, weather: weather, isBedtime: world.isBedtime) else { return nil }
        return HomePlate(plate: island, light: state.light, stage: state.stage, placement: CaglayanLayout.placement)
    }

    /// How much of the painted plate and its backdrop shows at a camera, 0 (the island cut alone
    /// among the others: on the Map, in a flight) to 1 (the Island stop): the camera's zoom
    /// against the stop's and how far it looks from the island. A flight is a fade, never a
    /// plate-sized rectangle over the sky.
    public static func isleFade(pose: CameraPose, box: WorldBox, closeScale: Double, viewportWidth: Double) -> Double {
        func smooth(_ x: Double) -> Double {
            let t = min(max(x, 0), 1)
            return t * t * (3 - 2 * t)
        }
        let stopScale = closeScale * viewportWidth / CameraRail.referenceWidth
        let zoom = smooth((pose.scale / max(stopScale, 1e-6) - 0.62) / 0.30)
        let off = hypot(pose.lookX - box.midX, pose.lookY - box.midY)
        let near = 1 - smooth((off - 0.15 * box.width) / (0.45 * box.width))
        return zoom * near
    }

    /// `isleFade` for Çağlayan.
    public static func caglayanFade(pose: CameraPose, viewportWidth: Double) -> Double {
        isleFade(pose: pose, box: CaglayanLayout.islandBox, closeScale: CaglayanLayout.closeScale, viewportWidth: viewportWidth)
    }

    /// Damla's sprite on the plate at a story stage: the sprite key and her feet (world units).
    public func damla(stage: Int) -> (art: String, feet: WorldPoint)? {
        guard let feet = residentFeet(.damla) else { return nil }
        return (CaglayanLayout.damlaKey(stage: stage), feet)
    }
}
