#if canImport(SwiftUI)
import SwiftUI

// The skin and what it paints, as the environment carries them. Not
// iOS-only: the kit's faces read it on every platform that has SwiftUI.

private struct PofuSkinKey: EnvironmentKey {
    static let defaultValue: PofuSkin = .glass
}

extension EnvironmentValues {
    /// The skin of the over-world chrome. Set once at the root from
    /// `PofuSkinPolicy`; views never read the policy themselves. Reduce
    /// Transparency overrides it where the faces are drawn.
    public var pofuSkin: PofuSkin {
        get { self[PofuSkinKey.self] }
        set { self[PofuSkinKey.self] = newValue }
    }

    /// Whether the baked painted faces of the Home slice (clay disc, linen,
    /// paper bubble and tail, ribbon tab, honey plaque) and the world's
    /// light on the chrome are drawn. Only the crafted skin paints them;
    /// the glass skin draws what it drew before asset wave 0, until the
    /// founder has compared the two. See `PofuSkinPolicy.face(for:)`.
    public var pofuPaintedChrome: Bool {
        PofuSkinPolicy.face(for: .plaque, skin: pofuSkin, reduceTransparency: accessibilityReduceTransparency) == .painted
    }
}
#endif
