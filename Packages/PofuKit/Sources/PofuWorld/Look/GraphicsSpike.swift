import Foundation

/// The graphics spike's switches (Rehearsal mode's Ayar panel, `WorldLook.spike`).
/// Everything is off by default, so nothing about the shipped look changes.
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
    /// authored, up to 2 (Ayar).
    public var lightStrength: Double
    public var depthOfField: Bool
    /// Scales the largest blur radius (Ayar).
    public var dofStrength: Double
    public var debug: Debug

    public init(
        normalLighting: Bool = false,
        lightStrength: Double = 1,
        depthOfField: Bool = false,
        dofStrength: Double = 1,
        debug: Debug = .off
    ) {
        self.normalLighting = normalLighting
        self.lightStrength = lightStrength
        self.depthOfField = depthOfField
        self.dofStrength = dofStrength
        self.debug = debug
    }

    /// Both switches off.
    public static let off = GraphicsSpike()

    /// The sprites that have a baked normal map (`world-<name>--normal` in
    /// the asset catalog).
    public static let litSprites: Set<String> = ["cay-1", "mochi", "pofu"]

    /// The depth blur's lens: in focus at `focus` (the focal object's
    /// depth), tuned for the Home framing.
    public func field(focus: Double) -> DepthOfField {
        DepthOfField(focus: focus, slab: 14, range: 110, maxRadius: 9 * max(dofStrength, 0))
    }
}
