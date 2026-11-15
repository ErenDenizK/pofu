import Foundation

/// One camera with a depth function (docs/design/world-presentation-v2.md section 2): every backdrop layer
/// is drawn at the world camera's pose pulled toward a reference pose by its depth exponent `k`.
///
/// With the mid stop's camera as the reference (scale `s0`, look `L0`) and the camera at scale `s`, look
/// `L`, a layer at depth `k` is drawn at
///
///     scale_k = s0 * (s / s0)^k
///     look_k  = L0 + k * (L - L0)
///
/// with the camera's own anchor. `k = 1` is the camera (the island); `k = 0` never moves. One function
/// replaces the Map's separate sky camera and the per-stop placements.
public enum DepthLayer {
    /// The pose a layer of depth `k` is drawn at, for the world camera `camera`.
    public static func pose(_ camera: CameraPose, reference: CameraPose, k: Double) -> CameraPose {
        CameraPose(
            logScale: reference.logScale + k * (camera.logScale - reference.logScale),
            lookX: reference.lookX + k * (camera.lookX - reference.lookX),
            lookY: reference.lookY + k * (camera.lookY - reference.lookY),
            anchorY: camera.anchorY
        )
    }

    /// Whether a layer is the cloud sea (the near band or one of the Map's receding copies of it).
    public static func isSea(_ layer: SkySet.Layer) -> Bool {
        layer.role == .tile && layer.asset.contains("-sky-sea-")
    }

    /// The gradient sky moves with the camera's anchor and never with its scale, so it can leave a screen
    /// edge bare: its rows are extended to both edges (it is a gradient, so nothing shows).
    public static func coveringSky(minY: Double, maxY: Double, screenHeight: Double) -> (minY: Double, maxY: Double) {
        (min(minY, 0), max(maxY, screenHeight))
    }

    /// The factor the whole cloud sea is scaled by, about its tile's top (`pivotY`) and the screen's
    /// middle, so that its foot reaches the screen's: 1 when it already does. Every sea layer (the near
    /// band and the Map's receding copies) is scaled by the same factor about the same point, so their
    /// layout is untouched; the puffs grow toward the viewer. A stopgap until WP9's floor tiles reach
    /// the bottom by themselves: at the Map the depth function draws the sea smaller than the screen is
    /// tall.
    public static func seaFit(top: Double, bottom: Double, screenHeight: Double) -> Double {
        guard bottom < screenHeight, bottom > top else { return 1 }
        return (screenHeight - top) / (bottom - top)
    }

    /// A rectangle scaled by `f` about the point (`x`, `y`).
    public static func scaled(minX: Double, minY: Double, width: Double, height: Double, by f: Double, aboutX x: Double, y: Double) -> (minX: Double, minY: Double, width: Double, height: Double) {
        (x + (minX - x) * f, y + (minY - y) * f, width * f, height * f)
    }
}
