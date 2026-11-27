import Foundation
import PofuCore

/// The Gezgin (Nazlı), the cloud whale who carries the player, moored beside Home's island (ADR-0028).
///
/// This file is the pure part: her rules as data (`world-map.json` `gezgin`: when she is a shadow, when
/// she is moored, her level, the numbers of her small motions), her level, her pose and the maths of
/// her motion. The views that draw her are in `GezginView.swift`. She is one cut-out per level and
/// state, moved by code (D6 of the main-flow plan): a bob, a squash when she wakes, her eyes by swapping
/// the asleep and awake cut-outs, her tail by a separate piece that sways.
public struct GezginData: Decodable, Sendable, Equatable {
    public struct Art: Decodable, Sendable, Equatable {
        /// The shared cut-out box in pixels (every level, state, tail and shadow is cut to it).
        public var canvas: [Double]
        /// The body's solid box in those pixels (left, top, right, bottom).
        public var body: [Double]
        /// Where the tail piece pivots, in the same pixels.
        public var tailPivot: [Double]
    }

    public struct Bob: Decodable, Sendable, Equatable {
        /// The rise and fall, in plate pixels.
        public var plate: Double
        public var seconds: Double
    }

    public struct Sway: Decodable, Sendable, Equatable {
        public var degrees: Double
        public var seconds: Double
    }

    public struct Blink: Decodable, Sendable, Equatable {
        public var every: Double
        public var seconds: Double
    }

    public struct Shadow: Decodable, Sendable, Equatable {
        /// The row the shadow crosses, in plate pixels.
        public var y: Double
        /// Seconds from one side of the cloud sea to the other.
        public var seconds: Double
        public var opacity: Double
    }

    /// The mooring line from her bow to a post standing on the island's rim, in widths of her body from her
    /// feet (up is negative). `postX`, `postY` are the post's foot on the rim.
    public struct Rope: Decodable, Sendable, Equatable {
        public var bowX: Double
        public var bowY: Double
        public var postX: Double
        public var postY: Double
        /// How far the line hangs below the straight one.
        public var sag: Double
        public var thickness: Double
        /// The post's height, in widths of her body; the line is tied `tieShare` of the way up it.
        public var postHeight: Double
        public static let tieShare = 0.46

        public init(bowX: Double, bowY: Double, postX: Double, postY: Double, sag: Double, thickness: Double, postHeight: Double = 0.22) {
            self.bowX = bowX
            self.bowY = bowY
            self.postX = postX
            self.postY = postY
            self.sag = sag
            self.thickness = thickness
            self.postHeight = postHeight
        }

        /// Where the line is tied to the post: part of the way up it.
        public var tieY: Double { postY - postHeight * Self.tieShare }

        /// Home's: the post at the bridge's end on the rim (the pier's own painted post stands there).
        public static let standard = Rope(bowX: -0.40, bowY: -0.10, postX: -0.60, postY: -0.85, sag: 0.40, thickness: 0.016, postHeight: 0.18)

        /// How far the control point of a steep line lies outward from its chord, in lengths of the chord (the
        /// curve's midpoint is half of it off the chord).
        public static let belly = 0.34

        /// The control point of the slack line from the post's `tie` to her `bow` (a quadratic curve): under the
        /// middle of the chord by `sag` of its length, so it hangs in a soft curve like a rope, never a taut strap.
        public static func control(tie: WorldPoint, bow: WorldPoint, sag: Double) -> WorldPoint {
            let dx = bow.x - tie.x, dy = bow.y - tie.y
            let length = max((dx * dx + dy * dy).squareRoot(), 1e-9)
            let mid = WorldPoint(x: (tie.x + bow.x) / 2, y: (tie.y + bow.y) / 2)
            if slope(tie: tie, bow: bow) > steep {
                // A steep chord: the line hangs from the post and bellies outward, away from the cliff, to her
                // side, perpendicular to the chord, so the curve is obvious.
                var nx = dy / length, ny = -dx / length
                if (dx >= 0 && nx < 0) || (dx < 0 && nx > 0) { nx = -nx; ny = -ny }
                return WorldPoint(x: mid.x + nx * belly * length, y: mid.y + ny * belly * length)
            }
            // A shallow chord: it sags perpendicular to it, downward, so the drop is obvious.
            var nx = -dy / length, ny = dx / length
            if ny < 0 { nx = -nx; ny = -ny }
            return WorldPoint(x: mid.x + nx * sag * length, y: mid.y + ny * sag * length)
        }

        /// A chord steeper than this (degrees) bellies outward instead of sagging down.
        public static let steep = 55.0

        /// How far the midpoint of the quadratic line lies from its chord, in lengths of the chord.
        public static func drop(tie: WorldPoint, bow: WorldPoint, sag: Double) -> Double {
            let c = control(tie: tie, bow: bow, sag: sag)
            let mx = 0.25 * tie.x + 0.5 * c.x + 0.25 * bow.x, my = 0.25 * tie.y + 0.5 * c.y + 0.25 * bow.y
            let dx = bow.x - tie.x, dy = bow.y - tie.y
            let length = max((dx * dx + dy * dy).squareRoot(), 1e-9)
            // Perpendicular distance of the curve's midpoint from the chord.
            return abs((mx - tie.x) * dy - (my - tie.y) * dx) / length / length
        }

        /// How steep the line runs from the post's tie to her bow, in degrees from the horizontal (0 is level,
        /// 90 a plumb line). A line that reads as a rope, not a strap down a cliff, stays well under 45.
        public static func slope(tie: WorldPoint, bow: WorldPoint) -> Double {
            let dx = abs(bow.x - tie.x), dy = abs(bow.y - tie.y)
            return atan2(dy, max(dx, 1e-9)) * 180 / .pi
        }
    }

    /// Where she lies at a wonder island, in world units from the island's centre (`moorings` in the data): her
    /// body's bottom centre, her body's width, the post's foot on the island's rim, and where the passengers land.
    public struct IslandMooring: Decodable, Sendable, Equatable {
        public var feet: [Double]
        public var width: Double
        public var post: [Double]
        public var landing: [[Double]]
    }

    /// The Koke phase at which she is a shadow on the cloud (`rumoured`) and at which she is moored (`arrived`).
    public var shadowWhen: String
    public var mooredWhen: String
    /// The island whose phase brings her (Koke).
    public var island: String
    /// Her level from the second: the island whose healing raises her to it, by level ("2": "koke").
    public var levelAt: [String: String]
    public var art: Art
    public var bob: Bob
    public var sway: Sway
    public var blink: Blink
    /// How long she stays awake after a tap, in seconds.
    public var awakeSeconds: Double
    /// How long her line stays up.
    public var lineSeconds: Double
    public var shadow: Shadow
    /// Her mooring line; the standard one when the data has none.
    public var rope: Rope?
    /// Her place at the islands that are not Home (`koke`, `caglayan`); an island without one has her hover beside it.
    public var moorings: [String: IslandMooring]?

    /// The data shipped in the package (`world-map.json`'s `gezgin`).
    public static let shipped: GezginData? = {
        let url = Bundle.module.url(forResource: "world-map", withExtension: "json")
            ?? Bundle.module.url(forResource: "world-map", withExtension: "json", subdirectory: "Plates")
        guard let url, let data = try? Data(contentsOf: url) else { return nil }
        return try? decode(data)
    }()

    private struct File: Decodable {
        var gezgin: GezginData
    }

    static func decode(_ data: Data) throws -> GezginData {
        try JSONDecoder().decode(File.self, from: data).gezgin
    }
}

/// What the world shows of her now.
public enum GezginPresence: Hashable, Sendable {
    /// Nothing yet.
    case absent
    /// Before she arrives: her shadow crosses the cloud.
    case shadow
    /// Moored at the pier, at this level (1 to 3).
    case moored(level: Int)

    public var level: Int? {
        if case .moored(let level) = self { return level }
        return nil
    }
}

/// Her two states: eyes shut or open.
public enum GezginPose: String, Hashable, Sendable {
    case asleep
    case awake
}

public enum Gezgin {
    public static let maxLevel = 3

    /// Her presence from the wonder islands: a shadow while the first island is a hump on the horizon,
    /// moored once it can be visited, and her level as its data says (D7).
    public static func presence(koke: WonderStatus, caglayan: WonderStatus, data: GezginData) -> GezginPresence {
        func status(_ id: String) -> WonderStatus {
            switch id {
            case "koke": koke
            case "caglayan": caglayan
            default: WonderStatus()
            }
        }
        let own = status(data.island)
        func reached(_ phase: String) -> Bool {
            switch phase {
            case "rumoured": own.phase.rawValue >= WonderStatus.Phase.rumoured.rawValue
            case "arrived": own.phase.rawValue >= WonderStatus.Phase.arrived.rawValue
            default: false
            }
        }
        if reached(data.mooredWhen) {
            return .moored(level: level(koke: koke, caglayan: caglayan, data: data))
        }
        return reached(data.shadowWhen) ? .shadow : .absent
    }

    /// Her level: 1, then each level whose island is healed (`levelAt`), never above `maxLevel`.
    public static func level(koke: WonderStatus, caglayan: WonderStatus, data: GezginData) -> Int {
        var level = 1
        for (key, island) in data.levelAt.sorted(by: { $0.key < $1.key }) {
            guard let target = Int(key), target > level, target <= maxLevel else { continue }
            let status = island == "koke" ? koke : island == "caglayan" ? caglayan : WonderStatus()
            if status.stage >= WonderIslands.healedStage { level = target }
        }
        return level
    }

    /// Asleep in the night plate's light; awake otherwise. A tap wakes her for a while (`wakeAge`, seconds
    /// since the tap, nil when not tapped).
    public static func pose(light: String, wakeAge: Double?, data: GezginData) -> GezginPose {
        if light != "night" { return .awake }
        if let wakeAge, wakeAge >= 0, wakeAge < data.awakeSeconds { return .awake }
        return .asleep
    }

    /// Whether her eyes are shut this instant in a blink (awake only). A still frame (`time` 0) is the
    /// rest pose, eyes open.
    public static func blinking(time: Double, data: GezginData) -> Bool {
        guard data.blink.every > 0, time > 0 else { return false }
        return time.truncatingRemainder(dividingBy: data.blink.every) < data.blink.seconds
    }

    /// Her bob in plate pixels at `time` seconds (positive is down); zero in a still frame (`time` 0).
    public static func bob(time: Double, data: GezginData) -> Double {
        guard data.bob.seconds > 0, time > 0 else { return 0 }
        return data.bob.plate * sin(2 * .pi * time / data.bob.seconds)
    }

    /// The tail's angle in degrees at `time` seconds.
    public static func swayDegrees(time: Double, data: GezginData) -> Double {
        guard data.sway.seconds > 0, time > 0 else { return 0 }
        return data.sway.degrees * sin(2 * .pi * time / data.sway.seconds)
    }

    /// The squash and the hop of her answer to a tap, `age` seconds after it: a stretch up as she
    /// wakes, a settle, then rest. `squash` scales her height about her bottom (1 at rest) and
    /// widens her the other way; `lift` is plate pixels up.
    public static func answer(age: Double?) -> (squash: Double, lift: Double) {
        guard let age, age >= 0, age < 0.9 else { return (1, 0) }
        let rise = age < 0.3 ? sin(.pi * age / 0.3) : 0
        let settle = age >= 0.3 ? sin(.pi * (age - 0.3) / 0.6) * exp(-(age - 0.3) * 3) : 0
        return (1 + 0.045 * rise - 0.03 * settle, 7 * rise)
    }

    /// Where her shadow is across the cloud sea, from 0 (just off the left edge) to 1 (just off the
    /// right), at `time` seconds, repeating. A still frame (`time` 0) holds it mid-crossing, in sight.
    public static func shadowProgress(time: Double, data: GezginData) -> Double {
        guard data.shadow.seconds > 0, time > 0 else { return 0.55 }
        return time.truncatingRemainder(dividingBy: data.shadow.seconds) / data.shadow.seconds
    }

    /// The plate point at the centre of her shadow at `time` seconds, on the plate that is `plateWidth`
    /// pixels wide: it enters a body's width off the left edge and leaves a body's width off the right.
    public static func shadowCentre(time: Double, data: GezginData, mooring: PlateMooring, plateWidth: Double) -> PlatePoint {
        let span = plateWidth + 2 * mooring.width
        return PlatePoint(x: -mooring.width + shadowProgress(time: time, data: data) * span, y: data.shadow.y)
    }

    /// The line key a tap brings: the night line while she is asleep, otherwise the day lines in turn.
    public static func lineKey(asleep: Bool, taps: Int) -> String {
        asleep ? "gezgin.line.night" : "gezgin.line.\(taps % dayLines)"
    }

    /// How many day lines she has.
    public static let dayLines = 3

    /// Her body's tap box on a plate, in plate pixels: her body, a little above it for what she carries.
    public static func tapBox(_ mooring: PlateMooring) -> PlateRect {
        let w = mooring.width
        return PlateRect(
            minX: mooring.feet.x - w / 2, minY: mooring.feet.y - 0.72 * w,
            maxX: mooring.feet.x + w / 2, maxY: mooring.feet.y + 0.04 * w
        )
    }

    /// The asset names of her art at a level.
    public static func art(level: Int, _ part: String) -> String {
        "world-gezgin-l\(min(max(level, 1), maxLevel))-\(part)"
    }
}

/// The mooring post's cut-out (`tools/art/gezgin_post.py`, batch 160 `x4-gez-mooring-post`): where its pole stands
/// in it, as shares of its size, measured on the cut.
public enum GezginPost {
    /// Height over width.
    public static let aspect = 479.0 / 400.0
    /// The pole's centre across, and its foot down, as shares of the cut-out.
    public static let footX = 0.43
    public static let footY = 0.93
    /// The pole's height (cap to foot) as a share of the cut-out's height.
    public static let poleShare = 0.89
    /// Where the line leaves the rope's turns, to the right of the pole's centre, in widths of the cut-out.
    public static let tieReach = 0.37

    /// The cut-out's width for a pole of `poleHeight`.
    public static func width(poleHeight: Double) -> Double {
        poleHeight / poleShare / aspect
    }
}

/// Where she lies at an island, in absolute world units: her body, the post on the rim, the line between them
/// and where the passengers land. One shape for every island, so the ride and the island's own scene draw her
/// in the same place.
public struct GezginBerth: Equatable, Sendable {
    /// Her body's bottom centre.
    public var feet: WorldPoint
    /// Her body's width.
    public var width: Double
    /// The post's foot on the rim.
    public var post: WorldPoint
    /// The line's shape and the post's height (in widths of her body).
    public var rope: GezginData.Rope
    /// Where the passengers land when they hop off; empty: beside her, on the side the island is.
    public var landing: [WorldPoint]

    public init(feet: WorldPoint, width: Double, post: WorldPoint, rope: GezginData.Rope, landing: [WorldPoint] = []) {
        self.feet = feet
        self.width = width
        self.post = post
        self.rope = rope
        self.landing = landing
    }

    /// Her bow, where the line is made fast (at rest).
    public var bow: WorldPoint {
        WorldPoint(x: feet.x + rope.bowX * width, y: feet.y + rope.bowY * width)
    }

    /// Where the line is tied to the post: on the right of the rope's turns round its neck.
    public var tie: WorldPoint {
        WorldPoint(x: post.x + GezginPost.tieReach * GezginPost.width(poleHeight: postHeight), y: post.y - postHeight * GezginData.Rope.tieShare)
    }

    /// The post's pole height in world units.
    public var postHeight: Double { rope.postHeight * width }

    /// How steep the line runs, in degrees from the horizontal.
    public var slope: Double { GezginData.Rope.slope(tie: tie, bow: bow) }

    /// The centre of her cut-out on the canvas (her feet are its bottom edge of the body, centred).
    public func canvasCentre(data: GezginData) -> WorldPoint {
        let unit = width / max(data.art.body[2] - data.art.body[0], 1)
        return WorldPoint(x: feet.x, y: feet.y + (data.art.canvas[1] / 2 - data.art.body[3]) * unit)
    }

    /// The width of her cut-out on the canvas (a little more than her body's).
    public func canvasWidth(data: GezginData) -> Double {
        width / max(data.art.body[2] - data.art.body[0], 1) * data.art.canvas[0]
    }
}

extension Gezgin {
    /// Her berth at `island`, or `nil` when it has none (she hovers beside it). Home's comes from the plate's
    /// `mooring` and the standard line; the wonder islands' from the data, from their centres.
    public static func berth(at island: IslandID, data: GezginData, home: HomePlate?) -> GezginBerth? {
        let rope = data.rope ?? GezginData.Rope.standard
        if island == .home {
            guard let home, let mooring = home.plate.mooring else { return nil }
            let feet = home.world(mooring.feet)
            let width = mooring.width * home.unitsPerPixel
            return GezginBerth(
                feet: feet, width: width,
                post: WorldPoint(x: feet.x + rope.postX * width, y: feet.y + rope.postY * width),
                rope: rope
            )
        }
        let centre: WorldPoint
        switch island {
        case .koke: centre = KokeLayout.center
        case .caglayan: centre = CaglayanLayout.center
        default: return nil
        }
        guard let own = data.moorings?[island.rawValue], own.feet.count == 2, own.post.count == 2 else { return nil }
        func at(_ p: [Double]) -> WorldPoint { WorldPoint(x: centre.x + p[0], y: centre.y + p[1]) }
        return GezginBerth(
            feet: at(own.feet), width: own.width, post: at(own.post), rope: rope,
            landing: own.landing.filter { $0.count == 2 }.map(at)
        )
    }
}
