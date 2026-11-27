import Foundation
import PofuCore
#if canImport(SwiftUI)
import SwiftUI
#endif

/// One body of water on a plate (`plate-<island>.json` `water[]`, build spec WP13): a polygon
/// round the surface in plate pixels, the way the water drifts and how much it ripples. The
/// packed region mask the spec expected (R water, G sway, B emissive) does not exist, so the
/// region is this polygon, feathered at its edge, and the shader keeps the things that float in
/// it (a boat, a lantern, a lily pad) out of the motion by their colour.
public struct PlateWater: Decodable, Hashable, Sendable {
    public var id: String
    /// The stages that paint this water (every light); `nil`: all.
    public var stages: [Int]?
    /// The station whose pond this is (`"pond"`), or `nil`: water that belongs to no station. With `look` nil it is the
    /// water the plate paints itself, there where the station has no look over an erased base; with `look` set it is the
    /// outline fitted to that look's water (`tools/plate/pond_water.py`), there where that look is drawn.
    public var station: String?
    /// The station look (`StationLooks.lookLevel`, 1...) this outline is fitted to.
    public var look: Int?
    /// The surface, in plate pixels.
    public var polygon: [PlatePoint]
    /// How far in from the outline the water is fully in motion, in plate pixels.
    public var feather: Double
    /// The direction the water drifts (the first point to the last), in plate pixels.
    public var flow: [PlatePoint]
    /// The drift's speed, plate pixels per second.
    public var speed: Double
    /// The ripple's reach, plate pixels.
    public var ripple: Double
    /// The ripple's period, seconds; it divides `PlateRegionEffects.loop`.
    public var period: Double
    /// How much light plays on the surface (0...1).
    public var glint: Double

    private enum Keys: String, CodingKey { case id, stages, station, look, polygon, feather, flow, speed, ripple, period, glint }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Keys.self)
        id = try c.decode(String.self, forKey: .id)
        stages = try c.decodeIfPresent([Int].self, forKey: .stages)
        station = try c.decodeIfPresent(String.self, forKey: .station)
        look = try c.decodeIfPresent(Int.self, forKey: .look)
        polygon = try c.decode([[Double]].self, forKey: .polygon).map { PlatePoint(x: $0[0], y: $0[1]) }
        feather = try c.decodeIfPresent(Double.self, forKey: .feather) ?? 3
        flow = try (c.decodeIfPresent([[Double]].self, forKey: .flow) ?? []).map { PlatePoint(x: $0[0], y: $0[1]) }
        speed = try c.decodeIfPresent(Double.self, forKey: .speed) ?? 1
        ripple = try c.decodeIfPresent(Double.self, forKey: .ripple) ?? 1
        period = try c.decodeIfPresent(Double.self, forKey: .period) ?? 3
        glint = try c.decodeIfPresent(Double.self, forKey: .glint) ?? 0.1
    }

    public func isPresent(stage: Int) -> Bool {
        stages?.contains(stage) ?? true
    }

    /// The drift's unit direction (right when the data has none).
    public var direction: (x: Double, y: Double) {
        guard let a = flow.first, let b = flow.last, a != b else { return (1, 0) }
        let dx = b.x - a.x, dy = b.y - a.y
        let n = (dx * dx + dy * dy).squareRoot()
        return (dx / n, dy / n)
    }

    /// The most a pixel is taken from, in plate pixels: half the drift's sweep over one loop, and
    /// the ripple. The shader's object gate reaches a little past it.
    public var reach: Double { speed * PlateRegionEffects.loop / 2 + ripple + 0.5 }

    /// The surface's area, plate pixels squared.
    public var area: Double {
        var sum = 0.0
        for i in polygon.indices {
            let a = polygon[i], b = polygon[(i + 1) % polygon.count]
            sum += a.x * b.y - b.x * a.y
        }
        return abs(sum) / 2
    }

    /// The outline's box, plate pixels.
    public var box: PlateRect? {
        guard let first = polygon.first else { return nil }
        var r = PlateRect(minX: first.x, minY: first.y, maxX: first.x, maxY: first.y)
        for p in polygon {
            r = PlateRect(minX: min(r.minX, p.x), minY: min(r.minY, p.y), maxX: max(r.maxX, p.x), maxY: max(r.maxY, p.y))
        }
        return r
    }
}

/// Region shaders on a plate (build spec WP13), pure: which water a state has, when it moves and
/// where its patch sits on the screen. Water only: the sway and the emissive channels of the
/// spec's mask have no source (every object's `sway` is 0 and `emissive` false, and no mask
/// ships), so nothing draws for them. Home's plate has no falls; the falls Home shows are the
/// sky set's own (`SkySetView.drawFall`).
public enum PlateRegionEffects {
    /// The water's frame rate: Ambient asks for 30 Hz (`FramePolicy.ambientRate`). If the frame
    /// meter shows app frames over that at Ambient on the device, `fallbackHz` takes its place
    /// (`PofuFrameRate.idle`).
    public static let hz = 30.0
    public static let fallbackHz = 20.0
    /// Every motion's period divides this (the drift's cycle, the ripple's period), so a time
    /// taken modulo it leads into itself without a jump.
    public static let loop = 6.0

    /// Whether the water moves under a directive: only in Ambient, never under Reduce Motion or in
    /// a still frame. Low Power Mode and heat are the policy's: they turn Ambient into Settled.
    public static func runs(under directive: FrameDirective, reduceMotion: Bool, isStill: Bool) -> Bool {
        directive.state == .ambient && !reduceMotion && !isStill
    }

    /// A clock time quantised to the water's rate, inside one loop.
    public static func time(_ t: Double, hz: Double = PlateRegionEffects.hz) -> Double {
        guard t.isFinite, hz > 0 else { return 0 }
        let step = (t * hz).rounded(.down) / hz
        let m = step.truncatingRemainder(dividingBy: loop)
        return m < 0 ? m + loop : m
    }

    /// The water a painted state has, with the stations at `levels`. A station's water follows what is drawn: where its
    /// look stands over an erased base, the outline fitted to the look of its level (none while it is unbuilt: the base's
    /// plot is grass); where the state keeps the painted station, the plate's own water.
    public static func water(of plate: HomePlate, levels: [StationID: Int] = [:]) -> [PlateWater] {
        plate.plate.water.filter { body in
            guard body.isPresent(stage: plate.stage) else { return false }
            guard let station = body.station else { return true }
            let drawn = plate.plate.stationLooks(light: plate.key, stage: plate.stage)[station]
            guard let drawn else { return body.look == nil }
            guard let wanted = body.look else { return false }
            return drawn.lookLevel(stationLevel: levels[StationID(rawValue: station)] ?? 0, light: plate.key) == wanted
        }
    }

    /// The share of the island's pixels the water covers (the plate's budget: at most 5 %).
    public static func coverage(of plate: HomePlate, levels: [StationID: Int] = [:]) -> Double {
        let island = plate.plate.islandBox
        let total = island.width * island.height
        guard total > 0 else { return 0 }
        return water(of: plate, levels: levels).reduce(0) { $0 + $1.area } / total
    }

    /// The patch a body's shader draws, in screen points: its box and what the shader reaches past
    /// it, cut to the screen, on whole points (so the patch's pixels are the plate's own). `origin`
    /// is the screen point of plate pixel (0, 0) and `pointsPerPixel` the scale
    /// (`NearLensFrame.originX`, `pointsPerPixel`). `nil` when nothing of it is on the screen.
    public static func patch(of body: PlateWater, origin: (x: Double, y: Double), pointsPerPixel: Double, screen: (width: Double, height: Double)) -> PlateRect? {
        guard let box = body.box, pointsPerPixel > 0 else { return nil }
        let pad = body.feather + body.reach + 1
        let minX = max((origin.x + (box.minX - pad) * pointsPerPixel).rounded(.down), 0)
        let minY = max((origin.y + (box.minY - pad) * pointsPerPixel).rounded(.down), 0)
        let maxX = min((origin.x + (box.maxX + pad) * pointsPerPixel).rounded(.up), screen.width)
        let maxY = min((origin.y + (box.maxY + pad) * pointsPerPixel).rounded(.up), screen.height)
        guard maxX > minX, maxY > minY else { return nil }
        return PlateRect(minX: minX, minY: minY, maxX: maxX, maxY: maxY)
    }
}

#if canImport(SwiftUI)
extension EnvironmentValues {
    /// Forces the water to a time (seconds into its loop) whatever the frame policy says; a
    /// screenshot test sets it to show the water in motion in a still frame. `nil`: the policy.
    @Entry public var worldWaterClock: Double? = nil
}
#endif

#if os(iOS)
/// The water's moment on screen: a time in its loop.
struct WaterFrame: Hashable, Sendable {
    var time: Double
}

extension WorldShaders {
    /// The water shader of one body over its patch. `origin` is the screen point of plate pixel
    /// (0, 0) in the patch's own space.
    static func water(_ body: PlateWater, frame: WaterFrame, origin: (x: Double, y: Double), pointsPerPixel: Double) -> Shader {
        let dir = body.direction
        let outline = body.polygon.flatMap { [Float($0.x), Float($0.y)] }
        return Shader(function: ShaderFunction(library: library, name: "pofuWaterPatch"), arguments: [
            .float4(origin.x, origin.y, pointsPerPixel, frame.time),
            .float4(dir.x, dir.y, body.speed * PlateRegionEffects.loop, PlateRegionEffects.loop),
            .float4(body.ripple, body.period, body.glint, body.feather),
            .float4(body.reach, 0, 0, 0),
            .floatArray(outline),
        ])
    }
}

/// A body of water drawn again over the plate, moving (`pofuWaterPatch`): a copy of the picture the
/// island draws there (the base and the looks standing on it, so the pond look of the level and
/// never the plate under it) round the water, cut to the screen, that the shader displaces inside
/// the feathered outline. It is drawn after the looks. Where the shader's alpha is 0 the plate under it shows, so outside the water every
/// pixel is the plate's own. It sits in the island's content, so the lens's blur levels take it
/// like the rest of the island and the water moves at every distance.
struct PlateWaterPatch: View {
    let compositor: PlateCompositor
    let plate: HomePlate
    let water: PlateWater
    let frame: WaterFrame
    let pose: CameraPose
    let size: CGSize
    let offset: CGSize

    var body: some View {
        let zero = pose.project(plate.world(PlatePoint(x: 0, y: 0)), width: Double(size.width))
        let origin = (x: zero.x + Double(offset.width), y: zero.y + Double(offset.height))
        let ppp = plate.unitsPerPixel * pose.scale
        if let rect = PlateRegionEffects.patch(of: water, origin: origin, pointsPerPixel: ppp, screen: (Double(size.width), Double(size.height))) {
            let reach = CGFloat((water.reach * ppp).rounded(.up)) + 1
            ZStack(alignment: .topLeading) {
                PlateImage(name: plate.plate.drawnPlateArt(light: plate.key, stage: plate.stage), box: plate.plateImageBox, pose: pose, size: size, offset: offset)
                ForEach(compositor.stationsBackToFront, id: \.self) { station in
                    PlateLookPiece(compositor: compositor, station: station, build: nil, pose: pose, size: size, offset: offset)
                }
            }
            .frame(width: size.width, height: size.height, alignment: .topLeading)
            .offset(x: CGFloat(-rect.minX), y: CGFloat(-rect.minY))
            .frame(width: CGFloat(rect.width), height: CGFloat(rect.height), alignment: .topLeading)
            .clipped()
            .layerEffect(
                WorldShaders.water(water, frame: frame, origin: (origin.x - rect.minX, origin.y - rect.minY), pointsPerPixel: ppp),
                maxSampleOffset: CGSize(width: reach, height: reach)
            )
            .offset(x: CGFloat(rect.minX), y: CGFloat(rect.minY))
            .frame(width: size.width, height: size.height, alignment: .topLeading)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }
}
#endif
