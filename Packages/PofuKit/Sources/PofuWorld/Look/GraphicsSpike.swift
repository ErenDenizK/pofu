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
    /// depth). Crisp by default (the founder, 2026-11-05: "always very
    /// heavy", "no detail shows"): a thick in-focus slab and a small
    /// largest radius, so the playable island reads sharp and only the
    /// far plate and the island's roots recede. With a station or a
    /// resident focused (`focused`), the slab is thicker still and the
    /// blur lighter, so the object and the ground around it are sharp
    /// and only the far background softens. On the Map (`z` 0) there is
    /// no blur; it eases in by the Island framing (`z` 1).
    public func field(focus: Double, focused: Bool = false, z: Double = 2) -> DepthOfField {
        let ease = min(max(z.isFinite ? z : 2, 0), 1)
        let radius = (focused ? 3.5 : 5.0) * max(dofStrength, 0) * ease
        return DepthOfField(focus: focus, slab: focused ? 48 : 34, range: focused ? 190 : 170, maxRadius: radius)
    }
}
