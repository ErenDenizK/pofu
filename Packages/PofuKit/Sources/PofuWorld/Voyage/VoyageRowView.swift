#if os(iOS)
import PofuCore
import PofuDesignSystem
import SwiftUI

/// The voyage row (ADR-0028, plan row 2c): the far stop. Over the world, at the Map's framing, the cloud
/// sea of Home's sky and a row of islands along the route, one large, its neighbours cut by the screen's
/// edges. A horizontal swipe changes the island in view and snaps to one; a tap on a neighbour glides
/// there. One glass bar, native and never painted, carries the island's name, one line of state and the
/// verb. The Gezgin stays where she is moored while the player chooses.
struct VoyageRowOverlay: View {
    let model: IslandSceneModel
    let world: WorldSnapshot

    @Environment(\.worldLook) private var look
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let shown = model.projectedFraming == .map && model.island == .home && model.focus == nil
        ZStack {
            if shown {
                VoyageRow(model: model, state: model.voyage, world: world, look: look)
                    .transition(.opacity)
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.35), value: shown)
    }
}

/// The strings of the row, looked up by key in the package's catalog.
enum VoyageStrings {
    static func text(_ key: String) -> String {
        Bundle.module.localizedString(forKey: key, value: key, table: nil)
    }

    static var verb: String { text("voyage.verb") }
    static var here: String { text("voyage.here") }
    static var label: String { text("voyage.label") }
}

private struct VoyageRow: View {
    let model: IslandSceneModel
    let state: VoyageRowState
    let world: WorldSnapshot
    let look: WorldLook

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// The finger's direction once it has gone past the slop: the row takes horizontal drags only.
    @State private var dragStart: Int?
    @State private var horizontal: Bool?

    private var stops: [VoyageStop] {
        VoyageRoute.stops(koke: world.koke, caglayan: world.caglayan)
    }

    private var glide: Animation? {
        reduceMotion ? nil : .smooth(duration: (VoyageData.shipped ?? .fallback).glideSeconds)
    }

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let layout = VoyageRowLayout(width: Double(size.width), height: Double(size.height))
            let stops = stops
            let selected = VoyageRoute.index(of: state.island, in: stops)
            let position = state.held ?? Double(selected)
            ZStack(alignment: .topLeading) {
                VoyageSea(model: model, world: world, look: look, size: size)
                ForEach(order(stops, position: position), id: \.island) { stop in
                    if let index = stops.firstIndex(of: stop) {
                        VoyageIsle(model: model, stop: stop, world: world, place: layout.place(index: index, position: position), sleeps: false)
                    }
                }
                Color.clear
                    .contentShape(Rectangle())
                    .simultaneousGesture(drag(layout: layout, stops: stops, selected: selected))
                    .simultaneousGesture(
                        SpatialTapGesture().onEnded { tap in
                            guard let target = layout.tapTarget(x: Double(tap.location.x), selected: selected, count: stops.count) else { return }
                            withAnimation(glide) { state.choose(stops[target].island) }
                        }
                    )
                    .accessibilityElement()
                    .accessibilityLabel(Text(verbatim: VoyageStrings.label))
                    .accessibilityValue(Text(verbatim: WorldStrings.islandName(state.island)))
                    .accessibilityAdjustableAction { direction in
                        let next = selected + (direction == .increment ? 1 : -1)
                        guard stops.indices.contains(next) else { return }
                        withAnimation(glide) { state.choose(stops[next].island) }
                    }
                VoyageBar(model: model, state: state, stop: stops[min(selected, stops.count - 1)], size: size)
            }
            .frame(width: size.width, height: size.height, alignment: .topLeading)
            .clipped()
        }
        .ignoresSafeArea()
        .accessibilityIdentifier("voyage-row")
    }

    /// Far to near: the island in view is drawn last.
    private func order(_ stops: [VoyageStop], position: Double) -> [VoyageStop] {
        stops.enumerated().sorted { abs(Double($0.offset) - position) > abs(Double($1.offset) - position) }.map(\.element)
    }

    private func drag(layout: VoyageRowLayout, stops: [VoyageStop], selected: Int) -> some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                if horizontal == nil {
                    horizontal = abs(value.translation.width) > abs(value.translation.height)
                    dragStart = selected
                }
                guard horizontal == true, let start = dragStart else { return }
                state.hold(position: layout.position(from: start, translation: Double(value.translation.width), count: stops.count))
            }
            .onEnded { value in
                defer {
                    horizontal = nil
                    dragStart = nil
                }
                guard horizontal == true, let start = dragStart else { return }
                let position = layout.position(from: start, translation: Double(value.translation.width), count: stops.count)
                let target = layout.settle(from: start, position: position, velocity: Double(value.velocity.width), count: stops.count)
                state.hold(position: position)
                withAnimation(glide) { state.choose(stops[target].island) }
            }
    }
}

/// The cloud sea behind the row: Home's sky set as the Map placed it, framed at the Map's stop, with no
/// island on it; a plain sky where the world is not painted.
private struct VoyageSea: View {
    let model: IslandSceneModel
    let world: WorldSnapshot
    let look: WorldLook
    let size: CGSize

    var body: some View {
        if let sky = PaintedSky.mapSky(world: world, look: look) {
            let stop = sky.mapStop
            let pose = CameraPose(
                scale: stop.scale * Double(size.width) / CameraRail.referenceWidth,
                look: stop.look,
                anchorY: stop.anchorY * Double(size.height) / CameraRail.referenceHeight
            )
            PaintedSkyLayer(
                plate: sky,
                pose: pose,
                reference: sky.skyReference(width: Double(size.width), height: Double(size.height)),
                size: size,
                offset: .zero,
                fade: 1,
                isMap: true
            )
            .frame(width: size.width, height: size.height, alignment: .topLeading)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        } else {
            LinearGradient(colors: [Color(red: 0.62, green: 0.78, blue: 0.95), Color(red: 0.95, green: 0.93, blue: 0.98)], startPoint: .top, endPoint: .bottom)
                .frame(width: size.width, height: size.height)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }
}

/// One island of the row: its art on a soft bed of cloud, or a cloud tower where it is not yet open.
private struct VoyageIsle: View {
    let model: IslandSceneModel
    let stop: VoyageStop
    let world: WorldSnapshot
    let place: VoyageRowLayout.Place
    let sleeps: Bool

    var body: some View {
        let art = art
        let w = CGFloat(place.width)
        let h = w * CGFloat(art.aspect)
        ZStack {
            // The cloud bed under its foot.
            Ellipse()
                .fill(Color.white.opacity(0.5 * place.weight + 0.2))
                .frame(width: w * 1.05, height: w * 0.2)
                .blur(radius: 12)
                .offset(y: h * 0.36)
            Image(art.name, bundle: .module)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: w, height: h)
                .mask { VoyageFoot(fade: stop.status == .locked) }
        }
        .frame(width: w, height: h)
        .saturation(0.8 + 0.2 * place.weight)
        .brightness(-0.05 * (1 - place.weight))
        .position(x: CGFloat(place.x), y: CGFloat(place.y))
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// The picture, and its height over its width.
    private var art: (name: String, aspect: Double) {
        switch stop.status {
        case .locked:
            return (MapSlots.towerArt(for: stop.island.rawValue), 1.3)
        default:
            break
        }
        switch stop.island {
        case .home:
            if let plate = model.homePlate {
                let box = plate.islandBox
                return (plate.plate.mapIslandArt(light: plate.light, stage: plate.stage), box.height / max(box.width, 1))
            }
        case .caglayan:
            if let plate = model.caglayanPlate {
                let box = plate.islandBox
                return (plate.plate.mapIslandArt(light: plate.light, stage: plate.stage), box.height / max(box.width, 1))
            }
        case .koke:
            let size = KokeLayout.plateSize
            return (KokeLayout.islandArt(stage: world.koke.stage), size.height / size.width)
        default:
            break
        }
        return (MapSlots.towerArt(for: stop.island.rawValue), 1.3)
    }
}

/// A tower's foot dissolves into the sky (as on the old Map); an island is drawn whole.
private struct VoyageFoot: View {
    let fade: Bool

    var body: some View {
        if fade {
            LinearGradient(
                stops: [
                    .init(color: .black, location: 0),
                    .init(color: .black, location: 0.6),
                    .init(color: .black.opacity(0.45), location: 0.8),
                    .init(color: .clear, location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        } else {
            Color.black
        }
    }
}

/// The one glass bar: the name, one line of state and the verb. Native glass, never painted. It stands above
/// the place control's row, so the corner button stays free.
private struct VoyageBar: View {
    let model: IslandSceneModel
    let state: VoyageRowState
    let stop: VoyageStop
    let size: CGSize

    var body: some View {
        let here = stop.island == state.origin
        let live = stop.canSail && !here
        HStack(alignment: .center, spacing: PofuSpacing.m) {
            VStack(alignment: .leading, spacing: PofuSpacing.xxs) {
                Text(verbatim: WorldStrings.islandName(stop.island))
                    .font(PofuFont.title3)
                    .lineLimit(1)
                Text(verbatim: here ? VoyageStrings.here : VoyageStrings.text(stop.lineKey))
                    .font(PofuFont.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            Button {
                model.voyageSail()
            } label: {
                Text(verbatim: VoyageStrings.verb)
                    .font(PofuFont.headline)
                    .padding(.horizontal, PofuSpacing.s)
            }
            .buttonStyle(.glassProminent)
            .disabled(!live)
            .accessibilityIdentifier("voyage-sail")
        }
        .padding(.horizontal, PofuSpacing.l)
        .padding(.vertical, PofuSpacing.m)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .padding(.horizontal, PofuSpacing.screen)
        .frame(width: size.width, height: size.height, alignment: .bottom)
        .padding(.bottom, CGFloat((VoyageData.shipped ?? .fallback).barLift) + PlaceControl.size)
        .frame(width: size.width, height: size.height, alignment: .bottom)
        .id(stop.island)
        .animation(nil, value: stop.island)
    }
}
#endif
