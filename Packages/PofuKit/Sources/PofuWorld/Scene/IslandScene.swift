#if os(iOS)
import PofuCompanion
import PofuCore
import PofuDesignSystem
import SwiftUI

/// Pofu's island: one world seen through one continuous camera in three
/// framings, Home, Island and Map (ADR-0018; interaction spec §1, §12;
/// game design §15).
///
/// It reads only a `WorldSnapshot`. The island plate's depth bands, the
/// station vignettes at their fixed slots, the residents and the other
/// islands sit on one world canvas moved by one scale-and-offset
/// transform. Pofu is drawn in screen space at the same projection, so
/// his live companion view and its shader render at their final size
/// instead of being magnified ×2.4.
///
/// Gestures: a pinch scrubs the rail between the framings and settles on
/// the nearest with a spring; a double tap steps in; a one-finger drag
/// peeks. A tap on a station focuses it and raises its sheet; a tap on a
/// resident shows their card.
public struct IslandScene<Bubble: View>: View {
    let world: WorldSnapshot
    let model: IslandSceneModel
    let onPofuTap: (@MainActor () -> Void)?
    let onBuild: (@MainActor (StationID) -> Void)?
    let bubble: Bubble

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var safeTop: Double = 59

    /// - Parameters:
    ///   - world: The world to draw.
    ///   - model: The scene's camera, focus and sheet state.
    ///   - onPofuTap: Called after Pofu's own squish when he is tapped.
    ///   - onBuild: Builds a station's next level; `nil` shows the sheet's
    ///     button as unavailable.
    ///   - bubble: Pofu's speech bubble, shown above his head at Home.
    public init(
        world: WorldSnapshot,
        model: IslandSceneModel,
        onPofuTap: (@MainActor () -> Void)? = nil,
        onBuild: (@MainActor (StationID) -> Void)? = nil,
        @ViewBuilder bubble: () -> Bubble
    ) {
        self.world = world
        self.model = model
        self.onPofuTap = onPofuTap
        self.onBuild = onBuild
        self.bubble = bubble()
    }

    public var body: some View {
        @Bindable var model = model
        GeometryReader { proxy in
            let size = proxy.size
            TimelineView(.animation(minimumInterval: nil, paused: !model.needsFrames)) { context in
                let _ = model.revision
                let rig = model.frame(
                    at: context.date,
                    width: Double(size.width),
                    height: Double(size.height),
                    safeTop: safeTop
                )
                SceneFrame(
                    world: world,
                    rig: rig,
                    model: model,
                    size: size,
                    onPofuTap: onPofuTap,
                    bubble: bubble
                )
            }
            .contentShape(Rectangle())
            .gesture(
                TapGesture(count: 2)
                    .onEnded { model.stepIn() }
                    .exclusively(before: SpatialTapGesture().onEnded { value in
                        model.backgroundTapped(x: Double(value.location.x), y: Double(value.location.y))
                    })
            )
            .simultaneousGesture(
                MagnifyGesture(minimumScaleDelta: 0.01)
                    .onChanged { value in
                        model.pinchChanged(
                            magnification: Double(value.magnification),
                            startX: Double(value.startLocation.x),
                            startY: Double(value.startLocation.y),
                            time: value.time
                        )
                    }
                    .onEnded { value in
                        model.pinchEnded(time: value.time)
                    }
            )
            .simultaneousGesture(
                DragGesture(minimumDistance: 12)
                    .onChanged { value in
                        model.peekChanged(dx: Double(value.translation.width), dy: Double(value.translation.height))
                    }
                    .onEnded { _ in model.peekEnded() }
            )
        }
        .ignoresSafeArea()
        .background {
            // The safe area is read where it is respected; the scene itself
            // runs edge to edge.
            Color.clear
                .onGeometryChange(for: Double.self) { proxy in
                    Double(proxy.safeAreaInsets.top)
                } action: { top in
                    safeTop = top
                }
        }
        .onChange(of: reduceMotion, initial: true) { _, reduce in
            model.reduceMotion = reduce
        }
        .sensoryFeedback(.selection, trigger: model.projectedFraming)
        .accessibilityElement(children: .contain)
        .accessibilityZoomAction { action in
            if action.direction == .zoomIn {
                model.stepIn()
            } else {
                model.stepOut()
            }
        }
        .sheet(item: $model.sheet) { item in
            StationSheet(
                station: item.station,
                status: world.stations.first { $0.id == item.station },
                jar: world.jar,
                onBuild: onBuild,
                onClose: { model.dismissFocus() }
            )
            .id(item.station)
            .transition(.opacity)
            .presentationDetents([.fraction(0.42), .large])
            .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.42)))
            .presentationContentInteraction(.resizes)
        }
    }
}

extension IslandScene where Bubble == EmptyView {
    public init(
        world: WorldSnapshot,
        model: IslandSceneModel,
        onPofuTap: (@MainActor () -> Void)? = nil,
        onBuild: (@MainActor (StationID) -> Void)? = nil
    ) {
        self.init(world: world, model: model, onPofuTap: onPofuTap, onBuild: onBuild) { EmptyView() }
    }
}

// MARK: - One frame

/// Everything at one camera and lens: the sky, the world canvas, Pofu, and
/// the screen-space overlays.
private struct SceneFrame<Bubble: View>: View {
    let world: WorldSnapshot
    let rig: CameraRig
    let model: IslandSceneModel
    let size: CGSize
    let onPofuTap: (@MainActor () -> Void)?
    let bubble: Bubble

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let pose = rig.pose
        let lens = rig.lens
        let z = rig.railPosition
        let peek = rig.peekTilt
        let device = model.deviceTilt
        let tilt = (x: min(max(peek.x + device.x, -1), 1), y: min(max(peek.y + device.y, -1), 1))
        let isDusk = colorScheme == .dark || world.isBedtime
        let offset = CGSize(width: rig.offsetX.value, height: rig.offsetY.value)
        let interactive = rig.pinchStart == nil && (model.focus != nil || (z > 0.5 && z < 1.5))
        // Dusk and night grade the painted world in code (game design
        // §15: no night versions are generated).
        let grade = isDusk ? Color(red: 0.80, green: 0.80, blue: 0.92) : Color.white

        ZStack(alignment: .topLeading) {
            SkyBackdrop(isDusk: isDusk, isNight: world.isBedtime, tilt: tilt)

            WorldCanvas(
                world: world,
                lens: lens,
                z: z,
                scale: pose.scale,
                tilt: tilt,
                isInteractive: interactive,
                model: model
            )
            .frame(width: IslandLayout.canvasWidth, height: IslandLayout.canvasHeight, alignment: .topLeading)
            .cameraTransform(pose: pose, viewportWidth: Double(size.width), offset: offset)
            .colorMultiply(grade)
            .frame(width: size.width, height: size.height, alignment: .topLeading)

            PofuLayer(
                world: world,
                pose: pose,
                lens: lens,
                z: z,
                tilt: tilt,
                size: size,
                offset: offset,
                grade: grade,
                model: model,
                onPofuTap: onPofuTap,
                bubble: bubble
            )

            ScreenOverlays(world: world, pose: pose, z: z, size: size, offset: offset, model: model)
        }
        .frame(width: size.width, height: size.height)
        .clipped()
    }
}

/// One transform for the whole world canvas, scale then offset: world
/// point `p` lands at `(p − look) · s + (width / 2, anchorY) + offset`
/// (§1.9). Plates are never animated individually.
extension View {
    fileprivate func cameraTransform(pose: CameraPose, viewportWidth: Double, offset: CGSize) -> some View {
        let s = pose.scale
        let origin = IslandLayout.canvasOrigin
        let tx = viewportWidth / 2 - (pose.lookX + origin.x) * s + Double(offset.width)
        let ty = pose.anchorY - (pose.lookY + origin.y) * s + Double(offset.height)
        return scaleEffect(CGFloat(s), anchor: .topLeading)
            .offset(x: CGFloat(tx), y: CGFloat(ty))
    }
}

// MARK: - The world canvas

/// The world objects on the canvas, back to front by depth.
private struct WorldCanvas: View {
    let world: WorldSnapshot
    let lens: Lens
    let z: Double
    let scale: Double
    let tilt: (x: Double, y: Double)
    let isInteractive: Bool
    let model: IslandSceneModel

    var body: some View {
        ZStack(alignment: .topLeading) {
            otherIsles
            ForEach(IslandLayout.plateBands, id: \.art) { band in
                if let sprite = WorldArt.sprite(band.art) {
                    DepthImage(
                        name: band.art,
                        sprite: sprite,
                        level: lens.blurLevel(depth: band.depth),
                        anchor: canvasPoint(.zero, depth: band.depth)
                    )
                }
            }
            ForEach(objects) { object in
                objectView(object)
            }
        }
    }

    // MARK: Objects

    private struct Object: Identifiable {
        enum Kind {
            case station(StationStatus)
            case resident(IslandLayout.Resident)
        }

        var id: String
        var kind: Kind
        var anchor: WorldPoint
        var depth: Double
    }

    /// Stations whose slot is open on the home island, and the residents
    /// of built stations, sorted back to front.
    private var objects: [Object] {
        var objects: [Object] = []
        for status in world.stations where status.island == .aycicegi && status.isOpen {
            guard let anchor = IslandLayout.stationAnchors[status.id] else { continue }
            objects.append(Object(id: "station-\(status.id)", kind: .station(status), anchor: anchor, depth: IslandLayout.depth(ofY: anchor.y)))
        }
        for resident in IslandLayout.residents {
            guard let station = world.stations.first(where: { $0.id == resident.station }), station.level > 0 else { continue }
            objects.append(Object(id: "resident-\(resident.id)", kind: .resident(resident), anchor: resident.feet, depth: IslandLayout.depth(ofY: resident.feet.y)))
        }
        return objects.sorted { $0.depth < $1.depth }
    }

    @ViewBuilder
    private func objectView(_ object: Object) -> some View {
        let point = canvasPoint(object.anchor, depth: object.depth)
        let level = lens.blurLevel(depth: object.depth)
        switch object.kind {
        case .station(let status):
            StationView(status: status, point: point, level: level)
                .overlay {
                    hitArea(
                        box: IslandLayout.stationHitBox,
                        at: point,
                        label: WorldStrings.stationName(status.id),
                        value: status.level > 0 ? WorldStrings.level(status.level, of: status.maxLevel) : "",
                        tap: { model.stationTapped(status.id) },
                        activate: { model.focusStation(status.id) }
                    )
                }
        case .resident(let resident):
            ResidentView(resident: resident, point: point, level: level)
                .overlay {
                    hitArea(
                        box: IslandLayout.residentHitBox,
                        at: point,
                        label: "\(WorldStrings.residentName(resident.id)), \(WorldStrings.stationName(resident.station))",
                        value: "",
                        tap: { model.residentTapped(resident.id) },
                        activate: { model.focusResident(resident.id) }
                    )
                }
        }
    }

    /// A transparent tap target over a box (§2.7: simple shapes, never
    /// image alpha), positioned on the canvas last so the gesture covers
    /// only the box.
    private func hitArea(
        box: WorldBox,
        at point: CGPoint,
        label: String,
        value: String,
        tap: @escaping @MainActor () -> Void,
        activate: @escaping @MainActor () -> Void
    ) -> some View {
        Color.clear
            .frame(width: CGFloat(box.width), height: CGFloat(box.height))
            .contentShape(Rectangle())
            .onTapGesture { tap() }
            .accessibilityElement()
            .accessibilityLabel(Text(verbatim: label))
            .accessibilityValue(Text(verbatim: value))
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { activate() }
            .allowsHitTesting(isInteractive)
            .position(x: point.x + CGFloat(box.midX), y: point.y + CGFloat(box.midY))
    }

    // MARK: Other islands

    @ViewBuilder
    private var otherIsles: some View {
        // Far away from Home; leave the render tree there.
        if z < 1.7 {
            ForEach(IslandLayout.isles) { isle in
                if let sprite = WorldArt.sprite(isle.art) {
                    let arrived = world.islands.contains(isle.id)
                    // Soft once you are on an island, sharp on the map
                    // (§5.1); 35 % at the Island framing.
                    let fade = 1 - min(max(z, 0), 1) * 0.65
                    DepthImage(
                        name: isle.art,
                        sprite: sprite,
                        level: min(max(z, 0), 1),
                        anchor: canvasPoint(isle.center, depth: 0),
                        opacity: (arrived ? 1 : 0.55) * fade
                    )
                    .saturation(arrived ? 1 : 0.35)
                }
            }
        }
    }

    // MARK: Placement

    /// A world point on the canvas, shifted by parallax: objects in front
    /// of the focus plane move one way, those behind it the other (§12.3 a).
    private func canvasPoint(_ point: WorldPoint, depth: Double) -> CGPoint {
        let origin = IslandLayout.canvasOrigin
        let s = max(scale, 0.01)
        let px = (depth - lens.focus) * tilt.x * 0.12 / s
        let py = (depth - lens.focus) * tilt.y * 0.06 / s
        return CGPoint(x: origin.x + point.x + px, y: origin.y + point.y + py)
    }
}

/// A station: its contact shadow and vignette at its level, an empty build
/// spot, or a labelled placeholder where there is no art yet.
private struct StationView: View {
    let status: StationStatus
    let point: CGPoint
    let level: Double

    var body: some View {
        ZStack(alignment: .topLeading) {
            if status.level > 0 {
                ContactShadow(width: 92, height: 20)
                    .position(x: point.x, y: point.y + 2)
                if let art = IslandLayout.stationArt(status.id, level: status.level), let sprite = WorldArt.sprite(art.name) {
                    DepthImage(name: art.name, sprite: sprite, level: level, anchor: point)
                } else {
                    PlaceholderVignette(title: WorldStrings.stationName(status.id))
                        .position(x: point.x, y: point.y - 30)
                }
            } else {
                BuildSpot()
                    .opacity(1 - min(level, 1.5) * 0.4)
                    .position(x: point.x, y: point.y)
            }
        }
    }
}

/// An open, unbuilt slot: a dashed footprint with a small plus.
private struct BuildSpot: View {
    var body: some View {
        ZStack {
            Ellipse()
                .fill(Color.white.opacity(0.22))
            Ellipse()
                .strokeBorder(Color.white.opacity(0.75), style: StrokeStyle(lineWidth: 1.2, dash: [3.5, 3]))
            Image(systemName: "plus")
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.9))
        }
        .frame(width: 64, height: 18)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Where a station has no art at all yet.
private struct PlaceholderVignette: View {
    let title: String

    var body: some View {
        Text(verbatim: title)
            .font(.system(size: 8, weight: .semibold, design: .rounded))
            .multilineTextAlignment(.center)
            .foregroundStyle(Color.shadowInk)
            .frame(width: 72, height: 56)
            .background(Color.white.opacity(0.55), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Color.shadowInk.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
            }
            .allowsHitTesting(false)
    }
}

private struct ResidentView: View {
    let resident: IslandLayout.Resident
    let point: CGPoint
    let level: Double

    var body: some View {
        ZStack(alignment: .topLeading) {
            ContactShadow(width: 24, height: 6)
                .position(x: point.x, y: point.y)
            if let sprite = WorldArt.sprite(resident.art) {
                DepthImage(name: resident.art, sprite: sprite, level: level, anchor: point)
            }
        }
    }
}

// MARK: - Pofu

/// Pofu in screen space at the camera's projection: the live companion as
/// the sharp layer over his baked soft and deep variants, the vector pin
/// on the map, and the speech bubble at Home.
private struct PofuLayer<Bubble: View>: View {
    let world: WorldSnapshot
    let pose: CameraPose
    let lens: Lens
    let z: Double
    let tilt: (x: Double, y: Double)
    let size: CGSize
    let offset: CGSize
    let grade: Color
    let model: IslandSceneModel
    let onPofuTap: (@MainActor () -> Void)?
    let bubble: Bubble

    /// Pofu's art is 64 units wide (154 pt at Home, ADR-0018).
    static var artWidth: Double {
        64
    }

    var body: some View {
        let depth = IslandLayout.depth(ofY: IslandLayout.pofu.y)
        let s = pose.scale
        let projected = pose.project(IslandLayout.pofu, width: Double(size.width))
        let parallaxX = (depth - lens.focus) * tilt.x * 0.12
        let parallaxY = (depth - lens.focus) * tilt.y * 0.06
        let feet = CGPoint(
            x: projected.x + Double(offset.width) + parallaxX,
            y: projected.y + Double(offset.height) + parallaxY
        )
        let level = lens.blurLevel(depth: depth)
        let weights = DepthWeights(level: level)
        // The painted body above z 0.55, the pin below 0.25 (§1.6).
        let painted = min(max((z - 0.25) / 0.3, 0), 1)
        let bubbleOpacity = model.focus == nil ? min(max((z - 1.6) / 0.3, 0), 1) : 0

        ZStack(alignment: .topLeading) {
            if painted > 0.01 {
                if let sprite = WorldArt.sprite("pofu") {
                    DepthImage(name: "pofu", sprite: sprite, level: level, anchor: feet, scale: CGFloat(s), opacity: painted, skipsSharp: true)
                        .colorMultiply(grade)
                }
                if weights.sharp * painted > DepthWeights.visibleThreshold {
                    companion(feet: feet, scale: s)
                        .colorMultiply(grade)
                        .opacity(weights.sharp * painted)
                }
            }
            if painted < 0.99 {
                PofuPin()
                    .opacity(1 - painted)
                    .position(x: feet.x, y: feet.y - 15)
            }
            if bubbleOpacity > 0.01 {
                let head = feet.y - CGFloat(62 * s)
                bubble
                    .frame(maxWidth: min(size.width - 40, 320))
                    .frame(width: size.width, height: max(head - 4, 0), alignment: .bottom)
                    .offset(x: feet.x - size.width / 2)
                    .opacity(bubbleOpacity)
            }
        }
    }

    /// The live companion, laid out so its feet land on `feet`. The
    /// companion's stage keeps 10 % side margins, 24 % headroom and 6 %
    /// floor room around the art (`CompanionStageLayout`).
    private func companion(feet: CGPoint, scale s: Double) -> some View {
        let art = CompanionArt.placeholder
        let rig = art?.rig ?? CompanionRig.hamster
        let artWidth = Self.artWidth * s
        let artHeight = artWidth / rig.aspectRatio
        let viewWidth = artWidth * 1.2
        let viewHeight = artHeight * 1.3
        let groundX = artWidth * (0.1 + rig.ground.x)
        let groundY = artHeight * (0.24 + rig.ground.y)
        return CompanionView(
            vitality: min(max(world.wellbeing / 100, 0), 1),
            energy: min(Double(world.pending.total.units) / 60, 1),
            art: art,
            onTap: {
                if model.focus != nil || model.sheet != nil {
                    model.dismissFocus()
                } else {
                    onPofuTap?()
                }
            }
        )
        .frame(width: viewWidth, height: viewHeight)
        .position(x: feet.x - groundX + viewWidth / 2, y: feet.y - groundY + viewHeight / 2)
    }
}

/// Pofu on the map: a small vector pin (§1.6).
private struct PofuPin: View {
    var body: some View {
        Image(systemName: "pawprint.fill")
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(PofuColor.onAccent)
            .frame(width: 30, height: 30)
            .background(PofuColor.accent, in: Circle())
            .overlay { Circle().strokeBorder(Color.white.opacity(0.9), lineWidth: 2) }
            .shadow(color: Color.shadowInk.opacity(0.25), radius: 3, y: 1)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

// MARK: - Screen-space overlays

/// Map labels and the resident card: text stays crisp at every scale.
private struct ScreenOverlays: View {
    let world: WorldSnapshot
    let pose: CameraPose
    let z: Double
    let size: CGSize
    let offset: CGSize
    let model: IslandSceneModel

    var body: some View {
        let labels = 1 - min(max((z - 0.2) / 0.25, 0), 1)
        ZStack(alignment: .topLeading) {
            if labels > 0.01 {
                mapLabel(.aycicegi, at: WorldPoint(x: 0, y: 128), arrived: true)
                    .opacity(labels)
                ForEach(IslandLayout.isles) { isle in
                    mapLabel(isle.id, at: WorldPoint(x: isle.center.x, y: isle.center.y + 122), arrived: world.islands.contains(isle.id))
                        .opacity(labels)
                }
            }
            if case .resident(let id) = model.focus, let resident = IslandLayout.resident(id) {
                residentCard(resident)
            }
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
    }

    private func screenPoint(_ point: WorldPoint) -> CGPoint {
        let p = pose.project(point, width: Double(size.width))
        return CGPoint(x: p.x + Double(offset.width), y: p.y + Double(offset.height))
    }

    private func mapLabel(_ island: IslandID, at point: WorldPoint, arrived: Bool) -> some View {
        let p = screenPoint(point)
        return HStack(spacing: 4) {
            if !arrived {
                Image(systemName: "lock.fill")
                    .font(.system(size: 10, weight: .semibold))
            }
            Text(verbatim: WorldStrings.islandName(island))
                .font(PofuFont.caption)
        }
        .foregroundStyle(PofuColor.textPrimary)
        .padding(.horizontal, 10)
        .frame(height: 26)
        .glassEffect(.regular, in: Capsule(style: .continuous))
        .fixedSize()
        .position(x: p.x, y: p.y)
        .allowsHitTesting(false)
        .accessibilityElement(children: .combine)
    }

    private func residentCard(_ resident: IslandLayout.Resident) -> some View {
        let feet = screenPoint(resident.feet)
        let width: CGFloat = 232
        let x = min(max(feet.x, 12 + width / 2), size.width - 12 - width / 2)
        let status = world.stations.first { $0.id == resident.station }
        return ResidentCard(
            resident: resident,
            status: status,
            line: model.residentLine,
            tailOffset: feet.x - x,
            onGoToStall: { model.focusStation(resident.station) }
        )
        .frame(width: width)
        .frame(width: size.width, height: max(size.height - feet.y - 10, 0), alignment: .top)
        .offset(x: x - size.width / 2, y: feet.y + 10)
        .transition(.scale(scale: 0.9, anchor: .top).combined(with: .opacity))
    }
}

// MARK: - The sky

/// The sky behind the islands, with a parallax glow (§12.3 a: the sky moves
/// least).
private struct SkyBackdrop: View {
    let isDusk: Bool
    let isNight: Bool
    let tilt: (x: Double, y: Double)

    var body: some View {
        let colors: [Color] = isNight
            ? [Color(red: 0.11, green: 0.14, blue: 0.27), Color(red: 0.24, green: 0.24, blue: 0.38)]
            : isDusk
            ? [Color(red: 0.16, green: 0.20, blue: 0.33), Color(red: 0.38, green: 0.36, blue: 0.48)]
            : [Color(red: 0.78, green: 0.88, blue: 0.95), Color(red: 0.97, green: 0.94, blue: 0.87)]
        ZStack {
            LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
            RadialGradient(
                colors: [Color.white.opacity(isDusk ? 0.10 : 0.55), Color.white.opacity(0)],
                center: UnitPoint(x: 0.25 - tilt.x * 0.03, y: 0.18 - tilt.y * 0.02),
                startRadius: 0,
                endRadius: 320
            )
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
#endif
