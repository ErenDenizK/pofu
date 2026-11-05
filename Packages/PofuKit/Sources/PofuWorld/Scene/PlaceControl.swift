#if os(iOS)
import PofuCore
import PofuDesignSystem
import SwiftUI

/// The one control (experience v1 §1.2): a 52 pt glass circle, bottom
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
            .foregroundStyle(PofuColor.textPrimary)
            .frame(width: Self.size, height: Self.size)
            .glassEffect(.regular.interactive(), in: Circle())
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

/// One glyph of the place control, drawn as vector shapes in the control's
/// 52 pt circle.
private struct PlaceGlyphView: View {
    let glyph: PlaceGlyph

    var body: some View {
        switch glyph {
        case .island:
            IslandOutline()
                .stroke(style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
                .frame(width: 26, height: 18)
        case .archipelago:
            ArchipelagoDots()
                .frame(width: 26, height: 22)
        case .pofu:
            PofuFace()
                .frame(width: 26, height: 24)
        }
    }
}

/// An island in outline: a lawn mound over a rounded underside.
private struct IslandOutline: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let lawnY = rect.minY + rect.height * 0.42
        path.move(to: CGPoint(x: rect.minX, y: lawnY))
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.minY), control: CGPoint(x: rect.minX + rect.width * 0.18, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: lawnY), control: CGPoint(x: rect.maxX - rect.width * 0.18, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.maxY), control: CGPoint(x: rect.maxX - rect.width * 0.08, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: lawnY), control: CGPoint(x: rect.minX + rect.width * 0.08, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// Three islands as dots over two waves.
private struct ArchipelagoDots: View {
    var body: some View {
        ZStack {
            Circle().frame(width: 7, height: 7).offset(x: -8, y: -6)
            Circle().frame(width: 9, height: 9).offset(x: 2, y: -8)
            Circle().frame(width: 6, height: 6).offset(x: 9, y: -3)
            Wave().stroke(style: StrokeStyle(lineWidth: 2, lineCap: .round)).frame(width: 24, height: 5).offset(y: 5)
            Wave().stroke(style: StrokeStyle(lineWidth: 2, lineCap: .round)).frame(width: 18, height: 5).offset(x: 3, y: 10)
        }
    }
}

private struct Wave: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addCurve(
            to: CGPoint(x: rect.midX, y: rect.midY),
            control1: CGPoint(x: rect.width * 0.12, y: rect.minY),
            control2: CGPoint(x: rect.width * 0.38, y: rect.maxY)
        )
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.midY),
            control1: CGPoint(x: rect.width * 0.62, y: rect.minY),
            control2: CGPoint(x: rect.width * 0.88, y: rect.maxY)
        )
        return path
    }
}

/// Pofu's face as a vector: a round head, two ears, eyes and cheeks.
private struct PofuFace: View {
    var body: some View {
        ZStack {
            Circle().frame(width: 8, height: 8).offset(x: -9, y: -9)
            Circle().frame(width: 8, height: 8).offset(x: 9, y: -9)
            Ellipse().frame(width: 24, height: 21).offset(y: 1)
            Circle().fill(Color.white).frame(width: 3.4, height: 3.4).offset(x: -5, y: -1)
            Circle().fill(Color.white).frame(width: 3.4, height: 3.4).offset(x: 5, y: -1)
            Capsule().fill(Color.white).frame(width: 5, height: 2).offset(y: 4)
        }
    }
}
#endif
