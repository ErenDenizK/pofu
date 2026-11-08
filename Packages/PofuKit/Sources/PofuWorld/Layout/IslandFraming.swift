import Foundation
import PofuCore

/// The framing math behind the rail's three stops and the station focus
/// (ADR-0018; interaction spec §1.2). Pure, so the numbers are tested
/// instead of eyeballed.
///
/// **The Island framing (look round 4).** The world is not shrunk to fit:
/// Pofu is 96 pt (×1.5) and a horizontal drag pans across the island,
/// tip to tip, with momentum, rubber-banded ends and snap points at each
/// station and at Pofu; it opens centred on Pofu. Round 3 fitted the whole
/// plate to 88 % of the width, which made every station tiny; that view is
/// now the establishing shot on arrival (`wholeStop`) and what a pinch out
/// passes through. Vertically the island's box (the tallest station down
/// to the roots) is centred between the top chrome and the bottom band;
/// far isles fill the sky above it and the cloud sea rises to its roots.
///
/// **Home** keeps ADR-0018's balanced diorama, re-framed in visual round 2
/// (2026-11-05): the island comes up and the sky band shrinks to about a
/// quarter of the screen, Pofu is a little smaller beside it (141 pt wide,
/// ×2.2), his feet at 400 pt, nudged sideways so Mochi and Fındık are whole
/// or out of frame, never cut by an edge. Round 1 had him 154 pt wide at
/// 600 pt, which left 45 % of the screen as hazy sky and the island low.
public enum IslandFraming {
    /// The top chrome band at Home, in points (ADR-0018).
    public static let topBand = 118.0
    /// The bottom chrome band at Home, in points (app–game boundary §6.3:
    /// 676–874 pt on a 874 pt screen).
    public static let bottomBand = 198.0
    /// Keeps the outermost station art off the screen's edge.
    public static let sideMargin = 6.0
    /// Keeps a character whole a few points inside the edge.
    public static let characterMargin = 8.0
    /// How much of the width the plate fills at the Island framing.
    public static let islandFill = 0.88
    /// Pofu's scale at Home (growth round, 2026-11-06): 64 units at 90 pt,
    /// so the lawn reaches both screen edges, its stations and every level's
    /// growth are on screen, and the earth body is about a sixth of the
    /// height. The old close-up (×2.2, 141 pt) hid the growth off-screen and
    /// let the unchanging earth fill 45 % of the frame; it is a pinch away
    /// (the rail's band) and a station focus away.
    public static let homeScale = 1.40
    /// Pofu's feet at Home, in reference points from the top: the lawn's
    /// back edge lands near 285 pt, so the sky is about a third of the
    /// screen, the lawn reads larger than the earth below it, and the
    /// speech bubble still clears the top chrome.
    public static let homeFeetY = 470.0

    /// The look x at Home: just right of the island's middle, so Pofu's own
    /// door (H1, painted into the plate) is whole on the left edge while the
    /// tea corner, the path and the pond stay in frame (36 pushed the door
    /// off the screen).
    public static let homeLookX = 12.0

    /// The centre of Pofu's own door in the plate's earth face (home layout
    /// H1), in world x.
    public static let pofuDoorX = -107.0

    // MARK: - Content

    /// A box at an anchor, in absolute world units.
    static func placed(_ box: WorldBox, at anchor: WorldPoint) -> WorldBox {
        WorldBox(minX: anchor.x + box.minX, minY: anchor.y + box.minY, maxX: anchor.x + box.maxX, maxY: anchor.y + box.maxY)
    }

    static func union(_ boxes: [WorldBox]) -> WorldBox? {
        guard var result = boxes.first else { return nil }
        for box in boxes.dropFirst() {
            result = WorldBox(
                minX: min(result.minX, box.minX),
                minY: min(result.minY, box.minY),
                maxX: max(result.maxX, box.maxX),
                maxY: max(result.maxY, box.maxY)
            )
        }
        return result
    }

    /// Where a slot's vignette has no art yet: the labelled placeholder's
    /// box, relative to the footprint.
    static let placeholderBox = WorldBox(minX: -36, minY: -58, maxX: 36, maxY: -2)

    /// A station slot's art, absolute, over every level it can show (the
    /// highest level is usually the tallest).
    public static func stationBox(_ station: StationID) -> WorldBox? {
        guard let anchor = IslandLayout.stationAnchors[station] else { return nil }
        let levels = IslandLayout.generatedLevels[station] ?? 0
        let boxes = (1...max(levels, 1)).compactMap { level in
            IslandLayout.stationArt(station, level: level).flatMap { WorldArt.sprite($0.name)?.sharp }
        }
        return placed(union(boxes) ?? placeholderBox, at: anchor)
    }

    /// Pofu's painted body, absolute (his soft variant's box: the live
    /// companion draws inside it).
    public static var pofuBox: WorldBox {
        let box = WorldArt.sprite("pofu")?.soft ?? WorldBox(minX: -32, minY: -62, maxX: 32, maxY: 4)
        return placed(box, at: IslandLayout.pofu)
    }

    /// A resident's sprite, absolute.
    public static func residentBox(_ resident: IslandLayout.Resident) -> WorldBox {
        let box = WorldArt.sprite(resident.art)?.sharp ?? WorldBox(minX: -15, minY: -26, maxX: 15, maxY: 0)
        return placed(box, at: resident.feet)
    }

    /// The characters a focus must keep whole or leave out: Pofu and the
    /// residents.
    public static var characterBoxes: [WorldBox] {
        [pofuBox] + IslandLayout.residents.map(residentBox)
    }

    /// Every station slot, Pofu and the residents: what the Island framing
    /// must keep on screen side to side.
    public static var stationRow: WorldBox {
        let boxes = IslandLayout.stationAnchors.keys.sorted().compactMap(stationBox) + characterBoxes
        return union(boxes) ?? WorldBox(minX: -240, minY: -60, maxX: 240, maxY: 40)
    }

    /// The plate's depth bands, absolute.
    public static var plateBox: WorldBox {
        let boxes = IslandLayout.plateBands.compactMap { band in WorldArt.sprite(band.art)?.sharp }
        return union(boxes) ?? WorldBox(minX: -244, minY: -48, maxX: 244, maxY: 146)
    }

    /// The island top to bottom: the tallest slot art down to the roots.
    public static var islandBox: WorldBox {
        union([stationRow, plateBox]) ?? plateBox
    }

    // MARK: - The framings

    /// The middle of the band between the chrome, in points.
    public static func bandMid(height: Double) -> Double {
        (topBand + (height - bottomBand)) / 2
    }

    /// The band between the chrome, in points.
    public static func bandHeight(height: Double) -> Double {
        max(height - topBand - bottomBand, 1)
    }

    /// Home plus İskele: the plate and every neighbouring islet beside it
    /// (concept flows §2.4), absolute.
    public static var homeAndIsleBox: WorldBox {
        let isles = IslandLayout.isles.compactMap { isle in WorldArt.sprite(isle.art)?.sharp.map { placed($0, at: isle.center) } }
        return union([plateBox] + isles) ?? plateBox
    }

    /// The whole island (round 3's Island framing, now the establishing
    /// shot): home plus İskele fill `islandFill` of the width (or the island
    /// fills the band, whichever is smaller), the island's box centred in
    /// the band.
    public static func wholeStop(width: Double, height: Double) -> CameraRail.Stop {
        let plate = homeAndIsleBox
        let island = union([islandBox, plate]) ?? islandBox
        let scale = min(width * islandFill / max(plate.width, 1), bandHeight(height: height) / max(island.height, 1))
        return CameraRail.Stop(
            scale: scale,
            look: WorldPoint(x: plate.midX, y: island.midY),
            anchorY: bandMid(height: height)
        )
    }

    /// The Island framing (look round 4): the world at `islandScale`, so
    /// Pofu is at least 80 pt, the island's box centred between the bands
    /// and the camera centred on Pofu. A horizontal drag pans across it
    /// (`CameraRig.panDrag`) between `panRange`'s ends, settling on
    /// `panSnaps`. Round 3 shrank the world to fit the whole plate; that
    /// view is now the establishing shot (`wholeStop`).
    public static func islandStop(width: Double, height: Double) -> CameraRail.Stop {
        let island = islandBox
        let scale = min(islandScale * width / CameraRail.referenceWidth, bandHeight(height: height) / max(island.height, 1))
        return CameraRail.Stop(
            scale: scale,
            look: WorldPoint(x: islandLookX, y: island.midY),
            anchorY: bandMid(height: height)
        )
    }

    /// Points per world unit at the Island framing, at the reference width:
    /// Pofu's 64 units at 96 pt (visual round 2: closer, so the island
    /// fills more of the screen).
    public static let islandScale = 1.0

    /// The Island stop's look x range at the reference width: the plate's
    /// tips reach the screen's edges at either end, never past them.
    public static var lookRange: ClosedRange<Double> {
        let half = CameraRail.referenceWidth / 2 / islandScale
        let lo = plateBox.minX + half, hi = plateBox.maxX - half
        return lo <= hi ? lo...hi : plateBox.midX...plateBox.midX
    }

    /// The Island stop's look x: Pofu, kept inside `lookRange`.
    public static var islandLookX: Double {
        min(max(IslandLayout.pofu.x, lookRange.lowerBound), lookRange.upperBound)
    }

    /// The pan (world units off the Island stop's look x) for a look x.
    public static func panValue(lookX: Double) -> Double {
        min(max(lookX, lookRange.lowerBound), lookRange.upperBound) - islandLookX
    }

    /// The pan's range: tip to tip.
    public static var panRange: ClosedRange<Double> {
        (lookRange.lowerBound - islandLookX)...(lookRange.upperBound - islandLookX)
    }

    /// Where a released pan settles: centred on each station (or as close
    /// as the ends allow) and on Pofu.
    public static var panSnaps: [Double] {
        let xs = IslandLayout.stationAnchors.values.map(\.x) + [IslandLayout.pofu.x]
        let snaps = Set(xs.map { (panValue(lookX: $0) * 100).rounded() / 100 })
        return snaps.sorted()
    }

    /// How much of the band's height the island box fills at `scale`.
    public static func bandFill(scale: Double, height: Double) -> Double {
        islandBox.height * scale / bandHeight(height: height)
    }

    /// How much of the width the plate fills at `scale`.
    public static func widthFill(scale: Double, width: Double) -> Double {
        plateBox.width * scale / width
    }

    /// The residents' boxes, absolute.
    public static var residentBoxes: [WorldBox] {
        IslandLayout.residents.map(residentBox)
    }

    /// Home: Pofu at ×2.4 with his feet at `homeFeetY`, nudged sideways at
    /// most a quarter of the width so no resident is cut by an edge.
    public static func homeStop(width: Double = CameraRail.referenceWidth) -> CameraRail.Stop {
        let pose = CameraPose(scale: homeScale, look: WorldPoint(x: homeLookX, y: IslandLayout.pofu.y), anchorY: homeFeetY)
        let kept = keepingCharactersWhole(pose, focus: pofuBox, subjects: residentBoxes, width: width, maxDrift: width * 0.25)
        return CameraRail.Stop(scale: homeScale, look: WorldPoint(x: kept.lookX, y: IslandLayout.pofu.y), anchorY: homeFeetY)
    }

    /// Another island's Island stop (§1.2): the camera at the Island scale,
    /// centred on that island's art. The home island has its own rail.
    public static func isleStop(_ island: IslandID, width: Double, height: Double) -> CameraRail.Stop? {
        if island == .koke {
            let box = KokeLayout.islandBox
            return CameraRail.Stop(
                scale: KokeLayout.closeScale * width / CameraRail.referenceWidth,
                look: WorldPoint(x: box.midX, y: box.midY),
                anchorY: bandMid(height: height)
            )
        }
        if island == .caglayan {
            let box = CaglayanLayout.islandBox
            return CameraRail.Stop(
                scale: CaglayanLayout.closeScale * width / CameraRail.referenceWidth,
                look: WorldPoint(x: box.midX, y: box.midY),
                anchorY: bandMid(height: height)
            )
        }
        guard let isle = IslandLayout.isles.first(where: { $0.id == island }) else { return nil }
        let box = WorldArt.sprite(isle.art)?.sharp.map { placed($0, at: isle.center) }
        let scale = islandScale * width / CameraRail.referenceWidth
        return CameraRail.Stop(
            scale: scale,
            look: WorldPoint(x: box?.midX ?? isle.center.x, y: box?.midY ?? isle.center.y),
            anchorY: bandMid(height: height)
        )
    }

    /// The Map: the home plate, every other island of the X and the wonder
    /// islands whole, with a margin, centred in the band.
    public static func mapStop(width: Double, height: Double) -> CameraRail.Stop {
        let isles = IslandLayout.isles.compactMap { isle in WorldArt.sprite(isle.art)?.sharp.map { placed($0, at: isle.center) } }
        let all = union(isles + [plateBox, KokeLayout.islandBox, CaglayanLayout.islandBox]) ?? WorldBox(minX: -400, minY: -380, maxX: 400, maxY: 420)
        let margin = 10.0
        let scale = min((width - 2 * margin) / all.width, (bandHeight(height: height) - 2 * margin) / all.height)
        return CameraRail.Stop(scale: scale, look: WorldPoint(x: all.midX, y: all.midY), anchorY: bandMid(height: height))
    }

    // MARK: - Keeping characters whole

    /// Shifts `pose` sideways so every character in `subjects` is either
    /// fully on screen or fully off it, never cut by an edge, while `focus`
    /// stays whole and its centre drifts at most `maxDrift` points.
    ///
    /// Among the shifts that work, it keeps the most characters in frame,
    /// then moves least. If no shift works, the pose is returned unchanged.
    public static func keepingCharactersWhole(
        _ pose: CameraPose,
        focus: WorldBox,
        subjects: [WorldBox],
        width: Double,
        margin: Double = characterMargin,
        maxDrift: Double
    ) -> CameraPose {
        let s = pose.scale
        func interval(_ box: WorldBox) -> (lo: Double, hi: Double) {
            (width / 2 + (box.minX - pose.lookX) * s, width / 2 + (box.maxX - pose.lookX) * s)
        }
        let target = interval(focus)
        let spans = subjects.map(interval)

        var candidates: [Double] = [0]
        for span in spans {
            candidates += [margin - span.lo, width - margin - span.hi, -span.hi, width - span.lo]
        }

        var best: (shift: Double, inFrame: Int)?
        for shift in candidates where abs(shift) <= maxDrift {
            guard target.lo + shift >= 0, target.hi + shift <= width else { continue }
            var inFrame = 0
            var valid = true
            for span in spans {
                let lo = span.lo + shift
                let hi = span.hi + shift
                if lo >= -1e-9 && hi <= width + 1e-9 {
                    inFrame += 1
                } else if !(hi <= 1e-9 || lo >= width - 1e-9) {
                    valid = false
                    break
                }
            }
            guard valid else { continue }
            if let current = best {
                if inFrame > current.inFrame || (inFrame == current.inFrame && abs(shift) < abs(current.shift)) {
                    best = (shift, inFrame)
                }
            } else {
                best = (shift, inFrame)
            }
        }
        guard let best, best.shift != 0 else { return pose }
        var shifted = pose
        shifted.lookX -= best.shift / s
        return shifted
    }
}
