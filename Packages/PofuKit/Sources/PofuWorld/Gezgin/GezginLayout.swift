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

    /// The mooring line from her bow to the post on the pier, in widths of her body from her feet.
    public struct Rope: Decodable, Sendable, Equatable {
        public var bowX: Double
        public var bowY: Double
        public var postX: Double
        public var postY: Double
        /// How far the line hangs below the straight one.
        public var sag: Double
        public var thickness: Double

        public static let standard = Rope(bowX: -0.40, bowY: -0.10, postX: -0.52, postY: -0.40, sag: 0.12, thickness: 0.012)
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
