import Foundation
import PofuCore

/// The framing math behind the rail's Island stop and the station focus
/// (ADR-0018; interaction spec §1.2). Pure, so the numbers are tested
/// instead of eyeballed.
///
/// **The Island framing.** The home plate is a flat lawn oval about twice
/// as wide as it is tall, on a screen about half as wide as it is tall. The
/// station row, not the screen's height, is what limits the scale: the
/// framing is the largest one that keeps every station slot (at any level),
/// Pofu and the residents fully on screen with a small margin, so the
/// plate's grassy tips may bleed off the sides. Vertically, the island's
/// whole content box (the tallest slot art down to the plate's roots) is
/// centred between the chrome bands. ADR-0018 asks for the world at about
/// 70 % of the band height at Home; at the Island framing the plate's
/// proportions cap the island itself at about 54 % (with every slot built),
/// and the living sky, the cloud sea and the neighbouring islands fill the
/// rest of the band. Cropping stations to reach 70 % would defeat the
/// framing's purpose, which is to see and tap all of them.
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

    /// The large home plate (`island-main-l-v2`, batch 03, #52) draws the
    /// island about 40 % wider at roughly 70 % scale on the same canvas.
    /// When the scene swaps from `island-main-s` to the large plate at
    /// stage 3, the small plate must draw at 1 / 1.4 of the large plate's
    /// on-screen width so the two stay consistent.
    ///
    /// TODO(batch-03): the scene draws only the small plate today; apply
    /// this ratio (and refit `stationRow` and `plateBox` to the large
    /// plate's slots) when the plate swap lands.
    public static let largePlateWidthRatio = 1.4

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

    /// A station slot's art, absolute, at the level whose art is tallest
    /// (every level shares one vignette until level art exists).
    public static func stationBox(_ station: StationID) -> WorldBox? {
        guard let anchor = IslandLayout.stationAnchors[station] else { return nil }
        let box = IslandLayout.stationArt(station, level: 1).flatMap { WorldArt.sprite($0.name)?.sharp } ?? placeholderBox
        return placed(box, at: anchor)
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
        return union(boxes) ?? WorldBox(minX: -175, minY: -60, maxX: 175, maxY: 40)
    }

    /// The plate's depth bands, absolute.
    public static var plateBox: WorldBox {
        let boxes = IslandLayout.plateBands.compactMap { band in WorldArt.sprite(band.art)?.sharp }
        return union(boxes) ?? WorldBox(minX: -180, minY: -49, maxX: 180, maxY: 115)
    }

    /// The island top to bottom: the tallest slot art down to the roots.
    public static var islandBox: WorldBox {
        union([stationRow, plateBox]) ?? plateBox
    }

    // MARK: - The Island framing

    /// The middle of the band between the chrome, in points.
    public static func bandMid(height: Double) -> Double {
        (topBand + (height - bottomBand)) / 2
    }

    /// The band between the chrome, in points.
    public static func bandHeight(height: Double) -> Double {
        max(height - topBand - bottomBand, 1)
    }

    /// The Island framing for a viewport: the station row fills the width
    /// within `sideMargin`, and the island's box is centred in the band.
    public static func islandStop(width: Double, height: Double) -> CameraRail.Stop {
        let row = stationRow
        let island = islandBox
        let scale = max(width - 2 * sideMargin, 1) / max(row.width, 1)
        return CameraRail.Stop(
            scale: scale,
            look: WorldPoint(x: row.midX, y: island.midY),
            anchorY: bandMid(height: height)
        )
    }

    /// How much of the band's height the island box fills at `scale`.
    public static func bandFill(scale: Double, height: Double) -> Double {
        islandBox.height * scale / bandHeight(height: height)
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
