import Foundation
import PofuCore

/// Home's painted sky at the wonder stops (D7 of docs/design/demo-one-world-v1.md): Koke's stop and the
/// harbor's draw the home plate's sky set (ADR-0025) of the hour's light, its island layer left out,
/// placed around the stop, instead of the code sky, the cloud sea and the height fog, so a Koke day
/// reads as the same painted world as Home. Pure: where the sky sits, how much of it shows at a camera,
/// and which light it has; `PaintedSkyLayer` draws it.
///
/// The sky is the home plate's stage 0 (the level-10 sky set: its day, golden and night all exist), so a
/// player at any level sees the one sky. Weather does not change it (D2): rain falls over it as code
/// streaks, overcast and mist draw nothing over a painting.
public enum PaintedSky {
    /// Where the home plate sits for each stop, as `HomePlate.Placement.island`: the plate's island box
    /// is `width` world units wide and its middle lands on `centre`, so the sky set's cloud sea lies
    /// behind and below the island of the stop, as it does behind Home's. The numbers are tuned so the
    /// sky set covers the screen at every phone size (`PaintedSkyTests`) and the whale and the distant
    /// isles clear the island's crown at rest.
    public static let stops: [IslandID: (centre: WorldPoint, width: Double)] = [
        .koke: (centre: WorldPoint(x: KokeLayout.center.x + 25, y: KokeLayout.center.y + 74), width: 290),
        .harbor: (centre: WorldPoint(x: harborCentre.x + 45, y: harborCentre.y + 106), width: 520),
    ]

    /// The harbor isle's centre on the world canvas (`IslandLayout.isles`).
    private static var harborCentre: WorldPoint {
        IslandLayout.isles.first { $0.id == .harbor }?.center ?? WorldPoint(x: 395, y: 14)
    }

    /// One painted sky showing: the stop's island, the plate state (always the home's stage 0, the
    /// hour's light) placed around the stop, and how much of it shows (0...1).
    public struct Sky: Hashable, Sendable {
        public var island: IslandID
        public var plate: HomePlate
        public var fade: Double
    }

    /// The minute of the day the scene shows: a look's override, else the world's clock, else noon.
    static func hour(world: WorldSnapshot, look: WorldLook, calendar: Calendar) -> Double {
        let minute = look.hourOverride.map { $0 * 60 } ?? world.clock.map { SkyModel.minuteOfDay($0, calendar: calendar) } ?? 12 * 60
        return minute / 60
    }

    /// The painted sky behind `island`'s stop, or `nil`: the island has no stop here, the look has no
    /// plates, or the plate has no sky set for the hour's light.
    public static func sky(
        for island: IslandID,
        world: WorldSnapshot,
        look: WorldLook,
        calendar: Calendar = .current
    ) -> HomePlate? {
        guard look.homePlates, let stop = stops[island], let home = HomePlate.shipped?.plate else { return nil }
        let light = HomePlate.light(hour: hour(world: world, look: look, calendar: calendar), isBedtime: world.isBedtime)
        let plate = HomePlate(plate: home, light: light, stage: 0, placement: .island(centre: stop.centre, width: stop.width))
        return plate.skySet == nil ? nil : plate
    }

    /// The island's box the camera frames at its stop, and the stop's scale at the reference width.
    static func frame(of island: IslandID) -> (box: WorldBox, closeScale: Double)? {
        switch island {
        case .koke:
            return (KokeLayout.islandBox, KokeLayout.closeScale)
        case .harbor:
            guard
                let isle = IslandLayout.isles.first(where: { $0.id == .harbor }),
                let sprite = WorldArt.sprite(isle.art)?.sharp
            else { return nil }
            return (IslandFraming.placed(sprite, at: isle.center), IslandFraming.islandScale)
        default:
            return nil
        }
    }

    /// How much of the stop's sky shows at a camera: 0 on the Map, at Home and in a flight across the sea
    /// (the code sky is drawn there), 1 at the stop (`HomePlate.isleFade`).
    public static func fade(for island: IslandID, pose: CameraPose, viewportWidth: Double) -> Double {
        guard let frame = frame(of: island) else { return 0 }
        return HomePlate.isleFade(pose: pose, box: frame.box, closeScale: frame.closeScale, viewportWidth: viewportWidth)
    }

    /// The painted skies to draw at this camera: those of the stops it is on or near, in the world's hour.
    public static func skies(
        world: WorldSnapshot,
        look: WorldLook,
        pose: CameraPose,
        viewportWidth: Double,
        calendar: Calendar = .current
    ) -> [Sky] {
        guard look.homePlates else { return [] }
        return stops.keys.sorted { $0.rawValue < $1.rawValue }.compactMap { island in
            let fade = fade(for: island, pose: pose, viewportWidth: viewportWidth)
            guard fade > 0.001, let plate = sky(for: island, world: world, look: look, calendar: calendar) else { return nil }
            return Sky(island: island, plate: plate, fade: fade)
        }
    }
}

#if os(iOS)
import SwiftUI

/// A painted sky at the camera's projection: the home plate's sky set of the hour's light without its
/// island layer, never graded. An hour change is a crossfade between two whole skies
/// (`PlateHomeLayer.crossfade`), the same as at Home; `fade` brings it in as the camera lands on the
/// stop and out as it leaves.
struct PaintedSkyLayer: View {
    let plate: HomePlate
    let pose: CameraPose
    let size: CGSize
    let offset: CGSize
    let fade: Double

    @State private var shown: HomePlate
    @State private var incoming: HomePlate?
    @State private var incomingOpacity = 0.0
    @State private var shownStart = Date()
    @State private var incomingStart = Date()

    init(plate: HomePlate, pose: CameraPose, size: CGSize, offset: CGSize, fade: Double) {
        self.plate = plate
        self.pose = pose
        self.size = size
        self.offset = offset
        self.fade = fade
        _shown = State(initialValue: plate)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            sky(shown, start: shownStart)
            if let incoming {
                sky(incoming, start: incomingStart).compositingGroup().opacity(incomingOpacity)
            }
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .opacity(fade)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onChange(of: plate) { _, new in
            if let incoming {
                shown = incoming
                shownStart = incomingStart
            }
            guard new != shown else {
                incoming = nil
                return
            }
            incoming = new
            incomingStart = Date()
            incomingOpacity = 0
            withAnimation(.easeInOut(duration: PlateHomeLayer.crossfade)) {
                incomingOpacity = 1
            } completion: {
                if incoming == new {
                    shown = new
                    shownStart = incomingStart
                    incoming = nil
                }
            }
        }
    }

    @ViewBuilder
    private func sky(_ plate: HomePlate, start: Date) -> some View {
        if let set = plate.skySet {
            SkySetLayers(sky: set, plate: plate, pose: pose, size: size, offset: offset, start: start, drawsIsland: false)
        }
    }
}
#endif
