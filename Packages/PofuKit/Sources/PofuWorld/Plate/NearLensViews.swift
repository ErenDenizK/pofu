#if os(iOS)
import CoreGraphics
import SwiftUI

extension EnvironmentValues {
    /// The thin lens on screen (WP11), set by the scene over a Home plate; `nil` where nothing
    /// blurs (the Map, mid, a flight). Characters, props and occluders read it for their own blur.
    @Entry var nearLens: NearLensFrame? = nil
}

/// The depth rows of a state's island as a texture (what the packed mask's A channel will carry):
/// a quarter of the plate's pixels, red the encoded row (`NearLayers.encode`), green the share of
/// a standing thing over the ground (1 inside its outline, soft at its edge). Where green is 0 the
/// shader takes the pixel's own row, exactly; texel (0, 0) is a 0.5 grey that lets the shader undo
/// any colour decoding of the texture (the plate's corner is sky, never sampled for the island).
@MainActor
enum NearDepthTexture {
    struct Key: Hashable, Sendable {
        var light: String
        var stage: Int

        init(_ plate: HomePlate) {
            light = plate.light
            stage = plate.stage
        }
    }

    private static var cache: [Key: Image] = [:]

    /// The texture if it is made.
    static func cached(_ plate: HomePlate) -> Image? {
        cache[Key(plate)]
    }

    /// The texture, made off the main thread the first time (a state's plate shows at mid first, so it
    /// is ready before the camera comes close).
    static func load(_ plate: HomePlate) async -> Image? {
        let key = Key(plate)
        if let hit = cache[key] { return hit }
        guard let near = plate.plate.near else { return nil }
        let lip = near.lipRow
        return store(await Task.detached(priority: .utility, operation: { render(plate, lipRow: lip) }).value, key: key)
    }

    /// The texture now, on the main thread: when the camera is already close and the warm-up at mid
    /// never ran (a cold start at near). A few milliseconds in a release build.
    static func make(_ plate: HomePlate) -> Image? {
        let key = Key(plate)
        if let hit = cache[key] { return hit }
        guard let near = plate.plate.near else { return nil }
        return store(render(plate, lipRow: near.lipRow), key: key)
    }

    private static func store(_ made: Pixels?, key: Key) -> Image? {
        if let hit = cache[key] { return hit }
        guard let made,
              let provider = CGDataProvider(data: Data(made.pixels) as CFData),
              let cg = CGImage(width: made.width, height: made.height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: made.width * 4,
                               space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue),
                               provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
        else { return nil }
        let image = Image(decorative: cg, scale: 1)
        if cache.count > 4 { cache.removeAll() }
        cache[key] = image
        return image
    }

    private struct Pixels: Sendable {
        var width: Int
        var height: Int
        var pixels: [UInt8]
    }

    private nonisolated static func render(_ plate: HomePlate, lipRow: Double) -> Pixels? {
        let k = NearLayers.textureScale
        let size = plate.plate.plateSize
        let w = Int((size.width * k).rounded()), h = Int((size.height * k).rounded())
        guard w > 1, h > 1,
              let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                                  space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
        else { return nil }
        // Top-left origin, plate pixels.
        ctx.translateBy(x: 0, y: CGFloat(h))
        ctx.scaleBy(x: CGFloat(k), y: CGFloat(-k))
        // The ground: each band of rows at its own (clamped) row.
        let step = 1 / k
        var y = 0.0
        while y < size.height {
            let row = NearLayers.groundRow(y + step / 2, lipRow: lipRow)
            ctx.setFillColor(red: CGFloat(NearLayers.encode(row: row)), green: 0, blue: 0, alpha: 1)
            ctx.fill(CGRect(x: 0, y: y, width: size.width, height: step))
            y += step
        }
        // The standing things, back to front, each at its foot.
        for region in NearLayers.regions(plate) {
            guard let first = region.polygon.first else { continue }
            ctx.beginPath()
            ctx.move(to: CGPoint(x: first.x, y: first.y))
            for p in region.polygon.dropFirst() { ctx.addLine(to: CGPoint(x: p.x, y: p.y)) }
            ctx.closePath()
            ctx.setFillColor(red: CGFloat(NearLayers.encode(row: region.row)), green: 1, blue: 0, alpha: 1)
            ctx.fillPath()
        }
        // A standing thing's edge feathers over the ground: a blurred thing in front spreads past its outline.
        if let data = ctx.data {
            feather(data.bindMemory(to: UInt8.self, capacity: w * h * 4), width: w, height: h, radius: NearLayers.featherTexels)
        }
        // The calibration texel.
        ctx.setFillColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
        ctx.fill(CGRect(x: 0, y: 0, width: step, height: step))
        guard let data = ctx.data else { return nil }
        let bytes = data.bindMemory(to: UInt8.self, capacity: w * h * 4)
        return Pixels(width: w, height: h, pixels: Array(UnsafeBufferPointer(start: bytes, count: w * h * 4)))
    }

    /// Two box passes each way over green (the share) and over red weighted by it (normalised), so the
    /// share falls off softly and the row under a soft edge stays the standing thing's.
    private nonisolated static func feather(_ px: UnsafeMutablePointer<UInt8>, width w: Int, height h: Int, radius: Int) {
        guard radius > 0 else { return }
        let n = w * h
        var share = [Double](repeating: 0, count: n), rowShare = [Double](repeating: 0, count: n)
        for i in 0..<n {
            let g = Double(px[i * 4 + 1]) / 255
            share[i] = g
            rowShare[i] = Double(px[i * 4]) / 255 * g
        }
        NearLayers.feather(&share, width: w, height: h, radius: radius)
        NearLayers.feather(&rowShare, width: w, height: h, radius: radius)
        for i in 0..<n where share[i] > 1e-3 {
            px[i * 4] = UInt8(min(max(rowShare[i] / share[i], 0), 1) * 255)
            px[i * 4 + 1] = UInt8(min(max(share[i], 0), 1) * 255)
        }
    }
}

extension WorldShaders {
    /// One blur level's share of the island (`BlurLevels.weight`), per pixel, from the depth rows.
    /// `shift` is where the level's layer starts on screen (its margin).
    static func lensLevel(_ level: Int, frame: NearLensFrame, depth: Image, plateSize: CGSize, shift: Double) -> Shader {
        let r = BlurLevels.radii
        let lens = frame.lens
        return Shader(function: ShaderFunction(library: library, name: "pofuLensLevel"), arguments: [
            .image(depth),
            .float4(frame.originX + shift, frame.originY + shift, frame.pointsPerPixel, 0),
            .float4(lens.focusRow, lens.depthPerRow, lens.aperture * lens.scale, lens.distance),
            .float4(r[0], r[1], r[2], r[3]),
            .float4(Double(level), frame.lipRow, NearLayers.rowRange.lowerBound, NearLayers.rowRange.upperBound),
            .float4(plateSize.width, plateSize.height, ThinLens.skip, ThinLens.cap),
        ])
    }
}

/// The island at the blur levels its rows need, each blurred as a whole and weighted per pixel by
/// the lens (D10): the weights sum to 1, so the levels add up (`plusLighter`) to one picture. Each
/// level is drawn with a margin round the screen, so its blur reads the island past the edge and
/// never thins the frame's border. Without a lens, or without the shader library, the island as is.
struct NearLensLevels: ViewModifier {
    let frame: NearLensFrame?
    let plate: HomePlate
    let size: CGSize

    /// The state's depth rows, once made (`NearDepthTexture.load`).
    @State private var depth: Image?

    /// Wider than the largest blur reaches.
    static let margin = 32.0

    func body(content: Content) -> some View {
        Group {
            if let frame, frame.levels != [0], WorldShaders.isAvailable, let depth = self.depth ?? NearDepthTexture.make(plate) {
                levels(content, frame: frame, depth: depth)
            } else if WorldShaders.isAvailable, let depth = self.depth {
                // Before the camera comes close the level shader runs once on a few transparent points, so
                // its pipeline is built at mid and the first near frame does not stall on it.
                content.overlay(alignment: .topLeading) {
                    ZStack {
                        Color.white
                        Color.white.blendMode(.plusLighter)
                    }
                    .frame(width: 4, height: 4)
                    .blur(radius: 2)
                    .colorEffect(WorldShaders.lensLevel(1, frame: .warmUp, depth: depth, plateSize: CGSize(width: 4, height: 4), shift: 0))
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                }
            } else {
                content
            }
        }
        .task(id: NearDepthTexture.Key(plate)) {
            if WorldShaders.isAvailable, plate.plate.near != nil {
                depth = await NearDepthTexture.load(plate)
            }
        }
    }

    private func levels(_ content: Content, frame: NearLensFrame, depth: Image) -> some View {
        let m = Self.margin
        let plateSize = CGSize(width: plate.plate.plateSize.width, height: plate.plate.plateSize.height)
        let levels = frame.levels
        return ZStack(alignment: .topLeading) {
            ForEach(levels, id: \.self) { level in
                content
                    .offset(x: CGFloat(m), y: CGFloat(m))
                    .frame(width: size.width + CGFloat(2 * m), height: size.height + CGFloat(2 * m), alignment: .topLeading)
                    .blur(radius: CGFloat(BlurLevels.radii[level]), opaque: false)
                    .colorEffect(WorldShaders.lensLevel(level, frame: frame, depth: depth, plateSize: plateSize, shift: m))
                    .offset(x: CGFloat(-m), y: CGFloat(-m))
                    .blendMode(level == levels.first ? .normal : .plusLighter)
            }
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .compositingGroup()
    }
}

extension NearLensFrame {
    /// A lens that blurs nothing (every level-1 weight is 0): the shader's warm-up.
    static let warmUp = NearLensFrame(
        lens: ThinLens(scale: 1, aperture: 0, focusRow: 0, unitsPerPixel: 1),
        originX: 0, originY: 0, pointsPerPixel: 1, lipRow: 0, range: 0...0,
        plateOrigin: PlatePoint(x: 0, y: 0), unitsPerPixel: 1
    )
}

extension View {
    /// A plain blur of a lens radius (points on screen), drawn at `localScale` points per local
    /// unit; nothing under the skip radius.
    @ViewBuilder
    func lensBlur(_ radius: Double, localScale: Double = 1) -> some View {
        if radius >= ThinLens.skip, localScale > 0 {
            blur(radius: CGFloat(radius / localScale))
        } else {
            self
        }
    }
}
#endif
