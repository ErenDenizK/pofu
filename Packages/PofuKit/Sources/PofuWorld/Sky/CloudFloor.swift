import Foundation
import PofuCore
#if os(iOS)
import PofuDesignSystem
import SwiftUI
#endif

/// The cloud floor and its life on the Map (WP9 of docs/design/world-presentation-build-spec.md, with pofu-art
/// batch 126's cut-out forms; tools/plate/cloud_kit.py ships them): a bed of cloud under each island so it
/// rests in the sea instead of hanging in bare sky, single puffs in the sky between the horizon and the
/// wonder islands at a depth of their own (k 0.6, hazier), a low mound on the horizon (the two low wisps wait for art:
/// the kit has no form left that is not another piece's). The pieces sit behind the islands, over the code-free painted sea. Where each stands is
/// data (`spots`, reference points at the Map's rest camera); how each moves is `motion` and `drift`: pure
/// functions of the time, every period apart from the others, every travel inside the limits of v2 section 3
/// (`SkyMotionLimitsTests`). Pure here; `CloudFloorLayer` draws it.
public enum CloudFloor {
    // MARK: - The forms

    /// A shipped form: its imageset and the height over its width (`Plates/cloud-kit.json`).
    public struct Form: Decodable, Hashable, Sendable {
        public var asset: String
        public var width: Int
        public var height: Int
        public var aspect: Double
    }

    private struct File: Decodable { var forms: [String: Form] }

    /// The kit's forms by id (`bed-round`, `puff-big`, ...).
    public static let forms: [String: Form] = {
        guard
            let url = Bundle.module.url(forResource: "cloud-kit", withExtension: "json")
                ?? Bundle.module.url(forResource: "cloud-kit", withExtension: "json", subdirectory: "Plates"),
            let data = try? Data(contentsOf: url),
            let file = try? JSONDecoder().decode(File.self, from: data)
        else { return [:] }
        return file.forms
    }()

    /// The form's texture bytes (texture pixels), for the budget.
    public static func textureBytes(_ ids: [String]) -> Int {
        ids.reduce(0) { $0 + (forms[$1].map { $0.width * $0.height } ?? 0) }
    }

    // MARK: - Pieces

    public enum Kind: String, Hashable, Sendable {
        /// The bed an island rests in: still in place, swelling.
        case bed
        /// A single puff in the sky: drifts, swells, breathes.
        case puff
        /// A low wisp in front of the sea: drifts, swells.
        case wisp
        /// The mound on the horizon: swells, breathes.
        case mound
    }

    /// One piece on the world canvas. Its depth `k` places it through `DepthLayer`: at `k` 1 it is a world
    /// object like the islands; at 0.6 it moves less than they do with the camera.
    public struct Piece: Hashable, Sendable, Identifiable {
        public var id: String
        public var form: String
        public var kind: Kind
        /// The piece's middle at the camera it was placed for, in the world of depth `k`.
        public var centre: WorldPoint
        public var width: Double
        public var k: Double
        /// Points a second to the right (at a 402 pt screen), 0 for a piece that stays.
        public var drift: Double
        /// A vertical swell, points and seconds.
        public var swell: Double
        public var swellPeriod: Double
        /// The breath: a share of the size, and its period.
        public var breathe: Double
        public var breathePeriod: Double
        public var phase: Double

        /// How much of the piece shows: farther pieces are hazier (`haze(k:)`).
        public var opacity: Double { CloudFloor.haze(k: k) }
    }

    /// The haze by depth: a piece at `k` 1 or nearer is as painted, one farther lets the sky through, up
    /// to a third at k 0.
    public static func haze(k: Double) -> Double {
        1 - 0.35 * min(max(1 - k, 0), 1)
    }

    /// Where a piece of the kit stands at the Map's rest camera: its middle `x` (a share of the screen's
    /// width) and `y` (reference points), its `width` in points, its depth and its motion.
    public struct Spot: Hashable, Sendable {
        public var id: String
        public var form: String
        public var kind: Kind
        public var x: Double
        public var y: Double
        public var width: Double
        public var k: Double
        public var drift: Double
        public var swell: Double
        public var swellPeriod: Double
        public var breathe: Double
        public var breathePeriod: Double
        public var phase: Double
    }

    /// The sky's single puffs and the horizon's mound, each a different form of the kit (the kit has four
    /// puffs and no wisp form that is not another piece's: the spec's two wisps wait for the volume jobs, so no
    /// silhouette repeats on one screen). The periods are all different and
    /// share no small multiple; the travels follow v2 section 3 (puffs 2 to 5 pt/s breathing 1.5 % over
    /// 14 to 20 s, the floors' swells 3 to 8 pt over 11 to 23 s).
    public static let spots: [Spot] = [
        Spot(id: "puff-1", form: "puff-big", kind: .puff, x: 0.58, y: 312, width: 74, k: 0.6, drift: 2.2, swell: 2.0, swellPeriod: 13.0, breathe: 0.015, breathePeriod: 16.4, phase: 0.10),
        Spot(id: "puff-2", form: "puff-small-a", kind: .puff, x: 0.82, y: 392, width: 52, k: 0.6, drift: 3.1, swell: 2.0, swellPeriod: 15.7, breathe: 0.015, breathePeriod: 19.7, phase: 0.45),
        Spot(id: "puff-3", form: "puff-small-b", kind: .puff, x: 0.36, y: 368, width: 44, k: 0.6, drift: 2.6, swell: 1.5, swellPeriod: 12.4, breathe: 0.012, breathePeriod: 14.9, phase: 0.72),
        Spot(id: "puff-4", form: "puff-small-c", kind: .puff, x: 0.23, y: 405, width: 46, k: 0.6, drift: 3.8, swell: 1.5, swellPeriod: 12.1, breathe: 0.012, breathePeriod: 16.1, phase: 0.28),
        Spot(id: "mound", form: "tower-c", kind: .mound, x: 0.74, y: 458, width: 120, k: 0.5, drift: 0, swell: 3.0, swellPeriod: 19.3, breathe: 0.015, breathePeriod: 20.0, phase: 0.35),
    ]

    /// The cool grade every piece is drawn in (a multiply): the kit's warm whites sit on the Map's lilac sea.
    public static let coolTint = (r: 0.92, g: 0.935, b: 1.0)

    /// The bed under an island (Home's `bed-wide`, Köke's `bed-round`, the others' `hill-cap`, so no two beds
    /// are one picture): this wide over the island's box, its middle this far (a share of the box's
    /// height) above the box's foot, so the island's belly sits in the cloud and the bed shows round it.
    public static let bedWidth = 1.4
    public static let bedLift = 0.1
    /// Each bed's swell (points, seconds), and its phase: three different, 3 to 8 pt over 11 to 23 s.
    static let bedSwells: [(amp: Double, period: Double, phase: Double)] = [(5.0, 17.0, 0.0), (3.0, 11.0, 0.33), (8.0, 23.0, 0.66)]

    /// The beds, the mound and the puffs for the Map at the stop `stop` (the camera at rest) and
    /// `reference` (Home's stop, the depth's reference), both in reference points (402 x 874): Home's bed
    /// first, then those of the open islands and of the tower standing; a slot not yet announced has none.
    public static func pieces(homeBox: WorldBox, slots: [MapSlots.Slot], stop: CameraPose, reference: CameraPose) -> [Piece] {
        var out: [Piece] = []
        func bed(_ id: String, form: String, box: WorldBox, n: Int) {
            guard forms[form] != nil else { return }
            let swell = bedSwells[n % bedSwells.count]
            let w = box.width * bedWidth
            out.append(Piece(
                id: "bed-\(id)", form: form, kind: .bed,
                centre: WorldPoint(x: box.midX, y: box.maxY - box.height * bedLift),
                width: w, k: 1, drift: 0,
                swell: swell.amp, swellPeriod: swell.period, breathe: 0, breathePeriod: 0, phase: swell.phase
            ))
        }
        bed("home", form: "bed-wide", box: homeBox, n: 0)
        for (n, slot) in slots.enumerated() where slot.state == .island || slot.showsTower {
            bed(slot.id, form: slot.id == IslandID.koke.rawValue ? "bed-round" : "hill-cap", box: slot.state == .island ? slot.box : slot.tower, n: n + 1)
        }
        for s in spots {
            guard forms[s.form] != nil else { continue }
            let pose = DepthLayer.pose(stop, reference: reference, k: s.k)
            let centre = pose.unproject(x: s.x * CameraRail.referenceWidth, y: s.y, width: CameraRail.referenceWidth)
            out.append(Piece(
                id: s.id, form: s.form, kind: s.kind, centre: centre, width: s.width / pose.scale, k: s.k, drift: s.drift,
                swell: s.swell, swellPeriod: s.swellPeriod, breathe: s.breathe, breathePeriod: s.breathePeriod, phase: s.phase
            ))
        }
        return out
    }

    // MARK: - Motion

    /// A piece's vertical swell in points (at a 402 pt screen) and its size factor at `time` seconds; both
    /// start at the painting's `phase` and are 0 and 1 at rest (`time` nil).
    public static func motion(_ piece: Piece, time: Double?) -> (dy: Double, scale: Double) {
        guard let time else { return (0, 1) }
        let dy = piece.swellPeriod > 0 ? piece.swell * sin(2 * .pi * (time / piece.swellPeriod + piece.phase)) : 0
        let scale = piece.breathePeriod > 0 ? 1 + piece.breathe * sin(2 * .pi * (time / piece.breathePeriod + piece.phase)) : 1
        return (dy, scale)
    }

    /// The fastest a piece moves, points a second: its drift, or the swell's peak speed, whichever is more.
    public static func speed(_ piece: Piece) -> Double {
        let swell = piece.swellPeriod > 0 ? piece.swell * 2 * .pi / piece.swellPeriod : 0
        return max(abs(piece.drift), swell)
    }

    /// Every period the pieces move by, seconds.
    public static func periods(_ pieces: [Piece]) -> [Double] {
        pieces.flatMap { [$0.swellPeriod, $0.breathePeriod] }.filter { $0 > 0 }
    }
}

#if os(iOS)
/// The cloud floor on the Map: `CloudFloor.pieces` drawn in one `Canvas` through `PofuTimeline` at the
/// sky's own rate (D6: the fallback that needs no judgement; `RenderServerMotionTests` measures
/// the render-server alternative), behind the islands. Still frames, Reduce Motion and Low Power draw it at rest.
struct CloudFloorLayer: View {
    let pieces: [CloudFloor.Piece]
    let pose: CameraPose
    let reference: CameraPose
    let size: CGSize
    let offset: CGSize

    @State private var start = Date()
    @Environment(\.worldStillFrame) private var still
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isStatic: Bool {
        still || reduceMotion || ProcessInfo.processInfo.isLowPowerModeEnabled
    }

    var body: some View {
        Group {
            if isStatic {
                canvas(time: nil)
            } else {
                PofuTimeline(hz: SkyMotion.frameRate) { context in
                    canvas(time: max(context.date.timeIntervalSince(start), 0))
                }
            }
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func canvas(time: Double?) -> some View {
        let unit = Double(size.width) / CameraRail.referenceWidth
        return Canvas(opaque: false, colorMode: .nonLinear, rendersAsynchronously: false) { context, _ in
            for piece in pieces {
                guard let form = CloudFloor.forms[piece.form] else { continue }
                let layerPose = DepthLayer.pose(pose, reference: reference, k: piece.k)
                let m = CloudFloor.motion(piece, time: time)
                let w = piece.width * layerPose.scale * m.scale, h = w * form.aspect
                let c = layerPose.project(piece.centre, width: Double(size.width))
                var left = c.x - w / 2
                if piece.drift != 0, let time {
                    left = SkyMotion.glideLeft(restLeft: left, width: w, speed: piece.drift * 3, time: time, screenWidth: Double(size.width), scale: unit)
                }
                let rect = CGRect(x: left + offset.width, y: c.y - h / 2 + m.dy * unit + offset.height, width: w, height: h)
                var layer = context
                layer.opacity = piece.opacity
                layer.addFilter(.colorMultiply(Color(red: CloudFloor.coolTint.r, green: CloudFloor.coolTint.g, blue: CloudFloor.coolTint.b)))
                let image = context.resolve(Image(form.asset, bundle: .module).interpolation(.high))
                layer.draw(image, in: rect)
            }
        }
    }
}
#endif
