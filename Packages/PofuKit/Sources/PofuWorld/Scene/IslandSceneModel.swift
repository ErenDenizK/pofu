#if os(iOS)
import Foundation
import Observation
import PofuCore

/// What the camera and the lens are focused on, off the rail.
public enum SceneFocus: Hashable, Sendable {
    case station(StationID)
    case resident(ResidentID)
}

/// The station sheet's detents (interaction spec §2.3): compact is used
/// only while building.
public enum StationSheetDetent: Hashable, Sendable {
    case compact
    case medium
    case large
}

/// The station whose sheet is up. The identity is constant, so a tap on
/// another station swaps the sheet's content in place instead of
/// dismissing and presenting again (§2.3).
public struct StationSheetItem: Identifiable, Hashable, Sendable {
    public var station: StationID

    public init(station: StationID) {
        self.station = station
    }

    public var id: String {
        "station"
    }
}

/// The island scene's interaction state: the framing, the focus, the
/// station sheet, and the camera springs.
///
/// Discrete state is observable; the springs live in a plain reference
/// (`engine`) that the scene's timeline advances every frame, like
/// `CompanionDriver`, so stepping them while rendering never schedules
/// extra view updates. `isAnimating` runs the timeline; it stops once the
/// springs rest, so a still world costs nothing per frame.
@MainActor
@Observable
public final class IslandSceneModel {
    /// The framing the camera rests at or is heading to.
    public private(set) var framing: WorldFraming
    /// Where a pinch would land if released now (the detent tick).
    public private(set) var projectedFraming: WorldFraming
    public private(set) var focus: SceneFocus?
    /// The island the camera is on (§1.1). The home island has the whole
    /// rail; another island has its Island stop, reached by a flight.
    public private(set) var island: IslandID = .home
    /// Taps on the home objects (jar, lantern, pots); Home sets it.
    @ObservationIgnored public var onPropTap: (@MainActor (HomeSlots.Prop) -> Void)?
    /// Per-target tap pulses, bumped by every resolved tap: the squish
    /// answers inside one frame (§1.3). Keyed by `HitTarget` id.
    public private(set) var pulses: [String: Int] = [:]
    /// Bumped by every resolved tap, for the "tap" haptic.
    public private(set) var tapCount = 0
    /// Where the home objects were last drawn, in window points (read by
    /// the screenshot tests).
    @ObservationIgnored public private(set) var propFrames: [HomeSlots.Prop: CGRect] = [:]
    /// Where each mounted place control sits, in window points: exactly one
    /// is mounted at a time (read by the screenshot tests).
    @ObservationIgnored public private(set) var placeControlFrames: [UUID: CGRect] = [:]

    func reportProp(_ prop: HomeSlots.Prop, _ frame: CGRect) {
        propFrames[prop] = frame
    }

    func reportPlaceControl(id: UUID, frame: CGRect?) {
        placeControlFrames[id] = frame
    }
    /// The station sheet; setting it to `nil` (a swipe down) returns the
    /// camera.
    public var sheet: StationSheetItem? {
        didSet {
            if sheet == nil {
                sheetDetent = .medium
                buildFraming = nil
                if case .station = focus {
                    releaseFocus()
                }
            }
        }
    }

    /// Garden rounds playable now, for the garden's sheet and Home's play
    /// button; Home keeps it current.
    public var playableRounds = 0
    /// Starts the garden game; `nil` until Home sets it. The sheet's
    /// "Play" calls it.
    public var onPlay: (@MainActor () -> Void)?

    /// The sheet's detent; the build moment drops it to compact.
    public var sheetDetent: StationSheetDetent = .medium

    /// The station the build moment has the camera pushed in on.
    public private(set) var buildFraming: StationID?

    /// Device-tilt parallax (interaction spec §12.3 a), at most a few
    /// points. Off by default: untested on a phone. Reduce Motion and Low
    /// Power Mode turn it off.
    public var isDeviceTiltEnabled = false {
        didSet {
            if isDeviceTiltEnabled {
                engine.tilt.start()
            } else {
                engine.tilt.stop()
            }
            kick()
        }
    }

    /// The device tilt now, −1…1 on each axis, halved so the strongest
    /// parallax stays around 8 pt; zero when off.
    var deviceTilt: (x: Double, y: Double) {
        guard isDeviceTiltEnabled, !reduceMotion, !ProcessInfo.processInfo.isLowPowerModeEnabled else { return (0, 0) }
        return (engine.tilt.x * 0.5, engine.tilt.y * 0.5)
    }

    /// The frame-rate policy's inputs: Low Power Mode, the held thermal
    /// state and Reduce Motion (experience v1 §4).
    public let power = WorldPower()

    /// What the world is asking for now, as the policy's demand. Direct is
    /// a finger, a pinch, momentum, a flight or a brush; Moment is a build,
    /// a collect or the rack focus; Ambient is the visit window.
    func demand(moment: Bool, at date: Date = Date()) -> FrameDemand {
        let direct = engine.rig.isMoving || engine.thumb.isZooming || isBrushing(at: date)
        return FrameDemand(
            isCovered: isCovered || isInviting,
            isDirect: direct,
            isMoment: moment || isMoment || (isAnimating && !direct),
            isVisiting: isVisiting || (isDeviceTiltEnabled && !reduceMotion)
        )
    }

    /// The policy's directive for the timeline's interval and pause, and
    /// for the effects that run (§4.1).
    func directive(moment: Bool, at date: Date = Date()) -> FrameDirective {
        power.policy.directive(for: demand(moment: moment, at: date), conditions: power.conditions)
    }

    /// Whether the timeline must run: springs moving, or the visit window
    /// and the phone's tilt feeding the ambient layers (unless Low Power
    /// Mode, heat or Reduce Motion skip Ambient).
    var needsFrames: Bool {
        // A sheet or cover over the island freezes the ambient layers, so
        // presenting and dismissing it never competes with a live world.
        // The camera springs still run (a sheet can open with the camera
        // on its way).
        let wanted = isVisiting || (isDeviceTiltEnabled && !reduceMotion)
        let ambient = wanted && !isCovered && !isInviting && !hasSheet
            && power.policy.directive(for: .ambient, conditions: power.conditions).hz > 0
        return isAnimating || isMoment || ambient
    }

    /// Whether a sheet or full-screen cover that is not the station sheet
    /// sits over the island; Home sets it while one is presented.
    public var isCovered = false

    // MARK: - Visitors and the lawn's life (experience v1 §5, §6)

    /// Sends a game event for a tap on the visit (greeting, gift, help,
    /// invitation); Home sets it.
    @ObservationIgnored public var onVisitorEvent: (@MainActor (GameEvent.Kind) -> Void)?
    /// Today's visitor reached the lawn (the app plays the door knock).
    @ObservationIgnored public var onVisitorArrived: (@MainActor () -> Void)?
    /// A quiet day's invitation sheet is up.
    public var isInviting = false
    /// Koke's bubble, swell and haptic (the first wonder island).
    public let koke = KokeBeatState()
    /// A Moment is running: the visitor's arrival or the dressing's puff.
    /// The frame policy holds the Moment rate until it ends.
    public private(set) var isMoment = false
    private var momentUntil = Date.distantPast
    private var momentTask: Task<Void, Never>?
    /// When the visit's arrival beat began; `nil` when none is running.
    @ObservationIgnored private var arrivalStart: Date?
    private var arrivalTask: Task<Void, Never>?
    /// Arrivals this scene has played: each visit arrives once.
    @ObservationIgnored private var arrivalsPlayed: Set<String> = []
    /// What shows on the residents' faces now (`ResidentEvent`): each lapses after its seconds; `holdMoment`
    /// keeps frames coming until it does.
    private(set) var reactions = ResidentReactions()
    /// The island level the scene last saw; dressing leaves when it rises.
    @ObservationIgnored private var lastIslandLevel: Int?
    @ObservationIgnored private var leavingDressing: [(piece: DressingPiece, start: Date)] = []

    /// The island level the dressing is drawn at.
    var shownIslandLevel: Int {
        lastIslandLevel ?? 1
    }

    /// `event` shows on `ids` now.
    public func react(_ event: ResidentEvent, for ids: [String], at now: Date = Date()) {
        reactions.add(event, for: ids, at: now)
        holdMoment(seconds: event.seconds + 0.1, from: now)
    }

    /// Holds the Moment state for `seconds` (at least until any earlier hold
    /// ends).
    func holdMoment(seconds: Double, from now: Date = Date()) {
        momentUntil = max(momentUntil, now.addingTimeInterval(seconds))
        isMoment = true
        kick()
        momentTask?.cancel()
        momentTask = Task { @MainActor [weak self] in
            while let remaining = self?.momentUntil.timeIntervalSinceNow, remaining > 0 {
                try? await Task.sleep(for: .seconds(remaining))
                if Task.isCancelled { return }
            }
            guard !Task.isCancelled else { return }
            self?.isMoment = false
            self?.kick()
        }
    }

    /// The scene saw today's visitor (or none). A visit that has not been
    /// greeted arrives once: the camera pans to its slot first, then the
    /// visitor drifts down or lands (`VisitorStage`), inside a 2 s Moment.
    /// Reduce Motion and a still frame skip the pan and the beat.
    ///
    /// - Returns: Whether this visit's arrival began now (the first time the
    ///   scene sees it).
    @discardableResult
    func noteVisitor(_ visitor: VisitorSnapshot?, at now: Date, still: Bool) -> Bool {
        guard let visitor, !still, VisitorStage.hasArrival(visitor) else { return false }
        guard arrivalsPlayed.insert(VisitorStage.arrivalKey(of: visitor)).inserted else { return false }
        react(.visitorArrived, for: ResidentReactions.everyone, at: now)
        onVisitorArrived?()
        guard !reduceMotion else { return true }
        arrivalStart = now
        holdMoment(seconds: VisitorStage.momentSeconds, from: now)
        // The pan: only where the camera can show the slot.
        guard island == .home, framing != .map, focus == nil, sheet == nil, engine.rig.pinchStart == nil else { return true }
        // The establishing shot gives way to the arrival.
        establishTask?.cancel()
        let feet = VisitorStage.feet(of: visitor)
        let from = engine.rig.rail.pose(z: Double(WorldFraming.island.rawValue))
        let pose = CameraPose(logScale: from.logScale, lookX: feet.x, lookY: from.lookY, anchorY: from.anchorY)
        travel { $0.focus(pose: pose, lens: .island, camera: WorldSprings.residentFocus) }
        kick()
        arrivalTask?.cancel()
        arrivalTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(VisitorStage.momentSeconds))
            guard let self, !Task.isCancelled, self.arrivalStart != nil, self.focus == nil, self.sheet == nil else { return }
            self.arrivalStart = nil
            self.travel { $0.releaseFocus() }
            self.kick()
        }
        return true
    }

    /// Seconds since the arrival began, while it runs; `nil` when settled.
    func arrivalElapsed(at date: Date) -> Double? {
        guard let arrivalStart else { return nil }
        let elapsed = date.timeIntervalSince(arrivalStart)
        return elapsed < VisitorStage.momentSeconds ? max(elapsed, 0) : nil
    }

    /// A touch of the camera by the player ends the arrival's pan.
    private func cancelArrival(releasing: Bool) {
        guard arrivalStart != nil else { return }
        arrivalTask?.cancel()
        arrivalTask = nil
        arrivalStart = nil
        if releasing, focus == nil, sheet == nil, engine.rig.isFocused {
            travel { $0.releaseFocus() }
        }
    }

    /// The scene saw the island level. When it rises, the dressing that
    /// waited on a slot that has opened leaves in the reveal's puff.
    func noteIslandLevel(_ level: Int, at now: Date) {
        defer { lastIslandLevel = level }
        guard let last = lastIslandLevel, level > last, !reduceMotion else { return }
        pullBackForLevelUp()
        let gone = IslandDressing.leaving(fromLevel: last, toLevel: level)
        guard !gone.isEmpty else { return }
        leavingDressing = gone.map { (piece: $0, start: now) }
        holdMoment(seconds: DressingReveal.puffSeconds + 0.05, from: now)
    }

    /// The dressing mid-puff at `date`, with the seconds since it began.
    func dressingLeaving(at date: Date) -> [(piece: DressingPiece, elapsed: Double)] {
        leavingDressing.compactMap { entry in
            let elapsed = date.timeIntervalSince(entry.start)
            return elapsed < DressingReveal.puffSeconds ? (piece: entry.piece, elapsed: max(elapsed, 0)) : nil
        }
    }

    /// A tap on a part of the visit: the quiet day's letter opens the
    /// invitation sheet; the rest send their event.
    func visitorTapped(_ part: VisitorPart, visitor: VisitorSnapshot?) {
        if part == .letter {
            isInviting = true
            return
        }
        if let kind = VisitorStage.event(for: part, visitor: visitor) {
            onVisitorEvent?(kind)
        }
    }

    /// The player picked a resident from the letter: they come tomorrow.
    public func invite(_ resident: ResidentID) {
        isInviting = false
        onVisitorEvent?(.invited(resident))
    }

    /// The look's live window after the scene appears (look-dev B): the
    /// HD-2D layers animate during a visit and while the camera moves;
    /// otherwise the settled frame is cached and costs nothing.
    public private(set) var isVisiting = false
    /// When the current visit began: the residents' cycles count from it.
    @ObservationIgnored private(set) var visitBegan: Date?
    private var visitTask: Task<Void, Never>?

    /// Starts (or extends) a visit: the look animates for `seconds`.
    /// Reduce Motion skips it.
    public func beginLookVisit(seconds: Double = LookTuning.visitSeconds) {
        guard !reduceMotion, seconds > 0 else { return }
        visitTask?.cancel()
        // A visit that is extended keeps its start, so a walk in progress
        // is never cut and restarted.
        if !isVisiting || visitBegan == nil { visitBegan = Date() }
        isVisiting = true
        // A visit animates the look; it does not let go of a held frame.
        let held = engine.isHeld
        kick()
        engine.isHeld = held
        visitTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(seconds))
            guard !Task.isCancelled else { return }
            self?.isVisiting = false
        }
    }
    /// Reduce Motion, from the environment.
    public var reduceMotion = false {
        didSet {
            engine.rig.reduceMotion = reduceMotion
        }
    }

    /// Runs the scene's timeline while springs move or a finger is down.
    private(set) var isAnimating = false
    /// Bumped by every change the springs cannot report themselves.
    private(set) var revision = 0
    /// Lines each resident has said this visit (rationed, never repeated).
    private(set) var linesSaid: [ResidentID: Int] = [:]
    /// The line the open resident card shows.
    private(set) var residentLine: String?

    /// Not observed: a `let` reference, mutated per frame.
    let engine: SceneEngine

    /// How long Reduce Motion's cross-fade between two camera framings
    /// lasts (interaction spec §1.8).
    public nonisolated static let crossFade = 0.2

    public init(framing: WorldFraming = .home) {
        self.framing = framing
        self.projectedFraming = framing
        self.engine = SceneEngine(rig: CameraRig(framing: framing))
    }

    public var hasSheet: Bool {
        sheet != nil
    }

    /// The rail position now, clamped to the framings.
    public var railPosition: Double {
        engine.rig.railPosition
    }

    // MARK: - Framings

    public func go(to target: WorldFraming, animated: Bool = true) {
        closeSurfaces()
        if island != .home {
            // From another island every move is a flight to the home rail.
            island = .home
            let pose = engine.rig.rail.pose(of: target)
            if animated {
                travel { $0.startFlight(to: pose, landing: .rail(target)) }
            } else {
                engine.rig.jump(to: target)
            }
        } else if animated {
            travel { $0.fly(to: target) }
        } else {
            engine.rig.jump(to: target)
        }
        framing = target
        projectedFraming = target
        kick()
    }

    /// Holds the camera `seconds` into a flight from one framing to
    /// another, still, as a frame of the move (screenshots of depth in
    /// motion, tests). Any interaction lets go of the hold.
    public func holdFlight(from start: WorldFraming, to target: WorldFraming, at seconds: Double) {
        closeSurfaces()
        engine.rig.jump(to: start)
        engine.rig.fly(to: target)
        let step = 1.0 / 120
        var t = 0.0
        while t + 1e-9 < seconds {
            engine.rig.advance(min(step, seconds - t))
            t += step
        }
        framing = target
        projectedFraming = target
        engine.isHeld = true
        engine.lastDate = nil
        revision &+= 1
    }

    /// Holds the camera `seconds` into a pan from one station's focus to
    /// another's, still and without a sheet: a frame of the move, for the
    /// screenshots of depth in motion across the island. Any interaction
    /// lets go of the hold.
    public func holdStationPan(from start: StationID, to target: StationID, at seconds: Double) {
        closeSurfaces()
        let width = engine.rig.rail.width, height = engine.rig.rail.height
        guard
            let a = IslandLayout.stationAnchors[start],
            let b = IslandLayout.stationAnchors[target],
            let from = IslandLayout.stationFocusPose(start, width: width, height: height, safeTop: engine.safeTop),
            let to = IslandLayout.stationFocusPose(target, width: width, height: height, safeTop: engine.safeTop)
        else { return }
        engine.rig.jump(to: .island)
        engine.rig.focus(pose: from, lens: Lens.station(depth: IslandLayout.depth(ofY: a.y)))
        engine.rig.snapToTargets()
        engine.rig.focus(pose: to, lens: Lens.station(depth: IslandLayout.depth(ofY: b.y)))
        let step = 1.0 / 120
        var t = 0.0
        while t + 1e-9 < seconds {
            engine.rig.advance(min(step, seconds - t))
            t += step
        }
        focus = .station(target)
        framing = .island
        projectedFraming = .island
        engine.isHeld = true
        engine.lastDate = nil
        revision &+= 1
    }

    /// One framing in (Map → Island → Home); at Home, the Island (§1.4).
    /// A double tap on a station also opens its sheet, so this waits for
    /// the surfaces to be closed.
    public func stepIn() {
        guard focus == nil, sheet == nil else { return }
        go(to: framing.stepIn ?? .island)
    }

    // MARK: - Place

    /// Where the camera is now: the island and the rail position.
    public var place: CameraPlace {
        CameraPlace(island: island, z: railPosition)
    }

    /// The one control's tap (§1.2): out one stop, and from the Archipelago
    /// home to Pofu.
    public func placeControlTapped() {
        let stop = PlaceStop(framing: projectedFraming)
        go(to: stop.controlTarget.framing)
    }

    /// Flies to another island's Island stop (§1.2): up, across the sea,
    /// down. The home island is reached the same way from another island.
    public func fly(to target: IslandID) {
        if target == .home {
            go(to: .island)
            return
        }
        guard target != island else { return }
        guard let stop = IslandFraming.isleStop(target, width: engine.rig.rail.width, height: engine.rig.rail.height) else { return }
        closeSurfaces()
        let pose = CameraPose(scale: stop.scale, look: stop.look, anchorY: stop.anchorY)
        island = target
        framing = .island
        projectedFraming = .island
        travel { $0.startFlight(to: pose, landing: .pose(pose)) }
        kick()
        koke.landed(on: target, model: self)
    }

    /// Holds the camera on another island's Island stop, still
    /// (screenshots).
    public func holdIsle(_ target: IslandID) {
        closeSurfaces()
        guard
            target != .home,
            let stop = IslandFraming.isleStop(target, width: engine.rig.rail.width, height: engine.rig.rail.height)
        else { return }
        island = target
        engine.rig.jump(to: .island)
        engine.rig.focus(pose: CameraPose(scale: stop.scale, look: stop.look, anchorY: stop.anchorY), lens: .island)
        engine.rig.snapToTargets()
        framing = .island
        projectedFraming = .island
        engine.isHeld = true
        engine.lastDate = nil
        revision &+= 1
    }

    /// Holds the camera on the rail at `z`, still (screenshots).
    public func holdRail(z: Double) {
        closeSurfaces()
        island = .home
        engine.rig.jump(toZ: z)
        let nearest = WorldFraming.nearest(to: z)
        framing = nearest
        projectedFraming = nearest
        engine.isHeld = true
        engine.lastDate = nil
        revision &+= 1
    }

    // MARK: - Focus follows the camera

    /// How long the rack focus takes once the camera settles (§1.2).
    public nonisolated static let rackSeconds = 0.35

    /// Depth of field's strength now, 0...1: zero while the camera moves
    /// (finger down, pinch, momentum, flight), then a 0.35 s pull to the
    /// target once it settles.
    func rackFocus(at date: Date) -> Double {
        if engine.rig.isMoving { return 0 }
        guard !reduceMotion, let start = engine.rackStart else { return 1 }
        let t = min(max(date.timeIntervalSince(start) / Self.rackSeconds, 0), 1)
        return t * t * (3 - 2 * t)
    }

    /// Whether the rack focus is still pulling at `date`.
    private func isRacking(at date: Date) -> Bool {
        guard !reduceMotion, let start = engine.rackStart else { return false }
        return date.timeIntervalSince(start) < Self.rackSeconds
    }

    // MARK: - Brushing

    /// A dragging finger at screen point (`x`, `y`) touches the island
    /// (§1.3): at the Island framing and closer, with nothing focused.
    func brush(x: Double, y: Double, at time: Date) {
        guard railPosition >= TouchField.minimumZ, focus == nil, sheet == nil, !isInviting, engine.rig.pinchStart == nil else { return }
        let world = engine.rig.pose.unproject(
            x: x - engine.rig.offsetX.value,
            y: y - engine.rig.offsetY.value,
            width: engine.rig.rail.width
        )
        // The stations give a little, and so do the dressing and the
        // critters at the island's level (§6).
        let props = IslandLayout.touchProps.map { (id: $0.id, base: $0.center) }
            + IslandLife.touchProps(atLevel: shownIslandLevel)
        engine.touch.brush(at: world, t: time.timeIntervalSinceReferenceDate, props: props)
        kick()
    }

    func endBrush() {
        engine.touch.endStroke()
    }

    /// A touchable prop's sway at `date`, in degrees.
    func sway(of prop: String, at date: Date) -> Double {
        engine.touch.sway(of: prop, at: date.timeIntervalSinceReferenceDate)
    }

    /// Whether a brushed prop is still swaying at `date`.
    func isBrushing(at date: Date) -> Bool {
        engine.touch.isActive(at: date.timeIntervalSinceReferenceDate)
    }

    // MARK: - One-thumb zoom

    /// A finger went down (for the one-thumb zoom's double tap).
    func touchBegan(x: Double, y: Double, at time: Date) {
        engine.thumb.touchDown(time: time.timeIntervalSinceReferenceDate, x: x, y: y)
    }

    /// Whether a one-thumb zoom owns the finger; a pan must not.
    var isOneThumbZooming: Bool {
        engine.thumb.isZooming
    }

    /// The finger moved; a one-thumb zoom drives the pinch. Returns whether
    /// the zoom owns the finger.
    @discardableResult
    func touchMoved(y: Double, at time: Date) -> Bool {
        guard let magnification = engine.thumb.touchMoved(y: y) else { return false }
        pinchChanged(
            magnification: magnification,
            startX: engine.thumb.anchor.x,
            startY: engine.thumb.anchor.y,
            time: time
        )
        return true
    }

    func touchEnded(x: Double, y: Double, at time: Date) {
        if engine.thumb.touchUp(time: time.timeIntervalSinceReferenceDate, x: x, y: y) {
            pinchEnded(time: time)
        }
    }

    /// One framing out.
    public func stepOut() {
        if let out = framing.stepOut {
            go(to: out)
        }
    }

    // MARK: - Focus

    /// Focuses a station and raises its sheet (§2.2). Behind a sheet,
    /// another station retargets without dismissing.
    public func focusStation(_ id: StationID, animated: Bool = true) {
        guard
            let anchor = IslandLayout.stationAnchors[id],
            let pose = IslandLayout.stationFocusPose(
                id,
                width: engine.rig.rail.width,
                height: engine.rig.rail.height,
                safeTop: engine.safeTop
            )
        else { return }
        residentLine = nil
        focus = .station(id)
        let lens = Lens.station(depth: IslandLayout.depth(ofY: anchor.y))
        if animated {
            travel { $0.focus(pose: pose, lens: lens) }
        } else {
            engine.rig.focus(pose: pose, lens: lens)
            engine.rig.snapToTargets()
        }
        sheet = StationSheetItem(station: id)
        kick()
    }

    /// Focuses a resident and shows their card (§12.2). Behind a station
    /// sheet, a resident means their station.
    public func focusResident(_ id: ResidentID, animated: Bool = true) {
        guard let resident = IslandLayout.resident(id) else { return }
        if sheet != nil {
            focusStation(resident.station, animated: animated)
            return
        }
        // From another resident, start from the rail's pose so the ×1.3
        // does not compound.
        let from = engine.rig.rail.pose(z: Double(framing.rawValue))
        guard let pose = IslandLayout.residentFocusPose(id, from: from) else { return }
        focus = .resident(id)
        // The first resident tapped today starts (wide-eyed for a moment).
        if reactions.noteTap(on: id.rawValue, at: Date()) {
            holdMoment(seconds: ResidentEvent.firstTapOfDay.seconds + 0.1)
        } else {
            react(.tapped, for: [id.rawValue])
        }
        let lines = WorldStrings.residentLines(id)
        let said = linesSaid[id, default: 0]
        residentLine = said < lines.count ? lines[said] : nil
        linesSaid[id] = said + 1
        let lens = Lens.resident(depth: IslandLayout.depth(ofY: resident.feet.y))
        if animated {
            travel { $0.focus(pose: pose, lens: lens, camera: WorldSprings.residentFocus) }
        } else {
            engine.rig.focus(pose: pose, lens: lens, camera: WorldSprings.residentFocus)
            engine.rig.snapToTargets()
        }
        kick()
    }

    /// Closes the sheet or the card and returns the camera (§2.5).
    public func dismissFocus() {
        guard focus != nil || sheet != nil else { return }
        closeSurfaces()
        kick()
    }

    /// Forgets the visit's rationed lines (a new visit).
    public func beginVisit() {
        linesSaid = [:]
    }

    private func closeSurfaces() {
        // Whatever moves the camera now takes over from the arrival's pan.
        cancelArrival(releasing: false)
        focus = nil
        residentLine = nil
        if sheet != nil {
            sheet = nil
        }
        travel { $0.releaseFocus() }
    }

    private func releaseFocus() {
        focus = nil
        residentLine = nil
        travel { $0.releaseFocus() }
        kick()
    }

    /// Moves the camera with `change`; under Reduce Motion the camera jumps
    /// and the old framing cross-fades out over the new one in 200 ms
    /// instead of travelling (interaction spec §1.8).
    private func travel(_ change: (inout CameraRig) -> Void) {
        guard reduceMotion else {
            change(&engine.rig)
            return
        }
        let from = engine.crossfade?.from ?? engine.rig
        change(&engine.rig)
        engine.rig.snapToTargets()
        engine.crossfade = SceneEngine.Crossfade(from: from, start: nil)
    }

    // MARK: - Screen points

    /// The screen point of a world point now, with the peek's offset.
    public func screenPoint(of point: WorldPoint) -> (x: Double, y: Double) {
        let p = engine.rig.pose.project(point, width: engine.rig.rail.width)
        return (p.x + engine.rig.offsetX.value, p.y + engine.rig.offsetY.value)
    }

    // MARK: - Taps

    /// The single tap resolver (§1.3): the frontmost target under the finger
    /// answers within the frame (a squish and the "tap" haptic), then focus
    /// and the sheet follow. A tap on empty ground does nothing, except to
    /// dismiss a card or sheet.
    func tapped(
        x: Double,
        y: Double,
        stations: [StationStatus],
        arrived: Set<IslandID>,
        visitor: VisitorSnapshot? = nil,
        invitationOpen: Bool = false,
        isBedtime: Bool = false,
        koke wonder: WonderStatus = WonderStatus()
    ) {
        let rig = engine.rig
        // On Koke's island only Koke answers; elsewhere its island answers
        // on the Map once it can be visited.
        var targets = island == .koke
            ? (wonder.isArrived ? [HitTarget(kind: .koke, worldBox: KokeLayout.kokeBox, depth: 0)] : [])
            : WorldHitTest.targets(
                stations: stations, z: rig.railPosition, visitor: visitor, invitationOpen: invitationOpen, isBedtime: isBedtime,
                koke: wonder.isArrived ? .arrived : .none
            )
        if focus != nil || sheet != nil {
            // Behind a card or a sheet the home objects and the visit step aside.
            targets.removeAll {
                switch $0.kind {
                case .prop, .visitor: true
                default: false
                }
            }
        }
        let hit = WorldHitTest.resolve(
            x: x,
            y: y,
            targets: targets,
            pose: rig.pose,
            width: rig.rail.width,
            offset: (rig.offsetX.value, rig.offsetY.value)
        )
        guard let hit else {
            if focus != nil || sheet != nil {
                // A tap outside a transient surface dismisses it and is
                // consumed (§7.3).
                dismissFocus()
            }
            return
        }
        switch hit.kind {
        case .station(let id):
            pulse("station-\(id.rawValue)")
            stationTapped(id)
        case .resident(let id):
            pulse("resident-\(id.rawValue)")
            residentTapped(id)
        case .prop(let prop):
            pulse("prop-\(prop.rawValue)")
            onPropTap?(prop)
        case .visitor(let part):
            pulse("visitor-\(part.rawValue)")
            visitorTapped(part, visitor: visitor)
        case .koke:
            pulse("koke")
            koke.tapped(in: self)
        case .island(let id):
            guard arrived.contains(id) || id == .home else {
                pulse("island-\(id.rawValue)")
                return
            }
            pulse("island-\(id.rawValue)")
            if id == .home {
                go(to: .island)
            } else {
                fly(to: id)
            }
        }
    }

    private func pulse(_ id: String) {
        pulses[id, default: 0] += 1
        tapCount &+= 1
    }

    /// A tap on a station focuses it and raises its sheet. From the Map or
    /// Home the camera first heads for the island, so the one gesture
    /// travels there and opens the sheet, and closing it rests at the
    /// island.
    func stationTapped(_ id: StationID) {
        if focus == nil, framing != .island {
            go(to: .island)
        }
        focusStation(id)
    }

    func residentTapped(_ id: ResidentID) {
        if focus == nil, framing == .home {
            go(to: .island)
            return
        }
        if focus == .resident(id) {
            dismissFocus()
            return
        }
        focusResident(id)
    }

    // MARK: - Pinch and peek

    func pinchChanged(magnification: Double, startX: Double, startY: Double, time: Date) {
        if engine.rig.pinchStart == nil {
            closeSurfaces()
            // A pinch leaves another island for the shared sea.
            island = .home
            engine.pinchWorldPoint = engine.rig.pose.unproject(x: startX, y: startY, width: engine.rig.rail.width)
            engine.samples = []
        }
        let logScale = engine.rig.pinch(magnification: magnification)
        if let world = engine.pinchWorldPoint {
            engine.rig.pull(toward: world, screenX: startX, screenY: startY)
        }
        engine.record(logScale: logScale, at: time)
        let projected = CameraRelease.projectedFraming(
            logScale: logScale,
            velocity: engine.velocity,
            idle: 0,
            rail: engine.rig.rail
        )
        if projected != projectedFraming {
            projectedFraming = projected
        }
        kick()
    }

    func pinchEnded(time: Date) {
        let idle = engine.samples.last.map { time.timeIntervalSince($0.time) } ?? 1
        let landing = engine.rig.endPinch(velocity: engine.velocity, idle: idle)
        engine.pinchWorldPoint = nil
        engine.samples = []
        framing = landing.framing
        projectedFraming = landing.framing
        kick()
    }

    /// Whether a one-finger drag pans the island (look round 4): at the
    /// Island framing with nothing focused; elsewhere it peeks.
    var pansIsland: Bool {
        island == .home && framing == .island && focus == nil && sheet == nil && engine.rig.pinchStart == nil
    }

    func peekChanged(dx: Double, dy: Double) {
        guard engine.rig.pinchStart == nil, !engine.thumb.isZooming else { return }
        if pansIsland {
            if engine.rig.isFocused {
                // A finger during the establishing shot takes over.
                establishTask?.cancel()
                cancelArrival(releasing: false)
                engine.rig.releaseFocus()
            }
            engine.rig.panDrag(dx: dx)
            engine.rig.peek(dx: 0, dy: dy)
        } else {
            engine.rig.peek(dx: dx, dy: dy)
        }
        kick()
    }

    func peekEnded(velocityX: Double = 0) {
        if engine.rig.panStart != nil {
            engine.rig.endPan(velocity: velocityX)
        }
        engine.rig.settleOffset()
        kick()
    }

    // MARK: - The island pan

    /// A scripted one-finger drag, `dx`/`dy` points since it began, as the
    /// gesture would report it (motion beats).
    public func scriptedDrag(dx: Double, dy: Double = 0) {
        peekChanged(dx: dx, dy: dy)
    }

    /// A scripted finger lift at `velocityX` points per second.
    public func scriptedRelease(velocityX: Double) {
        peekEnded(velocityX: velocityX)
    }

    /// The camera's springs; the tuning lab panel tunes them live.
    public var cameraSprings: CameraSprings {
        get { engine.rig.springs }
        set { engine.rig.springs = newValue }
    }

    /// The pan now, in world units off the Island stop (Pofu-centred).
    public var panOffset: Double {
        engine.rig.pan.value
    }

    /// Pans to a station's snap point (or Pofu's, `nil`), with the release
    /// spring.
    public func pan(to station: StationID?) {
        let x = station.flatMap { IslandLayout.stationAnchors[$0]?.x } ?? IslandLayout.pofu.x
        let target = IslandFraming.panValue(lookX: x)
        engine.rig.panTo(target)
        kick()
    }

    /// Holds the camera at the Island framing panned to `value` (or
    /// `seconds` into a flick from `start` at `velocity` points per
    /// second), still: a frame of the pan for screenshots and motion beats.
    public func holdPan(start: Double = 0, velocity: Double = 0, at seconds: Double = 0) {
        closeSurfaces()
        engine.rig.jump(to: .island)
        engine.rig.jumpPan(to: start)
        if velocity != 0 {
            engine.rig.panDrag(dx: 0)
            engine.rig.endPan(velocity: velocity)
        }
        let step = 1.0 / 120
        var t = 0.0
        while t + 1e-9 < seconds {
            engine.rig.advance(min(step, seconds - t))
            t += step
        }
        framing = .island
        projectedFraming = .island
        engine.isHeld = true
        engine.lastDate = nil
        revision &+= 1
    }

    /// Holds the establishing shot's frame, still (screenshots).
    public func holdEstablishingShot() {
        closeSurfaces()
        engine.rig.jump(to: .island)
        engine.rig.focus(pose: engine.rig.rail.wholeIslandPose, lens: .island)
        engine.rig.snapToTargets()
        framing = .island
        projectedFraming = .island
        engine.isHeld = true
        engine.lastDate = nil
        revision &+= 1
    }

    /// The establishing shot (look round 4): the whole island at 88 % of
    /// the width, held a beat, then the camera settles into the pan view
    /// centred on Pofu. On arrival at the Island; Reduce Motion skips it.
    public func establish(hold seconds: Double = 0.9) {
        guard !reduceMotion, framing == .island, focus == nil else { return }
        let whole = engine.rig.rail.wholeIslandPose
        engine.rig.focus(pose: whole, lens: .island)
        engine.rig.snapToTargets()
        kick()
        establishTask?.cancel()
        establishTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(seconds))
            guard let self, !Task.isCancelled, self.focus == nil else { return }
            self.engine.rig.releaseFocus()
            self.kick()
        }
    }

    private var establishTask: Task<Void, Never>?

    /// The island-level ceremony (LS-3): the camera pulls back to the whole
    /// island so every new thing is in frame, holds a beat, then settles
    /// back where it was. Only from the resting framings with nothing open.
    func pullBackForLevelUp(hold seconds: Double = 2.4) {
        guard !reduceMotion, island == .home, framing != .map, focus == nil, sheet == nil, engine.rig.pinchStart == nil else { return }
        engine.rig.focus(pose: engine.rig.rail.wholeIslandPose, lens: .island)
        kick()
        establishTask?.cancel()
        establishTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(seconds))
            guard let self, !Task.isCancelled, self.focus == nil else { return }
            self.engine.rig.releaseFocus()
            self.kick()
        }
    }

    // MARK: - The timeline

    /// Advances the springs to `date` and returns the rig to draw. Called
    /// from the timeline while rendering: it never mutates observed state
    /// synchronously.
    func frame(at date: Date, width: Double, height: Double, safeTop: Double) -> CameraRig {
        engine.rig.resize(width: width, height: height)
        engine.safeTop = safeTop
        if engine.isHeld {
            return engine.rig
        }
        if let last = engine.lastDate {
            engine.rig.advance(date.timeIntervalSince(last))
        }
        engine.lastDate = date
        if engine.rig.isMoving {
            engine.wasMoving = true
            engine.rackStart = nil
        } else if engine.wasMoving {
            engine.wasMoving = false
            engine.rackStart = date
        }
        if var crossfade = engine.crossfade {
            if let start = crossfade.start {
                if date.timeIntervalSince(start) >= Self.crossFade {
                    engine.crossfade = nil
                }
            } else {
                crossfade.start = date
                engine.crossfade = crossfade
            }
        }
        // Frames run on until the rack focus has pulled and a brushed prop
        // has stopped swaying.
        if isAnimating, engine.rig.isSettled, engine.crossfade == nil, !isDeviceTiltEnabled, !engine.settleScheduled,
           !isRacking(at: date), !isBrushing(at: date) {
            engine.settleScheduled = true
            Task { @MainActor [weak self] in
                self?.settle()
            }
        }
        return engine.rig
    }

    /// Reduce Motion's outgoing framing and its opacity at `date`, while
    /// a cross-fade runs.
    func crossfade(at date: Date) -> (rig: CameraRig, opacity: Double)? {
        guard let crossfade = engine.crossfade else { return nil }
        let elapsed = crossfade.start.map { date.timeIntervalSince($0) } ?? 0
        let opacity = 1 - min(max(elapsed / Self.crossFade, 0), 1)
        return opacity > 0.001 ? (crossfade.from, opacity) : nil
    }

    private func settle() {
        engine.settleScheduled = false
        guard engine.rig.isSettled, engine.crossfade == nil else { return }
        isAnimating = false
        engine.lastDate = nil
    }

    private func kick() {
        engine.isHeld = false
        if !isAnimating {
            engine.lastDate = nil
            isAnimating = true
        }
        revision &+= 1
    }
}

/// The springs and the gesture's bookkeeping. Deliberately not
/// observable; see `IslandSceneModel`.
@MainActor
final class SceneEngine {
    /// Reduce Motion's cross-fade: the framing the camera jumped from.
    struct Crossfade {
        var from: CameraRig
        /// Set on the first frame drawn after the jump.
        var start: Date?
    }

    var rig: CameraRig
    var crossfade: Crossfade?
    let tilt = DeviceTilt()
    var lastDate: Date?
    /// A held frame of a move (`holdFlight`): the springs do not advance.
    var isHeld = false
    var settleScheduled = false
    /// Brushing (§1.3) and the one-thumb zoom (§1.2).
    var touch = TouchField()
    var thumb = OneThumbZoom()
    /// When the camera last came to rest, for the rack focus; `nil` while
    /// it moves or has never moved.
    var rackStart: Date?
    var wasMoving = false
    var safeTop = 59.0
    var pinchWorldPoint: WorldPoint?
    /// Recent pinch samples, for the release velocity.
    var samples: [(time: Date, logScale: Double)] = []

    init(rig: CameraRig) {
        self.rig = rig
    }

    func record(logScale: Double, at time: Date) {
        samples.append((time: time, logScale: logScale))
        // Keep the last 100 ms.
        samples.removeAll { time.timeIntervalSince($0.time) > 0.1 }
    }

    /// The pinch's velocity over the recent samples, in ln s per second.
    var velocity: Double {
        guard let first = samples.first, let last = samples.last else { return 0 }
        let dt = last.time.timeIntervalSince(first.time)
        guard dt > 0.008 else { return 0 }
        return (last.logScale - first.logScale) / dt
    }
}

extension IslandSceneModel: WorldCamera {
    /// The build moment pushes in (§2.4): the sheet drops to compact and
    /// the camera comes in to ×1.95 on spring(0.6, 0.1).
    public func beginBuildFraming(_ station: StationID) {
        guard
            let anchor = IslandLayout.stationAnchors[station],
            let pose = IslandLayout.buildFocusPose(
                station,
                width: engine.rig.rail.width,
                height: engine.rig.rail.height,
                safeTop: engine.safeTop
            )
        else { return }
        buildFraming = station
        sheetDetent = .compact
        focus = .station(station)
        let lens = Lens.station(depth: IslandLayout.depth(ofY: anchor.y))
        travel { $0.focus(pose: pose, lens: lens, camera: $0.springs.buildPush.token) }
        kick()
    }

    /// The sheet returns to medium and the camera settles back to the
    /// station's focus, unless the user already closed the sheet.
    public func endBuildFraming(_ station: StationID) {
        guard buildFraming == station else { return }
        buildFraming = nil
        // The ceremony is over: the station's resident is proud of it for a while.
        react(.ceremonyDone, for: ResidentReactions.cast(of: station))
        guard sheet?.station == station else { return }
        sheetDetent = .medium
        guard
            let anchor = IslandLayout.stationAnchors[station],
            let pose = IslandLayout.stationFocusPose(
                station,
                width: engine.rig.rail.width,
                height: engine.rig.rail.height,
                safeTop: engine.safeTop
            )
        else { return }
        let lens = Lens.station(depth: IslandLayout.depth(ofY: anchor.y))
        travel { $0.focus(pose: pose, lens: lens, camera: WorldSprings.refocus) }
        kick()
    }
}
#endif
