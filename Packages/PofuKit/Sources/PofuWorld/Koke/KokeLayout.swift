import Foundation
import PofuCore

extension IslandID {
    /// Koke, the first wonder island. Not a station island: it is drawn and
    /// flown to through `KokeLayout`, never through `IslandLayout.isles`.
    public static let koke: IslandID = "koke"
}

extension CameraPlace {
    /// The camera on Koke's Island stop.
    public static let koke = CameraPlace(island: .koke, z: 1)
}

/// Who says a stage's line.
public enum KokeSpeaker: String, Hashable, Sendable {
    case pofu
    case mochi
    /// Koke's own sound, no words.
    case koke
}

/// What a bubble at Koke says.
public enum KokeLineKind: Hashable, Sendable {
    /// The stage's line, 0 to 4.
    case stage(Int)
    /// Seen from the harbor, before the island can be visited.
    case rumour
    /// A tap on a day that cannot advance: come back after a quiet day.
    case rest
}

/// One bubble: a new `id` for every line said.
public struct KokeLine: Hashable, Sendable, Identifiable {
    public var id: Int
    public var kind: KokeLineKind

    public init(id: Int, kind: KokeLineKind) {
        self.id = id
        self.kind = kind
    }

    public var speaker: KokeSpeaker {
        switch kind {
        case .stage(let stage): KokeLayout.speaker(stage: stage)
        case .rumour, .rest: .pofu
        }
    }
}

/// Where Koke is and how it looks, per stage (Koke prototype spec §2).
/// Pure, so the numbers are tested. The art swaps in by name; until an
/// imageset exists the view draws its code placeholder.
public enum KokeLayout {
    /// The island's centre on the world canvas: left of the harbor, below
    /// the home plate and far enough below it that the home island is out of
    /// the frame when the camera is here (`closeScale`). The Map frames it
    /// (`IslandFraming.mapStop` takes its box in).
    public static let center = WorldPoint(x: -100, y: 410)
    /// The depth of Koke's lawn: the focus plane at Koke (`Lens`, the depth
    /// of field), where the home island's lawn is the focus at home.
    public static var focusDepth: Double {
        IslandLayout.depth(ofY: center.y)
    }

    /// The painted island's box: the plates are cut from their sky and
    /// drawn 250 units wide, the island itself about 212 by 140 of it.
    public static let plateSize = (width: 212.0, height: 140.0)
    /// How wide the full plate image is drawn, for the placeholder's frame.
    public static let artWidth = 250.0
    /// Points per world unit at the Koke stop, at the reference width: the
    /// painted island fills about 95 % of the width, as the home plate's
    /// lawn does at its own framing, and the home island (187 units above
    /// the plate's roots) is above the top edge.
    public static let closeScale = 1.8

    /// The island's box, absolute.
    public static var islandBox: WorldBox {
        WorldBox(
            minX: center.x - plateSize.width / 2, minY: center.y - plateSize.height / 2,
            maxX: center.x + plateSize.width / 2, maxY: center.y + plateSize.height / 2
        )
    }

    /// Where Koke lies on the lawn, relative to the centre.
    public static let kokeOffset = WorldPoint(x: 0, y: -4)
    /// Where Koke's feet are on the painted lawn, relative to the centre.
    public static let kokeFeet = WorldPoint(x: 0, y: 2)
    /// The carved stone and its first warm light: the gap on the lawn's
    /// front right, between the stepping stones and the ferns.
    public static let stoneOffset = WorldPoint(x: 46, y: -22)

    /// Koke's tap box, absolute.
    public static var kokeBox: WorldBox {
        let c = WorldPoint(x: center.x + kokeOffset.x, y: center.y + kokeOffset.y)
        return WorldBox(minX: c.x - 62, minY: c.y - 66, maxX: c.x + 62, maxY: c.y + 8)
    }

    // MARK: - The stages

    public static let stages = 5

    /// The world's grade at Koke: its saturation scaled to the stage.
    public static func graded(_ grade: WorldGrade, stage: Int) -> WorldGrade {
        var graded = grade
        graded.saturation *= saturation(stage: stage)
        return graded
    }

    static func clamped(_ stage: Int) -> Int {
        min(max(stage, 0), stages - 1)
    }

    /// The world grade's saturation at Koke, by stage. The colour coming
    /// back is painted into the plates (stages 0 to 2), so the grade leaves
    /// them as painted; stages 3 and 4 borrow stage 2's plate until theirs
    /// are painted, and the grade lifts it a little each stage.
    public static func saturation(stage: Int) -> Double {
        [1.0, 1.0, 1.0, 1.1, 1.2][clamped(stage)]
    }

    /// The last plate painted: later stages draw it until their own arrive.
    public static let paintedStages = 2

    /// The first warm practical, from stage 2.
    public static func hasWarmLight(stage: Int) -> Bool {
        stage >= 2
    }

    /// Open flowers by stage; before stage 2 they are buds.
    public static func openFlowers(stage: Int) -> Int {
        [0, 0, 3, 6, 10][clamped(stage)]
    }

    /// How much of the lawn has turned green, 0 to 1.
    public static func greenShare(stage: Int) -> Double {
        Double(clamped(stage)) / Double(stages - 1)
    }

    public static func islandArt(stage: Int) -> String {
        "world-koke-island-\(clamped(stage))"
    }

    /// The plate drawn at `stage`: its own, or the last painted one.
    public static func plateArt(stage: Int) -> String {
        "world-koke-island-\(min(clamped(stage), paintedStages))"
    }

    /// Whether the plate at `stage` is a stand-in for art not painted yet.
    public static func plateIsStandIn(stage: Int) -> Bool {
        clamped(stage) > paintedStages
    }

    /// Code-drawn blossoms on the lawn: the stage 4 signature until its
    /// plate is painted.
    public static func hasBlossoms(stage: Int) -> Bool {
        clamped(stage) >= stages - 1
    }

    public enum Pose: String, Hashable, Sendable, CaseIterable {
        case asleep, oneEye, stretch, standing

        /// The pose drawn when this one has no art yet: the stretch and the
        /// standing pose use the one-eyed Koke.
        public var fallback: Pose? {
            switch self {
            case .stretch, .standing: .oneEye
            case .asleep, .oneEye: nil
            }
        }

        public var art: String {
            switch self {
            case .asleep: "world-koke-asleep"
            case .oneEye: "world-koke-one-eye"
            case .stretch: "world-koke-stretch"
            case .standing: "world-koke-standing"
            }
        }
    }

    public static func pose(stage: Int) -> Pose {
        [Pose.asleep, .asleep, .oneEye, .stretch, .standing][clamped(stage)]
    }

    /// The pose drawn over the plate: the plates carry Koke as painted for
    /// stages 0 to 2, so a pose is drawn only once the plate is a stand-in
    /// (stage 3 and 4), covering the plate's Koke. `scale` is its size
    /// against the painted Koke; the stand-in is a little larger than the
    /// plate's Koke so that it hides it, and stage 4 stands taller still.
    public static func overlay(stage: Int) -> (pose: Pose, scale: Double)? {
        switch clamped(stage) {
        case 3: (.stretch, 1.12)
        case 4: (.standing, 1.12 * 1.1)
        default: nil
        }
    }

    /// Koke's gentle bounce at stage 4, in world units up (0 to `bounceHeight`
    /// and back every `bouncePeriod` seconds); still when `time` is `nil`.
    public static let bounceHeight = 2.5
    public static let bouncePeriod = 2.4

    public static func bounce(stage: Int, time: Double?) -> Double {
        guard clamped(stage) == stages - 1, let time, time.isFinite else { return 0 }
        let phase = time.truncatingRemainder(dividingBy: bouncePeriod) / bouncePeriod
        return bounceHeight * abs(sin(phase * .pi))
    }

    // MARK: - The lines

    /// Pofu opens, Mochi answers; stage 3 is Mochi reading the stone, and
    /// stage 4 is Koke's own sound.
    public static func speaker(stage: Int) -> KokeSpeaker {
        [KokeSpeaker.pofu, .mochi, .pofu, .mochi, .koke][clamped(stage)]
    }

    /// The localization key of a line.
    public static func lineKey(_ kind: KokeLineKind) -> String {
        switch kind {
        case .stage(let stage): "koke.line.\(clamped(stage))"
        case .rumour: "koke.rumour"
        case .rest: "koke.rest"
        }
    }

    /// How long a bubble stays, in seconds.
    public static let lineSeconds = 4.5

    // MARK: - The beat's light

    /// The beat's soft light swell: the level-up ceremony's burst at half
    /// strength, or `nil` outside its window. `age` is seconds since the tap.
    public static func swell(age: Double, reduceMotion: Bool = false) -> (radius: Double, opacity: Double)? {
        guard !reduceMotion, age >= 0, age < BuildMoment.Ceremony.burstLength else { return nil }
        let p = age / BuildMoment.Ceremony.burstLength
        let from = BuildMoment.Ceremony.burstRadius.from, to = BuildMoment.Ceremony.burstRadius.to
        let radius = (from + (to - from) * MomentCurves.easeOut(p)) * 1.2
        let rise = MomentCurves.easeOut(MomentCurves.progress(p, from: 0, length: BuildMoment.Ceremony.burstPeak))
        let fall = MomentCurves.smoothstep(MomentCurves.progress(p, from: BuildMoment.Ceremony.burstPeak, length: 1 - BuildMoment.Ceremony.burstPeak))
        return (radius, BuildMoment.Ceremony.burstOpacity * 0.5 * rise * (1 - fall))
    }

    // MARK: - The harbor horizon

    /// The hump on the far sky as the harbor sees it: where (as shares of
    /// the screen) and how wide, at the Island stop.
    public static let farHump = (x: 0.40, y: 0.205, width: 96.0)

    /// How much of the hump shows at rail position `z`: only at the Island
    /// stop and nearer, fading in over the first half.
    public static func farOpacity(z: Double) -> Double {
        min(max((z.isFinite ? z : 0) - 0.5, 0), 0.5) * 2
    }

    // MARK: - Home

    /// Where the moss gift lies at home, on the lawn's front-right lip.
    public static var homeGift: WorldPoint {
        WorldPoint(x: IslandLayout.pofu.x + 84, y: IslandLayout.pofu.y + 22)
    }
}
