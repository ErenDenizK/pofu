import Foundation
import PofuCore

extension IslandID {
    /// Çağlayan, the second wonder island: a waterfall frozen in the noon sun.
    /// Like Koke it is drawn and flown to through its own layout, never
    /// through `IslandLayout.isles`.
    public static let caglayan: IslandID = "caglayan"
}

extension CameraPlace {
    /// The camera on Çağlayan's Island stop.
    public static let caglayan = CameraPlace(island: .caglayan, z: 1)
}

/// Who says a stage's line at Çağlayan.
public enum CaglayanSpeaker: String, Hashable, Sendable {
    case pofu
    case mochi
    case damla
}

/// What a bubble at Çağlayan says.
public enum CaglayanLineKind: Hashable, Sendable {
    /// The stage's line, 0 to 4 (0 is Damla's greeting on arrival).
    case stage(Int)
    /// Seen from the harbor: the water noise stopped somewhere.
    case rumour
    /// A tap on a day that cannot advance: skip one reach today, then come back.
    case rest
    /// A tap at bedtime: the water rests, come in the morning.
    case night
}

/// One bubble: a new `id` for every line said.
public struct CaglayanLine: Hashable, Sendable, Identifiable {
    public var id: Int
    public var kind: CaglayanLineKind

    public init(id: Int, kind: CaglayanLineKind) {
        self.id = id
        self.kind = kind
    }

    public var speaker: CaglayanSpeaker {
        switch kind {
        case .stage(let stage): CaglayanLayout.speaker(stage: stage)
        case .rumour: .pofu
        case .rest, .night: .damla
        }
    }
}

/// Where Çağlayan is and how it looks, per stage. Pure, so the numbers are
/// tested. The five plates are painted (`world-caglayan-island-N`, batch 43);
/// Damla is `world-damla` (and `world-damla-glass` once her glass is full).
/// The story map governs the beats: the stage 3 turn is Mochi reading the
/// mill's wall, the waterfall's fall off the underside is the stage 4
/// signature, and the home gift is the pool fountain at home.
public enum CaglayanLayout {
    /// The island's centre on the world canvas: below the harbor and right
    /// of Koke, out of the home plate's frame (`closeScale`).
    public static let center = WorldPoint(x: 150, y: 440)
    /// The depth of the island's lawn: the focus plane at Çağlayan.
    public static var focusDepth: Double {
        IslandLayout.depth(ofY: center.y)
    }

    /// The painted island's box (the plates are cut with a traced matte and
    /// drawn so the island is 212 units across, as Koke's is).
    public static let plateSize = (width: 212.0, height: 134.0)
    /// How wide the full plate image is drawn.
    public static let artWidth = 768.0 * 212.0 / 720.0
    /// Points per world unit at the island stop, at the reference width.
    public static let closeScale = 1.8
    /// Plate pixels per world unit (the plates are 768 px wide).
    public static let pixelsPerUnit = 768.0 / artWidth

    /// The island's box, absolute.
    public static var islandBox: WorldBox {
        WorldBox(
            minX: center.x - plateSize.width / 2, minY: center.y - plateSize.height / 2,
            maxX: center.x + plateSize.width / 2, maxY: center.y + plateSize.height / 2
        )
    }

    /// What a tap opens the flow round from: the whole island (the plaque
    /// below it is the same target, drawn as a button).
    public static var tapBox: WorldBox { islandBox }

    // MARK: - On the lawn (relative to the centre)

    /// Where Damla's feet are: on the lawn at the pool's left rim.
    public static let damlaFeet = WorldPoint(x: -50, y: 14)
    /// At stage 4 she sits at the top of the waterfall with her glass full.
    public static let damlaTop = WorldPoint(x: -14, y: -52)
    /// Her drawn height and width in world units (the depth map keeps all of
    /// her in focus with the lawn).
    public static let damlaBoxHeight = 34.0
    public static let damlaBoxWidth = 30.0
    /// The pool's middle, where its tiny night light lies.
    public static let pool = WorldPoint(x: -15, y: -1)
    /// The note on the mill hut's wall, shown from stage 2.
    public static let note = WorldPoint(x: 66, y: -10)
    /// The trickle the stage 0 shaft lands on (the single thin stream on the
    /// cliff's left).
    public static let trickle = WorldPoint(x: -34, y: -28)

    /// Damla's tap box, absolute (the island is one target; this is for
    /// tests and VoiceOver).
    public static var damlaBox: WorldBox {
        let p = damlaPoint(stage: 0)
        return WorldBox(minX: center.x + p.x - 22, minY: center.y + p.y - 50, maxX: center.x + p.x + 22, maxY: center.y + p.y + 4)
    }

    // MARK: - The stages

    public static let stages = 5

    static func clamped(_ stage: Int) -> Int {
        min(max(stage, 0), stages - 1)
    }

    /// The painted plate at `stage`.
    public static func islandArt(stage: Int) -> String {
        "world-caglayan-island-\(clamped(stage))"
    }

    /// The key the baked sprite table uses for the plate.
    public static func islandKey(stage: Int) -> String {
        "caglayan-island-\(clamped(stage))"
    }

    /// Damla is baked 38 units wide; she is drawn at this share of that, about Mochi's size.
    public static let damlaScale = 26.0 / 38.0

    /// Damla by the pool; with a full glass at stage 4.
    public static func damlaArt(stage: Int) -> String {
        clamped(stage) >= stages - 1 ? "world-damla-glass" : "world-damla"
    }

    public static func damlaKey(stage: Int) -> String {
        clamped(stage) >= stages - 1 ? "damla-glass" : "damla"
    }

    /// Where Damla stands, relative to the centre.
    public static func damlaPoint(stage: Int) -> WorldPoint {
        clamped(stage) >= stages - 1 ? damlaTop : damlaFeet
    }

    /// The note in the mill hut shows from stage 2.
    public static func showsNote(stage: Int) -> Bool {
        clamped(stage) >= 2
    }

    /// The stage 0 shaft on the single trickle, by stage: a soft warm wedge
    /// that fades as the water comes back (the beautiful-wound rule).
    public static func shaftAlpha(stage: Int) -> Double {
        [0.5, 0.32, 0.16, 0, 0][clamped(stage)]
    }

    /// The tiny light in the pool at night: the window far away in the
    /// deepest pool. Out when the waterfall flows.
    public static func poolLight(stage: Int, night: Double) -> Double {
        guard clamped(stage) < stages - 1 else { return 0 }
        return min(max(night.isFinite ? night : 0, 0), 1) * [1.0, 0.9, 0.75, 0.55, 0][clamped(stage)]
    }

    // MARK: - The falls off the underside (stage 4)

    /// One ribbon of the falls: where it leaves the underside (relative to
    /// the centre), how wide it is, how far it falls and its own phase.
    public struct Ribbon: Hashable, Sendable {
        public var x: Double
        public var width: Double
        public var length: Double
        public var phase: Double
    }

    /// The y of the body's lowest line, where the falls leave it.
    public static let undersideY = 56.0
    public static let ribbons: [Ribbon] = [
        Ribbon(x: -22, width: 4, length: 110, phase: 0.0),
        Ribbon(x: 0, width: 7, length: 140, phase: 0.37),
        Ribbon(x: 22, width: 4, length: 95, phase: 0.71),
    ]
    /// Seconds for the highlight to run one ribbon's length.
    public static let fallPeriod = 1.1

    /// How far the highlight has run on a ribbon, 0 to 1; still (0) when
    /// `time` is `nil` (a settled frame).
    public static func fallPhase(_ ribbon: Ribbon, time: Double?) -> Double {
        guard let time, time.isFinite else { return 0 }
        let p = time / fallPeriod + ribbon.phase
        return p - p.rounded(.down)
    }

    /// The falls' strength by stage: only the healed island pours.
    public static func fallStrength(stage: Int) -> Double {
        clamped(stage) >= stages - 1 ? 1 : 0
    }

    // MARK: - The lines

    /// Damla greets, Pofu lays the stones for Mochi, Pofu reads the note,
    /// Mochi reads the wall at the turn, Damla slides down.
    public static func speaker(stage: Int) -> CaglayanSpeaker {
        [CaglayanSpeaker.damla, .pofu, .pofu, .mochi, .damla][clamped(stage)]
    }

    /// The localization key of a line.
    public static func lineKey(_ kind: CaglayanLineKind) -> String {
        switch kind {
        case .stage(let stage): "caglayan.line.\(clamped(stage))"
        case .rumour: "caglayan.rumour"
        case .rest: "caglayan.rest"
        case .night: "caglayan.night"
        }
    }

    /// How long a bubble stays, in seconds.
    public static let lineSeconds = 5.0
    /// How long the next stage's plate takes to crossfade in.
    public static let crossfadeSeconds = 2.4

    // MARK: - Home

    /// Where the pool's fountain flows at home once Çağlayan is healed,
    /// relative to the pond station's anchor.
    public static let homeFountainOffset = WorldPoint(x: 0, y: -8)
    /// Hook for Nazlı's back (Gezgin): a small pool joins it when she is
    /// drawn. Nothing draws it yet.
    public static let nazliPoolHook = "nazli-pool"
}
