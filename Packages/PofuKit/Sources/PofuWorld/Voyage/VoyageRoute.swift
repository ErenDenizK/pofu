import Foundation
import Observation
import PofuCore

/// The voyage row's route and its numbers (ADR-0028, docs/design/mainflow-plan-2026-11-26.md row 2c).
///
/// The far view is a row of islands along the route: one island large (`islandWidth` of the screen's
/// width), its neighbours cut by the screen's edges, the cloud sea under them. The route is data
/// (`world-map.json` `voyage`): an island keeps its slot in `order`, and a new island needs a slot and
/// nothing else. This file is the pure part: the data, which stops the player sees and in what state,
/// where each island stands in the row, and what a swipe or a tap on a neighbour does. The views are in
/// `VoyageRowView.swift`.
public struct VoyageData: Decodable, Sendable, Equatable {
    /// The islands of the route in order, by `IslandID` raw value.
    public var order: [String]
    /// The island in view, as a share of the screen's width.
    public var islandWidth: Double
    /// The distance between two neighbours' centres, as a share of the screen's width.
    public var pitch: Double
    /// A neighbour's size against the island in view.
    public var neighbourScale: Double
    /// A neighbour's lift above the island in view, in reference points (402 x 874).
    public var neighbourLift: Double
    /// The island in view's centre row, as a share of the screen's height.
    public var centreY: Double
    /// The glass bar's lowest edge above the screen's foot, in points (clear of the place control).
    public var barLift: Double
    /// Seconds one glide takes (a tap on a neighbour, or a swipe settling).
    public var glideSeconds: Double
    /// A swipe of at least this many islands per second carries to the next one, whatever its length.
    public var flick: Double
    /// The ride (row 2d): seconds of boarding, of flight and of mooring. Their sum is the ride's length.
    public var ride: Ride

    public struct Ride: Decodable, Sendable, Equatable {
        public var board: Double
        public var fly: Double
        public var moor: Double
        /// Seconds the cross-fade takes under Reduce Motion.
        public var reduced: Double
    }

    public static let shipped: VoyageData? = {
        let url = Bundle.module.url(forResource: "world-map", withExtension: "json")
            ?? Bundle.module.url(forResource: "world-map", withExtension: "json", subdirectory: "Plates")
        guard let url, let data = try? Data(contentsOf: url) else { return nil }
        return try? decode(data)
    }()

    private struct File: Decodable {
        var voyage: VoyageData
    }

    static func decode(_ data: Data) throws -> VoyageData {
        try JSONDecoder().decode(File.self, from: data).voyage
    }

    /// The numbers when the package carries none (the same as `world-map.json`).
    public static let fallback = VoyageData(
        order: ["home", "koke", "caglayan"], islandWidth: 0.7, pitch: 0.62, neighbourScale: 0.86,
        neighbourLift: 26, centreY: 0.47, barLift: 72, glideSeconds: 0.42, flick: 1.6,
        ride: Ride(board: 0.9, fly: 2.2, moor: 0.9, reduced: 0.5)
    )
}

/// What one stop of the row is for the player.
public enum VoyageStatus: String, Hashable, Sendable {
    /// Home: the player's own island.
    case home
    /// An island the player can visit, not yet healed.
    case open
    /// An island the player can visit, healed.
    case healed
    /// The next island to open: a cloud tower, no way there yet.
    case locked
}

/// One stop of the row.
public struct VoyageStop: Hashable, Sendable, Identifiable {
    public var island: IslandID
    public var status: VoyageStatus

    public var id: IslandID { island }

    /// Whether the verb is live: Home and the islands the player can visit.
    public var canSail: Bool { status != .locked }

    /// The catalog key of the one line of state under the island's name.
    public var lineKey: String { "voyage.line.\(island.rawValue).\(status.rawValue)" }

    public init(island: IslandID, status: VoyageStatus) {
        self.island = island
        self.status = status
    }
}

public enum VoyageRoute {
    /// The stops the player sees, in route order: Home, the islands that can be visited and the one next
    /// to open as a cloud tower. An island not yet announced has no stop.
    public static func stops(
        koke: WonderStatus,
        caglayan: WonderStatus,
        data: VoyageData = VoyageData.shipped ?? .fallback
    ) -> [VoyageStop] {
        let stage = caglayan.isArrived ? 3 : koke.isArrived ? 2 : 1
        let map = WorldMap.shipped
        return data.order.compactMap { raw -> VoyageStop? in
            let island = IslandID(rawValue: raw)
            switch island {
            case .home:
                return VoyageStop(island: .home, status: .home)
            case .koke, .caglayan:
                let wonder = island == .koke ? koke : caglayan
                let state = map?.state(of: raw, stage: stage) ?? (wonder.isArrived ? .island : .cloud)
                switch state {
                case .cloud: return nil
                case .veiled: return VoyageStop(island: island, status: .locked)
                case .island: return VoyageStop(island: island, status: wonder.isHealed ? .healed : .open)
                }
            default:
                return nil
            }
        }
    }

    /// The index of an island's stop; Home's (0) when it has none.
    public static func index(of island: IslandID, in stops: [VoyageStop]) -> Int {
        stops.firstIndex { $0.island == island } ?? 0
    }
}

/// Where each island stands in the row, for a screen `width` by `height` points, with the row at
/// `position` (in islands: 1.0 has the second stop in view).
public struct VoyageRowLayout: Sendable, Equatable {
    public let width: Double
    public let height: Double
    public let data: VoyageData

    public init(width: Double, height: Double, data: VoyageData = VoyageData.shipped ?? .fallback) {
        self.width = width
        self.height = height
        self.data = data
    }

    /// The distance between two neighbours' centres, in points.
    public var pitch: Double { data.pitch * width }

    /// One island as the row draws it.
    public struct Place: Equatable, Sendable {
        /// The island's art box, centred on (`x`, `y`), `width` wide, in points.
        public var x: Double
        public var y: Double
        public var width: Double
        public var scale: Double
        /// 1 for the island in view, falling toward 0 as it leaves.
        public var weight: Double
    }

    /// The place of stop `index` with the row at `position`: the island in view is `islandWidth` of the
    /// width at the screen's middle; each neighbour is `pitch` away, `neighbourScale` the size and lifted.
    public func place(index: Int, position: Double) -> Place {
        let d = Double(index) - position
        let near = min(abs(d), 1)
        let scale = 1 + (data.neighbourScale - 1) * near
        return Place(
            x: width / 2 + d * pitch,
            y: data.centreY * height - data.neighbourLift * near * height / 874,
            width: data.islandWidth * width * scale,
            scale: scale,
            weight: 1 - near
        )
    }

    /// The horizontal extent of stop `index`'s art on the screen, and so how much of it is on screen.
    public func visibleShare(index: Int, position: Double) -> Double {
        let p = place(index: index, position: position)
        let lo = max(p.x - p.width / 2, 0), hi = min(p.x + p.width / 2, width)
        return max(hi - lo, 0) / max(p.width, 1)
    }

    /// The rail position of a drag: the start index moved by `translation` points (a drag to the left
    /// advances), eased past either end of a row of `count` stops.
    public func position(from start: Int, translation: Double, count: Int) -> Double {
        let raw = Double(start) - translation / max(pitch, 1)
        let last = Double(max(count - 1, 0))
        if raw < 0 { return -CameraRail.rubberBand(-raw * pitch, limit: pitch * 0.5) / max(pitch, 1) }
        if raw > last { return last + CameraRail.rubberBand((raw - last) * pitch, limit: pitch * 0.5) / max(pitch, 1) }
        return raw
    }

    /// The stop a swipe lands on: the nearest to where the finger's flick would carry the row, never more
    /// than one stop from `start`, so one swipe is one island.
    public func settle(from start: Int, position: Double, velocity: Double, count: Int) -> Int {
        let last = max(count - 1, 0)
        // `velocity` is in points per second of the finger (negative advances); in islands per second.
        let islandsPerSecond = -velocity / max(pitch, 1)
        var target = Int(position.rounded())
        if abs(islandsPerSecond) >= data.flick {
            target = islandsPerSecond > 0 ? Int(floor(position)) + 1 : Int(ceil(position)) - 1
        }
        target = min(max(target, start - 1), start + 1)
        return min(max(target, 0), last)
    }

    /// The stop a tap at screen `x` glides to: a neighbour whose art holds the tap, never the island in
    /// view (that is the bar's verb). `nil` for a tap on the sea.
    public func tapTarget(x: Double, selected: Int, count: Int) -> Int? {
        for index in [selected - 1, selected + 1] where index >= 0 && index < count {
            let p = place(index: index, position: Double(selected))
            if x >= p.x - p.width / 2, x <= p.x + p.width / 2 { return index }
        }
        return nil
    }
}

/// The row's own state: the island in view and the finger's drag. The model keeps one.
@MainActor
@Observable
public final class VoyageRowState {
    /// The island in view (the row finds its stop by it, so a change of route keeps the choice).
    public private(set) var island: IslandID = .home
    /// The island the player stands on when the row opens: its verb says "here", not "set sail".
    public private(set) var origin: IslandID = .home
    /// The rail position the finger holds, or `nil` at rest.
    public private(set) var held: Double?

    public init() {}

    /// The row opens on the island the camera is at.
    public func open(on island: IslandID) {
        self.island = island
        origin = island
        held = nil
    }

    public func choose(_ island: IslandID) {
        self.island = island
        held = nil
    }

    public func hold(position: Double) {
        held = position
    }
}
