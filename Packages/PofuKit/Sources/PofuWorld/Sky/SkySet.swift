import Foundation

/// A sky set (ADR-0025): the layers a world screen draws behind its island plate, split from the same
/// painted master (`tools/plate/split.py`) and shipped by `tools/plate/skyset_export.py`, which writes the
/// layers' places and the motion constants into `Plates/skyset-<island>.json`. That file is the one
/// source of the numbers: this runtime and the offline renderer (`tools/plate/skyset_render.py`) read the
/// same ones, so a review clip is the app's own motion.
///
/// Layers are listed bottom to top: the sky gradient, the stars' own light (night), the far clouds, the
/// distant isles, the whale, the mid clouds, the cloud sea, the island. Places and sizes are in master
/// pixels (the shipped x2 plate, 2048 x 3072); motion is in screen px at the 1206 px reference screen.
public struct SkySet: Hashable, Sendable {
    public enum Role: String, Hashable, Sendable {
        /// The gradient sky, stretched; stands still.
        case sky
        /// A drift tile that wraps in x.
        case tile
        /// A distant isle: bobs.
        case sprite
        /// The whale: bobs and glides across, wrapping once it is off screen.
        case whale
        /// The island layer with its cloud bank: never moves.
        case island
        /// A star group's own light, added over the sky and brightened in beats.
        case stars
    }

    /// A vertical sine of `amp` reference px over `period` s, `sign` its direction. It starts at zero, so
    /// time zero is the painting.
    public struct Bob: Hashable, Sendable {
        public var amp: Double
        public var period: Double
        public var sign: Double
    }

    /// A star group's brightening: up to `peak` of its own light, `sin^2` over `period` s, 0 at time zero.
    public struct Twinkle: Hashable, Sendable {
        public var peak: Double
        public var period: Double
    }

    /// Painted detail the app gives a little life of its own (`tools/plate/skyset_detail.py`), code only, from
    /// the sprite's own pixels: a waterfall's water flows down, a canopy's inside sways, a lamp flickers.
    /// Every amount rises from zero over `ramp` s, so time zero is the painting.
    public struct Detail: Hashable, Sendable, Identifiable {
        public enum Kind: String, Hashable, Sendable {
            /// A veil of lighter and darker streaks scrolls down inside `mask`; a mist breathes at its foot.
            case fall
            /// `crop` (the sprite's pixels) shears under `mask`: the top moves most, the silhouette stays.
            case sway
            /// `asset` (the lit pixels, alpha the mask) brightens and dims a few per cent.
            case glow
        }

        /// A faint mist at a fall's foot: an ellipse fading out, its opacity breathing 0 ... `peak`.
        public struct Mist: Hashable, Sendable {
            public var centre: PlatePoint
            public var radius: PlatePoint
            public var color: [Double]
            public var peak: Double
            public var period: Double
        }

        public var id: String
        public var kind: Kind
        /// The region's top-left and size in master pixels (the layer's own placement and bob apply).
        public var pos: PlatePoint
        public var size: PlatePoint
        public var ramp: Double
        public var mask: String?
        public var flow: String?
        public var crop: String?
        public var asset: String?
        /// A fall's streak tile height in master pixels (the scroll's period).
        public var flowHeight: Double = 0
        /// Reference px per second a fall's streaks move down.
        public var speed: Double = 0
        /// How much of the veil's alpha is drawn (0 ... 1).
        public var strength: Double = 0
        public var mist: Mist?
        /// A canopy top's displacement in reference px, or a lamp's luminance fraction.
        public var amp: Double = 0
        /// A canopy's sway period; a lamp's two flicker periods.
        public var period: Double = 0
        public var periods: [Double] = []
    }

    /// The mid clouds' drift tile (`<island>-sky-mid-<light>`).
    public static func isMidClouds(_ layer: Layer) -> Bool {
        layer.role == .tile && layer.asset.contains("-sky-mid-")
    }

    public struct Layer: Hashable, Sendable, Identifiable {
        public var id: String
        public var role: Role
        /// The imageset's name in the package's asset catalog.
        public var asset: String
        /// Top-left and size in master pixels.
        public var pos: PlatePoint
        public var size: PlatePoint
        /// Tile width in master pixels (a drift tile).
        public var tileWidth: Double?
        /// Reference px per second towards +x (tiles; the whale's glide).
        public var drift: Double
        public var bob: Bob?
        public var twinkle: Twinkle?
        /// Painted detail on a sprite or the whale.
        public var details: [Detail] = []
    }

    /// A plate's place on the master (`tools/plate/portrait.py`, `portraitFrame` in the island's `objects.json`).
    public struct PlateFrame: Hashable, Sendable {
        public var scale: Double
        public var offset: PlatePoint
    }

    public var light: String
    /// The master's size in pixels.
    public var master: PlatePoint
    /// The screen width the motion constants are given at.
    public var referenceWidth: Double
    public var layers: [Layer]
    /// Where the island plate's own pixels sit on the master, when the plate is not the master scaled
    /// (Çağlayan: a landscape plate on a portrait master): master px = plate px x `scale` + `offset`.
    /// `nil`: the plate is the master at its own scale (Home).
    public var plateFrame: PlateFrame?
    /// The state's textures in ASTC bytes (one a pixel): the set, the island cut for the Map and the
    /// occluders; the plate and its backdrop are not loaded while a sky set draws.
    public var textureBytes: Int

    /// The sky set a state shows, when it has one: home's level-10 day, golden hour and night; Çağlayan's
    /// day at each story stage (`day-<stage>`: the same sky, each stage plate's own island layer).
    public static func shipped(island: String, light: String, stage: Int) -> SkySet? {
        guard let file = SkySetFile.shipped(island) else { return nil }
        if let staged = file.lights["\(light)-\(stage)"] { return staged }
        return stage == 0 ? file.lights[light] : nil
    }
}

/// The motion of a sky set: pure functions of the time since the set appeared and the screen's width, in
/// points. `scale` is the screen width over the reference width (402 pt over 1206 px is a third), so a
/// reference px is `scale` points. `tools/plate/skyset_render.py` implements the same formulas.
public enum SkyMotion {
    /// The timeline's lowest smooth rate: the clouds move under 5 pt a second, a sixth of a point a frame.
    public static let frameInterval = 1.0 / 30.0
    /// The whale stays this far past an edge, in reference px, before it wraps.
    public static let glideMargin = 40.0

    public static func scale(width: Double, referenceWidth: Double) -> Double {
        referenceWidth > 0 ? width / referenceWidth : 1
    }

    /// The vertical offset of a bobbing layer, in points.
    public static func bob(_ bob: SkySet.Bob?, time: Double, scale: Double) -> Double {
        guard let bob, bob.period > 0 else { return 0 }
        return bob.sign * bob.amp * sin(2 * .pi * time / bob.period) * scale
    }

    /// How far a drift tile has moved right, in points, kept within one tile (`tileWidth` points).
    public static func drift(rate: Double, time: Double, tileWidth: Double, scale: Double) -> Double {
        guard tileWidth > 0 else { return 0 }
        return wrap(rate * scale * time, tileWidth)
    }

    /// The whale's left edge in points: at rest at `restLeft`, gliding right at `speed` reference px a
    /// second, re-entering from the left only once it is `glideMargin` past the right edge, so the
    /// wrap is never on screen.
    public static func glideLeft(restLeft: Double, width: Double, speed: Double, time: Double, screenWidth: Double, scale: Double) -> Double {
        let margin = glideMargin * scale
        let span = screenWidth + 2 * margin + width
        guard span > 0 else { return restLeft }
        return wrap(restLeft + margin + width + speed * scale * time, span) - margin - width
    }

    /// A star group's added light, 0 ... `peak`; 0 at time zero.
    public static func twinkle(_ twinkle: SkySet.Twinkle?, time: Double) -> Double {
        guard let twinkle, twinkle.period > 0 else { return 0 }
        let s = sin(.pi * time / twinkle.period)
        return twinkle.peak * s * s
    }

    // MARK: Painted detail

    /// The envelope of every detail amount: 0 at time zero, 1 from `ramp` s on (smoothstep).
    public static func ease(time: Double, ramp: Double) -> Double {
        guard ramp > 0 else { return 1 }
        let x = min(max(time / ramp, 0), 1)
        return x * x * (3 - 2 * x)
    }

    /// How far a waterfall's streak tile has scrolled down, in points, kept within one tile (`period` points).
    public static func flowOffset(speed: Double, time: Double, period: Double, scale: Double) -> Double {
        guard period > 0 else { return 0 }
        return wrap(speed * scale * time, period)
    }

    /// A fall's mist opacity: `peak` breathing as `sin^2` over its period, enveloped; 0 at time zero.
    public static func mist(_ mist: SkySet.Detail.Mist, time: Double, ease: Double) -> Double {
        guard mist.period > 0 else { return 0 }
        let s = sin(.pi * time / mist.period)
        return ease * mist.peak * s * s
    }

    /// A lamp's signed luminance change, -amp ... +amp: two slow sines (0.6 and 0.4 of it), enveloped.
    public static func flicker(_ detail: SkySet.Detail, time: Double) -> Double {
        guard detail.periods.count == 2, detail.periods[0] > 0, detail.periods[1] > 0 else { return 0 }
        let wave = 0.6 * sin(2 * .pi * time / detail.periods[0]) + 0.4 * sin(2 * .pi * time / detail.periods[1])
        return ease(time: time, ramp: detail.ramp) * detail.amp * wave
    }

    /// A canopy top's horizontal displacement in points.
    public static func sway(_ detail: SkySet.Detail, time: Double, scale: Double) -> Double {
        guard detail.period > 0 else { return 0 }
        return ease(time: time, ramp: detail.ramp) * detail.amp * sin(2 * .pi * time / detail.period) * scale
    }

    static func wrap(_ value: Double, _ length: Double) -> Double {
        let r = value.truncatingRemainder(dividingBy: length)
        return r < 0 ? r + length : r
    }
}

/// `Plates/skyset-<island>.json` as `skyset_export.py` writes it.
struct SkySetFile: Sendable {
    var island: String
    var lights: [String: SkySet]

    private static let cache = SkySetCache()

    /// The island's shipped sky sets, decoded once.
    static func shipped(_ island: String) -> SkySetFile? {
        cache.file(island)
    }

    static func load(_ island: String) -> SkySetFile? {
        let name = "skyset-\(island)"
        let url = Bundle.module.url(forResource: name, withExtension: "json")
            ?? Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Plates")
        guard let url, let data = try? Data(contentsOf: url) else { return nil }
        return try? decode(data)
    }

    static func decode(_ data: Data) throws -> SkySetFile {
        try JSONDecoder().decode(SkySetFile.self, from: data)
    }
}

private final class SkySetCache: @unchecked Sendable {
    private let lock = NSLock()
    private var files: [String: SkySetFile?] = [:]

    func file(_ island: String) -> SkySetFile? {
        lock.lock()
        defer { lock.unlock() }
        if let cached = files[island] { return cached }
        let loaded = SkySetFile.load(island)
        files[island] = .some(loaded)
        return loaded
    }
}

// MARK: - Decoding

extension SkySetFile: Decodable {
    private enum Keys: String, CodingKey {
        case island, master, referenceWidth, lights, plateFrame
    }

    private struct RawFrame: Decodable {
        var scale: Double
        var offset: [Double]
    }

    private struct RawBob: Decodable {
        var amp: Double
        var period: Double
        var sign: Double
    }

    private struct RawTwinkle: Decodable {
        var peak: Double
        var period: Double
    }

    private struct RawMist: Decodable {
        var centre: [Double]
        var radius: [Double]
        var color: [Double]
        var peak: Double
        var period: Double
    }

    private struct RawDetail: Decodable {
        var id: String
        var kind: String
        var pos: [Double]
        var size: [Double]
        var ramp: Double
        var mask: String?
        var flow: String?
        var crop: String?
        var asset: String?
        var flowHeight: Double?
        var speed: Double?
        var strength: Double?
        var mist: RawMist?
        var amp: Double?
        var period: Double?
        var periods: [Double]?
    }

    private struct RawLayer: Decodable {
        var id: String
        var role: String
        var asset: String
        var pos: [Double]
        var size: [Double]
        var tileWidth: Double?
        var drift: Double?
        var bob: RawBob?
        var twinkle: RawTwinkle?
        var details: [RawDetail]?
    }

    private struct RawLight: Decodable {
        var layers: [RawLayer]
        var textureBytes: Int
        var master: [Double]?
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Keys.self)
        island = try c.decode(String.self, forKey: .island)
        let master = try c.decode([Double].self, forKey: .master)
        let reference = try c.decodeIfPresent(Double.self, forKey: .referenceWidth) ?? 1206
        let raw = try c.decode([String: RawLight].self, forKey: .lights)
        let frame = try c.decodeIfPresent(RawFrame.self, forKey: .plateFrame)
        guard master.count == 2 else {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "the master has a width and a height"))
        }
        func point(_ v: [Double]) throws -> PlatePoint {
            guard v.count == 2 else { throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "a point has two numbers")) }
            return PlatePoint(x: v[0], y: v[1])
        }
        var sets: [String: SkySet] = [:]
        for (light, value) in raw {
            let layers = try value.layers.map { layer -> SkySet.Layer in
                guard let role = SkySet.Role(rawValue: layer.role) else {
                    throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "unknown sky layer role \(layer.role)"))
                }
                let details = try (layer.details ?? []).map { raw -> SkySet.Detail in
                    guard let kind = SkySet.Detail.Kind(rawValue: raw.kind) else {
                        throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "unknown sky detail kind \(raw.kind)"))
                    }
                    var detail = SkySet.Detail(
                        id: raw.id, kind: kind, pos: try point(raw.pos), size: try point(raw.size), ramp: raw.ramp,
                        mask: raw.mask, flow: raw.flow, crop: raw.crop, asset: raw.asset
                    )
                    detail.flowHeight = raw.flowHeight ?? 0
                    detail.speed = raw.speed ?? 0
                    detail.strength = raw.strength ?? 0
                    detail.amp = raw.amp ?? 0
                    detail.period = raw.period ?? 0
                    detail.periods = raw.periods ?? []
                    detail.mist = try raw.mist.map {
                        SkySet.Detail.Mist(centre: try point($0.centre), radius: try point($0.radius), color: $0.color, peak: $0.peak, period: $0.period)
                    }
                    return detail
                }
                return SkySet.Layer(
                    id: layer.id, role: role, asset: layer.asset, pos: try point(layer.pos), size: try point(layer.size),
                    tileWidth: layer.tileWidth, drift: layer.drift ?? 0,
                    bob: layer.bob.map { SkySet.Bob(amp: $0.amp, period: $0.period, sign: $0.sign) },
                    twinkle: layer.twinkle.map { SkySet.Twinkle(peak: $0.peak, period: $0.period) },
                    details: details
                )
            }
            let placed = try frame.map { SkySet.PlateFrame(scale: $0.scale, offset: try point($0.offset)) }
            // A staged set is keyed `<light>-<stage>`; its light is the name before the dash.
            sets[light] = SkySet(
                light: String(light.split(separator: "-").first ?? Substring(light)), master: try point(master),
                referenceWidth: reference, layers: layers, plateFrame: placed, textureBytes: value.textureBytes
            )
        }
        lights = sets
    }
}
