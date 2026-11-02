import Foundation

/// The world scene's look features, as flags (look-dev A, B, C). They
/// default to on in the world scene only; the UI around it never reads
/// them. Screenshots and the debug overlay switch them to compare.
public struct WorldLook: Hashable, Sendable {
    /// Which bake of the art to draw.
    public enum ArtSet: String, Hashable, Sendable, CaseIterable {
        /// Baked with `lock-light`: saturation and contrast near neutral,
        /// graded at runtime. The default.
        case lockLight
        /// The `soft-lock` bake the app shipped until 2026-11-02, kept to
        /// compare; drop it once the founder has chosen.
        case softLock
    }

    public var art: ArtSet
    /// The runtime color grade (`WorldGrade`) driven by `WorldLight`.
    public var grade: Bool
    /// Painted HD-2D lite: bloom, light shafts, ambient particles and the
    /// stronger tilt-shift. The vignette belongs to the grade.
    public var hd2d: Bool
    /// The terrarium's glass rim at the Island and Map framings.
    public var terrarium: Bool
    /// A fixed local hour (screenshots); `nil` follows the world's clock.
    public var hourOverride: Double?
    /// The frame-time counter in a corner (debug).
    public var frameMeter: Bool

    public init(
        art: ArtSet = .lockLight,
        grade: Bool = true,
        hd2d: Bool = true,
        terrarium: Bool = true,
        hourOverride: Double? = nil,
        frameMeter: Bool = false
    ) {
        self.art = art
        self.grade = grade
        self.hd2d = hd2d
        self.terrarium = terrarium
        self.hourOverride = hourOverride
        self.frameMeter = frameMeter
    }

    /// Everything on: the world scene's default.
    public static let standard = WorldLook()

    /// The look before look-dev: the soft-lock art and nothing else.
    public static let legacy = WorldLook(art: .softLock, grade: false, hd2d: false, terrarium: false)
}

extension WorldArt {
    /// The suffix of the soft-lock bake's sprites (`cay-1--softlock`).
    static let softLockSuffix = "--softlock"

    /// The sprite key to draw for `name` in `art`: the soft-lock bake when
    /// the pipeline baked one, otherwise `name` itself.
    public static func key(_ name: String, art: WorldLook.ArtSet) -> String {
        switch art {
        case .lockLight:
            return name
        case .softLock:
            let alt = name + softLockSuffix
            return generated[alt] != nil ? alt : name
        }
    }
}
