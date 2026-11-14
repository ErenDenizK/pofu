#if os(iOS)
import PofuCompanion
import PofuCore
import PofuDesignSystem
import SwiftUI

/// The one control (experience v1 §1.2): a 52 pt clay disc, bottom
/// trailing, at the same spot in every framing. Its glyph shows where a tap
/// goes next (an island outline at Close, waves at the Island, Pofu's face
/// on the Archipelago) and morphs as a pinch crosses halfway. A tap goes
/// there; a long press opens a native menu: Pofu, each arrived island, the
/// Archipelago.
struct PlaceControl: View {
    let model: IslandSceneModel
    /// The islands the player has arrived at, in story order.
    let islands: [IslandID]

    /// The control's side, in points.
    static let size: CGFloat = 52

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.pofuNight) private var night
    @Environment(\.pofuPaintedChrome) private var paintsChrome
    @State private var identity = UUID()

    var body: some View {
        let stop = PlaceStop(framing: model.projectedFraming)
        let glyph = stop.controlGlyph
        Menu {
            Button {
                model.go(to: .home)
            } label: {
                Text(verbatim: WorldStrings.placePofu)
            }
            ForEach(islands, id: \.self) { island in
                Button {
                    model.fly(to: island)
                } label: {
                    Text(verbatim: WorldStrings.islandName(island))
                }
            }
            Button {
                model.go(to: .map)
            } label: {
                Text(verbatim: WorldStrings.placeArchipelago)
            }
        } label: {
            ZStack {
                PlaceGlyphView(glyph: .island).opacity(glyph == .island ? 1 : 0)
                PlaceGlyphView(glyph: .archipelago).opacity(glyph == .archipelago ? 1 : 0)
                PlaceGlyphView(glyph: .pofu).opacity(glyph == .pofu ? 1 : 0)
            }
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: glyph)
            .foregroundStyle(paintsChrome && PofuKitArt.discClay.isPainted ? (night == true ? PofuKitPalette.night : PofuKitPalette.day).onPaper : PofuColor.textPrimary)
            .frame(width: Self.size, height: Self.size)
            .modifier(PlaceControlFace(painted: paintsChrome))
            .contentShape(Circle())
        } primaryAction: {
            model.placeControlTapped()
        }
        .buttonStyle(.plain)
        .frame(width: Self.size, height: Self.size)
        .accessibilityLabel(Text(verbatim: stop == .archipelago ? WorldStrings.placeHome : WorldStrings.placeOut))
        .accessibilityHint(Text(verbatim: WorldStrings.placeMenu))
        .accessibilityIdentifier("place-control")
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frame in
            model.reportPlaceControl(id: identity, frame: frame)
        }
        .onDisappear { model.reportPlaceControl(id: identity, frame: nil) }
    }
}

/// The control's face: the one round button, a clay disc in the crafted skin (asset
/// system v1 section 2.3); glass in the glass skin, or while the disc is
/// unpainted.
private struct PlaceControlFace: ViewModifier {
    /// The crafted skin paints the disc; the glass skin keeps its glass.
    let painted: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if painted, PofuKitArt.discClay.isPainted {
            content.background { PofuClayDisc() }
        } else {
            content.glassEffect(.regular.interactive(), in: Circle())
        }
    }
}

/// One glyph of the place control, in the control's 52 pt circle.
private struct PlaceGlyphView: View {
    let glyph: PlaceGlyph

    var body: some View {
        switch glyph {
        case .island:
            if PofuPaint.duoIsland.isAvailable {
                PofuPaintedIcon(.duoIsland, size: 34, scales: false)
            } else {
                IslandSilhouette().frame(width: 30, height: 26)
            }
        case .archipelago:
            if PofuPaint.duoMap.isAvailable {
                PofuPaintedIcon(.duoMap, size: 34, scales: false)
            } else {
                ArchipelagoGlyph().frame(width: 30, height: 26)
            }
        case .pofu:
            // Pofu's face: home.
            if PofuPaint.duoHome.isAvailable {
                PofuPaintedIcon(.duoHome, size: 34, scales: false)
            } else {
                PofuFaceGlyph()
            }
        }
    }
}

/// Pofu's face from the companion's portrait (the head of the bundled
/// hamster), 34 pt: the glyph for "home". It is the bitmap itself, not a
/// painted icon, so it never falls back to a blank disc.
private struct PofuFaceGlyph: View {
    /// The face region of the 522 × 496 portrait: the ears, the eyes and the
    /// cheeks, square.
    private static let face: UIImage? = {
        guard let portrait = CompanionArt.placeholder?.base,
              let crop = portrait.cropping(to: CGRect(x: 66, y: 36, width: 400, height: 400)) else { return nil }
        return UIImage(cgImage: crop)
    }()

    var body: some View {
        if let face = Self.face {
            Image(uiImage: face)
                .resizable()
                .scaledToFit()
                .frame(width: 34, height: 34)
                .accessibilityHidden(true)
        } else {
            Circle().fill(.foreground).frame(width: 22, height: 22)
        }
    }
}

/// A small island in silhouette: a lawn with a tuft over a tapering earth
/// underside.
private struct IslandSilhouette: View {
    var body: some View {
        Canvas { context, size in
            let w = size.width, h = size.height
            var earth = Path()
            earth.move(to: CGPoint(x: w * 0.06, y: h * 0.52))
            earth.addQuadCurve(to: CGPoint(x: w * 0.5, y: h), control: CGPoint(x: w * 0.12, y: h * 0.95))
            earth.addQuadCurve(to: CGPoint(x: w * 0.94, y: h * 0.52), control: CGPoint(x: w * 0.88, y: h * 0.95))
            earth.closeSubpath()
            context.fill(earth, with: .foreground)
            let lawn = Path(ellipseIn: CGRect(x: 0, y: h * 0.38, width: w, height: h * 0.26))
            context.fill(lawn, with: .foreground)
            // The tuft: three blades rising from the lawn.
            var tuft = Path()
            for (dx, lift) in [(-0.07, 0.24), (0.0, 0.34), (0.07, 0.22)] {
                tuft.move(to: CGPoint(x: w * (0.5 + dx * 0.4), y: h * 0.44))
                tuft.addQuadCurve(
                    to: CGPoint(x: w * (0.5 + dx * 1.6), y: h * (0.44 - lift)),
                    control: CGPoint(x: w * (0.5 + dx * 0.4), y: h * (0.44 - lift * 0.6))
                )
            }
            context.stroke(tuft, with: .foreground, style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
        }
    }
}

/// Three islands as dots over two waves.
private struct ArchipelagoGlyph: View {
    var body: some View {
        Canvas { context, size in
            let w = size.width, h = size.height
            for (x, y, r) in [(0.22, 0.3, 4.2), (0.56, 0.18, 5.4), (0.84, 0.36, 3.6)] {
                context.fill(
                    Path(ellipseIn: CGRect(x: w * x - r, y: h * y - r, width: r * 2, height: r * 2)),
                    with: .foreground
                )
            }
            for (y, inset) in [(0.66, 0.0), (0.9, 0.16)] {
                var wave = Path()
                let x0 = w * inset, x1 = w * (1 - inset), mid = (x0 + x1) / 2
                wave.move(to: CGPoint(x: x0, y: h * y))
                wave.addCurve(to: CGPoint(x: mid, y: h * y), control1: CGPoint(x: x0 + w * 0.08, y: h * (y - 0.14)), control2: CGPoint(x: mid - w * 0.12, y: h * (y + 0.14)))
                wave.addCurve(to: CGPoint(x: x1, y: h * y), control1: CGPoint(x: mid + w * 0.12, y: h * (y - 0.14)), control2: CGPoint(x: x1 - w * 0.08, y: h * (y + 0.14)))
                context.stroke(wave, with: .foreground, style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
            }
        }
    }
}
#endif
