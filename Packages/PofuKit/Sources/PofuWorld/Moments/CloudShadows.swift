import Foundation

/// Cloud shadows by day (light and shadow v2, section 5): two or three very
/// soft, large shapes drifting slowly across the island. Pure: what is drawn,
/// where, and when; `CloudShadowLayer` paints it from one cached image.
///
/// They drift only in the Ambient state (30 Hz), hold still wherever they
/// are while the world is settled or busy with a Moment, and are off in
/// Low Power Mode, under Reduce Motion and at night.
public enum CloudShadows {
    /// A cloud in the tile, in world units from the tile's left edge and the
    /// layer's top.
    public struct Shape: Hashable, Sendable {
        public var x: Double
        public var y: Double
        public var radiusX: Double
        public var radiusY: Double
        /// 0...1, relative to the layer's opacity.
        public var weight: Double
    }

    /// What one frame draws.
    public struct Frame: Hashable, Sendable {
        /// The layer's opacity, at most `maxOpacity`.
        public var opacity: Double
        /// The cloud shadow's hue: the cell shadow, darkened.
        public var tint: GradeRGB
        /// How far the tile has drifted to the right, in `0..<tileWidth`.
        public var shift: Double
    }

    /// Never darker than this.
    public static let maxOpacity = 0.12
    /// World units per second.
    public static let driftSpeed = 6.0
    /// The tile repeats every `tileWidth` and is `tileHeight` tall; the
    /// window it drifts through is the light map's width.
    public static let tileWidth = 1100.0
    public static let tileHeight = 300.0
    /// Where the window's top-left sits in the world, and its size: the
    /// island's lawn.
    public static let window = WorldBox(minX: -260, minY: -150, maxX: 540, maxY: 150)
    /// How much of the shadow's hue is kept (the rest is darkness).
    public static let darken = 0.7

    /// Three shapes, far apart, none touching the tile's edge so the wrap
    /// is invisible.
    public static let shapes: [Shape] = [
        Shape(x: 190, y: 90, radiusX: 170, radiusY: 62, weight: 1.0),
        Shape(x: 560, y: 200, radiusX: 150, radiusY: 54, weight: 0.8),
        Shape(x: 920, y: 120, radiusX: 140, radiusY: 58, weight: 0.9),
    ]

    /// Whether cloud shadows exist at all in this light and these settings.
    public static func isEnabled(band: SunShadow.Band, lowPower: Bool, reduceMotion: Bool) -> Bool {
        band != .night && !lowPower && !reduceMotion
    }

    /// The layer's opacity: full by day, fading with the golden hour's long
    /// shadows (the sun is low and the clouds flatten into the light).
    public static func opacity(band: SunShadow.Band) -> Double {
        switch band {
        case .day: maxOpacity
        case .golden: maxOpacity * 0.6
        case .night: 0
        }
    }

    /// Whether the clouds move: only in the 30 Hz Ambient state.
    public static func drifts(under directive: FrameDirective) -> Bool {
        directive.state == .ambient && directive.hz > 0
    }

    /// The drift after `time` seconds of ambient time, wrapped to the tile.
    public static func shift(atAmbientTime time: Double) -> Double {
        guard time.isFinite else { return 0 }
        let moved = time * driftSpeed
        return moved - (moved / tileWidth).rounded(.down) * tileWidth
    }

    /// The frame to draw, or `nil` when there are no clouds. While the clouds
    /// do not drift they stay at `held`, the shift they last had.
    public static func frame(
        shadow: SunShadow,
        directive: FrameDirective,
        lowPower: Bool,
        reduceMotion: Bool,
        ambientTime: Double,
        held: Double
    ) -> Frame? {
        guard isEnabled(band: shadow.band, lowPower: lowPower, reduceMotion: reduceMotion),
              !directive.flattensWorld else { return nil }
        let hue = shadow.tint
        return Frame(
            opacity: opacity(band: shadow.band),
            tint: GradeRGB(hue.r * darken, hue.g * darken, hue.b * darken),
            shift: drifts(under: directive) ? shift(atAmbientTime: ambientTime) : held
        )
    }
}
