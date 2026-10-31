import Foundation

/// Landmarks of one piece of companion art, in unit coordinates of the
/// image (x right, y down, both in `0...1`).
///
/// The motion system is art-agnostic: a new illustration only needs a new
/// rig. In production the landmarks ship as JSON next to each image (see
/// the asset contract in `docs/design/companion-motion.md`).
public struct CompanionRig: Hashable, Sendable {
    public struct Point: Hashable, Sendable {
        public var x: Double
        public var y: Double

        public init(x: Double, y: Double) {
            self.x = x
            self.y = y
        }
    }

    public struct Ellipse: Hashable, Sendable {
        public var center: Point
        /// Radii as fractions of the image width (x) and height (y).
        public var radiusX: Double
        public var radiusY: Double

        public init(center: Point, radiusX: Double, radiusY: Double) {
            self.center = center
            self.radiusX = radiusX
            self.radiusY = radiusY
        }
    }

    /// Pixel size of the art; fixes the aspect ratio.
    public var pixelWidth: Double
    public var pixelHeight: Double
    /// Where the feet touch the floor.
    public var ground: Point
    /// Eye regions (slightly larger than the iris, including its outline).
    public var leftEye: Ellipse
    public var rightEye: Ellipse
    /// Cheek-pouch bulge centers and radius (fraction of width).
    public var leftCheek: Point
    public var rightCheek: Point
    public var cheekRadius: Double
    /// Blush ovals (tinted by `CompanionPose.blush`).
    public var leftBlush: Ellipse
    public var rightBlush: Ellipse
    /// The tuft region (radius as a fraction of width) and its root.
    public var tuft: Ellipse
    public var tuftPivot: Point
    /// The body's main ellipse; fur ripple acts on its outer ring.
    public var body: Ellipse
    /// The lid plate's top-left corner and size within the base image.
    public var lidPlateOrigin: Point
    public var lidPlateSize: Point

    public var aspectRatio: Double { pixelWidth / pixelHeight }

    /// The bundled placeholder hamster (`pofu-hamster.png`, 522×496), keyed
    /// out of the founder's first GPT Image concept.
    public static let hamster: CompanionRig = {
        let w = 522.0
        let h = 496.0
        func p(_ x: Double, _ y: Double) -> Point { Point(x: x / w, y: y / h) }
        return CompanionRig(
            pixelWidth: w,
            pixelHeight: h,
            ground: p(266, 481),
            leftEye: Ellipse(center: p(188, 218), radiusX: 42 / w, radiusY: 41 / h),
            rightEye: Ellipse(center: p(359, 217), radiusX: 42 / w, radiusY: 41 / h),
            leftCheek: p(128, 292),
            rightCheek: p(404, 290),
            cheekRadius: 118 / w,
            leftBlush: Ellipse(center: p(153, 266), radiusX: 40 / w, radiusY: 26 / h),
            rightBlush: Ellipse(center: p(388, 263), radiusX: 40 / w, radiusY: 26 / h),
            tuft: Ellipse(center: p(272, 52), radiusX: 62 / w, radiusY: 62 / h),
            tuftPivot: p(266, 102),
            body: Ellipse(center: p(265, 300), radiusX: 249 / w, radiusY: 219 / h),
            lidPlateOrigin: p(140, 170),
            lidPlateSize: p(268, 96)
        )
    }()
}
