import Foundation

/// The painted menu art: approved masters baked into this package's
/// resources by `tools/assets/integrate.py` (target `ui`, files named
/// `paint-*.png`, 3x pixels unless noted). Controls stay native; these
/// are the painted pieces that sit on them (ADR-0018).
public enum PofuPaint: String, CaseIterable, Sendable {
    case jarFull = "paint-jar-full"
    case lanternOn = "paint-lantern-on"
    case potBloom = "paint-pot-bloom"
    case potBud = "paint-pot-bud"
    case facePrimary = "paint-face-primary"
    case faceSecondary = "paint-face-secondary"
    case faceDisc = "paint-face-disc"
    case tagPaper = "paint-tag-paper"
    /// A nine-slice panel, 120 pt: its caps are a quarter of its size.
    case panelPaper = "paint-panel-paper"
    case iconSeed = "paint-icon-seed"
    case iconCalm = "paint-icon-calm"
    case iconIsland = "paint-icon-island"
    case iconFriend = "paint-icon-friend"
    case iconMoodContent = "paint-icon-mood-content"
    case iconSkip = "paint-icon-skip"
    case iconRound = "paint-icon-round"
    case iconBreath = "paint-icon-breath"
    case iconRumour = "paint-icon-rumour"
    case iconDecor = "paint-icon-decor"
    case iconPlus = "paint-icon-plus"
    case iconTea = "paint-icon-tea"
    /// The two-tone icon set (batch 46, `icons-duo`): Pofu's face is home.
    case duoHome = "paint-duo-home"
    case duoIsland = "paint-duo-island"
    case duoMap = "paint-duo-map"
    case duoSettings = "paint-duo-settings"
    case duoClose = "paint-duo-close"
    case duoAdd = "paint-duo-add"
    case duoLetter = "paint-duo-letter"
    case duoShield = "paint-duo-shield"
    case duoGift = "paint-duo-gift"

    /// The pixels-per-point the file was baked at.
    var scale: Double { 3 }
}

#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI
import UIKit

extension PofuPaint {
    @MainActor private static let cache = NSCache<NSString, UIImage>()

    /// The painted image, decoded once; `nil` if the bundle lacks it (the
    /// callers keep a native fallback).
    @MainActor
    public var image: UIImage? {
        let key = rawValue as NSString
        if let hit = Self.cache.object(forKey: key) { return hit }
        guard let url = Bundle.module.url(forResource: rawValue, withExtension: "png"),
              let data = try? Data(contentsOf: url),
              let image = UIImage(data: data, scale: scale)
        else { return nil }
        Self.cache.setObject(image, forKey: key)
        return image
    }

    @MainActor
    public var isAvailable: Bool { image != nil }
}

/// A painted icon at a Dynamic-Type-scaled size. Decorative by default:
/// the row it sits in carries the label.
public struct PofuPaintedIcon: View {
    let paint: PofuPaint
    let base: CGFloat
    let scales: Bool
    @ScaledMetric private var scaled: CGFloat

    /// `scales: false` when the caller's size already follows Dynamic Type.
    public init(_ paint: PofuPaint, size: CGFloat = 28, scales: Bool = true) {
        self.paint = paint
        base = size
        self.scales = scales
        _scaled = ScaledMetric(wrappedValue: size, relativeTo: .body)
    }

    public var body: some View {
        if let image = paint.image {
            let side = scales ? scaled : base
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: side, height: side)
                .accessibilityHidden(true)
        }
    }
}

/// A two-tone icon where an SF Symbol stood for the same meaning: the painted
/// icon when the bundle has it, else the symbol. The control or row that
/// holds it carries the accessibility label, so it is hidden here.
public struct PofuDuoIcon: View {
    let paint: PofuPaint
    let size: CGFloat
    let fallback: String

    public init(_ paint: PofuPaint, size: CGFloat = 22, fallback: String) {
        self.paint = paint
        self.size = size
        self.fallback = fallback
    }

    public var body: some View {
        if paint.isAvailable {
            PofuPaintedIcon(paint, size: size, scales: false)
        } else {
            Image(systemName: fallback)
        }
    }
}

/// The painted primary face behind an action's label: a capsule stretched
/// by its cap insets so the ends keep their painted roundness.
public struct PofuPaintedFace: View {
    let paint: PofuPaint

    public init(_ paint: PofuPaint = .facePrimary) {
        self.paint = paint
    }

    public var body: some View {
        if let image = paint.image {
            let cap = image.size.height / 2
            Image(uiImage: image)
                .resizable(capInsets: EdgeInsets(top: 0, leading: cap, bottom: 0, trailing: cap), resizingMode: .stretch)
        } else {
            Capsule(style: .continuous).fill(paint == .facePrimary ? PofuColor.accent : PofuColor.card)
        }
    }
}

/// A cream paper panel (a nine-slice) that a sheet's header or a card sits
/// on. In dark mode it steps back to the card colour: the paper is light.
public struct PofuPaperPanel: View {
    @Environment(\.colorScheme) private var scheme

    public init() {}

    public var body: some View {
        if scheme == .light, let image = PofuPaint.panelPaper.image {
            let cap = min(image.size.width, image.size.height) * 0.25
            Image(uiImage: image)
                .resizable(capInsets: EdgeInsets(top: cap, leading: cap, bottom: cap, trailing: cap), resizingMode: .stretch)
        } else {
            RoundedRectangle(cornerRadius: PofuRadius.large, style: .continuous)
                .fill(PofuColor.card)
        }
    }
}

/// The quieter painted action: the cream pill with ink text.
public struct PofuPaintedSecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PofuFont.headline)
            .multilineTextAlignment(.center)
            .foregroundStyle(Color(red: 0.24, green: 0.18, blue: 0.14))
            .padding(.horizontal, PofuSpacing.xl)
            .frame(maxWidth: .infinity, minHeight: PofuSize.buttonHeight)
            .background {
                PofuPaintedFace(.faceSecondary)
                    .brightness(configuration.isPressed ? -0.08 : 0)
            }
            .opacity(isEnabled ? 1 : 0.45)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .animation(PofuMotion.respecting(reduceMotion, PofuMotion.squish), value: configuration.isPressed)
            .contentShape(Capsule(style: .continuous))
    }
}
#endif
