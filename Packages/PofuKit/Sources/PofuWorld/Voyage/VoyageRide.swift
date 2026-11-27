import Foundation
import PofuCore

/// The voyage ride (ADR-0028, docs/design/mainflow-plan-2026-11-26.md row 2d): the verb of the row. The
/// characters hop aboard the Gezgin, she flies with the camera on her, and she moors at the island.
///
/// A ride is three beats of a fixed length (`world-map.json` `voyage.ride`, 3 to 5 s together):
///
/// 1. **board**: the row stays; she waits moored at the island the player is leaving, and Pofu and his friend
///    hop from it onto her back;
/// 2. **fly**: the row gives way to the world; the camera rises, crosses the sea and descends (the camera's
///    own flight, `CameraFlight`, of exactly this beat's length) and she stays where the camera is looking:
///    the world moves, she does not;
/// 3. **moor**: the camera has arrived; she glides to her place beside the island and the passengers hop off.
///
/// Under Reduce Motion the ride is a cross-fade of `reduced` seconds: no whale, no hops, no flight.
///
/// This file is the pure part: the timeline and the screen positions as shares of the screen. The views are in
/// `VoyageRideView.swift`.
public struct VoyageRide: Equatable, Sendable {
    public enum Beat: String, Hashable, Sendable {
        case board, fly, moor, done
    }

    public let from: IslandID
    public let to: IslandID
    public let board: Double
    public let fly: Double
    public let moor: Double
    public let reduced: Bool
    /// Whether the way goes to the right along the row (she faces the way she goes).
    public let toTheRight: Bool
    /// Whether the ride starts from the voyage row (she moored beside the island, the passengers hopping aboard).
    /// A trip from anywhere else (a tap on a far island, the place control) has no boarding: she comes in
    /// already carrying them.
    public let fromRow: Bool

    public init(from: IslandID, to: IslandID, data: VoyageData = VoyageData.shipped ?? .fallback, reduceMotion: Bool = false, fromRow: Bool = true) {
        self.from = from
        self.to = to
        self.fromRow = fromRow
        reduced = reduceMotion
        if reduceMotion {
            board = 0
            fly = max(data.ride.reduced, 0.1)
            moor = 0
        } else {
            board = fromRow ? max(data.ride.board, 0) : 0
            fly = max(data.ride.fly, 0.5)
            moor = max(data.ride.moor, 0)
        }
        let a = data.order.firstIndex(of: from.rawValue) ?? 0
        let b = data.order.firstIndex(of: to.rawValue) ?? 0
        toTheRight = b >= a
    }

    /// The ride's whole length in seconds.
    public var duration: Double { board + fly + moor }

    /// The beat at `seconds` and how far into it (0 to 1).
    public func beat(at seconds: Double) -> (beat: Beat, progress: Double) {
        let t = max(seconds, 0)
        if t < board { return (.board, board > 0 ? t / board : 1) }
        if t < board + fly { return (.fly, (t - board) / fly) }
        if t < duration { return (.moor, moor > 0 ? (t - board - fly) / moor : 1) }
        return (.done, 1)
    }

    /// How a trip to `target` starts when the camera is on `island`, or `nil` when there is no trip (the camera is
    /// already there). Every trip is one ride: from the row (the camera at the Map of Home, nothing focused,
    /// motion allowed) she waits moored and they hop aboard; from anywhere else she comes in carrying them.
    public static func trip(from island: IslandID, to target: IslandID, atMap: Bool, focusOpen: Bool, reduceMotion: Bool) -> VoyageRide? {
        guard target != island else { return nil }
        let fromRow = atMap && island == .home && !focusOpen && !reduceMotion
        return VoyageRide(from: island, to: target, reduceMotion: reduceMotion, fromRow: fromRow)
    }

    /// Whether the scene's focus UI (an island's plaque, a bubble, a card, Home's tags) stays hidden: for the
    /// whole ride, until the passengers are off and the ride is over.
    public static func hidesFocusUI(_ ride: VoyageRide?) -> Bool { ride != nil }

    /// The seconds from the start of the ride to the start of the camera's flight.
    public var flightStart: Double { board }

    // MARK: - Where she is

    /// A place on the screen: the centre of her body as shares of the screen's width and height, and her
    /// body's width as a share of the screen's width.
    public struct Spot: Equatable, Sendable {
        public var x: Double
        public var y: Double
        public var width: Double

        public init(x: Double, y: Double, width: Double) {
            self.x = x
            self.y = y
            self.width = width
        }

        static func mix(_ a: Spot, _ b: Spot, _ u: Double) -> Spot {
            Spot(x: a.x + (b.x - a.x) * u, y: a.y + (b.y - a.y) * u, width: a.width + (b.width - a.width) * u)
        }
    }

    /// Where she flies: low in the middle of the screen, large, so the sea passes under her.
    public static let cruise = Spot(x: 0.5, y: 0.60, width: 0.66)

    /// Where she lies beside the island she has come to (lower right of it, small, clear of the glass bar's
    /// place): the stand-in for a mooring that an island does not yet have (row 2e).
    public static func hover(toTheRight: Bool) -> Spot {
        Spot(x: toTheRight ? 0.70 : 0.30, y: 0.70, width: 0.42)
    }

    /// Her body's width as a share of the island's art width, moored and in the air alike: she and the islands
    /// share one world scale.
    public static let islandShare = 0.36

    /// The share of the board beat in which the row glides to the island she leaves; the hops start after.
    public static let glideShare = 0.35

    /// Where the row's position (in stops) stands `seconds` into the ride: the player's choice (`selected`)
    /// glides back to the island she leaves (`origin`) in the first part of the board beat, so the hop aboard
    /// is seen on that island, whole and centred; the flight starts from there.
    public func rowPosition(at seconds: Double, selected: Double, origin: Double) -> Double {
        let (beat, progress) = beat(at: seconds)
        guard beat == .board, board > 0 else { return origin }
        let u = Self.ease(progress / Self.glideShare)
        return selected + (origin - selected) * u
    }

    /// A passenger's hop on the board beat: it begins once the row has settled on the island she leaves.
    public static func boardProgress(_ beatProgress: Double) -> Double {
        min(max((beatProgress - glideShare) / (1 - glideShare), 0), 1)
    }

    /// Her body's width on the screen in points: at the row's scale while the row is there, at the camera's
    /// (`world`, the same share of the island's width as in the row) once the world is. The row gives way to
    /// the world in the first fifth of the flight, and she changes scale with it; after that her size is the
    /// camera's own, never her own.
    public func whaleWidth(at seconds: Double, row: Double, world: Double) -> Double {
        let (beat, progress) = beat(at: seconds)
        switch beat {
        case .board: return row
        case .fly: return row + (world - row) * Self.ease(progress / 0.2)
        case .moor, .done: return world
        }
    }

    /// Smoothstep.
    static func ease(_ t: Double) -> Double {
        let u = min(max(t, 0), 1)
        return u * u * (3 - 2 * u)
    }

    /// Her body's spot `seconds` into the ride, from where she is moored at the start (`start`, from the row).
    public func whale(at seconds: Double, start: Spot) -> Spot {
        let (beat, progress) = beat(at: seconds)
        switch beat {
        case .board:
            return start
        case .fly:
            // She lifts off the mooring and settles into the cruise in the first quarter of the flight.
            return .mix(start, Self.cruise, Self.ease(progress / 0.28))
        case .moor, .done:
            return .mix(Self.cruise, Self.hover(toTheRight: toTheRight), Self.ease(progress / 0.8))
        }
    }

    /// Her opacity: whole until she has moored, then she fades out as the island takes over the frame.
    public func whaleOpacity(at seconds: Double) -> Double {
        let (beat, progress) = beat(at: seconds)
        switch beat {
        case .board: return 1
        case .fly: return fromRow ? 1 : Self.ease(progress / 0.15)
        case .moor: return progress < 0.7 ? 1 : 1 - Self.ease((progress - 0.7) / 0.3)
        case .done: return 0
        }
    }

    /// The row's opacity over the ride: whole while boarding, gone as the flight lifts off.
    public func rowOpacity(at seconds: Double) -> Double {
        let (beat, progress) = beat(at: seconds)
        switch beat {
        case .board: return 1
        case .fly: return 1 - Self.ease(progress / 0.2)
        case .moor, .done: return 0
        }
    }

    /// The nose of her body: how much she tips up on the rise and down on the descent, in degrees, plus a
    /// slight lean into the way she goes. A flat line at rest.
    public func tilt(at seconds: Double) -> Double {
        let (beat, progress) = beat(at: seconds)
        guard beat == .fly else { return 0 }
        let up = progress < CameraFlight.riseShare ? -Self.ease(progress / CameraFlight.riseShare) : 0
        let travelEnd = CameraFlight.riseShare + CameraFlight.travelShare
        let down = progress > travelEnd ? Self.ease((progress - travelEnd) / CameraFlight.descendShare) : 0
        let settle = progress >= CameraFlight.riseShare && progress <= travelEnd ? 0 : 1
        return (up * 5 + down * 4) * Double(settle) * (toTheRight ? 1 : -1)
    }

    // MARK: - The passengers

    /// A passenger's hop: `along` runs 0 to 1 from one place to the other, `lift` is the height of the arc
    /// in widths of her body (zero at both ends).
    public static func hop(_ u: Double) -> (along: Double, lift: Double) {
        let t = min(max(u, 0), 1)
        return (ease(t), 0.16 * sin(.pi * t))
    }

    /// The share of a beat (0 to 1) in which passenger `index` of `count` is in the air: they go one after
    /// another with an overlap, so the second leaves as the first lands.
    public static func hopProgress(index: Int, count: Int, beatProgress: Double) -> Double {
        let n = Double(max(count, 1))
        let span = 1 / (1 + 0.5 * (n - 1))
        let start = Double(index) * span * 0.5
        return min(max((beatProgress - start) / span, 0), 1)
    }

    /// Where a passenger stands on her back, in shares of her body's width from her body's centre and of
    /// her cut-out's height from its top: the grass patch, in front of the bench, never behind a thing
    /// taller than himself.
    public static func seat(index: Int, count: Int, toTheRight: Bool) -> (dx: Double, feetY: Double) {
        // Her art faces left; mirrored when she goes right.
        let seats: [Double] = [-0.14, 0.02, -0.26, 0.14]
        let dx = seats[min(index, seats.count - 1)]
        return (toTheRight ? -dx : dx, 0.50)
    }

    /// Where a passenger waits on the pier (boarding) or lands on the island's shore (leaving): beside her,
    /// on the side the island is (behind her as she goes), in shares of her body's width from her body's centre.
    public static func shore(index: Int, toTheRight: Bool) -> (dx: Double, feetY: Double) {
        let side = toTheRight ? -1.0 : 1.0
        return (side * (0.66 + 0.10 * Double(index)), 0.62)
    }
}

extension VoyageRowLayout {
    /// Where the Gezgin lies moored at the island drawn at `place`, at row scale: at the foot of the side
    /// that faces the middle of the screen (an island cut by the edge keeps her in sight), her cut-out's
    /// width a third of the island's. For the ride's start and the row's own drawing,
    /// so she does not jump when the ride takes her over.
    public func mooredSpot(at place: Place) -> VoyageRide.Spot {
        VoyageRide.Spot(
            x: (place.x + (place.x > width / 2 + 1 ? -0.34 : 0.34) * place.width) / max(width, 1),
            y: (place.y + place.width * 0.33) / max(height, 1),
            width: place.width * VoyageRide.islandShare / max(width, 1)
        )
    }
}

/// How the hour grades what the row paints without a night of its own (Köke, the cloud tower): the plate
/// island has its own night picture, the rest is graded to match by the same light name
/// (`HomePlate.light`: day, golden, night).
public struct VoyageGrade: Equatable, Sendable {
    public var saturation: Double
    public var brightness: Double
    public var red: Double
    public var green: Double
    public var blue: Double

    public static let day = VoyageGrade(saturation: 1, brightness: 0, red: 1, green: 1, blue: 1)

    /// The Gezgin's: lighter than the islands' (she is a pale cloud animal; at night she must not go to a
    /// silhouette).
    public static func whale(light: String) -> VoyageGrade {
        switch light {
        case "night": VoyageGrade(saturation: 0.85, brightness: -0.03, red: 0.74, green: 0.78, blue: 0.96)
        case "golden": VoyageGrade(saturation: 1.0, brightness: 0, red: 1.0, green: 0.94, blue: 0.86)
        default: .day
        }
    }

    public static func grade(light: String) -> VoyageGrade {
        switch light {
        case "night": VoyageGrade(saturation: 0.72, brightness: -0.10, red: 0.50, green: 0.58, blue: 0.86)
        case "golden": VoyageGrade(saturation: 1.05, brightness: -0.02, red: 1.0, green: 0.90, blue: 0.76)
        default: .day
        }
    }
}
