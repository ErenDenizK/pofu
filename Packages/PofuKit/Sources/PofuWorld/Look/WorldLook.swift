import Foundation

/// The world scene's look features, as flags (look-dev A, B). They
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
        /// The lock-light bake without its asset-harmony correction
        /// (`tools/assets/harmony.py`, look round 2), to compare; baked for
        /// the plate and two chain levels only.
        case unharmonized
        /// Look round 2's warm copper on the çaydanlık (its hue moved from
        /// 54 to 59), kept to compare with the colour script's rose copper
        /// lit by the ember (look round 3).
        case round2Copper
        /// The large plate's batch-03 version (v2), to compare with the
        /// shipped v3 (look round 4: the founder chooses).
        case plateV2

        /// The suffix of this set's sprites, `nil` for the default.
        var suffix: String? {
            switch self {
            case .lockLight: nil
            case .softLock: "--softlock"
            case .unharmonized: "--unharmonized"
            case .round2Copper: "--round2"
            case .plateV2: "--v2"
            }
        }
    }

    public var art: ArtSet
    /// The runtime color grade (`WorldGrade`) driven by `WorldLight`.
    public var grade: Bool
    /// Painted HD-2D lite: bloom, light shafts, ambient particles and the
    /// stronger tilt-shift. The vignette belongs to the grade.
    public var hd2d: Bool
    /// Depth in motion: parallax and depth of field that follow the
    /// camera while it moves (`DepthMotion`); part of HD-2D.
    public var depthMotion: Bool
    /// A fixed local hour (screenshots); `nil` follows the world's clock.
    public var hourOverride: Double?
    /// A fixed grade instead of the light's (screenshots: before and
    /// after a grade change); `nil` follows the hour and Pofu's state.
    public var gradeOverride: WorldGrade?
    /// A fixed sky (screenshots: rain, mist, a rainbow); `nil` follows the
    /// seeded weather of the date.
    public var weatherOverride: WeatherConditions?
    /// The frame-time counter in a corner (debug).
    public var frameMeter: Bool
    /// The feel numbers the tuning lab panel tunes live (look round 4).
    public var tuning: WorldTuning = .standard
    /// The painted night overlays of practical lights (tea-stall-1-lit's flame);
    /// off only to compare.
    public var litOverlays = true
    /// Debug (screenshots): the baked shadow layer alone, full opacity,
    /// magenta, to prove where it lands.
    public var shadowDebug = false
    /// Depth-map depth of field (on by default) and normal-lit art (off by
    /// default), switched in Rehearsal mode's tuning lab panel. Whole-layer blur
    /// remains the fallback where shaders are unavailable.
    public var spike: GraphicsSpike = .standard
    /// At night and dusk the practicals light Pofu, the residents and the
    /// key props through their baked normals (look pipeline v2); off only
    /// to compare.
    public var nightRelight = true
    /// The painted home plate where one exists for the state (ADR-0022); off
    /// only for the sprite island's own screenshots and to compare.
    public var homePlates = true

    /// A screenshot of an island at its stop: a fixed hour under a clear
    /// sky. The seeded forecast of the fixtures' date is overcast, whose
    /// grade (contrast 0.8, the rain LUT at 0.6) lays a light veil over the
    /// island; the reference look keeps haze on the backdrop and the island
    /// at full value (ADR-0021), so island shots pin the weather.
    public static func islandStop(hour: Double) -> WorldLook {
        var look = WorldLook(hourOverride: hour)
        look.weatherOverride = .clear
        return look
    }

    public init(
        art: ArtSet = .lockLight,
        grade: Bool = true,
        hd2d: Bool = true,
        depthMotion: Bool = true,
        hourOverride: Double? = nil,
        gradeOverride: WorldGrade? = nil,
        frameMeter: Bool = false
    ) {
        self.art = art
        self.grade = grade
        self.hd2d = hd2d
        self.depthMotion = depthMotion
        self.hourOverride = hourOverride
        self.gradeOverride = gradeOverride
        self.frameMeter = frameMeter
    }

    /// Everything on: the world scene's default.
    public static let standard = WorldLook()

    /// The look before look-dev: the soft-lock art and nothing else.
    public static let legacy = WorldLook(art: .softLock, grade: false, hd2d: false, depthMotion: false)
}

extension WorldArt {
    /// The sprite key to draw for `name` in `art`: the set's own bake when
    /// the pipeline baked one (`tea-stall-1--softlock`), otherwise `name` itself.
    public static func key(_ name: String, art: WorldLook.ArtSet) -> String {
        guard let suffix = art.suffix else { return name }
        let alt = name + suffix
        return generated[alt] != nil ? alt : name
    }
}
