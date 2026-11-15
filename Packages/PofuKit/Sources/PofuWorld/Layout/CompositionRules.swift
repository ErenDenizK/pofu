import Foundation
import PofuCore

/// One settled frame as the composition rules see it: the projected boxes of the subjects
/// (an island with its name chip; the characters at near), the chrome and the backdrop
/// features, in screen points (docs/design/world-presentation-v2.md section 1.2).
public struct CompositionFrame: Sendable {
    public enum Kind: String, Sendable {
        case map, mid, near
    }

    public enum SubjectType: String, Sendable {
        case island, tower, veil, character
        /// The lawn at near: a subject for the runs, never cut-checked.
        case lawn
    }

    public struct Subject: Sendable {
        public var id: String
        public var type: SubjectType
        /// The box the rules measure, with the name chip for an island.
        public var box: ScreenBox
        /// The island without its chip (C1's foot on the Map).
        public var island: ScreenBox?
        /// The art's own box, when it is tighter than `box` (C6).
        public var art: ScreenBox?
        public var tappable: Bool
    }

    public var name: String
    public var kind: Kind
    public var bands: ScreenBands
    /// The horizon row on the Map, in points.
    public var horizon: Double?
    public var hero: ScreenBox
    /// The focused character's feet at near.
    public var feet: (x: Double, y: Double)?
    public var subjects: [Subject]
    public var chrome: [WorldMap.Piece]
    public var features: [WorldMap.Piece]
}

public struct RuleResult: Sendable {
    public let rule: String
    public let passed: Bool
    public let detail: String
}

/// The five rules of v2 section 1.2 (C1 to C5) and round 3's C6, on projected boxes. A port,
/// one to one, of `tools/proof/composition_check.py` (the proof's chip sizes, the horizon
/// run's 0.21, C6's 24 pt), so the same numbers judge the proof's stills and the app's frames.
///
/// | # | Rule |
/// |---|---|
/// | C1 | Hero placement as a share of the height (Map: Home's foot 0.79 to 0.81; mid: the island's box centre 0.42 to 0.46; near: the character's feet 0.58 to 0.62) |
/// | C2 | Tallest full-width run with no subject, chrome or named backdrop feature (Map 0.18, 0.21 for the run that holds the horizon; mid 0.15; near 0.30) |
/// | C3 | Each third holds a subject, chrome or a backdrop feature (near: the top third may be sky) |
/// | C4 | No island box cut by an edge; nothing tappable in the safe bands or the corner keep-out |
/// | C5 | Smallest tappable island on the Map at least 88 pt wide |
/// | C6 | No backdrop feature within 24 pt of a subject, a slot or a chrome box |
public enum CompositionRules {
    public static let horizonRunLimit = 0.21
    public static let featureClearance = 24.0
    public static let minimumIslandWidth = 88.0

    /// C1 to C6, in order, for a frame.
    public static func check(_ frame: CompositionFrame) -> [RuleResult] {
        [c1(frame), c2(frame), c3(frame), c4(frame), c5(frame), c6(frame)]
    }

    public static func result(_ rule: String, in frame: CompositionFrame) -> RuleResult {
        check(frame).first { $0.rule == rule } ?? RuleResult(rule: rule, passed: false, detail: "no such rule")
    }

    private static func f(_ v: Double, _ digits: Int = 3) -> String { String(format: "%.\(digits)f", v) }

    // MARK: C1

    static func c1(_ frame: CompositionFrame) -> RuleResult {
        let h = frame.bands.height
        switch frame.kind {
        case .map:
            let foot = (frame.subjects.first { $0.id == IslandID.home.rawValue }?.island?.maxY ?? frame.hero.maxY) / h
            return RuleResult(rule: "C1", passed: (0.79 ... 0.81).contains(foot), detail: "Home's foot \(f(foot)) (0.79 to 0.81)")
        case .mid:
            let v = frame.hero.midY / h
            return RuleResult(rule: "C1", passed: (0.42 ... 0.46).contains(v), detail: "\(f(v)) (0.42 to 0.46)")
        case .near:
            let v = (frame.feet?.y ?? frame.hero.maxY) / h
            return RuleResult(rule: "C1", passed: (0.58 ... 0.62).contains(v), detail: "\(f(v)) (0.58 to 0.62)")
        }
    }

    // MARK: C2

    /// Every run of rows `[start, end)` covered by none of the boxes.
    static func runs(of boxes: [ScreenBox], height: Double) -> [(start: Int, end: Int)] {
        let rows = Int(height)
        var covered = [Bool](repeating: false, count: rows)
        for b in boxes {
            let lo = max(Int(b.minY.rounded(.towardZero)), 0)
            let hi = min(Int(b.maxY.rounded(.towardZero)) + 1, rows)
            if hi > lo { for y in lo ..< hi { covered[y] = true } }
        }
        var out: [(Int, Int)] = []
        var start: Int?
        for y in 0 ... rows {
            let isCovered = y == rows ? true : covered[y]
            if !isCovered, start == nil {
                start = y
            } else if isCovered, let s = start {
                out.append((s, y))
                start = nil
            }
        }
        return out
    }

    /// The tallest run as a share of the height; the run holding `horizon` counts `allow` less.
    static func tallestRun(_ boxes: [ScreenBox], height: Double, horizon: Double? = nil, allow: Double = 0) -> Double {
        var best = 0.0
        for run in runs(of: boxes, height: height) {
            var v = Double(run.end - run.start) / height
            if let horizon, Double(run.start) <= horizon, horizon < Double(run.end) { v = max(v - allow, 0) }
            best = max(best, v)
        }
        return best
    }

    static func c2(_ frame: CompositionFrame) -> RuleResult {
        let h = frame.bands.height
        let limit: Double
        switch frame.kind {
        case .map: limit = 0.18
        case .mid: limit = 0.15
        case .near: limit = 0.30
        }
        let horizon = frame.kind == .map ? frame.horizon : nil
        let allow = horizon != nil ? horizonRunLimit - 0.18 : 0
        let subjects = frame.subjects.map(\.box), chrome = frame.chrome.map(\.box), features = frame.features.map(\.box)
        let withFeatures = tallestRun(subjects + chrome + features, height: h, horizon: horizon, allow: allow)
        let strict = tallestRun(subjects + chrome, height: h, horizon: horizon, allow: allow)
        let note = horizon != nil ? "; the horizon run 0.21" : ""
        return RuleResult(
            rule: "C2", passed: withFeatures <= limit + 1e-9,
            detail: "\(f(withFeatures)) [strict \(f(strict))] (at most \(f(limit, 2))\(note))"
        )
    }

    // MARK: C3

    static func c3(_ frame: CompositionFrame) -> RuleResult {
        let h = frame.bands.height
        let thirds = [(0.0, h / 3), (h / 3, 2 * h / 3), (2 * h / 3, h)]
        let names = ["top", "middle", "bottom"]
        let all = frame.subjects.map(\.box) + frame.chrome.map(\.box) + frame.features.map(\.box)
        var missing: [String] = []
        for (i, third) in thirds.enumerated() {
            if frame.kind == .near, i == 0 { continue }
            if !all.contains(where: { $0.overlap(rows: third.0, third.1) >= 24 }) { missing.append(names[i]) }
        }
        return RuleResult(rule: "C3", passed: missing.isEmpty, detail: missing.isEmpty ? "all three thirds held" : "empty: " + missing.joined(separator: ", "))
    }

    // MARK: C4

    static func c4(_ frame: CompositionFrame) -> RuleResult {
        let w = frame.bands.width, h = frame.bands.height
        let safeTop = frame.bands.safeTop, safeBottom = frame.bands.bottomSafe.lowerBound
        let keepOut = frame.kind == .near ? frame.bands.cornerMirrored : frame.bands.corner
        var bad: [String] = []
        for s in frame.subjects {
            let b = s.box
            if s.type != .lawn, b.minX < 0 || b.maxX > w || b.minY < 0 || b.maxY > h { bad.append("\(s.id) cut by the edge") }
            if s.tappable, frame.kind != .near {
                if b.minY < safeTop || b.maxY > safeBottom { bad.append("\(s.id) in a safe band") }
                if b.intersects(keepOut) { bad.append("\(s.id) in the corner keep-out") }
            }
        }
        for c in frame.chrome {
            let isCorner = c.id.hasPrefix("corner") || c.id == "back-control"
            if !isCorner, c.box.minY < safeTop - 0.5 || c.box.maxY > safeBottom + 0.5 { bad.append("\(c.id) in a safe band") }
            if isCorner, c.box.maxY > safeBottom + 0.5 { bad.append("\(c.id) in the bottom safe band") }
        }
        return RuleResult(rule: "C4", passed: bad.isEmpty, detail: bad.isEmpty ? "none" : bad.joined(separator: "; "))
    }

    // MARK: C5

    static func c5(_ frame: CompositionFrame) -> RuleResult {
        guard frame.kind == .map else { return RuleResult(rule: "C5", passed: true, detail: "n/a") }
        let widths = frame.subjects.filter { $0.tappable && $0.type == .island }.map { ($0.id, $0.island?.width ?? $0.box.width) }
        guard let smallest = widths.min(by: { $0.1 < $1.1 }) else { return RuleResult(rule: "C5", passed: false, detail: "no tappable island") }
        return RuleResult(
            rule: "C5", passed: smallest.1 >= minimumIslandWidth,
            detail: "smallest \(smallest.0) \(f(smallest.1, 0)) pt (at least 88)"
        )
    }

    // MARK: C6

    static func c6(_ frame: CompositionFrame) -> RuleResult {
        guard frame.kind != .near else { return RuleResult(rule: "C6", passed: true, detail: "n/a") }
        let others: [(String, ScreenBox)] = frame.subjects.filter { $0.type != .character }.map { ($0.id, $0.art ?? $0.box) }
            + frame.chrome.map { ($0.id, $0.box) }
        var near: [String] = []
        for feature in frame.features where feature.id != "lip" {
            for (id, box) in others {
                let g = feature.box.gap(to: box)
                if g < featureClearance { near.append("\(feature.id) \(f(g, 0)) pt from \(id)") }
            }
        }
        return RuleResult(rule: "C6", passed: near.isEmpty, detail: near.isEmpty ? "all at least 24 pt clear" : near.joined(separator: "; "))
    }
}

// MARK: - Frames from the data

extension CompositionFrame {
    private static let reference = ScreenBands.reference

    private static func pose(_ stop: CameraRail.Stop) -> CameraPose {
        CameraPose(scale: stop.scale, look: stop.look, anchorY: stop.anchorY)
    }

    /// A Map frame at a tier: Home, the tier-1 islands at their stage, the tier-2 places at
    /// tier 2, the corner control, the backdrop (tier 1 only: the far picture is tuned there).
    /// `stage` is 1 (Koke veiled, Çağlayan a tower), 2 (Koke open, Çağlayan veiled) or 3.
    public static func map(stage: Int, tier: Int = 1, map: WorldMap) -> CompositionFrame {
        let camera = pose(map.tierFrame(tier: tier))
        let w = reference.width
        func project(_ x: Double, _ y: Double) -> (x: Double, y: Double) { camera.project(WorldPoint(x: x, y: y), width: w) }
        var subjects: [Subject] = []
        for slot in map.slots where slot.tier <= tier {
            let state = map.state(of: slot.id, stage: stage)
            let tl = project(slot.center.x - slot.width / 2, slot.center.y - slot.height / 2)
            let width = slot.width * camera.scale, height = slot.height * camera.scale
            if state == .island {
                let island = ScreenBox(minX: tl.x, minY: tl.y, maxX: tl.x + width, maxY: tl.y + height)
                var box = island
                box.maxY += map.chipGap + (slot.chip?.height ?? map.chipHeight)
                subjects.append(Subject(
                    id: slot.id, type: .island, box: box, island: island,
                    art: slot.tier == 0 ? island : nil, tappable: true
                ))
            } else {
                let tw = slot.width * map.towerWidth, th = slot.height * map.towerHeight
                let origin = project(slot.center.x - tw / 2, slot.center.y + slot.height / 2 - th)
                let box = ScreenBox(minX: origin.x, minY: origin.y, maxX: origin.x + tw * camera.scale, maxY: origin.y + th * camera.scale)
                subjects.append(Subject(id: slot.id, type: state == .veiled ? .veil : .tower, box: box, island: nil, art: nil, tappable: false))
            }
        }
        var features = tier == 1 ? map.mapFeatures : []
        features.append(WorldMap.Piece(id: "lip", box: ScreenBox(minX: 0, minY: map.lipTop, maxX: reference.width, maxY: reference.height)))
        let home = subjects.first { $0.id == IslandID.home.rawValue }
        return CompositionFrame(
            name: "map-tier\(tier)-stage\(stage)", kind: .map, bands: reference, horizon: map.horizon * reference.height,
            hero: home?.box ?? ScreenBox(minX: 0, minY: 0, maxX: 0, maxY: 0), feet: nil,
            subjects: subjects, chrome: [map.mapCorner], features: features
        )
    }

    /// Mid: the island fitted to the level-10 box (378 pt across, centred on y 383) with the
    /// real chrome and Home's characters on the plate's own feet. Every level uses the same
    /// box (v2 section 1.4), so `level` names the frame; it moves nothing.
    public static func mid(level: Int, map: WorldMap, plate: PlateIsland) -> CompositionFrame {
        let scale = map.midFitWidth / map.home.width
        let u = map.unitsPerPlatePoint
        let w = reference.width
        let box = ScreenBox(
            minX: w / 2 - map.midFitWidth / 2, minY: map.midCenterY - map.home.height * scale / 2,
            maxX: w / 2 + map.midFitWidth / 2, maxY: map.midCenterY + map.home.height * scale / 2
        )
        let perPlatePoint = scale * u
        let centre = (x: (plate.islandBox.minX + plate.islandBox.maxX) / 2, y: (plate.islandBox.minY + plate.islandBox.maxY) / 2)
        var subjects = [Subject(id: "island", type: .island, box: box, island: box, art: nil, tappable: true)]
        for (id, feet) in plate.characters.sorted(by: { $0.key < $1.key }) {
            let width = plate.pofuWidth * (plate.residentBoosts[id] ?? 1) * perPlatePoint
            let x = w / 2 + (feet.x - centre.x) * perPlatePoint
            let y = map.midCenterY + (feet.y - centre.y) * perPlatePoint
            subjects.append(Subject(
                id: id, type: .character,
                box: ScreenBox(minX: x - width / 2, minY: y - width * 66 / 64, maxX: x + width / 2, maxY: y),
                island: nil, art: nil, tappable: false
            ))
        }
        let features = map.midFeatures + [WorldMap.Piece(id: "lip", box: ScreenBox(minX: 0, minY: map.midLipTop, maxX: w, maxY: reference.height))]
        return CompositionFrame(
            name: "mid-level\(level)", kind: .mid, bands: reference, horizon: nil, hero: box, feet: nil,
            subjects: subjects, chrome: map.midChrome, features: features
        )
    }

    /// Near at `scale` pt per unit (rest 4.5, limit 7.4), centred on Pofu: his feet at 0.60 of
    /// the height and 0.50 of the width, the lawn round him, the back control bottom left.
    public static func near(scale: Double, map: WorldMap, plate: PlateIsland) -> CompositionFrame {
        let u = map.unitsPerPlatePoint
        let k = scale * u
        let feet = (x: map.nearFeetX * reference.width, y: map.nearFeetY * reference.height)
        let pofu = plate.characters["pofu"] ?? PlatePoint(x: 0, y: 0)
        let width = plate.pofuWidth * k
        let body = ScreenBox(minX: feet.x - width / 2, minY: feet.y - width * 66 / 64, maxX: feet.x + width / 2, maxY: feet.y)
        let island = plate.islandBox
        let lawn = ScreenBox(
            minX: feet.x + (island.minX - pofu.x) * k, minY: feet.y + (island.minY - pofu.y) * k,
            maxX: feet.x + (island.maxX - pofu.x) * k, maxY: feet.y + (island.maxY - pofu.y) * k
        )
        return CompositionFrame(
            name: "near-\(scale)", kind: .near, bands: reference, horizon: nil, hero: body, feet: feet,
            subjects: [
                Subject(id: "pofu", type: .character, box: body, island: nil, art: nil, tappable: false),
                Subject(id: "lawn", type: .lawn, box: lawn, island: nil, art: nil, tappable: false),
            ],
            chrome: [map.nearBack], features: []
        )
    }
}
