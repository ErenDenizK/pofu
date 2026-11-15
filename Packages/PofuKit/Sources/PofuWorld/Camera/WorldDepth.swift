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

    /// Which screen edges a layer is stretched to meet when the depth function leaves them bare. Only
    /// layers that are a ground to the picture are: the gradient sky (both edges: it moves with the
    /// camera's anchor, never its scale) and the cloud sea's own band (the bottom edge: at the Map the
    /// sea is drawn smaller than the screen is tall, and its painted foot lies above the screen's foot).
    /// A stopgap until the floor layers (WP9) are tiles that reach the bottom by themselves.
    public static func stretch(of layer: SkySet.Layer) -> (up: Bool, down: Bool) {
        switch layer.role {
        case .sky: (true, true)
        case .tile where layer.asset.contains("-sky-sea-") && !layer.id.contains("-map"): (false, true)
        default: (false, false)
        }
    }

    /// A layer's rows `minY` ... `maxY` stretched to meet the edges of `stretch(of:)` on a screen
    /// `screenHeight` tall. The layer's own picture is scaled with it; its top (or foot) stays put.
    public static func covering(minY: Double, maxY: Double, screenHeight: Double, stretch: (up: Bool, down: Bool)) -> (minY: Double, maxY: Double) {
        (stretch.up ? min(minY, 0) : minY, stretch.down ? max(maxY, screenHeight) : maxY)
    }
}
