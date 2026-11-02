import Foundation
import PofuCore

/// An emissive point in the world that blooms: an ember, a lit window.
/// Positions are measured on the lock-light masters (the ember under the
/// çaydanlık on `cay-1`, the round window in the island's door).
public struct WorldEmitter: Hashable, Sendable {
    public var point: WorldPoint
    /// The glow's radius in world units.
    public var radius: Double
    public var color: GradeRGB
    /// Strength by day and at night (golden hour is in between).
    public var dayStrength: Double
    public var nightStrength: Double
    /// Shown only while this station is built.
    public var station: StationID?

    public init(point: WorldPoint, radius: Double, color: GradeRGB, dayStrength: Double, nightStrength: Double, station: StationID? = nil) {
        self.point = point
        self.radius = radius
        self.color = color
        self.dayStrength = dayStrength
        self.nightStrength = nightStrength
        self.station = station
    }

    /// The strength under `light`, 0…~1.4.
    public func strength(in light: WorldLight) -> Double {
        let hour = dayStrength * light.day + (dayStrength + nightStrength) * 0.5 * light.golden + nightStrength * light.night
        return hour * light.bloom
    }
}

extension IslandLayout {
    /// The home island's emissive points.
    public static let emitters: [WorldEmitter] = [
        // The ember under the çaydanlık: (387, 603) px on cay-1, anchor
        // (512, 800), 8.53 px per unit, from the stall at (104, 6).
        WorldEmitter(point: WorldPoint(x: 89.4, y: -17.1), radius: 10, color: GradeRGB(1, 0.62, 0.26), dayStrength: 0.35, nightStrength: 1, station: .cay),
        // The round window in the door: (492, 670) px on the plate.
        WorldEmitter(point: WorldPoint(x: -67.3, y: 55.8), radius: 8, color: GradeRGB(1, 0.78, 0.44), dayStrength: 0, nightStrength: 1),
    ]
}
