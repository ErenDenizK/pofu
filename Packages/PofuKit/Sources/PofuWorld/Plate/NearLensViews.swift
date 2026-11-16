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
    private struct Key: Hashable {
        var light: String
        var stage: Int
    }

    private static var cache: [Key: Image] = [:]

    static func image(_ plate: HomePlate) -> Image? {
        let key = Key(light: plate.light, stage: plate.stage)
        if let hit = cache[key] { return hit }
        guard let near = plate.plate.near, let cg = render(plate, lipRow: near.lipRow) else { return nil }
        let image = Image(decorative: cg, scale: 1)
        if cache.count > 4 { cache.removeAll() }
        cache[key] = image
        return image
    }

    private static func render(_ plate: HomePlate, lipRow: Double) -> CGImage? {
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
        return ctx.makeImage()
    }

    /// Two box passes each way over green (the share) and over red weighted by it (normalised), so the
    /// share falls off softly and the row under a soft edge stays the standing thing's.
    private static func feather(_ px: UnsafeMutablePointer<UInt8>, width w: Int, height h: Int, radius: Int) {
        guard radius > 0 else { return }
        let n = w * h
        var share = [Double](repeating: 0, count: n), rowShare = [Double](repeating: 0, count: n)
        for i in 0..<n {
            let g = Double(px[i * 4 + 1]) / 255
            share[i] = g
            rowShare[i] = Double(px[i * 4]) / 255 * g
        }
        func box(_ v: inout [Double]) {
            var out = [Double](repeating: 0, count: n)
            for _ in 0..<2 {
                for y in 0..<h {
                    for x in 0..<w {
                        var sum = 0.0, count = 0.0
                        for dx in -radius...radius where (0..<w).contains(x + dx) { sum += v[y * w + x + dx]; count += 1 }
                        out[y * w + x] = sum / count
                    }
                }
                for y in 0..<h {
                    for x in 0..<w {
                        var sum = 0.0, count = 0.0
                        for dy in -radius...radius where (0..<h).contains(y + dy) { sum += out[(y + dy) * w + x]; count += 1 }
                        v[y * w + x] = sum / count
                    }
                }
            }
        }
        box(&share)
        box(&rowShare)
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

    /// Wider than the largest blur reaches.
    static let margin = 32.0

    func body(content: Content) -> some View {
        if let frame, frame.levels != [0], WorldShaders.isAvailable, let depth = NearDepthTexture.image(plate) {
            let m = Self.margin
            let plateSize = CGSize(width: plate.plate.plateSize.width, height: plate.plate.plateSize.height)
            let levels = frame.levels
            ZStack(alignment: .topLeading) {
                ForEach(levels, id: \.self) { level in
                    let radius = BlurLevels.radii[level]
                    content
                        .offset(x: CGFloat(m), y: CGFloat(m))
                        .frame(width: size.width + CGFloat(2 * m), height: size.height + CGFloat(2 * m), alignment: .topLeading)
                        .blur(radius: CGFloat(radius), opaque: false)
                        .colorEffect(WorldShaders.lensLevel(level, frame: frame, depth: depth, plateSize: plateSize, shift: m))
                        .offset(x: CGFloat(-m), y: CGFloat(-m))
                        .blendMode(level == levels.first ? .normal : .plusLighter)
                }
            }
            .frame(width: size.width, height: size.height, alignment: .topLeading)
            .compositingGroup()
        } else {
            content
        }
    }
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
