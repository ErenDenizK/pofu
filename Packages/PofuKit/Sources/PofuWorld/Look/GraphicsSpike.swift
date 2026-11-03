import Foundation

/// The graphics spike's switches (Rehearsal mode's tuning lab panel, `WorldLook.spike`).
/// Decision (docs/design/look-dev.md): depth-map depth of field is the
/// default look; normal lighting stays off by default but available.
///
/// 1. **Normal lighting**: the hour's key, a soft fill, the practicals
///    (the ember) and a rim computed on the painted art from baked normal
///    maps (`tools/assets/normals.py`), for the çay ocağı, Mochi and Pofu.
/// 2. **Depth of field from a depth map**: a blur whose radius is a
///    function of each pixel's depth from the focal object's depth
///    (`DepthOfField`), in place of whole-layer blur.
public struct GraphicsSpike: Hashable, Sendable {
    /// What a debug render shows instead of the picture.
    public enum Debug: String, Hashable, Sendable, CaseIterable {
        case off
        /// The normal maps as colour.
        case normals
        /// The depth map as grey.
        case depth
    }

    public var normalLighting: Bool
    /// How much the light modulates the painted albedo: 0 off, 1 as
    /// authored, up to 2 (tuning lab).
    public var lightStrength: Double
    public var depthOfField: Bool
    /// Scales the largest blur radius (tuning lab).
    public var dofStrength: Double
    public var debug: Debug

    public init(
        normalLighting: Bool = false,
        lightStrength: Double = 1,
        depthOfField: Bool = true,
        dofStrength: Double = 1,
        debug: Debug = .off
    ) {
        self.normalLighting = normalLighting
        self.lightStrength = lightStrength
        self.depthOfField = depthOfField
        self.dofStrength = dofStrength
        self.debug = debug
    }

    /// The default: depth of field on, normal lighting off.
    public static let standard = GraphicsSpike()

    /// Both switches off (whole-layer blur only, the pre-spike look).
    public static let off = GraphicsSpike(depthOfField: false)

    /// The sprites that have a baked normal map (`world-<name>--normal` in
    /// the asset catalog).
    public static let litSprites: Set<String> = ["tea-stall-1", "mochi", "pofu"]

    /// The depth blur's lens: in focus at `focus` (the focal object's
    /// depth), tuned for the Home framing.
    public func field(focus: Double) -> DepthOfField {
        DepthOfField(focus: focus, slab: 14, range: 110, maxRadius: 9 * max(dofStrength, 0))
    }
}
