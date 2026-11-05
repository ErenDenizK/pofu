import Foundation
import PofuCore

/// Where a visitor stands (experience v1 §5.3; home layout §5).
public enum VisitorSlots {
    /// The front-lip guest spot, before the harbor (island level below 3):
    /// between the pond and Pofu's step.
    public static let v1 = WorldPoint(x: -95, y: 36)
    /// The guest stall, from island level 3.
    public static let g1 = WorldPoint(x: 398, y: -6)
    /// The guest room's window, lit on stay-over nights.
    public static let h4 = WorldPoint(x: -15, y: 98)

    /// A visitor's ground: the small shadow under their feet.
    public static let footprint = WorldPolygon.ellipse(radiusX: 8, radiusY: 2)

    /// Where `slot` is. The favourite-station slot depends on the station;
    /// use `point(for:favourite:)` for it.
    public static func point(of slot: VisitSlot) -> WorldPoint? {
        switch slot {
        case .v1: v1
        case .g1: g1
        case .h4: h4
        case .v2: nil
        }
    }

    /// The favourite-station guest slot: beside the worker, a step toward
    /// the lawn's centre and a little in front. `nil` for a station that does not stand on
    /// the home plate (the harbor's), where the guest works at the stall.
    public static func v2(beside station: StationID) -> WorldPoint? {
        guard let anchor = IslandLayout.stationAnchors[station] else { return nil }
        let side: Double = anchor.x > 0 ? -1 : 1
        return WorldPoint(x: anchor.x + side * 30, y: anchor.y + 12)
    }

    /// The slot's point for a visit (the favourite-station slot needs the
    /// station), falling back to the guest stall when there is none.
    public static func point(for slot: VisitSlot, favourite: StationID?) -> WorldPoint {
        if slot == .v2, let favourite, let point = v2(beside: favourite) { return point }
        return point(of: slot) ?? g1
    }
}
