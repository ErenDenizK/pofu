import Foundation

/// `plate-<island>.json` `camera` (v2 §6.1): the painting's camera elevation.
public struct PlateCamera: Decodable, Hashable, Sendable {
    public var elevationDeg: Double
}

/// `plate-<island>.json` `near` (v2 §6.1, build spec WP11): the lens's shots and what the depth
/// rows need that the plate's objects do not say, and the near camera's ground (mainflow plan row 3a):
/// the focal lawn, the strip over the earth face and the dressing. All of them draw only at the near
/// framing and fade in with the camera's scale (`fadeIn`).
public struct PlateNear: Decodable, Hashable, Sendable {
    public var shots: ThinLens.Shots
    /// The lawn's front lip, a plate row: the earth face under it takes this row (v2 §5.1), and
    /// so does anything standing on that face (the doors).
    public var lipRow: Double
    /// The objects that lie flat on the ground (a pond, a deck): their pixels keep their own rows.
    /// Every other object stands, and all its pixels take its `footY`.
    public var flat: [String]
    /// The focal ground: a lawn detail tile drawn over the plate (soft light, so it takes the plate's
    /// own colour in every light), clipped to the walkable lawn by a mask, fading out in depth.
    public var patch: Patch?
    /// The soft strip over the front lip that covers the whole earth face.
    public var foreground: Foreground?
    /// The near dressing: tufts, pebbles, clover, daisies and the tea stool, each with its contact shadow.
    public var dressing: [Dressing]

    public struct Patch: Decodable, Hashable, Sendable {
        /// The seamless detail tile (mid grey is neutral) and the lawn mask (its alpha), asset names.
        public var detail: String
        public var mask: String
        /// The mask's extent in plate pixels: x0, y0, x1, y1.
        public var maskBox: [Double]
        /// Plate pixels one tile covers.
        public var tile: Double
        /// Plate rows where the band starts, is full, stops being full and ends.
        public var rows: [Double]
        /// The camera scales where the layer starts to show and is fully shown.
        public var fadeIn: [Double]
        /// The detail's strength at night (1 elsewhere).
        public var night: Double
    }

    public struct Foreground: Decodable, Hashable, Sendable {
        public var art: String
        /// The first copy's left edge, the copies (each mirrored from its neighbour) and their size, in plate pixels.
        public var x: Double
        public var count: Int
        public var width: Double
        public var height: Double
        /// The plate row of the first copy's top.
        public var top: Double
        public var fadeIn: [Double]
    }

    public struct Dressing: Decodable, Hashable, Sendable {
        public var art: String
        /// The foot (the image's bottom centre), width and height, plate pixels.
        public var at: [Double]
        public var footY: Double
        public var width: Double
        public var height: Double
        /// The contact shadow's strength.
        public var shadow: Double
        public var stages: [Int]?
    }

    private enum Keys: String, CodingKey { case shots, lipRow, flat, patch, foreground, dressing }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Keys.self)
        shots = try c.decodeIfPresent(ThinLens.Shots.self, forKey: .shots) ?? .standard
        lipRow = try c.decode(Double.self, forKey: .lipRow)
        flat = try c.decodeIfPresent([String].self, forKey: .flat) ?? []
        patch = try c.decodeIfPresent(Patch.self, forKey: .patch)
        foreground = try c.decodeIfPresent(Foreground.self, forKey: .foreground)
        dressing = try c.decodeIfPresent([Dressing].self, forKey: .dressing) ?? []
    }
}

/// How much of the near ground shows at a camera scale: 0 below `from`, 1 above `to`, smooth between.
public func nearGroundShare(scale: Double, fadeIn: [Double]) -> Double {
    guard fadeIn.count == 2, fadeIn[1] > fadeIn[0] else { return 0 }
    let t = min(max((scale - fadeIn[0]) / (fadeIn[1] - fadeIn[0]), 0), 1)
    return t * t * (3 - 2 * t)
}

/// The near layers (build spec WP11) in plate terms, pure: the depth row of every island pixel
/// (what the packed mask's A channel will carry once it ships) and the lens on screen.
public enum NearLayers {
    /// A standing thing's outline and the one row all its pixels take.
    public struct Region: Hashable, Sendable {
        public var id: String
        public var polygon: [PlatePoint]
        public var row: Double
    }

    /// The standing things of a state, back to front: every object the state paints that does
    /// not lie flat, at its foot, the lip's row at most.
    public static func regions(_ plate: HomePlate) -> [Region] {
        guard let near = plate.plate.near else { return [] }
        return plate.objects
            .filter { !near.flat.contains($0.id) && $0.polygon.count >= 3 }
            .map { Region(id: $0.id, polygon: $0.polygon, row: min($0.footY, near.lipRow)) }
            .sorted { ($0.row, $0.id) < ($1.row, $1.id) }
    }

    /// A ground pixel's depth row: its own, the lip's under the lip.
    public static func groundRow(_ row: Double, lipRow: Double) -> Double {
        min(row, lipRow)
    }

    /// The depth texture's row range: rows in it map linearly onto 0...1.
    public static let rowRange = 380.0...1300.0

    public static func encode(row: Double) -> Double {
        min(max((row - rowRange.lowerBound) / (rowRange.upperBound - rowRange.lowerBound), 0), 1)
    }

    public static func decode(_ v: Double) -> Double {
        rowRange.lowerBound + v * (rowRange.upperBound - rowRange.lowerBound)
    }

    /// The depth texture covers the whole plate at this share of its pixels (soft edges come
    /// from its linear filtering).
    public static let textureScale = 0.25

    /// A standing thing's edge feathers over this many texels (4 plate pixels each) of box blur, twice:
    /// about the cap's radius at near's rest, so a blurred thing in front never shows its outline.
    public static let featherTexels = 2

    /// Two box passes each way over a `width` x `height` field, in place: a sliding window, linear in
    /// the field's size (cheap enough for the main thread in a debug build). The window is cut at the
    /// border and averages what it covers.
    public static func feather(_ v: inout [Double], width w: Int, height h: Int, radius: Int) {
        guard radius > 0, w > 0, h > 0, v.count == w * h else { return }
        var line = [Double](repeating: 0, count: max(w, h))
        func pass(count: Int, lines: Int, index: (Int, Int) -> Int) {
            for l in 0..<lines {
                for i in 0..<count { line[i] = v[index(l, i)] }
                var sum = 0.0
                for i in 0..<min(radius, count) { sum += line[i] }
                for i in 0..<count {
                    if i + radius < count { sum += line[i + radius] }
                    if i - radius - 1 >= 0 { sum -= line[i - radius - 1] }
                    let lo = max(i - radius, 0), hi = min(i + radius, count - 1)
                    v[index(l, i)] = sum / Double(hi - lo + 1)
                }
            }
        }
        for _ in 0..<2 {
            pass(count: w, lines: h) { y, x in y * w + x }
            pass(count: h, lines: w) { x, y in y * w + x }
        }
    }
}

/// The lens on screen for one frame of a plate (WP11): the thin lens, and how plate pixels map to
/// the screen, so a layer can ask the radius of a row or of a world foot.
public struct NearLensFrame: Hashable, Sendable {
    public var lens: ThinLens
    /// The screen point of plate pixel (0, 0), in points.
    public var originX: Double
    public var originY: Double
    /// Screen points per plate pixel.
    public var pointsPerPixel: Double
    public var lipRow: Double
    /// The radii the island shows on screen (rows from the screen's top to its bottom).
    public var range: ClosedRange<Double>
    /// The world's origin, as a plate pixel, and world units per plate pixel (to turn a world
    /// foot into a row).
    public var plateOrigin: PlatePoint
    public var unitsPerPixel: Double

    /// What the camera is focused on.
    public enum Focus: Hashable, Sendable {
        /// A station or a resident: their foot row, the focus shot's aperture.
        case subject(row: Double)
        /// Near on the free rail: the ground under the near rest's feet row.
        case rail
    }

    /// The frame for `plate` under `pose`, or `nil` when the plate has no lens data or nothing
    /// on screen would blur.
    public static func make(plate: HomePlate, pose: CameraPose, width: Double, height: Double, offsetX: Double = 0, offsetY: Double = 0, focus: Focus, feetShare: Double = NearShot.feetY) -> NearLensFrame? {
        guard let near = plate.plate.near, let elevation = plate.plate.elevationDeg else { return nil }
        let s = pose.scale
        let u = plate.unitsPerPixel
        let zero = pose.project(plate.world(PlatePoint(x: 0, y: 0)), width: width)
        let ox = zero.x + offsetX, oy = zero.y + offsetY
        let ppp = u * s
        guard ppp > 0 else { return nil }
        let row: Double
        var aperture: Double
        switch focus {
        case .subject(let r):
            row = r
            aperture = near.shots.focusAperture(scale: s)
        case .rail:
            row = (feetShare * height - oy) / ppp
            aperture = near.shots.aperture(scale: s)
        }
        if plate.light == "night" { aperture *= near.shots.night }
        let lens = ThinLens(scale: s, aperture: aperture, focusRow: row, unitsPerPixel: u, elevationDeg: elevation)
        // The rows on screen, inside the island.
        let island = plate.plate.islandBox
        let top = max((0 - oy) / ppp, island.minY)
        let bottom = min((height - oy) / ppp, island.maxY)
        guard bottom > top else { return nil }
        // The island's rows run from `a` to `b`; the lip's row holds below it.
        let a = NearLayers.groundRow(top, lipRow: near.lipRow), b = NearLayers.groundRow(bottom, lipRow: near.lipRow)
        let ends = [lens.radius(row: a), lens.radius(row: b)]
        let low = (a...b).contains(row) ? 0 : ends.min() ?? 0
        let high = ends.max() ?? 0
        guard max(high, lens.skyRadius) >= ThinLens.skip else { return nil }
        return NearLensFrame(
            lens: lens,
            originX: ox,
            originY: oy,
            pointsPerPixel: ppp,
            lipRow: near.lipRow,
            range: low...high,
            plateOrigin: plate.origin,
            unitsPerPixel: u
        )
    }

    /// The radius (points) of a plate row.
    public func radius(row: Double) -> Double {
        ThinLens.applied(lens.radius(row: NearLayers.groundRow(row, lipRow: lipRow)))
    }

    /// The radius (points) of a thing standing at world row `worldY`.
    public func radius(worldY: Double) -> Double {
        radius(row: plateOrigin.y + worldY / unitsPerPixel)
    }

    /// The sky's radius (points).
    public var skyRadius: Double {
        ThinLens.applied(lens.skyRadius)
    }

    /// The blur levels the island needs on screen.
    public var levels: [Int] {
        BlurLevels.levels(spanning: range)
    }
}
