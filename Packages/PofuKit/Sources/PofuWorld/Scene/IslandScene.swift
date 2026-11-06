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
/// instead of being magnified ×2.4. Behind the world, a living sky follows
/// the snapshot's clock; in front of it, a cloud sea keeps the bottom band
/// calm.
///
/// Gestures: a pinch scrubs the rail between the framings and settles on
/// the nearest with a spring; a double tap steps in; a one-finger drag
/// peeks. A tap on a station focuses it and raises its sheet; a tap on a
/// resident shows their card. With a `WorldHomeModel`, the station sheet
/// builds and the build moment plays in the world.
public struct IslandScene<Bubble: View>: View {
    let world: WorldSnapshot
    let model: IslandSceneModel
    let home: WorldHomeModel?
    let onPofuTap: (@MainActor () -> Void)?
    let onBuild: (@MainActor (StationID) -> Void)?
    let props: WorldProps?
    /// Sends the game event of a tap on the visit: greeting, gift, help,
    /// invitation (experience v1 §5).
    let onVisitor: (@MainActor (GameEvent.Kind) -> Void)?
    let bubble: Bubble

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.worldLook) private var look
    @Environment(\.worldStillFrame) private var still
    @State private var safeTop: Double = 59
    /// The one-thumb zoom owns this finger, or a drag has gone past the
    /// slop: the touch is a gesture, not a tap.
    @State private var dragging = false
    @State private var touching = false

    /// - Parameters:
    ///   - world: The world to draw.
    ///   - model: The scene's camera, focus and sheet state.
    ///   - home: The visit and its moments; the build moment plays from it.
    ///   - onPofuTap: Called after Pofu's own squish when he is tapped.
    ///   - onBuild: Builds a station's next level; `nil` shows the sheet's
    ///     button as unavailable.
    ///   - props: The home objects drawn in the world (jar, lantern, pots).
    ///   - onVisitor: Sends the game event of a tap on today's visitor, the
    ///     parcel, the help target or an invitation; `nil` leaves them
    ///     decorative.
    ///   - bubble: Pofu's speech bubble, shown above his head at Home.
    public init(
        world: WorldSnapshot,
        model: IslandSceneModel,
        home: WorldHomeModel? = nil,
        onPofuTap: (@MainActor () -> Void)? = nil,
        onBuild: (@MainActor (StationID) -> Void)? = nil,
        props: WorldProps? = nil,
        onVisitor: (@MainActor (GameEvent.Kind) -> Void)? = nil,
        @ViewBuilder bubble: () -> Bubble
    ) {
        self.world = world
        self.model = model
        self.home = home
        self.onPofuTap = onPofuTap
        self.onBuild = onBuild
        self.props = props
        self.onVisitor = onVisitor
        self.bubble = bubble()
    }

    public var body: some View {
        @Bindable var model = model
        // The visit's taps report here; set on every pass so it never holds
        // a stale closure.
        let _ = model.onVisitorEvent = onVisitor
        let _ = model.koke.status = world.koke
        let _ = model.caglayan.status = world.caglayan
        GeometryReader { proxy in
            let size = proxy.size
            // The interval and the pause come from the frame policy (§4.1):
            // Direct, Moment, Ambient, Settled, Covered.
            let moment = home?.build != nil || home?.collect != nil
            let policy = model.directive(moment: moment)
            TimelineView(.animation(minimumInterval: policy.timelineInterval, paused: !model.needsFrames && !moment)) { context in
                let _ = model.revision
                let rig = model.frame(
                    at: context.date,
                    width: Double(size.width),
                    height: Double(size.height),
                    safeTop: safeTop
                )
                let directive = model.directive(moment: moment, at: context.date)
                // Low Power Mode and heat drop the depth-of-field pass.
                let rack = directive.depthOfField ? model.rackFocus(at: context.date) : 0
                let build: BuildFrame? = home?.build.flatMap { active in
                    home?.buildTime(at: context.date).map { (moment: active.moment, time: $0) }
                }
                ZStack(alignment: .topLeading) {
                    SceneFrame(
                        world: world,
                        rig: rig,
                        model: model,
                        size: size,
                        time: context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 3600),
                        clock: context.date,
                        rack: rack,
                        directive: directive,
                        build: build,
                        celebrations: home?.celebrations ?? 0,
                        home: home,
                        props: props,
                        onPofuTap: onPofuTap,
                        bubble: bubble
                    )
                    if let fade = model.crossfade(at: context.date) {
                        // Reduce Motion: the old framing fades out over the
                        // new one instead of the camera travelling.
                        SceneFrame(
                            world: world,
                            rig: fade.rig,
                            model: model,
                            size: size,
                            time: context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 3600),
                            clock: context.date,
                            rack: rack,
                            directive: directive,
                            build: build,
                            celebrations: home?.celebrations ?? 0,
                            home: home,
                            props: nil,
                            onPofuTap: nil,
                            bubble: bubble
                        )
                        .opacity(fade.opacity)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                    }
                }
            }
            // A sheet or cover freezes then flattens the world (§3.1).
            .pofuFlattenWhenCovered(model.isCovered || model.isInviting)
            .contentShape(Rectangle())
            // One tap resolver replaces the per-object tap overlays (§1.3).
            // It answers on touch-up, with no wait for a double tap.
            .gesture(
                SpatialTapGesture().onEnded { value in
                    model.tapped(
                        x: Double(value.location.x),
                        y: Double(value.location.y),
                        stations: world.stations,
                        arrived: Set(world.islands + (world.koke.isArrived ? [IslandID.koke] : []) + (world.caglayan.isArrived ? [IslandID.caglayan] : [])),
                        visitor: world.visitor,
                        invitationOpen: world.invitationOpen,
                        isBedtime: world.isBedtime,
                        koke: world.koke,
                        caglayan: world.caglayan
                    )
                }
            )
            .simultaneousGesture(
                TapGesture(count: 2).onEnded { model.stepIn() }
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
            // One finger: the one-thumb zoom (double tap, hold, drag), the
            // pan or peek, and brushing the island.
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let now = Date()
                        if !touching {
                            touching = true
                            model.touchBegan(x: Double(value.startLocation.x), y: Double(value.startLocation.y), at: now)
                        }
                        if model.touchMoved(y: Double(value.location.y), at: now) {
                            dragging = true
                            return
                        }
                        let moved = hypot(value.translation.width, value.translation.height)
                        guard dragging || moved >= 12 else { return }
                        dragging = true
                        model.peekChanged(dx: Double(value.translation.width), dy: Double(value.translation.height))
                        model.brush(x: Double(value.location.x), y: Double(value.location.y), at: now)
                    }
                    .onEnded { value in
                        let now = Date()
                        touching = false
                        model.touchEnded(x: Double(value.location.x), y: Double(value.location.y), at: now)
                        if dragging {
                            model.peekEnded(velocityX: Double(value.velocity.width))
                            model.endBrush()
                        }
                        dragging = false
                    }
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
            home?.reduceMotion = reduce
        }
        .onAppear {
            if look.hd2d {
                // One residents' cycle: they work or walk out and back.
                model.beginLookVisit(seconds: ResidentLife.cycleSeconds)
            }
            // Arriving at the Island: the establishing shot of the whole
            // island, then the pan view centred on Pofu.
            if !still {
                model.establish()
            }
        }
        .onChange(of: look.tuning.springs, initial: true) { _, springs in
            model.cameraSprings = springs
        }
        // The dressing leaves in a puff when a slot opens; a new visitor
        // arrives once (experience v1 §5.3, §6).
        .onChange(of: world.islandLevel, initial: true) { _, level in
            model.noteIslandLevel(level, at: Date())
        }
        .onChange(of: world.visitor, initial: true) { _, visitor in
            if model.noteVisitor(visitor, at: Date(), still: still), let visitor {
                AccessibilityNotification.Announcement(WorldStrings.visitorArrived(visitor.resident)).post()
            }
        }
        .task {
            model.power.startObservingSystem()
        }
        .overlay { KokeBubbleOverlay(state: model.koke) }
        .overlay { CaglayanBubbleOverlay(state: model.caglayan) }
        .overlay { CaglayanPlaque(model: model, state: model.caglayan) }
        .overlay(alignment: .bottomTrailing) {
            // The one control: the same spot in every framing, thumb zone.
            PlaceControl(model: model, islands: arrivedIslands)
                .padding(.trailing, PofuSpacing.screen)
                .padding(.bottom, PofuSpacing.s)
                .opacity(model.focus == nil && !model.hasSheet ? 1 : 0)
                .allowsHitTesting(model.focus == nil && !model.hasSheet)
                .animation(PofuMotion.respecting(reduceMotion, PofuMotion.snappy), value: model.focus == nil && !model.hasSheet)
        }
        .sensoryFeedback(.selection, trigger: model.projectedFraming)
        .sensoryFeedback(.impact(weight: .light, intensity: 0.7), trigger: model.tapCount)
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
                isBuilding: home?.buildingStation == item.station,
                playableRounds: model.playableRounds,
                onPlay: model.onPlay,
                onBuild: onBuild,
                onClose: { model.dismissFocus() }
            )
            .id(item.station)
            .transition(.opacity)
            .presentationDetents(detents, selection: detentSelection)
            .pofuPaperSheet()
            .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.42)))
            .presentationContentInteraction(.resizes)
        }
        // A quiet day's letter: pick who comes tomorrow.
        .sheet(isPresented: $model.isInviting) {
            InviteSheet(
                choices: VisitorStage.inviteChoices(met: world.metResidents),
                onPick: { model.invite($0) },
                onClose: { model.isInviting = false }
            )
            .presentationDetents([.medium, .large])
            .pofuSheetBackground()
        }
    }

    /// The islands the player has arrived at, home first.
    private var arrivedIslands: [IslandID] {
        var ids = [IslandID.home]
        for id in world.islands where !ids.contains(id) {
            ids.append(id)
        }
        if world.koke.isArrived {
            ids.append(.koke)
        }
        if world.caglayan.isArrived {
            ids.append(.caglayan)
        }
        return ids
    }

    // MARK: Sheet detents

    private static var compactDetent: PresentationDetent {
        .height(CGFloat(IslandLayout.compactSheetHeight))
    }

    /// Compact exists only while a build has the sheet down (§2.3).
    private var detents: Set<PresentationDetent> {
        model.sheetDetent == .compact || model.buildFraming != nil
            ? [Self.compactDetent, .fraction(0.42), .large]
            : [.fraction(0.42), .large]
    }

    private var detentSelection: Binding<PresentationDetent> {
        Binding(
            get: {
                switch model.sheetDetent {
                case .compact: Self.compactDetent
                case .medium: .fraction(0.42)
                case .large: .large
                }
            },
            set: { detent in
                if detent == .large {
                    model.sheetDetent = .large
                } else if detent == Self.compactDetent {
                    model.sheetDetent = .compact
                } else {
                    model.sheetDetent = .medium
                }
            }
        )
    }
}

extension IslandScene where Bubble == EmptyView {
    public init(
        world: WorldSnapshot,
        model: IslandSceneModel,
        home: WorldHomeModel? = nil,
        onPofuTap: (@MainActor () -> Void)? = nil,
        onBuild: (@MainActor (StationID) -> Void)? = nil,
        props: WorldProps? = nil,
        onVisitor: (@MainActor (GameEvent.Kind) -> Void)? = nil
    ) {
        self.init(world: world, model: model, home: home, onPofuTap: onPofuTap, onBuild: onBuild, props: props, onVisitor: onVisitor) { EmptyView() }
    }
}

/// A build moment at one instant.
typealias BuildFrame = (moment: BuildMoment, time: Double)

/// Today's visit and the lawn's small life at one frame (experience v1 §5,
/// §6): what the world canvas draws besides the stations and residents.
struct LifeFrame {
    var visitor: VisitorSnapshot?
    var invitationOpen = false
    var isBedtime = false
    var islandLevel = 1
    /// Seconds since the visitor's arrival began, while it runs.
    var arrival: Double?
    /// The Ambient state is on: critters and the visitor may move.
    var isAmbient = false
    /// The residents' frames now, by id (empty at rest): `ResidentLife`.
    var residents: [String: ResidentLife.Step] = [:]
    /// The frame's time, quantised to the policy's rate; 0 in a still frame.
    var time = 0.0
    /// Dressing mid-puff, with the seconds since it began.
    var leaving: [(piece: DressingPiece, elapsed: Double)] = []
}

// MARK: - One frame

/// Everything at one camera and lens, back to front (look round 3):
///
/// 1. the living sky, its far isles and clouds, pre-graded on the CPU (no
///    shader pass of its own);
/// 2. the world canvas (plate and stations) under the world's grade, the
///    only full-screen shader pass;
/// 3. the characters (residents and Pofu) under the colour script's
///    character light, each graded in its own small rect;
/// 4. the cloud sea, pre-graded and lifted at night;
/// 5. one vignette over the whole world;
/// 6. the HD-2D lite light (bloom, shafts, particles, the practicals'
///    pools and the characters' rims);
/// 7. the screen-space overlays, which are never graded.
private struct SceneFrame<Bubble: View>: View {
    @Environment(\.worldResidentPin) private var residentPin
    let world: WorldSnapshot
    let rig: CameraRig
    let model: IslandSceneModel
    let size: CGSize
    /// Seconds, for the ambient layers; frozen while the scene is settled.
    let time: Double
    /// The frame's date, for brushed props.
    let clock: Date
    /// Depth of field's strength, 0 while the camera moves and a 0.35 s
    /// pull to 1 once it settles (§1.2).
    let rack: Double
    /// The frame policy's say on particles, shafts and flicker.
    let directive: FrameDirective
    let build: BuildFrame?
    let celebrations: Int
    let home: WorldHomeModel?
    let props: WorldProps?
    let onPofuTap: (@MainActor () -> Void)?
    let bubble: Bubble

    @Environment(\.worldLook) private var look
    @Environment(\.worldStillFrame) private var still
    @Environment(\.screenHazeClearing) private var hazeClearing
    @Environment(\.resistSeals) private var resistSeals

    /// The residents' loop now (`ResidentLife`): only while the Ambient state
    /// runs and Reduce Motion is off; a still frame, a settled island and Low
    /// Power Mode hold the rest pose. A screenshot may pin the time
    /// (`worldResidentPin`).
    private func residentSteps(directive: FrameDirective) -> [String: ResidentLife.Step] {
        // At night they are drowsy and still.
        guard !world.isBedtime else { return [:] }
        let elapsed: Double
        var day = ResidentLife.day(of: clock)
        if let pinned = residentPin {
            elapsed = pinned.elapsed
            day = pinned.day
        } else if !still, CritterMotion.moves(under: directive), !model.reduceMotion {
            elapsed = clock.timeIntervalSince(model.visitBegan ?? clock)
        } else {
            return [:]
        }
        let specs = IslandLayout.residents.map { ResidentLife.Spec(id: $0.id.rawValue, home: $0.feet) }
        return ResidentLife.steps(
            of: specs,
            day: day,
            elapsed: elapsed,
            walkable: IslandFootprint.walkable,
            avoid: [IslandLayout.pofu],
            isAmbient: true
        )
    }

    var body: some View {
        let pose = rig.pose
        let z = rig.railPosition
        // Depth in motion (HD-2D): while the camera moves, layers parallax
        // by depth and the depth of field strengthens; both settle to zero.
        let motion = look.hd2d && look.depthMotion && !model.reduceMotion ? rig.motion.parallax(look.tuning.parallax) : CameraMotion.still
        let lookPoint = WorldPoint(x: pose.lookX, y: pose.lookY)
        // HD-2D's tilt-shift: the depth lens, stronger per framing.
        let rigLens = DepthMotion.lens(look.hd2d ? rig.lens.tiltShifted(by: LookTuning.tiltShift(z: z, island: look.tuning.tiltShiftIsland, home: look.tuning.tiltShiftHome)) : rig.lens, motion: motion)
        // At Koke the focus plane is Koke's lawn, not the home lawn's.
        let baseLens = model.island == .koke
            ? Lens(focus: KokeLayout.focusDepth, slab: rigLens.slab, gain: rigLens.gain)
            : model.island == .caglayan ? Lens(focus: CaglayanLayout.focusDepth, slab: rigLens.slab, gain: rigLens.gain) : rigLens
        // Graphics spike: with the depth map's depth of field on, whole-layer
        // blur is off (every layer stays sharp) and the shader blurs per pixel.
        let spike = look.spike
        let spikeDOF = spike.depthOfField && WorldShaders.isAvailable
        // Focus follows the camera: no depth of field while it moves, then
        // a rack focus once it settles.
        let lens = spikeDOF ? Lens(focus: baseLens.focus, slab: baseLens.slab, gain: 0) : Lens(focus: baseLens.focus, slab: baseLens.slab, gain: baseLens.gain * rack)
        let peek = rig.peekTilt
        let device = model.deviceTilt
        let tilt = (x: min(max(peek.x + device.x, -1), 1), y: min(max(peek.y + device.y, -1), 1))
        let offset = CGSize(width: rig.offsetX.value, height: rig.offsetY.value)
        // Stations answer taps in every framing: on the Map and at Home a
        // tap flies to the island and opens the sheet in one gesture.
        let interactive = rig.pinchStart == nil
        let minute = look.hourOverride.map { $0 * 60 }
            ?? world.clock.map { SkyModel.minuteOfDay($0, calendar: .current) } ?? 12 * 60
        // The world's weather (the date's seeded bag, or the screenshot's) and
        // the player's screen haze (wellbeing only): two skies that never mix.
        let conditions = look.weatherOverride
            ?? WeatherForecast.conditions(clock: world.clock, firstDay: world.firstDay, hour: minute / 60, calendar: .current)
        let rawHaze = look.grade ? ScreenHaze.amount(wellbeing: world.wellbeing) : 0
        let atmosphere = look.grade
            ? Atmosphere(conditions: conditions, haze: ScreenHaze.parted(rawHaze, parting: hazeClearing?.partingTarget(at: Date()) ?? 0))
            : .clear
        let baseLight = WorldLight.at(
            hour: minute / 60,
            wellbeing: world.wellbeing,
            calm: world.calm,
            isBedtime: world.isBedtime
        ).withAtmosphere(atmosphere)
        // The colour script's sky, overcast when Pofu is unwell, then the
        // weather's and the haze's.
        let palette = SkyModel.palette(minuteOfDay: minute, isBedtime: world.isBedtime, unwell: look.grade ? baseLight.unwell : 0)
            .atmospheric(atmosphere)
        // The living sky places the sun; the light follows it.
        let light = baseLight.withSun(x: palette.sun.x, y: palette.sun.y)
        // One sun (or moon) for every shadow on the ground (light and shadow v2).
        let shadow = SunShadow.make(light: light, world: world)
        // Cloud shadows by day: Ambient 30 Hz drift, otherwise held (BuildEffects).
        let clouds: CloudShadows.Frame? = look.hd2d
            ? CloudHold.frame(shadow: shadow, directive: directive, conditions: model.power.conditions, ambientTime: still ? 0 : FramePolicy.ambientTime(clock.timeIntervalSinceReferenceDate))
            : nil
        // The night's pools on the lawn, under every object (LS-2).
        let pools = look.hd2d
            ? LightField.make(world: world, light: light, guestNight: VisitorStage.isGuestNight(world.visitor))
            : LightField(sources: [], ambientFloor: 0, moonRim: 0, moonColour: .zero)
        // Without the runtime grade, the time of day tints the painted
        // world as before (game design §15: no night versions are
        // generated); with it, the colour script does the whole job.
        // Without the shader library the grade pass cannot run, so the
        // time-of-day tint stands in.
        let tint = look.grade && WorldShaders.isAvailable ? Color.white : palette.grade.color
        let baseGrade = look.grade ? look.gradeOverride ?? light.grade : WorldGrade.neutral
        // At Koke the colour comes back with the stage.
        let grade = model.island == .koke && world.koke.isArrived ? KokeLayout.graded(baseGrade, stage: world.koke.stage) : baseGrade
        let characterGrade = look.grade ? light.characterGrade : WorldGrade.neutral
        // The sky and the cloud sea are pre-graded: no shader pass of their own.
        let skyBase = palette.graded(by: grade)
        // Behind Koke at its first stages the sky deepens, so the island's
        // silhouette sits off it (sky and weather v1 §2.4).
        let sky = model.island == .koke && world.koke.isArrived ? KokeStageLook(stage: world.koke.stage).sky(skyBase) : skyBase
        let sea = CloudSea.Colours(cell: light.cell, grade: grade, unwell: look.grade ? light.unwell : 0)
        // Where the cloud-sea's crest sits (the height fog's densest line):
        // the strip's lobes top out about 140 pt above the screen's bottom.
        let fogSeaLine = Double(size.height) - 140 - CloudSea.rise(z: z, pose: pose, height: Double(size.height))
        // Graphics spike: the key, fill, practicals and rim on the painted art.
        let relight: RelightRig? = (spike.normalLighting || spike.debug == .normals) && WorldShaders.isAvailable
            ? RelightRig.make(
                light: light,
                emitters: IslandLayout.emitters.filter { e in
                    e.station.map { id in (world.stations.first(where: { $0.id == id })?.level ?? 0) > 0 } ?? true
                },
                strength: spike.debug == .normals ? 1 : spike.lightStrength
            )
            : nil
        let depthMap: Image? = (spikeDOF && rack > 0.001) || spike.debug == .depth
            ? SpikeDepthMap.image(world: world, pose: pose, offset: offset, size: size, art: look.art, koke: model.island == .koke && world.koke.isArrived, caglayan: model.island == .caglayan && world.caglayan.isArrived)
            : nil
        let field: DepthOfField = {
            var f = spike.field(focus: SpikeDepthMap.focusDepth(model.focus, island: model.island), focused: model.focus != nil, z: z)
            f.maxRadius *= rack
            return f
        }()
        // Weather crossfades over 8 s (6 to 10 s, section 2.2).
        let animation: Animation? = still ? nil : .easeInOut(duration: atmosphere.isClear ? 2.5 : 8)
        // Settled: the ambient layers hold still, so the frame is cached.
        let ambientPaused = look.hd2d && !model.needsFrames && build == nil
        // The visit and the lawn's small life: the critters move only in the
        // Ambient state, and a still frame is the rest pose.
        let life = LifeFrame(
            visitor: world.visitor,
            invitationOpen: world.invitationOpen,
            isBedtime: world.isBedtime,
            islandLevel: world.islandLevel,
            arrival: model.arrivalElapsed(at: clock),
            isAmbient: !still && CritterMotion.moves(under: directive),
            residents: residentSteps(directive: directive),
            time: still ? 0 : FramePolicy.ambientTime(time),
            leaving: model.dressingLeaving(at: clock)
        )

        // Seen from the harbor, Koke is a snoring hump on the horizon.
        let farKoke: FarSky.Look.Koke? = model.island == .harbor && world.koke.phase != .hidden
            ? FarSky.Look.Koke(lit: world.koke.giftUnlocked)
            : nil

        ZStack(alignment: .topLeading) {
            ZStack(alignment: .topLeading) {
                LivingSky(palette: sky, offset: offset, far: FarSky.Look(z: z, cell: light.cell, grade: grade, koke: farKoke, mist: atmosphere.mist))
                    .environment(\.worldAmbientPaused, ambientPaused)
                    .animation(animation, value: sky)

                // The rainbow, soft and pastel, behind the island and its fog.
                WeatherRainbow(atmosphere: atmosphere, size: size, seaLine: fogSeaLine, offset: offset)

                // Height fog behind the island, densest at the cloud-sea line.
                FogCards(layer: .behind, horizon: sky.horizon, mist: atmosphere.mist, offset: offset, size: size, seaLine: fogSeaLine)
                    .environment(\.worldAmbientPaused, ambientPaused)

                WorldCanvas(
                    world: world,
                    layer: .environment,
                    lens: lens,
                    z: z,
                    scale: pose.scale,
                    tilt: tilt,
                    motion: motion,
                    look: lookPoint,
                    isInteractive: interactive,
                    build: build,
                    model: model,
                    clock: clock,
                    characterGrade: characterGrade,
                    life: life,
                    shadow: shadow,
                    pools: pools,
                    clouds: clouds
                )
                .frame(width: IslandLayout.canvasWidth, height: IslandLayout.canvasHeight, alignment: .topLeading)
                .cameraTransform(pose: pose, viewportWidth: Double(size.width), offset: offset)
                .tinted(tint, isEnabled: !(look.grade && WorldShaders.isAvailable))
                .frame(width: size.width, height: size.height, alignment: .topLeading)
                .environment(\.worldAmbientPaused, ambientPaused)
                // The world's grade: plates and stations only. The vignette
                // is drawn once over everything below.
                .modifier(GradeEffect(grade: grade.withoutVignette, isEnabled: look.grade))
                .animation(animation, value: grade)

                // Today's resist seals on the earth beside Pofu's door: an
                // earth detail, graded with the world, still at rest.
                ResistSealsLayer(tally: resistSeals, pose: pose, offset: offset, size: size, night: world.isBedtime)
                    .tinted(tint, isEnabled: !(look.grade && WorldShaders.isAvailable))
                    .modifier(GradeEffect(grade: grade.withoutVignette, isEnabled: look.grade))

                // The characters keep their warmth: the colour script's
                // character light, graded per sprite.
                WorldCanvas(
                    world: world,
                    layer: .characters,
                    lens: lens,
                    z: z,
                    scale: pose.scale,
                    tilt: tilt,
                    motion: motion,
                    look: lookPoint,
                    isInteractive: interactive,
                    build: build,
                    model: model,
                    clock: clock,
                    characterGrade: characterGrade,
                    life: life,
                    shadow: shadow,
                    pools: pools,
                    clouds: clouds
                )
                .frame(width: IslandLayout.canvasWidth, height: IslandLayout.canvasHeight, alignment: .topLeading)
                .cameraTransform(pose: pose, viewportWidth: Double(size.width), offset: offset)
                .tinted(tint, isEnabled: !(look.grade && WorldShaders.isAvailable))
                .frame(width: size.width, height: size.height, alignment: .topLeading)

                PofuLayer(
                    world: world,
                    pose: pose,
                    lens: lens,
                    z: z,
                    tilt: tilt,
                    motion: motion,
                    size: size,
                    offset: offset,
                    grade: tint,
                    characterGrade: characterGrade,
                    celebrations: celebrations,
                    home: home,
                    model: model,
                    onPofuTap: onPofuTap,
                    part: .body,
                    bubble: bubble
                )

                if let props {
                    // The jar, the lantern and the pots share the island's
                    // transform: they never lag or bob (§1.4).
                    props.world(WorldPropsFrame(pose: pose, size: size, offset: offset, z: z, isFocused: model.focus != nil || model.hasSheet, model: model))
                }

                CloudSea(colours: sea, offset: offset, rise: CloudSea.rise(z: z, pose: pose, height: Double(size.height)))
                    .environment(\.worldAmbientPaused, ambientPaused)
                    .animation(animation, value: sea)

                // One fog card across the island's base: the foot dissolves,
                // the top stays clear.
                FogCards(layer: .front, horizon: sky.horizon, mist: atmosphere.mist, offset: offset, size: size, seaLine: fogSeaLine)
                    .environment(\.worldAmbientPaused, ambientPaused)

                // Rain, splash ticks and puddle glints in front of the island.
                WeatherRain(atmosphere: atmosphere, pose: pose, offset: offset, size: size, horizon: sky.horizon)
                    .environment(\.worldAmbientPaused, ambientPaused)

                // The screen haze (the player's sky): from the harbor side.
                ScreenHazeLayer(haze: rawHaze, sunX: palette.sun.x, offset: offset, size: size, seaLine: fogSeaLine)
                    .environment(\.worldAmbientPaused, ambientPaused)

                if look.grade {
                    VignetteOverlay(strength: grade.vignette)
                        .animation(animation, value: grade.vignette)
                }

                if look.hd2d {
                    HD2DLayer(
                        world: world,
                        light: light,
                        pose: pose,
                        offset: offset,
                        size: size,
                        time: still ? 0 : time,
                        motion: motion,
                        focus: lens.focus,
                        tilt: tilt,
                        art: look.art,
                        litOverlays: look.litOverlays,
                        harborFade: model.island == .harbor ? 1 : max(0, 1 - max(z, 0) / 0.8) * (model.focus == nil ? 1 : 0),
                        relit: relight != nil,
                        guestNight: VisitorStage.isGuestNight(world.visitor),
                        directive: directive
                    )
                }
            }
            .frame(width: size.width, height: size.height, alignment: .topLeading)
            .environment(\.worldRelight, relight)
            .environment(\.worldHorizon, sky.horizon)
            .environment(\.worldNight, light.night)
            .modifier(SpikeDepthOfFieldEffect(depth: depthMap, field: field, size: size, showsDepth: spike.debug == .depth))

            PofuLayer(
                world: world,
                pose: pose,
                lens: lens,
                z: z,
                tilt: tilt,
                motion: motion,
                size: size,
                offset: offset,
                grade: tint,
                characterGrade: characterGrade,
                celebrations: celebrations,
                home: home,
                model: model,
                onPofuTap: onPofuTap,
                part: .overlay,
                bubble: bubble
            )

            ScreenOverlays(world: world, pose: pose, z: z, size: size, offset: offset, build: build, model: model)

            if let props {
                props.screen(WorldPropsFrame(pose: pose, size: size, offset: offset, z: z, isFocused: model.focus != nil || model.hasSheet, model: model))
            }

            if look.frameMeter {
                FrameMeterOverlay()
                    .padding(.top, 62)
                    .padding(.leading, 12)
            }
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

/// The world objects on the canvas, back to front by depth: either the
/// environment (other isles, the plate, the stations) or the characters
/// (the residents), which are drawn in their own layer so the world's grade
/// never turns them lavender. The layout keeps every resident in front of
/// the stations it overlaps (`IslandFootprintTests`), so the split never
/// changes what hides what.
private struct WorldCanvas: View {
    enum Layer {
        case environment
        case characters
    }

    let world: WorldSnapshot
    let layer: Layer
    let lens: Lens
    let z: Double
    let scale: Double
    let tilt: (x: Double, y: Double)
    /// The camera's motion, for depth in motion.
    let motion: CameraMotion
    /// Where the camera looks, in world units.
    let look: WorldPoint
    let isInteractive: Bool
    let build: BuildFrame?
    let model: IslandSceneModel
    /// The frame's date, for brushed props.
    let clock: Date
    /// The residents' light (the colour script's character grade).
    let characterGrade: WorldGrade
    /// Today's visit and the lawn's small life at this frame.
    let life: LifeFrame
    /// The sun's (or the moon's) shadow on the ground.
    let shadow: SunShadow
    /// The light field whose pools lie on the lawn.
    let pools: LightField
    /// The cloud shadows by day, or nil.
    var clouds: CloudShadows.Frame?

    var body: some View {
        ZStack(alignment: .topLeading) {
            if layer == .environment {
                otherIsles
                kokeIsle
                caglayanIsle
                ForEach(IslandLayout.plateBands(islandLevel: life.islandLevel), id: \.art) { band in
                    if let sprite = WorldArt.sprite(band.art) {
                        DepthImage(
                            name: band.art,
                            sprite: sprite,
                            level: lens.blurLevel(depth: band.depth),
                            anchor: canvasPoint(.zero, depth: band.depth)
                        )
                    }
                }
                // Every static caster's shadow and pad in one image, on the
                // ground between the plate and the objects (LS-1).
                SunShadowLayer(
                    sun: shadow,
                    layout: ShadowCasters.Signature(stations: shadowStations, islandLevel: life.islandLevel)
                ) { point in
                    canvasPoint(point, depth: IslandLayout.depth(ofY: ShadowTuning.layerY))
                }
                if let clouds {
                    CloudShadowLayer(frame: clouds) { point in
                        canvasPoint(point, depth: IslandLayout.depth(ofY: ShadowTuning.layerY))
                    }
                }
                GroundPoolLayer(field: pools) { point in
                    canvasPoint(point, depth: IslandLayout.depth(ofY: ShadowTuning.layerY))
                }
                if let build {
                    LevelUpPad(moment: build.moment, time: build.time) { point in
                        canvasPoint(point, depth: IslandLayout.depth(ofY: ShadowTuning.layerY))
                    }
                }
            }
            ForEach(objects) { object in
                objectView(object)
            }
        }
    }

    /// The stations the shadow layer is baked for: during a level-up the
    /// built station keeps its old silhouette until the art swaps, so the
    /// bake rebuilds while the burst covers it.
    private var shadowStations: [StationStatus] {
        guard let build else { return world.stations }
        return world.stations.map { status in
            guard status.id == build.moment.station else { return status }
            var shown = status
            shown.level = build.moment.shownLevel(at: build.time)
            return shown
        }
    }

    // MARK: Objects

    private struct Object: Identifiable {
        enum Kind {
            case station(StationStatus)
            case resident(IslandLayout.Resident)
            /// A piece of the lawn's dressing; `elapsed` is set while it leaves in the reveal's puff.
            case dressing(DressingPiece, elapsed: Double?)
            case critter(Critter)
            case visitor(VisitorStage.Placed)
            /// A door in the earth face or the hive (`HomeFixtures`).
            case fixture(HomeFixtures.Placed)
            /// The moss Koke gave, once it is healed.
            case gift
            /// The pool's fountain, once Çağlayan flows.
            case fountain
            /// The island's growth at this level (`IslandGrowth`).
            case growth(GrowthPiece)
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
        for status in world.stations where layer == .environment && status.island == .home && status.isOpen {
            guard let slot = IslandLayout.stationAnchors[status.id] else { continue }
            // Containment: never past the walkable edge, whatever the art.
            let art = IslandLayout.stationArt(status.id, level: max(status.level, 1))?.name
            let footprint = status.level > 0 ? art.map(IslandFootprint.footprint(of:)) ?? IslandFootprint.buildSpot : IslandFootprint.buildSpot
            let anchor = IslandFootprint.clamped(slot, footprint: footprint)
            objects.append(Object(id: "station-\(status.id)", kind: .station(status), anchor: anchor, depth: IslandLayout.depth(ofY: anchor.y)))
        }
        for resident in IslandLayout.residents where layer == .characters {
            guard let station = world.stations.first(where: { $0.id == resident.station }), station.level > 0 else { continue }
            let rest = IslandFootprint.clamped(resident.feet, footprint: IslandFootprint.footprint(of: resident.art))
            // The loop's walk moves the whole resident (shadow and tap target
            // follow); the rest spot is where a settled island holds them.
            let step = life.residents[resident.id.rawValue] ?? .rest
            let feet = WorldPoint(x: rest.x + step.dx, y: rest.y + step.dy)
            objects.append(Object(id: "resident-\(resident.id)", kind: .resident(resident), anchor: feet, depth: IslandLayout.depth(ofY: feet.y)))
        }
        // The lawn's small life (§6) and today's visit (§5): nothing of it is
        // drawn on the Archipelago.
        if z >= WorldHitTest.archipelagoZ {
            if layer == .environment {
                // Dressing joins the station pass, back to front with it.
                let shown = IslandDressing.pieces(atLevel: life.islandLevel)
                for piece in shown {
                    objects.append(Object(id: "dressing-\(piece.id)", kind: .dressing(piece, elapsed: nil), anchor: piece.point, depth: IslandLayout.depth(ofY: piece.point.y)))
                }
                let home = world.stations.filter { $0.island == .home }
                let atTop = !home.isEmpty && home.allSatisfy { $0.level >= $0.maxLevel }
                for fixture in HomeFixtures.placed(islandLevel: life.islandLevel, homeStationsAtTop: atTop) {
                    objects.append(Object(id: "fixture-\(fixture.id)", kind: .fixture(fixture), anchor: fixture.point, depth: IslandLayout.depth(ofY: fixture.point.y)))
                }
                for piece in IslandGrowth.pieces(atLevel: life.islandLevel) {
                    objects.append(Object(id: "growth-\(piece.id)", kind: .growth(piece), anchor: piece.point, depth: piece.depth))
                }
                if world.koke.giftUnlocked {
                    let spot = KokeLayout.homeGift
                    objects.append(Object(id: "gift-moss", kind: .gift, anchor: spot, depth: IslandLayout.depth(ofY: spot.y)))
                }
                if world.caglayan.giftUnlocked, let pond = IslandLayout.stationAnchors[.pond], (world.stations.first { $0.id == .pond }?.level ?? 0) > 0 {
                    let spot = WorldPoint(x: pond.x + CaglayanLayout.homeFountainOffset.x, y: pond.y + CaglayanLayout.homeFountainOffset.y)
                    objects.append(Object(id: "gift-fountain", kind: .fountain, anchor: spot, depth: IslandLayout.depth(ofY: spot.y) + 0.001))
                }
                for entry in life.leaving where !shown.contains(where: { $0.id == entry.piece.id }) {
                    objects.append(Object(id: "dressing-\(entry.piece.id)", kind: .dressing(entry.piece, elapsed: entry.elapsed), anchor: entry.piece.point, depth: IslandLayout.depth(ofY: entry.piece.point.y)))
                }
            } else {
                // Critters and the visit join the characters' pass.
                for critter in Critters.critters(atLevel: life.islandLevel) where perchStands(critter) {
                    objects.append(Object(id: "critter-\(critter.id)", kind: .critter(critter), anchor: critter.rest, depth: IslandLayout.depth(ofY: critter.rest.y)))
                }
                for part in VisitorStage.parts(visitor: life.visitor, invitationOpen: life.invitationOpen, isBedtime: life.isBedtime) {
                    objects.append(Object(id: "visitor-\(part.id)", kind: .visitor(part), anchor: part.feet, depth: part.depth))
                }
            }
        }
        return objects.sorted { $0.depth < $1.depth }
    }

    /// Whether what a critter perches on is built (a bird needs its roof, a
    /// frog its pond).
    private func perchStands(_ critter: Critter) -> Bool {
        guard case .station(let station) = critter.perch else { return true }
        return (world.stations.first { $0.id == station }?.level ?? 0) > 0
    }

    @ViewBuilder
    private func objectView(_ object: Object) -> some View {
        let point = canvasPoint(object.anchor, depth: object.depth)
        let level = lens.blurLevel(depth: object.depth)
        switch object.kind {
        case .station(let status):
            let moment: BuildFrame? = build.flatMap { $0.moment.station == status.id ? $0 : nil }
            StationView(
                status: status,
                point: point,
                level: level,
                z: z,
                build: moment,
                isFocused: model.focus == .station(status.id),
                sway: model.sway(of: IslandLayout.touchID(status.id), at: clock),
                pulse: model.pulses["station-\(status.id.rawValue)", default: 0]
            )
                .overlay {
                    hitArea(
                        box: IslandLayout.stationHitBox,
                        at: point,
                        label: WorldStrings.stationName(status.id),
                        value: status.level > 0 ? WorldStrings.level(status.level, of: status.maxLevel) : "",
                        activate: { model.focusStation(status.id) }
                    )
                }
        case .resident(let resident):
            let step = life.residents[resident.id.rawValue] ?? .rest
            let reaction = model.reactions.age(of: resident.id.rawValue, at: clock).flatMap { ResidentLife.reaction(age: $0) }
            let lift = (build.map { $0.moment.station == resident.station ? $0.moment.residentLift(at: $0.time) : 0 } ?? 0)
                + step.hop + (reaction?.hop ?? 0)
            let focused = model.focus == .resident(resident.id) || model.focus == .station(resident.station)
            let pose = build.flatMap { $0.moment.station == resident.station ? $0.moment.residentPose(at: $0.time) : nil }
                ?? resident.idlePose(isBedtime: world.isBedtime, isFocused: focused,
                                     event: model.reactions.event(of: resident.id.rawValue, at: clock))
                .lifePose(step.pose)
            ResidentView(
                resident: resident,
                art: resident.art(for: pose),
                point: point,
                level: level,
                lift: lift,
                grade: characterGrade,
                pulse: model.pulses["resident-\(resident.id.rawValue)", default: 0],
                breath: step.breath,
                lean: step.lean
            )
                .overlay {
                    hitArea(
                        box: IslandLayout.residentHitBox,
                        at: point,
                        label: "\(WorldStrings.residentName(resident.id)), \(WorldStrings.stationName(resident.station))",
                        value: "",
                        activate: { model.focusResident(resident.id) }
                    )
                }
        case .dressing(let piece, let elapsed):
            DressingView(
                piece: piece,
                point: point,
                level: level,
                sway: model.sway(of: IslandLife.dressingID(piece), at: clock),
                leave: elapsed.flatMap { DressingReveal.frame(elapsed: $0) }
            )
        case .fixture(let fixture):
            FixtureView(art: fixture.art, point: point, level: level)
        case .growth(let piece):
            GrowthView(piece: piece, point: point, level: level, time: life.isAmbient ? life.time : 0)
        case .gift:
            MossGiftView(point: point)
        case .fountain:
            HomeFountainView(point: point, time: life.isAmbient ? life.time : nil)
        case .critter(let critter):
            CritterView(
                critter: critter,
                point: point,
                level: level,
                pose: CritterMotion.pose(of: critter, at: life.time, isAmbient: life.isAmbient),
                sway: model.sway(of: IslandLife.critterID(critter), at: clock),
                grade: characterGrade
            )
                .background { MovingShadow(art: critter.kind.art, feet: point, sun: shadow) }
        case .visitor(let placed):
            let style = life.visitor.map { VisitorStage.arrivalStyle(for: $0.slot) } ?? .dandelion
            let beat = life.visitor == nil ? nil : life.arrival.map { VisitorStage.arrival(style: style, elapsed: $0) }
            let words = WorldStrings.visitorPart(placed.part, visitor: life.visitor)
            VisitorPartView(
                part: placed,
                visitor: life.visitor,
                point: point,
                level: level,
                arrival: beat,
                bob: VisitorStage.idleBob(at: life.time, isAmbient: life.isAmbient),
                grade: characterGrade,
                pulse: model.pulses["visitor-\(placed.part.rawValue)", default: 0]
            )
                .background {
                    if placed.part == .visitor, let resident = life.visitor?.resident {
                        MovingShadow(art: "visitor-\(resident.rawValue)", feet: point, sun: shadow)
                    }
                }
                .overlay {
                    hitArea(
                        box: VisitorStage.hitBox(of: placed.part),
                        at: point,
                        label: words.label,
                        value: words.hint,
                        activate: { model.visitorTapped(placed.part, visitor: life.visitor) }
                    )
                }
        }
    }

    /// An invisible accessibility element over a box, one per target.
    /// Taps go through the one resolver (`WorldHitTest`), so it answers no
    /// touches itself.
    private func hitArea(
        box: WorldBox,
        at point: CGPoint,
        label: String,
        value: String,
        activate: @escaping @MainActor () -> Void
    ) -> some View {
        Color.clear
            .frame(width: CGFloat(box.width), height: CGFloat(box.height))
            .accessibilityElement()
            .accessibilityLabel(Text(verbatim: label))
            .accessibilityValue(Text(verbatim: value))
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { activate() }
            .allowsHitTesting(false)
            .position(x: point.x + CGFloat(box.midX), y: point.y + CGFloat(box.midY))
    }

    // MARK: Other islands

    @ViewBuilder
    private var otherIsles: some View {
        // Far away from Home; leave the render tree there.
        if z < 1.7 || model.island != .home {
            ForEach(IslandLayout.isles) { isle in
                if let sprite = WorldArt.sprite(isle.art) {
                    let arrived = world.islands.contains(isle.id)
                    // Soft once you are on an island, sharp on the map
                    // (§5.1); 35 % at the Island framing.
                    // A focus pushes in on one station: the neighbours,
                    // blurred and huge at that scale, step aside. At the
                    // Island framing they have left the frame to the far
                    // isles of the living sky (look round 3).
                    let here = isle.id == model.island
                    let fade = here ? 1 : max(0, 1 - max(z, 0) / 0.8) * (model.focus == nil ? 1 : 0)
                    DepthImage(
                        name: isle.art,
                        sprite: sprite,
                        level: min(max(z, 0), 1),
                        anchor: canvasPoint(isle.center, depth: 0),
                        opacity: (arrived ? 1 : 0.55) * fade
                    )
                    .saturation(arrived ? 1 : 0.35)
                    ForEach(islandPieces(on: isle.id)) { piece in
                        if let sprite = WorldArt.sprite(piece.art) {
                            DepthImage(
                                name: piece.art,
                                sprite: sprite,
                                level: min(max(z, 0), 1),
                                anchor: canvasPoint(
                                    WorldPoint(x: isle.center.x + piece.offset.x, y: isle.center.y + piece.offset.y),
                                    depth: 0
                                ),
                                opacity: (arrived ? 1 : 0.55) * fade
                            )
                            .saturation(arrived ? 1 : 0.35)
                        }
                    }
                }
            }
        }
    }

    /// Koke's island, once it can be visited: the same fade as the other
    /// isles, desaturated on the Map by how healed it is.
    @ViewBuilder
    private var kokeIsle: some View {
        if world.koke.isArrived, z < 1.7 || model.island != .home {
            let here = model.island == .koke
            let fade = here ? 1 : max(0, 1 - max(z, 0) / 0.8) * (model.focus == nil ? 1 : 0)
            KokeIsleView(
                stage: world.koke.stage,
                swellAge: model.koke.swellStart.map { clock.timeIntervalSince($0) },
                reduceMotion: model.reduceMotion,
                point: canvasPoint(KokeLayout.center, depth: here ? KokeLayout.focusDepth : 0),
                bounceTime: here && life.isAmbient ? life.time : nil
            )
            .saturation(here ? 1 : KokeLayout.saturation(stage: world.koke.stage))
            .opacity(fade)
        }
    }

    /// Çağlayan's island, once it can be visited: like Koke's, faded out on the
    /// Map by nothing (it keeps its colour) and out of frame at Home.
    @ViewBuilder
    private var caglayanIsle: some View {
        if world.caglayan.isArrived, z < 1.7 || model.island != .home {
            let here = model.island == .caglayan
            let fade = here ? 1 : max(0, 1 - max(z, 0) / 0.8) * (model.focus == nil ? 1 : 0)
            CaglayanIsleView(
                stage: world.caglayan.stage,
                swellAge: model.caglayan.swellStart.map { clock.timeIntervalSince($0) },
                reduceMotion: model.reduceMotion,
                point: canvasPoint(CaglayanLayout.center, depth: here ? CaglayanLayout.focusDepth : 0),
                time: here && life.isAmbient ? life.time : nil
            )
            .opacity(fade)
        }
    }

    /// What stands on another island, back to front: its built stations and their dressing, and its
    /// cast (`IslandLayout.scenery`, `IslandLayout.cast`).
    private func islandPieces(on island: IslandID) -> [IslandPiece] {
        let levels = Dictionary(world.stations.map { ($0.id, $0.level) }, uniquingKeysWith: max)
        let cast = IslandLayout.cast(on: island).map { IslandPiece(id: "cast-\($0.id)", art: castArt($0), offset: $0.offset) }
        return (IslandLayout.scenery(on: island, levels: levels) + cast).sorted { $0.offset.y < $1.offset.y }
    }

    /// A cast member's sprite: Simit's pose follows the cart, the hour and Pofu's calm ring (`SimitPose`);
    /// the goat coils rope once the pier is going up (`GoatPose`).
    private func castArt(_ member: IslandCastMember) -> String {
        let hopping = build?.moment.residentPose(at: build?.time ?? 0) == .happy
        if member.id == "goat" {
            let pier = world.stations.first { $0.id == .pier }?.level ?? 0
            let event = (build?.moment.station == .pier && hopping ? ResidentEvent.stationLevelledUp : nil)
                ?? model.reactions.event(of: member.id, at: clock)
            return GoatPose.pose(pierLevel: pier, isBedtime: world.isBedtime, event: event).art
        }
        guard member.id == "simit" else { return member.art }
        let level = world.stations.first { $0.id == .bagelCart }?.level ?? 0
        let isStartled = build?.moment.station == .bagelCart && (build?.moment.residentPose(at: build?.time ?? 0) == .surprised)
        let event = (build?.moment.station == .bagelCart && hopping ? ResidentEvent.stationLevelledUp : nil)
            ?? model.reactions.event(of: member.id, at: clock)
        return SimitPose.pose(bagelCartLevel: level, calmIsFull: world.calmIsFull, isBedtime: world.isBedtime, isStartled: isStartled, event: event).art
    }

    // MARK: Placement

    /// A world point on the canvas, shifted by parallax: objects in front
    /// of the focus plane move one way, those behind it the other (§12.3 a),
    /// from the peek or tilt and, while the camera moves, from its motion.
    private func canvasPoint(_ point: WorldPoint, depth: Double) -> CGPoint {
        let origin = IslandLayout.canvasOrigin
        let s = max(scale, 0.01)
        let px = (depth - lens.focus) * tilt.x * 0.12 / s
        let py = (depth - lens.focus) * tilt.y * 0.06 / s
        let m = DepthMotion.shift(point: point, depth: depth, focus: lens.focus, look: look, motion: motion)
        return CGPoint(x: origin.x + point.x + px + m.x, y: origin.y + point.y + py + m.y)
    }
}

/// A station: its contact shadow and vignette at its level, an empty build
/// spot, or a labelled placeholder where there is no art yet. During its
/// build moment it squashes and pops around its footprint, swaps its art
/// inside the squash, and throws puffs and sparkles.
private struct StationView: View {
    let status: StationStatus
    let point: CGPoint
    let level: Double
    let z: Double
    let build: BuildFrame?
    /// The camera is on this station: its painted parts get a small idle life.
    var isFocused = false
    /// A brushing finger's sway, in degrees about the base (§1.3).
    var sway = 0.0
    /// Bumped by every tap on the station: a squish.
    var pulse = 0

    var body: some View {
        let shown = build.map { $0.moment.shownLevel(at: $0.time) } ?? status.level
        let squash = build.map { $0.moment.stationScale(at: $0.time) } ?? (x: 1, y: 1)
        let anchor = UnitPoint(x: point.x / IslandLayout.canvasWidth, y: point.y / IslandLayout.canvasHeight)
        ZStack(alignment: .topLeading) {
            if shown > 0 {
                let ground = ContactShadow.station(art: IslandLayout.stationArt(status.id, level: shown)?.name, isWater: status.id == .pond)
                ContactShadow(width: CGFloat(ground.width), height: CGFloat(ground.height), strength: ground.strength)
                    .position(x: point.x + CGFloat(ground.dx), y: point.y + CGFloat(ground.dy))
                if let art = IslandLayout.stationArt(status.id, level: shown), let sprite = WorldArt.sprite(art.name) {
                    DepthImage(name: art.name, sprite: sprite, level: level, anchor: point)
                        .modifier(FocusLife(isActive: isFocused && build == nil, anchor: anchor))
                    if shown >= 2, !IslandLayout.hasLevelArt(status.id, level: shown), z < 1.6, let top = sprite.sharp {
                        LevelBadge(level: shown)
                            .opacity(min(max((1.6 - z) / 0.3, 0), 1))
                            .position(x: point.x + CGFloat(top.maxX) - 8, y: point.y + CGFloat(top.minY) + 10)
                    }
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
        .scaleEffect(x: CGFloat(squash.x), y: CGFloat(squash.y), anchor: anchor)
        .modifier(TapSquish(trigger: pulse, anchor: anchor))
        .rotationEffect(.degrees(sway), anchor: anchor)
        .overlay {
            if let build {
                BuildParticles(moment: build.moment, time: build.time, point: point)
                LevelUpBloom(moment: build.moment, time: build.time, point: point)
            }
        }
    }
}

/// A focused station's idle life: a barely-there sway and breath about its
/// base, so a held focus never reads as a still photograph. Pure transforms
/// (no blur, no extra pass); the timeline runs at 30 fps and only while the
/// station is focused, then pauses, so a settled world stays a cached frame.
/// Off under Reduce Motion, Low Power Mode and the still frame.
private struct FocusLife: ViewModifier {
    let isActive: Bool
    let anchor: UnitPoint

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.worldStillFrame) private var still

    func body(content: Content) -> some View {
        let live = isActive && !reduceMotion && !still && !ProcessInfo.processInfo.isLowPowerModeEnabled
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !live)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let sway = live ? sin(t * 1.7) * 0.6 : 0
            let breath = live ? 1 + sin(t * 2.4 + 1) * 0.006 : 1
            content
                .rotationEffect(.degrees(sway), anchor: anchor)
                .scaleEffect(x: 1, y: CGFloat(breath), anchor: anchor)
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
    /// The baked sprite of the resident's pose (`Resident.art(for:)`).
    let art: String
    let point: CGPoint
    let level: Double
    /// World units off the ground (a hop).
    var lift: Double = 0
    /// The colour script's character light.
    var grade: WorldGrade = .neutral
    /// Bumped by every tap on the resident: a squish.
    var pulse = 0
    /// The loop's breath (1.0 to 1.012) and lean (degrees), about the feet.
    var breath = 1.0
    var lean = 0.0

    var body: some View {
        let anchor = UnitPoint(x: point.x / IslandLayout.canvasWidth, y: point.y / IslandLayout.canvasHeight)
        ZStack(alignment: .topLeading) {
            ContactShadow(width: 24, height: 6, strength: 1 - min(lift / 20, 0.5))
                .position(x: point.x, y: point.y)
            if let sprite = WorldArt.sprite(art) {
                DepthImage(name: art, sprite: sprite, level: level, anchor: CGPoint(x: point.x, y: point.y - CGFloat(lift)), grade: grade)
                    .scaleEffect(breath, anchor: anchor)
                    .rotationEffect(.degrees(lean), anchor: anchor)
            }
        }
        .modifier(TapSquish(
            trigger: pulse,
            anchor: UnitPoint(x: point.x / IslandLayout.canvasWidth, y: point.y / IslandLayout.canvasHeight)
        ))
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
    let motion: CameraMotion
    let size: CGSize
    let offset: CGSize
    let grade: Color
    /// The colour script's character light: Pofu keeps his warmth at night.
    let characterGrade: WorldGrade
    let celebrations: Int
    let home: WorldHomeModel?
    let model: IslandSceneModel
    let onPofuTap: (@MainActor () -> Void)?
    /// Pofu himself (under the character light), or his map pin and speech
    /// bubble (UI, never graded).
    let part: Part
    let bubble: Bubble

    enum Part {
        case body
        case overlay
    }

    @Environment(\.worldStillFrame) private var still
    @Environment(\.worldRelight) private var relight
    @Environment(\.worldLook.spike.debug) private var spikeDebug

    /// Pofu's art is 64 units wide (154 pt at Home, ADR-0018).
    static var artWidth: Double {
        64
    }

    var body: some View {
        let depth = IslandLayout.depth(ofY: IslandLayout.pofu.y)
        let s = pose.scale
        let projected = pose.project(IslandLayout.pofu, width: Double(size.width))
        let moving = DepthMotion.shift(
            point: IslandLayout.pofu,
            depth: depth,
            focus: lens.focus,
            look: WorldPoint(x: pose.lookX, y: pose.lookY),
            motion: motion
        )
        let parallaxX = (depth - lens.focus) * tilt.x * 0.12 + moving.x * s
        let parallaxY = (depth - lens.focus) * tilt.y * 0.06 + moving.y * s
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
            if part == .body, painted > 0.01 {
                if let sprite = WorldArt.sprite("pofu") {
                    DepthImage(name: "pofu", sprite: sprite, level: level, anchor: feet, scale: CGFloat(s), opacity: painted, skipsSharp: true, grade: characterGrade)
                        .colorMultiply(grade)
                }
                if weights.sharp * painted > DepthWeights.visibleThreshold {
                    companion(feet: feet, scale: s)
                        .colorMultiply(grade)
                        .opacity(weights.sharp * painted)
                }
            }
            if part == .overlay, painted < 0.99 {
                PofuPin()
                    .opacity(1 - painted)
                    .position(x: feet.x, y: feet.y - 15)
            }
            if part == .overlay, bubbleOpacity > 0.01 {
                let head = feet.y - CGFloat(62 * s)
                bubble
                    .frame(maxWidth: min(size.width - 40, 320))
                    .frame(width: size.width, height: max(head - 4, 0), alignment: .bottom)
                    .offset(x: feet.x - size.width / 2)
                    .opacity(bubbleOpacity)
            }
        }
    }

    /// What shows on his face: what just happened to the residents, then
    /// the night, the visitor and the wellbeing band (`PofuMoodSource`).
    private var mood: PofuMood {
        let now = Date()
        let event = ResidentReactions.everyone.lazy.compactMap { model.reactions.event(of: $0, at: now) }.first
        return PofuMoodSource.mood(
            band: world.band,
            isBedtime: world.isBedtime,
            calmIsFull: world.calmIsFull,
            visitorPresent: world.visitor != nil,
            event: event
        )
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
            energy: home?.cheekEnergy(uncollected: world.pending.total.units)
                ?? CheekStep(uncollected: world.pending.total.units).companionEnergy,
            celebrations: celebrations,
            art: art,
            onTap: {
                if model.focus != nil || model.sheet != nil {
                    model.dismissFocus()
                } else {
                    onPofuTap?()
                }
            }
        )
        // A still frame never catches him mid-blink.
        .environment(\.companionBlinks, !still)
        .environment(\.companionMood, mood)
        .accessibilityValue(Text(verbatim: WorldStrings.pofuValue(band: world.band, uncollected: world.pending.total.units)))
        .frame(width: viewWidth, height: viewHeight)
        .overlay {
            if HomeArt.paintedPaws, home?.pawsPressed == true {
                CheekPaws(
                    artWidth: artWidth,
                    left: CGPoint(x: artWidth * (0.1 + rig.leftCheek.x + 0.05), y: artHeight * (0.24 + rig.leftCheek.y)),
                    right: CGPoint(x: artWidth * (0.1 + rig.rightCheek.x - 0.05), y: artHeight * (0.24 + rig.rightCheek.y))
                )
            }
        }
        .modifier(RelightEffect(config: relightConfig(feet: feet, scale: s, ground: CGPoint(x: groundX, y: groundY), view: CGSize(width: viewWidth, height: viewHeight))))
        .gradedIfNeeded(characterGrade)
        .position(x: feet.x - groundX + viewWidth / 2, y: feet.y - groundY + viewHeight / 2)
    }
}

extension PofuLayer {
    /// The graphics spike's relight of the live companion: his baked normal
    /// map covers the art, which the stage lays out at 10 % side margins,
    /// 24 % headroom and 6 % floor room (`CompanionStageLayout`).
    fileprivate func relightConfig(feet: CGPoint, scale s: Double, ground: CGPoint, view: CGSize) -> RelightConfig? {
        guard let rig = relight, GraphicsSpike.litSprites.contains("pofu") else { return nil }
        let originX = Double(feet.x - ground.x), originY = Double(feet.y - ground.y)
        let lights = rig.points(
            place: { p in
                let at = pose.project(p, width: Double(size.width))
                return CGPoint(x: at.x + Double(offset.width) - originX, y: at.y + Double(offset.height) - originY)
            },
            unit: s
        )
        // The art's rectangle inside the view, as fractions of it.
        let x0 = 0.1 / 1.2, y0 = 0.24 / 1.3, w = 1 / 1.2, h = 1 / 1.3
        return RelightConfig(
            normal: "world-pofu--normal",
            rig: rig,
            lights: lights,
            size: view,
            uvRect: CGRect(x: -x0 / w, y: -y0 / h, width: 1 / w, height: 1 / h),
            showsNormals: spikeDebug == .normals
        )
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

/// Map labels, the build's level tag and the resident card: text stays
/// crisp at every scale.
private struct ScreenOverlays: View {
    let world: WorldSnapshot
    let pose: CameraPose
    let z: Double
    let size: CGSize
    let offset: CGSize
    let build: BuildFrame?
    let model: IslandSceneModel

    var body: some View {
        let labels = 1 - min(max((z - 0.2) / 0.25, 0), 1)
        ZStack(alignment: .topLeading) {
            if labels > 0.01 {
                mapLabel(.home, at: WorldPoint(x: 0, y: 128), arrived: true)
                    .opacity(labels)
                ForEach(IslandLayout.isles) { isle in
                    mapLabel(isle.id, at: WorldPoint(x: isle.center.x, y: isle.center.y + 122), arrived: world.islands.contains(isle.id))
                        .opacity(labels)
                }
            }
            if let build, let tag = build.moment.tag(at: build.time), let top = tagPoint(build.moment.station) {
                BuildTag(level: build.moment.toLevel)
                    .scaleEffect(CGFloat(tag.scale), anchor: .bottom)
                    .opacity(tag.opacity)
                    .position(x: top.x, y: top.y - 22)
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

    /// Just above a station's vignette, kept on screen.
    private func tagPoint(_ station: StationID) -> CGPoint? {
        guard let box = IslandFraming.stationBox(station) else { return nil }
        let p = screenPoint(WorldPoint(x: box.midX, y: box.minY))
        return CGPoint(x: min(max(p.x, 70), size.width - 70), y: max(p.y, 120))
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
#endif
