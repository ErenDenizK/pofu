import Foundation
import PofuCore

/// An emissive point in the world that blooms and lights its neighbours: an
/// ember, a lit window. How strongly it burns is the colour script's
/// (`Practicals`, per hour and wellbeing); positions are measured on the
/// masters (the ember under the çaydanlık on `cay-1`, the round window in
/// the plate's door).
public struct WorldEmitter: Hashable, Sendable {
    /// Which of the colour script's practical lights this is.
    public enum Kind: Hashable, Sendable {
        case ember
        case window
    }

    public var kind: Kind
    public var point: WorldPoint
    /// The glow's radius in world units.
    public var radius: Double
    public var color: GradeRGB
    /// How far its light reaches onto nearby objects (the warm pool on the
    /// çaydanlık, the rim on a resident), in world units.
    public var reach: Double
    /// Shown only while this station is built.
    public var station: StationID?

    public init(kind: Kind, point: WorldPoint, radius: Double, color: GradeRGB, reach: Double, station: StationID? = nil) {
        self.kind = kind
        self.point = point
        self.radius = radius
        self.color = color
        self.reach = reach
        self.station = station
    }

    /// The strength under `light`, 0…~1.4.
    public func strength(in light: WorldLight) -> Double {
        let practical = switch kind {
        case .ember: light.practicals.ember
        case .window: light.practicals.window
        }
        return practical * light.bloom
    }
}

extension IslandLayout {
    /// The home island's emissive points.
    public static let emitters: [WorldEmitter] = [
        // The ember under the çaydanlık: (387, 603) px on cay-1, anchor
        // (512, 800), 8.53 px per unit: (−14.6, −23.1) from the stall.
        WorldEmitter(kind: .ember, point: onStation(.cay, x: -14.6, y: -23.1), radius: 6, color: GradeRGB(1, 0.62, 0.26), reach: 70, station: .cay),
        // The round window in the door, measured on the plate master.
        WorldEmitter(kind: .window, point: WorldArt.generatedPlate.window, radius: 7, color: GradeRGB(1, 0.78, 0.44), reach: 30),
    ]

    /// A point on a station's art, so its emitter moves with the slot.
    static func onStation(_ station: StationID, x: Double, y: Double) -> WorldPoint {
        let anchor = stationAnchors[station] ?? .zero
        return WorldPoint(x: anchor.x + x, y: anchor.y + y)
    }
}
