#if canImport(SwiftUI)
import SwiftUI

/// Access to the companion's Metal shaders.
///
/// SwiftPM packages ship Metal shaders as a resource that Xcode compiles
/// into `default.metallib` in the package bundle. Command-line `swift
/// build` (and therefore `swift test`) copies the `.metal` source without
/// compiling it, so the library only exists in Xcode builds. Callers check
/// `isAvailable` and fall back to the pure SwiftUI approximation.
public enum CompanionShaders {
    /// Whether the compiled shader library is present in the bundle.
    public static let isAvailable: Bool =
        Bundle.module.url(forResource: "default", withExtension: "metallib") != nil

    static var library: ShaderLibrary { .bundle(.module) }

    /// The deformation pass: cheek pouches, tuft follow-through, fur ripple.
    ///
    /// - Parameter artRect: the art's rectangle inside the layer, in points.
    static func deform(pose: CompanionPose, rig: CompanionRig, artRect: CGRect) -> Shader {
        let function = ShaderFunction(library: library, name: "pofuCompanionDeform")
        return Shader(function: function, arguments: [
            .float4(artRect.minX, artRect.minY, artRect.width, artRect.height),
            .float4(rig.leftCheek.x, rig.leftCheek.y, rig.rightCheek.x, rig.rightCheek.y),
            .float2(rig.cheekRadius, CompanionShaders.inflation(cheekPuff: pose.cheekPuff)),
            .float4(rig.tuft.center.x, rig.tuft.center.y, rig.tuftPivot.x, rig.tuftPivot.y),
            .float2(rig.tuft.radiusX, pose.tuftAngle),
            .float4(rig.body.center.x, rig.body.center.y, rig.body.radiusX, rig.body.radiusY),
            .float2(pose.time.truncatingRemainder(dividingBy: 1000), pose.furRipple),
        ])
    }

    /// Shader inflation for a cheek fill in `0...1`. Kept below the point
    /// where the bulge starts to swallow the eyes.
    static func inflation(cheekPuff: Double) -> Double {
        min(max(cheekPuff, 0), 1.1) * 0.58
    }
}
#endif
