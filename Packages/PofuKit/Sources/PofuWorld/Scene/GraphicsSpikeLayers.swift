#if os(iOS)
import PofuCore
import SwiftUI

// The graphics spike, drawn: normal-lit art and depth of field from a depth
// map. Everything here is reached only through `WorldLook.spike`, which is
// off by default; see `GraphicsSpike`.

extension EnvironmentValues {
    /// The light on painted art, set by the scene when the spike's normal
    /// lighting (or its normals debug view) is on; `nil` otherwise.
    @Entry var worldRelight: RelightRig? = nil
}

// MARK: - Normal lighting

/// One sprite's relight: its normal map, the rig, the practicals in the
/// sprite's own points and how the sprite's frame maps onto the map.
struct RelightConfig {
    var normal: String
    var rig: RelightRig
    var lights: [RelightRig.Point]
    var size: CGSize
    /// (u0, v0, du, dv): uv = (u0, v0) + position / size * (du, dv).
    var uvRect: CGRect
    var showsNormals: Bool
}

extension RelightRig {
    /// The practicals in a view's own points: `place` maps a world point to
    /// the view's local points, `unit` is points per world unit.
    func points(place: (WorldPoint) -> CGPoint, unit: Double) -> [RelightRig.Point] {
        practicals.prefix(2).map { p in
            let at = place(p.point)
            return RelightRig.Point(x: Double(at.x), y: Double(at.y), height: p.height * unit, radius: p.radius * unit, colour: p.colour)
        }
    }
}

extension WorldShaders {
    static func relight(_ c: RelightConfig) -> Shader {
        func point(_ i: Int) -> (Double, Double, Double, Double) {
            guard i < c.lights.count else { return (0, 0, 0, 0) }
            let p = c.lights[i]
            return (p.x, p.y, p.height, p.radius)
        }
        func colour(_ i: Int) -> GradeRGB {
            i < c.lights.count ? c.lights[i].colour : GradeRGB(0, 0, 0)
        }
        let p0 = point(0), p1 = point(1)
        let c0 = colour(0), c1 = colour(1)
        let rig = c.rig
        return Shader(function: ShaderFunction(library: library, name: "pofuRelight"), arguments: [
            .image(Image(c.normal, bundle: .module)),
            .float4(c.size.width, c.size.height, c.showsNormals ? 1 : 0, 0),
            .float4(c.uvRect.minX, c.uvRect.minY, c.uvRect.width, c.uvRect.height),
            .float3(rig.keyX, rig.keyY, rig.keyZ),
            .float3(rig.keyColour.r, rig.keyColour.g, rig.keyColour.b),
            .float3(rig.ambient.r, rig.ambient.g, rig.ambient.b),
            .float3(rig.rim.r, rig.rim.g, rig.rim.b),
            .float4(p0.0, p0.1, p0.2, p0.3),
            .float3(c0.r, c0.g, c0.b),
            .float4(p1.0, p1.1, p1.2, p1.3),
            .float3(c1.r, c1.g, c1.b),
            .float(rig.strength),
        ])
    }

    static func depthBlur(depth: Image, field: DepthOfField, size: CGSize, direction: CGSize, showsDepth: Bool) -> Shader {
        let p = field.shaderParameters
        return Shader(function: ShaderFunction(library: library, name: "pofuDepthBlur"), arguments: [
            .image(depth),
            .float4(p.focus, p.slab, p.range, p.maxRadius),
            .float4(size.width, size.height, showsDepth ? 2 : 0, field.behindBias),
            .float2(direction.width, direction.height),
        ])
    }
}

/// Relights a sprite from its normal map; a no-op without a config.
struct RelightEffect: ViewModifier {
    let config: RelightConfig?

    func body(content: Content) -> some View {
        if let config, WorldShaders.isAvailable {
            content.colorEffect(WorldShaders.relight(config))
        } else {
            content
        }
    }
}

// MARK: - Depth of field

/// Two separable, depth-aware blur passes over the composed world, driven
/// by the scene's depth map; a no-op without one.
struct SpikeDepthOfFieldEffect: ViewModifier {
    let depth: Image?
    let field: DepthOfField
    let size: CGSize
    let showsDepth: Bool

    func body(content: Content) -> some View {
        if let depth, WorldShaders.isAvailable {
            let reach = CGSize(width: field.maxRadius.rounded(.up) + 1, height: field.maxRadius.rounded(.up) + 1)
            content
                .layerEffect(
                    WorldShaders.depthBlur(depth: depth, field: field, size: size, direction: CGSize(width: 1, height: 0), showsDepth: showsDepth),
                    maxSampleOffset: reach
                )
                .layerEffect(
                    WorldShaders.depthBlur(depth: depth, field: field, size: size, direction: CGSize(width: 0, height: 1), showsDepth: false),
                    maxSampleOffset: reach,
                    isEnabled: !showsDepth
                )
        } else {
            content
        }
    }
}

/// Renders the scene's depth map: black for the sky, the ground plate as a
/// vertical ramp of its screen row's depth (through the camera pose), and
/// every standing object (stations, residents, Pofu) flat at the depth of
/// its base row, back to front. Red carries the depth (0 far, 1 near) and a
/// 0.5 swatch in the top-left corner lets the shader calibrate the
/// texture's colour decoding. Half resolution, cached while nothing moves:
/// a spike's shortcut; a shipped version would draw depth in a Metal pass.
@MainActor
enum SpikeDepthMap {
    private struct Key: Hashable {
        var pose: CameraPose
        var width: Double
        var height: Double
        var offsetX: Double
        var offsetY: Double
        var art: WorldLook.ArtSet
        var levels: [String]
        var koke: Bool
        var caglayan: Bool
    }

    private static var last: (key: Key, image: Image)?

    static func image(world: WorldSnapshot, pose: CameraPose, offset: CGSize, size: CGSize, art: WorldLook.ArtSet, koke: Bool = false, caglayan: Bool = false) -> Image? {
        let key = Key(
            pose: pose,
            width: Double(size.width),
            height: Double(size.height),
            offsetX: Double(offset.width),
            offsetY: Double(offset.height),
            art: art,
            levels: world.stations.map { "\($0.id.rawValue):\($0.level):\($0.isOpen)" },
            koke: koke,
            caglayan: caglayan
        )
        if let last, last.key == key { return last.image }
        let renderer = ImageRenderer(content: SpikeDepthMapView(world: world, pose: pose, offset: offset, size: size, art: art, koke: koke, caglayan: caglayan))
        renderer.scale = 0.5
        guard let cg = renderer.cgImage else { return nil }
        let image = Image(decorative: cg, scale: 0.5)
        last = (key, image)
        return image
    }

    /// The depth the focus plane sits at: the focused station's or
    /// resident's base row, otherwise Pofu's.
    static func focusDepth(_ focus: SceneFocus?, island: IslandID = .home) -> Double {
        // The map encodes depth up to `nearest`: Koke's lawn is nearer than
        // the home island's, so its focus plane is clamped to the range.
        if island == .koke, focus == nil { return min(KokeLayout.focusDepth, DepthOfField.nearest) }
        if island == .caglayan, focus == nil { return min(CaglayanLayout.focusDepth, DepthOfField.nearest) }
        switch focus {
        case .station(let id)?:
            if let slot = IslandLayout.stationAnchors[id] { return IslandLayout.depth(ofY: slot.y) }
        case .resident(let id)?:
            if let resident = IslandLayout.resident(id) { return IslandLayout.depth(ofY: resident.feet.y) }
        case nil:
            break
        }
        return IslandLayout.depth(ofY: IslandLayout.pofu.y)
    }
}

private struct SpikeDepthMapView: View {
    let world: WorldSnapshot
    let pose: CameraPose
    let offset: CGSize
    let size: CGSize
    let art: WorldLook.ArtSet
    let koke: Bool
    let caglayan: Bool

    private struct Item {
        var name: String
        var variant: DepthVariant
        var base: WorldPoint
    }

    var body: some View {
        Canvas(rendersAsynchronously: false) { context, canvas in
            context.fill(Path(CGRect(origin: .zero, size: canvas)), with: .color(Self.grey(0)))

            // The ground: depth follows the screen row.
            let far = DepthOfField.screenY(forDepth: DepthOfField.farthest, pose: pose, offsetY: Double(offset.height))
            let near = DepthOfField.screenY(forDepth: DepthOfField.nearest, pose: pose, offsetY: Double(offset.height))
            let ramp = GraphicsContext.Shading.linearGradient(
                Gradient(colors: [Self.grey(0), Self.grey(1)]),
                startPoint: CGPoint(x: 0, y: far),
                endPoint: CGPoint(x: 0, y: near)
            )
            for band in IslandLayout.plateBands {
                if let mask = mask(band.art, .sharp, at: .zero) {
                    paint(&context, mask, ramp)
                }
            }

            // Koke's island: one flat depth, its own row (clamped to the map).
            if koke {
                let box = KokeLayout.islandBox
                let a = pose.project(WorldPoint(x: box.minX, y: box.minY), width: Double(size.width))
                let b = pose.project(WorldPoint(x: box.maxX, y: box.maxY), width: Double(size.width))
                let rect = CGRect(x: a.x + Double(offset.width), y: a.y + Double(offset.height), width: b.x - a.x, height: b.y - a.y)
                let depth = DepthOfField.encoded(KokeLayout.focusDepth)
                context.fill(Path(ellipseIn: rect.insetBy(dx: -rect.width * 0.04, dy: -rect.height * 0.05)), with: .color(Self.grey(depth)))
            }

            // Çağlayan's island: the same, at its own row.
            if caglayan {
                let box = CaglayanLayout.islandBox
                let a = pose.project(WorldPoint(x: box.minX, y: box.minY), width: Double(size.width))
                let b = pose.project(WorldPoint(x: box.maxX, y: box.maxY), width: Double(size.width))
                let rect = CGRect(x: a.x + Double(offset.width), y: a.y + Double(offset.height), width: b.x - a.x, height: b.y - a.y)
                let depth = DepthOfField.encoded(CaglayanLayout.focusDepth)
                context.fill(Path(ellipseIn: rect.insetBy(dx: -rect.width * 0.04, dy: -rect.height * 0.05)), with: .color(Self.grey(depth)))
            }

            // Objects: flat at their base row, back to front.
            for item in items.sorted(by: { $0.base.y < $1.base.y }) {
                guard let mask = mask(item.name, item.variant, at: item.base) else { continue }
                let depth = DepthOfField.encoded(IslandLayout.depth(ofY: item.base.y))
                paint(&context, mask, .color(Self.grey(depth)))
            }

            // The calibration swatch.
            context.fill(Path(CGRect(x: 0, y: 0, width: 6, height: 6)), with: .color(Self.grey(0.5)))
        }
        .frame(width: size.width, height: size.height)
    }

    private static func grey(_ v: Double) -> Color {
        Color(.sRGB, white: min(max(v, 0), 1), opacity: 1)
    }

    private var items: [Item] {
        var items: [Item] = []
        for status in world.stations where status.island == .home && status.isOpen && status.level > 0 {
            guard let slot = IslandLayout.stationAnchors[status.id],
                  let art = IslandLayout.stationArt(status.id, level: status.level)?.name else { continue }
            let base = IslandFootprint.clamped(slot, footprint: IslandFootprint.footprint(of: art))
            items.append(Item(name: art, variant: .sharp, base: base))
        }
        for resident in IslandLayout.residents {
            guard (world.stations.first(where: { $0.id == resident.station })?.level ?? 0) > 0 else { continue }
            let feet = IslandFootprint.clamped(resident.feet, footprint: IslandFootprint.footprint(of: resident.art))
            items.append(Item(name: resident.art, variant: .sharp, base: feet))
        }
        items.append(Item(name: "pofu", variant: .soft, base: IslandLayout.pofu))
        return items
    }

    private func mask(_ name: String, _ variant: DepthVariant, at anchor: WorldPoint) -> (Image, CGRect)? {
        let key = WorldArt.key(name, art: art)
        guard let sprite = WorldArt.sprite(key), let box = sprite.box(for: variant) else { return nil }
        let p = pose.project(anchor, width: Double(size.width))
        let a = CGPoint(x: p.x + Double(offset.width), y: p.y + Double(offset.height))
        let s = pose.scale
        let rect = CGRect(x: a.x + box.minX * s, y: a.y + box.minY * s, width: box.width * s, height: box.height * s)
        return (Image(WorldArt.assetName(key, variant: variant), bundle: .module), rect)
    }

    private func paint(_ context: inout GraphicsContext, _ mask: (Image, CGRect), _ shading: GraphicsContext.Shading) {
        context.drawLayer { layer in
            layer.clipToLayer { m in
                m.draw(mask.0, in: mask.1)
            }
            layer.fill(Path(mask.1), with: shading)
        }
    }
}
#endif
