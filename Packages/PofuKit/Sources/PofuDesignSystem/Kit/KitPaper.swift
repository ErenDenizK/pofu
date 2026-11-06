#if canImport(SwiftUI)
import SwiftUI

/// What a card is made of (UI v3 section 5): stitched paper for rewards
/// and info, linen for stats, wood for the game.
public enum PofuCardKind: Sendable {
    case stitched
    case linen
    case wood
}

/// A top edge that is not quite straight: a deckled paper edge. Fills
/// down to the bottom of its rect. Deterministic, so it never shimmers.
struct PofuDeckleShape: Shape {
    var amplitude: CGFloat = 1.6
    var period: CGFloat = 11

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + amplitude))
        var x = rect.minX
        var index: CGFloat = 0
        while x < rect.maxX {
            x = min(x + period * (0.8 + 0.4 * abs(sin(index * 1.7))), rect.maxX)
            let y = rect.minY + amplitude * (1 + sin(index * 2.3 + 0.6)) * 0.5
            path.addLine(to: CGPoint(x: x, y: y))
            index += 1
        }
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// Paper: the surface of sheets and cards. Day is cream paper with a
/// grain; night is lamplit paper (ink with a warm glow from above).
/// Increase Contrast gets flat fill and a solid edge.
public struct PofuPaperSurface: View {
    var cornerRadius: CGFloat
    var kind: PofuCardKind
    var stitched: Bool

    @Environment(\.pofuNight) private var night
    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorSchemeContrast) private var contrast

    public init(cornerRadius: CGFloat = PofuRadius.large, kind: PofuCardKind = .stitched) {
        self.cornerRadius = cornerRadius
        self.kind = kind
        self.stitched = kind == .stitched
    }

    public var body: some View {
        let resolver = PofuKitStyleResolver(night: night, scheme: scheme, contrast: contrast)
        let palette = resolver.palette
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        ZStack {
            if resolver.isHighContrast {
                shape.fill(kind == .wood ? palette.woodTop : palette.paperTop)
                shape.strokeBorder(palette.onPaper, lineWidth: 2)
            } else {
                PofuKitFace(art(palette), caps: EdgeInsets(top: cornerRadius, leading: cornerRadius, bottom: cornerRadius, trailing: cornerRadius)) {
                    drawn(shape, palette)
                }
            }
        }
        .clipShape(shape)
        .shadow(color: palette.edge.opacity(palette.isNight ? 0.5 : 0.12), radius: 10, y: 4)
    }

    private func art(_ palette: PofuKitPalette) -> PofuKitArt {
        switch kind {
        case .stitched: palette.isNight ? .sheetPaperNight : .cardStitched
        case .linen: .cardLinen
        case .wood: .plaqueBare
        }
    }

    private func colors(_ palette: PofuKitPalette) -> [Color] {
        switch kind {
        case .stitched: [palette.paperTop, palette.paperBottom]
        case .linen: [palette.linen, palette.linen.opacity(0.92)]
        case .wood: [palette.woodTop, palette.woodBottom]
        }
    }

    private func drawn(_ shape: RoundedRectangle, _ palette: PofuKitPalette) -> some View {
        ZStack {
            shape.fill(LinearGradient(colors: colors(palette), startPoint: .top, endPoint: .bottom))
            if palette.isNight && kind != .wood {
                // The lamp: warm light falling from the top of the paper.
                shape.fill(
                    RadialGradient(
                        colors: [palette.glow.opacity(0.2), palette.glow.opacity(0)],
                        center: .top, startRadius: 0, endRadius: 280
                    )
                )
            }
            PofuGrainOverlay(opacity: kind == .linen ? 0.1 : 0.06)
            shape.pofuInnerShadow(palette.edge.opacity(palette.isNight ? 0.4 : 0.1), width: 3, blur: 3, y: 1)
            shape.strokeBorder(palette.edge.opacity(palette.isNight ? 0.5 : 0.14), lineWidth: 1)
            if stitched {
                shape.inset(by: 7)
                    .stroke(palette.stitch.opacity(0.75), style: StrokeStyle(lineWidth: 1.2, lineCap: .round, dash: [5, 4]))
            }
        }
    }
}

/// The sheet's paper: paper at every detent, a deckled top edge, bleeding
/// under the home indicator.
public struct PofuPaperSheetBackground: View {
    @Environment(\.pofuNight) private var night
    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorSchemeContrast) private var contrast

    public init() {}

    public var body: some View {
        let resolver = PofuKitStyleResolver(night: night, scheme: scheme, contrast: contrast)
        let palette = resolver.palette
        ZStack(alignment: .top) {
            PofuKitFace(palette.isNight ? .sheetPaperNight : .sheetPaper) {
                PofuDeckleShape()
                    .fill(LinearGradient(colors: [palette.paperTop, palette.paperBottom], startPoint: .top, endPoint: .bottom))
                    .overlay {
                        if palette.isNight {
                            Rectangle()
                                .fill(RadialGradient(colors: [palette.glow.opacity(0.18), palette.glow.opacity(0)], center: .top, startRadius: 0, endRadius: 320))
                        }
                    }
                    .overlay { PofuGrainOverlay(opacity: 0.06) }
                    .clipShape(PofuDeckleShape())
            }
            if resolver.isHighContrast {
                Rectangle().fill(palette.onPaper).frame(height: 2)
            }
        }
        .ignoresSafeArea()
    }
}

extension View {
    /// Paper at every detent (UI v3 section 5): the sheet's background.
    public func pofuPaperSheet() -> some View {
        presentationBackground { PofuPaperSheetBackground() }
    }

    /// Puts the content on a kit card.
    public func pofuKitCard(_ kind: PofuCardKind = .stitched, padding: CGFloat = PofuSpacing.l) -> some View {
        self
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background { PofuPaperSurface(kind: kind) }
    }
}
#endif
