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
    /// 2x pixels: a nine-slice panel.
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

    /// The pixels-per-point the file was baked at.
    var scale: Double { self == .panelPaper ? 2 : 3 }
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
    @ScaledMetric private var size: CGFloat

    public init(_ paint: PofuPaint, size: CGFloat = 28) {
        self.paint = paint
        _size = ScaledMetric(wrappedValue: size, relativeTo: .body)
    }

    public var body: some View {
        if let image = paint.image {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .accessibilityHidden(true)
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
            Capsule(style: .continuous).fill(PofuColor.accent)
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
            let cap = min(image.size.width, image.size.height) * 0.3
            Image(uiImage: image)
                .resizable(capInsets: EdgeInsets(top: cap, leading: cap, bottom: cap, trailing: cap), resizingMode: .stretch)
        } else {
            RoundedRectangle(cornerRadius: PofuRadius.large, style: .continuous)
                .fill(PofuColor.card)
        }
    }
}

extension View {
    /// An opaque, static sheet background. A sheet over the live island
    /// must not sample it (glass or material would re-blur every frame
    /// while the detent animates), so it paints one flat surface.
    public func pofuSheetBackground() -> some View {
        presentationBackground(PofuColor.sunken)
    }
}
#endif
