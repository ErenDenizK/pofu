import Foundation

/// The one asset-name hook per material. A file named `<rawValue>.png`
/// (3x pixels) in the package resources replaces the code-drawn face.
/// `tools/assets/integrate.py` bakes them (target `kit`): sheets cut by the
/// committed cells in `integration_map.json`, trimmed to the paint.
public enum PofuKitArt: String, CaseIterable, Sendable {
    case plaqueHoney = "ui-plaque-honey"
    case plaqueHoneyPressed = "ui-plaque-honey-pressed"
    case plaqueBare = "ui-plaque-bare"
    case plaqueCream = "ui-plaque-cream"
    case plaqueCreamPressed = "ui-plaque-cream-pressed"
    case sheetPaper = "ui-sheet-paper-v3"
    case sheetPaperNight = "ui-sheet-paper-v3-night"
    case cardStitched = "ui-card-stitched"
    case cardLinen = "ui-card-linen"
    case cardLinenNight = "ui-card-linen-night"
    case bubblePaper = "ui-bubble-paper"
    case bubblePaperNight = "ui-bubble-paper-night"
    /// The bubble's tail, pointing down (the middle cell of the tail sheet).
    case bubbleTail = "ui-bubble-tail"
    /// The night tail: a recolour of the day tail by the bubble's own
    /// day-to-night shift (no night tail was painted).
    case bubbleTailNight = "ui-bubble-tail-night"
    /// The speaker tab: the honey row of the ribbon sheet.
    case tabRibbon = "ui-tab-ribbon"
    /// The one round button: a clay disc under a duo glyph.
    case discClay = "ui-face-disc-v2"
    case discClayNight = "ui-face-disc-v2-night"
    case chipFelt = "ui-chip-felt"
    case chipFeltSelected = "ui-chip-felt-selected"
    case toastStrip = "ui-toast-strip"
    case grooveWood = "ui-groove-wood"
    /// The wax seal of a resisted reach (batch-61 `seals-and-stamps`).
    case sealResist = "seal-resist"

    /// The pixels per point the faces are baked at.
    public static let scale: Double = 3

    /// How the face stretches to its frame. The caps match the bake in
    /// `integration_map.json`; `KitArtTests` holds them to the files.
    public var slicing: PofuKitSlicing {
        switch self {
        case .plaqueHoney, .plaqueHoneyPressed, .plaqueCream, .plaqueCreamPressed:
            // The scalloped ends end at 0.57 of the height; the rest is flat wood.
            .ends(leading: 0.62, trailing: 0.62)
        case .tabRibbon:
            .ends(leading: 0.6, trailing: 0.6)
        case .bubblePaper, .bubblePaperNight:
            .nine(top: 22, leading: 22, bottom: 22, trailing: 22)
        case .cardLinen, .cardLinenNight:
            // The bottom cap holds the lip's soft shadow.
            .nine(top: 16, leading: 16, bottom: 18, trailing: 16)
        case .bubbleTail, .bubbleTailNight, .discClay, .discClayNight:
            .whole
        case .plaqueBare, .sheetPaper, .sheetPaperNight, .cardStitched, .chipFelt, .chipFeltSelected,
             .toastStrip, .grooveWood, .sealResist:
            .halfHeight
        }
    }

    /// The face drawn while this one is unpainted: a pressed plaque is its
    /// rest face, darkened in code (`ui-plaque-honey-pressed` was never
    /// painted). `nil`: the code-drawn face.
    public var standIn: PofuKitArt? {
        switch self {
        case .plaqueHoneyPressed: .plaqueHoney
        case .plaqueCreamPressed: .plaqueCream
        default: nil
        }
    }
}

/// How a painted face is stretched to its frame.
public enum PofuKitSlicing: Equatable, Sendable {
    /// Nine-slice with fixed caps, in points.
    case nine(top: Double, leading: Double, bottom: Double, trailing: Double)
    /// Three-slice that keeps its ends' shape at any height: the face is
    /// drawn at the frame's height and only its middle stretches. The caps
    /// are fractions of the height.
    case ends(leading: Double, trailing: Double)
    /// Drawn whole, scaled to the frame (a disc, a tail).
    case whole
    /// Caps of half the image's height on every side (the first hook's
    /// default, for faces not yet baked).
    case halfHeight
}
