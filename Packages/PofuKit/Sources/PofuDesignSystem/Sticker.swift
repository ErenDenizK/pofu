import Foundation

/// The sticker set: small full-body poses of Pofu and the residents for
/// reactions, letters and summaries. Production art is batch 42
/// (`tools/imagegen/manifest/batch-42-stickers.yaml`), baked into this
/// package's resources as `sticker-<id>.png`. Until a file lands, every
/// sticker draws an SF Symbol stand-in, so a swap is only the file: no code
/// changes. World objects stay painted, chrome stays native (ADR-0018);
/// stickers are the painted guests inside native cards.
public enum Sticker: String, CaseIterable, Sendable {
    case pofuHappy = "sticker-pofu-happy"
    case pofuSleepy = "sticker-pofu-sleepy"
    case pofuSurprised = "sticker-pofu-surprised"
    case pofuProud = "sticker-pofu-proud"
    case pofuWaving = "sticker-pofu-waving"
    case pofuTea = "sticker-pofu-tea"
    case mochiHappy = "sticker-mochi-happy"
    case mochiThinking = "sticker-mochi-thinking"
    case mochiSulky = "sticker-mochi-sulky"
    case simitHappy = "sticker-simit-happy"
    case findikHappy = "sticker-findik-happy"
    case goatIndignant = "sticker-goat-indignant"
    case duoTea = "sticker-duo-tea"

    /// The asset's file name (without extension) in the bundle.
    public var assetName: String { rawValue }

    /// The stand-in drawn until the art exists.
    public var fallbackSymbol: String {
        switch self {
        case .pofuHappy, .mochiHappy, .simitHappy, .findikHappy: "face.smiling"
        case .pofuSleepy: "moon.zzz"
        case .pofuSurprised: "exclamationmark.circle"
        case .pofuProud, .goatIndignant: "star.circle"
        case .pofuWaving: "hand.wave"
        case .pofuTea, .duoTea: "cup.and.saucer"
        case .mochiThinking: "ellipsis.bubble"
        case .mochiSulky: "cloud"
        }
    }

    /// Spoken by VoiceOver when a sticker stands alone; decorative otherwise.
    public var accessibilityDescription: String {
        switch self {
        case .pofuHappy: "Pofu, happy"
        case .pofuSleepy: "Pofu, sleepy"
        case .pofuSurprised: "Pofu, surprised"
        case .pofuProud: "Pofu, proud"
        case .pofuWaving: "Pofu, waving"
        case .pofuTea: "Pofu with tea"
        case .mochiHappy: "Mochi, happy"
        case .mochiThinking: "Mochi, thinking"
        case .mochiSulky: "Mochi, sulky"
        case .simitHappy: "Simit, happy"
        case .findikHappy: "Fındık, happy"
        case .goatIndignant: "The goat, indignant"
        case .duoTea: "Pofu and Mochi with tea"
        }
    }

    /// A resident's reaction sticker, by the resident's id; `nil` for a
    /// resident without one yet (the caller shows no sticker).
    public static func reaction(forResident id: String) -> Sticker? {
        switch id {
        case "mochi": .mochiHappy
        case "simit": .simitHappy
        case "findik": .findikHappy
        case "goat": .goatIndignant
        default: nil
        }
    }

    /// The one sticker for the day's mood on the Today page. Never a
    /// reproach: a day with reaches and no skips is a wave, not a frown.
    public static func dayMood(skipped: Int, reaches: Int) -> Sticker {
        guard reaches > 0 else { return .pofuTea }
        let ratio = Double(skipped) / Double(reaches)
        if ratio >= 0.5 { return .pofuProud }
        if skipped > 0 { return .pofuHappy }
        return .pofuWaving
    }
}

#if canImport(SwiftUI)
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// A sticker at a Dynamic-Type-scaled size: the painted file when the
/// bundle has it, otherwise its SF Symbol. Decorative unless `isLabelled`.
public struct StickerView: View {
    let sticker: Sticker
    let base: CGFloat
    let isLabelled: Bool
    @ScaledMetric private var side: CGFloat

    public init(_ sticker: Sticker, size: CGFloat = 56, isLabelled: Bool = false) {
        self.sticker = sticker
        base = size
        self.isLabelled = isLabelled
        _side = ScaledMetric(wrappedValue: size, relativeTo: .body)
    }

    public var body: some View {
        face
            .frame(width: side, height: side)
            .accessibilityHidden(!isLabelled)
            .accessibilityLabel(Text(verbatim: sticker.accessibilityDescription))
    }

    @ViewBuilder
    private var face: some View {
        #if canImport(UIKit)
        if let url = Bundle.module.url(forResource: sticker.assetName, withExtension: "png"),
           let image = UIImage(contentsOfFile: url.path) {
            Image(uiImage: image).resizable().scaledToFit()
        } else {
            stand
        }
        #else
        stand
        #endif
    }

    private var stand: some View {
        Image(systemName: sticker.fallbackSymbol)
            .resizable()
            .scaledToFit()
            .padding(side * 0.14)
            .foregroundStyle(PofuKitPalette.day.ink)
            .background(Circle().fill(PofuKitPalette.day.honey.opacity(0.45)))
    }
}
#endif
