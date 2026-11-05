import Foundation

/// Every number of the sun shadows (light and shadow v2, §2 and §3), in
/// one place so they tune without touching the code that uses them.
public enum ShadowTuning {
    // MARK: Direction

    /// How much the ground foreshortens the shadow's depth component: the
    /// camera looks down at the lawn, so a shadow falling toward the
    /// viewer is half as long on screen as one falling sideways.
    public static let groundForeshortening = 0.5
    /// How far toward the camera the shadow always leans, against the
    /// sideways push of the sun's screen position (the sun sits behind
    /// the island). 0.4 is a noon shadow straight down the screen and a
    /// morning one about 35° off it.
    public static let towardCamera = 0.4

    // MARK: Length (× the object's height), by the sun's height on screen

    /// `(sunY, length)` pairs, low sunY = high sun. Noon (0.11) 0.35, late
    /// day (0.20) 0.9, dawn and golden hour (0.30) 1.8, and the sun on the
    /// horizon 2.4 (design §2: dawn 1.6…2.2, golden 1.4…2.4).
    public static let lengthBySunY: [(sunY: Double, length: Double)] = [
        (0.11, 0.35), (0.20, 0.90), (0.30, 1.80), (0.36, 2.40),
    ]

    // MARK: Opacity and softness (0 crisp … 1 very soft)

    public static let dayOpacity = 0.50
    public static let goldenOpacity = 0.52
    public static let dawnOpacity = 0.34
    public static let daySoftness = 0.25
    public static let goldenSoftness = 0.55
    public static let dawnSoftness = 0.85

    // MARK: Moon

    /// The faint moon shadow that replaces the sun's at night.
    public static let moonOpacity = 0.10
    public static let moonLength = 1.2
    public static let moonSoftness = 0.9
    /// A blue the night's shadow leans to.
    public static let moonTint = GradeRGB(0.10, 0.14, 0.30)

    // MARK: Hue

    /// The luminance a sun shadow's colour is darkened to. `cell.shadow` is
    /// a light hue (it is what the grade lifts the shade to); over green
    /// grass a light colour at a quarter opacity was invisible, so the
    /// shadow keeps the cell's hue (violet at golden, cool at dawn) at this
    /// low luminance.
    public static let tintLuminance = 0.14

    // MARK: Ambient occlusion pad

    public static let padOpacityDay = 0.38
    public static let padOpacityNight = 0.42

    // MARK: Shadows from night light sources

    /// A character's shadow from the strongest source in reach: opacity is
    /// this times the source's strength at the character (≤ 1), so it never
    /// exceeds 0.30.
    public static let sourceOpacity = 0.30
    /// The length (× height) away from a weak and from a full-strength
    /// source: a close, strong lamp throws the shorter shadow (design §2:
    /// 0.6…1.4).
    public static let sourceLengthWeak = 1.4
    public static let sourceLengthStrong = 0.6
    public static let sourceSoftness = 0.7
    /// Below this contribution a source does not cast; the faint moon
    /// shadow stays.
    public static let sourceMinimumStrength = 0.05

    // MARK: Bucketing (the bake rebuilds only when the key changes)

    /// Direction steps in degrees; about ten game minutes of sun.
    public static let angleStep = 3.0
    public static let lengthStep = 0.1
    public static let opacityStep = 0.02
    /// Tint channel steps (1/32).
    public static let tintSteps = 32.0

    // MARK: The bake

    /// Texels of the bake per world unit (the screen shows 7 to 8 device
    /// pixels per unit at Home, so this is about a fifth: the shadows are
    /// soft).
    public static let bakeScale = 1.5
    /// The lawn polygon's growth for clipping the bake, per axis: shadows
    /// may fall over the lip a little but never into the sky.
    public static let clipGrowX = 1.03
    public static let clipGrowY = 1.3
    /// The depth the bake sits at, as a world y on the plate (the middle
    /// lawn band).
    public static let layerY = 0.0
    /// Pofu's blob caster, in world units (he is the live companion view,
    /// no silhouette exists): the body's width and height.
    public static let pofuWidth = 36.0
    public static let pofuHeight = 44.0
}
