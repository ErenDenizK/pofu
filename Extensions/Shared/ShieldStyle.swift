import PofuCore
import UIKit

// Shared by the shield configuration extension and the app (Rehearsal
// mode's shield replica), so both draw the shield in the same colors with
// the same icon. Kept out of PofuKit because it is UIKit and only these
// two targets need it.

/// The sky the shield is painted from (experience v1 section 3.4): four
/// solid palettes taken from the colour script's sky, the lesson of Tide
/// Guide. There is never a blur: a blur would show the feed the person
/// reached for, which is the temptation itself.
enum ShieldSky: String, CaseIterable {
    case dawn, day, dusk, night

    /// The sky at `date`, by the colour script's schedule: night until
    /// 05:30, dawn to 07:45, day to 17:30, dusk (golden hour included) to
    /// 20:30, then night.
    init(date: Date, calendar: Calendar = .autoupdatingCurrent) {
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        let minute = (parts.hour ?? 12) * 60 + (parts.minute ?? 0)
        switch minute {
        case 330..<465: self = .dawn
        case 465..<1050: self = .day
        case 1050..<1230: self = .dusk
        default: self = .night
        }
    }
}

/// The shield's colors per palette (gate v2, section 5.2, and experience v1
/// section 3.4). The copy's palette says bedtime or the breath; otherwise
/// the sky of the hour decides. In the system's dark appearance dawn and
/// day step back to the night palette. The golden hour (dusk) is warm
/// apricot; only night is indigo. Buttons are honey by day and amber at
/// night, never the system purple.
struct ShieldColors {
    let background: UIColor
    let title: UIColor
    let subtitle: UIColor
    let primaryFill: UIColor
    let primaryLabel: UIColor
    let secondaryLabel: UIColor

    init(palette: ShieldPalette, sky: ShieldSky = ShieldSky(date: Date())) {
        let cream = Self.hex(0xFFF6EC)
        let night = Self.hex(0x1E1A3C)
        let cocoa = Self.hex(0x4A3326)
        let honey = Self.hex(0xF6C453)
        let amber = Self.hex(0xE9A93B)
        let amberInk = Self.hex(0x2A1A0A)
        let ink900 = Self.hex(0x2A1F2D)
        let ink600 = Self.hex(0x66555F)
        let mist300 = Self.hex(0xB8A8B1)
        let umber = Self.hex(0x8A4B12)
        let amber300 = Self.hex(0xFFC766)
        switch palette {
        case .night:
            self = Self.night(cream: cream, night: night, mist300: mist300, amber: amber, amberInk: amberInk)
        case .breath:
            background = Self.dynamic(light: Self.hex(0xF1ECFF), dark: Self.hex(0x1E1828))
            title = Self.dynamic(light: ink900, dark: cream)
            subtitle = Self.dynamic(light: ink600, dark: mist300)
            primaryFill = Self.dynamic(light: honey, dark: amber)
            primaryLabel = Self.dynamic(light: cocoa, dark: amberInk)
            secondaryLabel = Self.dynamic(light: umber, dark: amber300)
        case .day:
            switch sky {
            case .night:
                self = Self.night(cream: cream, night: night, mist300: mist300, amber: amber, amberInk: amberInk)
            case .dusk:
                // The golden hour: a warm apricot, ink text, honey button.
                background = Self.dynamic(light: Self.hex(0xFFE0C0), dark: night)
                title = Self.dynamic(light: ink900, dark: cream)
                subtitle = Self.dynamic(light: Self.hex(0x5A4750), dark: mist300)
                primaryFill = Self.dynamic(light: honey, dark: amber)
                primaryLabel = Self.dynamic(light: cocoa, dark: amberInk)
                secondaryLabel = Self.dynamic(light: Self.hex(0x9C3F1B), dark: amber300)
            case .dawn, .day:
                // Dawn peach, or the day's cream-sky.
                let light = sky == .dawn ? Self.hex(0xFBE4D8) : Self.hex(0xFFF1DE)
                let dark = sky == .dawn ? Self.hex(0x2B1F2C) : night
                background = Self.dynamic(light: light, dark: dark)
                title = Self.dynamic(light: ink900, dark: cream)
                subtitle = Self.dynamic(light: ink600, dark: mist300)
                primaryFill = Self.dynamic(light: honey, dark: amber)
                primaryLabel = Self.dynamic(light: cocoa, dark: amberInk)
                secondaryLabel = Self.dynamic(light: sky == .dawn ? Self.hex(0xA8431F) : umber, dark: amber300)
            }
        }
    }

    private init(background: UIColor, title: UIColor, subtitle: UIColor, primaryFill: UIColor, primaryLabel: UIColor, secondaryLabel: UIColor) {
        self.background = background
        self.title = title
        self.subtitle = subtitle
        self.primaryFill = primaryFill
        self.primaryLabel = primaryLabel
        self.secondaryLabel = secondaryLabel
    }

    private static func night(cream: UIColor, night: UIColor, mist300: UIColor, amber: UIColor, amberInk: UIColor) -> ShieldColors {
        ShieldColors(
            background: night,
            title: cream.withAlphaComponent(0.92),
            subtitle: mist300,
            primaryFill: amber,
            primaryLabel: amberInk,
            secondaryLabel: mist300
        )
    }

    /// Whether this palette is dark whatever the system appearance is.
    static func isDark(palette: ShieldPalette, sky: ShieldSky) -> Bool {
        palette == .night || (palette == .day && sky == .night)
    }

    private static func hex(_ value: UInt32) -> UIColor {
        UIColor(
            red: CGFloat((value >> 16) & 0xFF) / 255,
            green: CGFloat((value >> 8) & 0xFF) / 255,
            blue: CGFloat(value & 0xFF) / 255,
            alpha: 1
        )
    }

    private static func dynamic(light: UIColor, dark: UIColor) -> UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        }
    }
}

/// Pofu at his door, for the shield (experience v1 section 3.4): 180 px,
/// one of three moods, his cheeks never puffed and never a guilty look.
enum ShieldDoorMood: String {
    case calm, proud, sleepy

    init(icon: ShieldIcon) {
        switch icon {
        case .proud, .relieved, .excited: self = .proud
        case .breathe, .unwell: self = .sleepy
        case .curious, .jealous: self = .calm
        }
    }

    /// The Codex plate's name in the bundle: `shield-pofu-door-calm.png`
    /// and its siblings.
    var assetName: String { "shield-pofu-door-\(rawValue)" }
}

/// Pofu's face for the shield, small: the shield draws its icon at about
/// 60 points, and the extension has only a few megabytes to work with.
///
/// The icon is `shield-pofu-door-<mood>.png`, the painted plate cut from the
/// Codex sheet (`tools/assets/integrate.py`). Should a bundle lack it, a
/// code-drawn door with the portrait in front of it stands in. Older mood images
/// (`pofu-proud.png`, ...) and the base portrait remain the fallbacks, and
/// "unwell" is the base desaturated (never a guilt picture).
enum ShieldIconImage {
    private static let side: CGFloat = 180

    /// - Parameter locate: Finds a PNG by resource name: the main bundle in
    ///   the extension; the app adds PofuCompanion's bundle, where the
    ///   portrait lives.
    static func image(for icon: ShieldIcon, locate: (String) -> URL? = mainBundlePNG) -> UIImage? {
        let mood = ShieldDoorMood(icon: icon)
        if let plate = load(mood.assetName, locate: locate) {
            return plate
        }
        let portrait = load(icon.rawValue, locate: locate) ?? load("pofu-hamster", locate: locate)
        guard let portrait else { return nil }
        let face = icon == .unwell && load(icon.rawValue, locate: locate) == nil ? desaturated(portrait) : portrait
        return placeholderDoor(mood: mood, portrait: face)
    }

    static func mainBundlePNG(named name: String) -> URL? {
        Bundle.main.url(forResource: name, withExtension: "png")
    }

    private static func load(_ name: String, locate: (String) -> URL?) -> UIImage? {
        guard
            let url = locate(name),
            let image = UIImage(contentsOfFile: url.path)
        else { return nil }
        let scale = min(side / max(image.size.width, 1), side / max(image.size.height, 1), 1)
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        return image.preparingThumbnail(of: size) ?? image
    }

    /// A round-topped door in warm wood with Pofu standing in front of it:
    /// the stand-in for `shield-pofu-door-<mood>`. Sleepy adds a pair of
    /// soft z's, proud a small star; calm has neither.
    private static func placeholderDoor(mood: ShieldDoorMood, portrait: UIImage) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = false
        let canvas = CGSize(width: side, height: side)
        return UIGraphicsImageRenderer(size: canvas, format: format).image { _ in
            // The door: a round-topped slab with a frame and a knob.
            let frame = CGRect(x: 30, y: 8, width: 120, height: 164)
            let doorPath = UIBezierPath(roundedRect: frame, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 60, height: 60))
            UIColor(red: 0.773, green: 0.545, blue: 0.369, alpha: 1).setFill()
            doorPath.fill()
            let inner = frame.insetBy(dx: 9, dy: 9)
            let innerPath = UIBezierPath(roundedRect: inner, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 51, height: 51))
            UIColor(red: 0.541, green: 0.353, blue: 0.235, alpha: 1).setFill()
            innerPath.fill()
            UIColor(red: 0.980, green: 0.839, blue: 0.451, alpha: 1).setFill()
            UIBezierPath(ovalIn: CGRect(x: inner.maxX - 24, y: inner.midY + 14, width: 11, height: 11)).fill()
            // The doorstep.
            UIColor(red: 0.427, green: 0.322, blue: 0.282, alpha: 0.35).setFill()
            UIBezierPath(ovalIn: CGRect(x: 22, y: 160, width: 136, height: 14)).fill()
            // Pofu in front, standing on the step.
            let height: CGFloat = 112
            let width = portrait.size.width / max(portrait.size.height, 1) * height
            portrait.draw(in: CGRect(x: (side - width) / 2, y: 166 - height, width: width, height: height))
            switch mood {
            case .sleepy:
                let font = UIFont.systemFont(ofSize: 22, weight: .heavy)
                let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: UIColor(white: 1, alpha: 0.9)]
                ("z" as NSString).draw(at: CGPoint(x: 128, y: 40), withAttributes: attributes)
                ("z" as NSString).draw(at: CGPoint(x: 142, y: 22), withAttributes: [.font: UIFont.systemFont(ofSize: 15, weight: .heavy), .foregroundColor: UIColor(white: 1, alpha: 0.75)])
            case .proud:
                let star = UIBezierPath()
                let centre = CGPoint(x: 138, y: 40)
                for point in 0..<10 {
                    let radius: CGFloat = point.isMultiple(of: 2) ? 12 : 5
                    let angle = CGFloat(point) * .pi / 5 - .pi / 2
                    let vertex = CGPoint(x: centre.x + cos(angle) * radius, y: centre.y + sin(angle) * radius)
                    if point == 0 {
                        star.move(to: vertex)
                    } else {
                        star.addLine(to: vertex)
                    }
                }
                star.close()
                UIColor(red: 0.980, green: 0.839, blue: 0.451, alpha: 1).setFill()
                star.fill()
            case .calm:
                break
            }
        }
    }

    /// The image at about a third of its color, keeping its alpha.
    private static func desaturated(_ image: UIImage) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = image.scale
        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: image.size)
            image.draw(in: rect)
            UIColor(white: 0.5, alpha: 0.65).setFill()
            context.fill(rect, blendMode: .saturation)
            image.draw(in: rect, blendMode: .destinationIn, alpha: 1)
        }
    }
}
