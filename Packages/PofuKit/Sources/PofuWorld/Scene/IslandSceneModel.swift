#if os(iOS)
import Foundation
import Observation
import PofuCore

/// What the camera and the lens are focused on, off the rail.
public enum SceneFocus: Hashable, Sendable {
    case station(StationID)
    case resident(ResidentID)
}

/// The station whose card hangs by it. A tap on another station swaps the
/// station in place, so the card moves instead of closing and opening.
public struct StationCardItem: Hashable, Sendable {
    public var station: StationID

    public init(station: StationID) {
        self.station = station
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
    /// Home's chrome opacity (ADR-0027): 1 at mid, falling to 0 between 1.05 and 1.25 x the mid
    /// scale. It follows the fingers during a pinch and jumps to where the camera is heading
    /// otherwise, so the chrome's own animation carries it.
    public private(set) var chromeOpacity = 1.0
    public private(set) var focus: SceneFocus?
    /// The island the camera is on (§1.1). The home island has the whole
    /// rail; another island has its Island stop, reached by a flight.
    public private(set) var island: IslandID = .home
    /// Taps on the home objects (jar, lantern, pots); Home sets it.
    @ObservationIgnored public var onPropTap: (@MainActor (HomeSlots.Prop) -> Void)?
    /// The home drawn from its painted plate (ADR-0022), when it shows: the
    /// scene draws the plate instead of the sprite island, taps land on its
    /// polygons and the rail takes its stops. Set by the scene.
    public private(set) var homePlate: HomePlate?
    /// Çağlayan drawn from its painted plate, when its state is painted (ADR-0022): the scene draws
    /// the plate instead of the sprite island and Damla stands on it. Set by the scene.
    public private(set) var caglayanPlate: HomePlate?
    /// Taps on a plate object Home handles itself (the door, the garden
    /// at Collect); returns whether it did. Home sets it.
    @ObservationIgnored public var onPlateTap: (@MainActor (String) -> Bool)?
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
    /// The station card; setting it to `nil` (a tap on empty ground) returns
    /// the camera.
    public var card: StationCardItem? {
        didSet {
            if card == nil {
                cardExpanded = false
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
    /// Builds a station's next level; the scene sets it from its own `onBuild`.
    @ObservationIgnored public var onBuild: (@MainActor (StationID) -> Void)?

    /// The Hap variant's pill, opened in place into the full card. Always
    /// false for the Etiket variant.
    public var cardExpanded = false

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
    /// Holds the Direct tier (up to 120 Hz) under a finger and while its spring settles.
    @ObservationIgnored private var touchLease = TouchLease()
    @ObservationIgnored private var touchTierTask: Task<Void, Never>?
    /// The Direct tier is held (read by the timeline, so it re-renders when
    /// it flips). Set only from gestures and the settle timer, never from a
    /// frame, so no view update writes it.
    private(set) var isTouchTier = false

    private func isFingerDown(at date: Date) -> Bool {
        engine.rig.isFingerDown || engine.thumb.isZooming || isBrushing(at: date)
    }

    /// Feeds the lease; while it holds, looks again every 0.1 s so the tier
    /// drops within about half a second of the finger lifting.
    private func refreshTouchTier() {
        let now = Date()
        let held = touchLease.observe(
            fingerDown: isFingerDown(at: now), springMoving: engine.rig.isMoving,
            at: now.timeIntervalSinceReferenceDate
        )
        if held != isTouchTier { isTouchTier = held }
        guard held, touchTierTask == nil else { return }
        touchTierTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100))
                guard let self else { return }
                self.refreshTouchTier()
                if !self.isTouchTier { break }
            }
            self?.touchTierTask = nil
        }
    }

    /// What the world is asking for now, as the policy's demand. Direct is
    /// a finger, a pinch, momentum, a flight or a brush; Moment is a build,
    /// a collect or the rack focus; Ambient is the visit window.
    func demand(moment: Bool, at date: Date = Date()) -> FrameDemand {
        let direct = engine.rig.isMoving || isFingerDown(at: date)
        return FrameDemand(
            isCovered: isCovered || isInviting,
            isDirect: direct,
            isUnderFinger: isTouchTier,
            isMoment: moment || isMoment || (isAnimating && !direct),
            isVisiting: isVisiting || (isDeviceTiltEnabled && !reduceMotion)
        )
    }

    /// Where the water's loop stood when Ambient last ran (WP13): the water holds there outside
    /// Ambient, so a pinch or the end of a visit never snaps it back to the painted still. `nil`
    /// until Ambient has run once: the plate shows as painted.
    @ObservationIgnored var waterTime: Double?

    /// The policy's directive for the timeline's interval and pause, and
    /// for the effects that run (§4.1).
    func directive(moment: Bool, at date: Date = Date()) -> FrameDirective {
        let demand = demand(moment: moment, at: date)
        return power.policy.directive(for: demand, conditions: power.conditions)
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
    /// A hop the ears should hear: an idle hop on the painted Home (`quiet`
    /// is the sound's level, 0...1) or a tapped resident's (1). The app maps
    /// it to `SoundCue.pofuHop` and its settings; the sound engine rate-limits.
    @ObservationIgnored public var onHop: (@MainActor (_ level: Double) -> Void)?
    /// Pofu was tapped with nothing open (the app plays his voice).
    @ObservationIgnored public var onPofuPoke: (@MainActor () -> Void)?
    /// The last idle-hop slot that sounded, so each hop sounds once.
    @ObservationIgnored private var lastHopSlot: Int?
    /// A quiet day's invitation sheet is up.
    public var isInviting = false
    /// Koke's bubble, swell and haptic (the first wonder island).
    public let koke = KokeBeatState()
    /// The Gezgin moored at the pier: her tap, her line and the moment she woke (ADR-0028).
    public let gezgin = GezginBeatState()
    /// The voyage row's choice: the island in view and the finger's drag (ADR-0028).
    public let voyage = VoyageRowState()
    /// The ride in progress (the verb of the row, plan row 2d), or `nil`.
    public private(set) var ride: VoyageRide?
    /// When the ride began, or `nil` when it is held at a moment (screenshots) or none is under way.
    public private(set) var rideStart: Date?
    /// The moment a held ride stands at, in seconds (screenshots).
    public private(set) var rideHeld: Double?
    @ObservationIgnored private var rideTask: Task<Void, Never>?
    /// She was woken: the app plays her cue. Home sets it.
    @ObservationIgnored public var onGezginWake: (@MainActor () -> Void)?
    /// Çağlayan's bubble, swell and haptic (the second wonder island).
    public let caglayan = CaglayanBeatState()
    /// Opens the flow round for a stage (1 to 4) of Çağlayan; the app sets
    /// it and answers with a full-screen cover, then calls
    /// `caglayan.roundFinished` once the stage has advanced.
    @ObservationIgnored public var onPlayFlow: (@MainActor (Int) -> Void)?
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

    // MARK: "Ada büyüdü" state

    /// The level of the painting the scene draws: it trails the world's until
    /// the moment's cross-fade begins (`presenting(_:)`).
    public private(set) var levelStage: IslandLevelStage
    /// The island's growth in progress: the old painting held, the camera
    /// pulled back, the bloom, the cross-fade and the "Ada n" card.
    public private(set) var grow: ActiveIslandGrow?
    /// Bumped when the bloom's cue plays: Home answers with the growth haptic.
    public private(set) var growBlooms = 0
    /// The level the player last saw painted, kept across launches.
    @ObservationIgnored public let levelMemory: IslandLevelMemory
    /// The bloom's cue plays (the app plays the level-up sound).
    @ObservationIgnored public var onIslandGrew: (@MainActor () -> Void)?
    /// Whether the visit's news has not spoken yet: Home sets it. While it is
    /// true an overnight rise waits for the news beat's button.
    @ObservationIgnored public var newsHolds: (@MainActor () -> Bool)?
    /// The level the island is about to grow to, once something lets it.
    @ObservationIgnored private var growTarget: Int?
    @ObservationIgnored private var growGate: GrowGate?
    @ObservationIgnored private var growTask: Task<Void, Never>?
    /// The news beat's button began the moment: the camera ends on the Island stop.
    @ObservationIgnored private var growSettlesAtIsland = false

    /// What an island rise waits for before the moment begins.
    private enum GrowGate {
        /// A build's ceremony: the moment begins at its `sheetBack` cue.
        case build
        /// The visit's news beat: its button begins the moment.
        case news
    }
    @ObservationIgnored private var leavingDressing: [(piece: DressingPiece, start: Date)] = []

    /// The island level the dressing is drawn at.
    var shownIslandLevel: Int {
        lastIslandLevel ?? 1
    }

    /// The scene saw this idle-hop slot (`nil` when none is going on): the
    /// first sighting of a slot plays the hop's quiet sound.
    func noteIdleHop(slot: Int?) {
        guard let slot else { return }
        guard slot != lastHopSlot else { return }
        lastHopSlot = slot
        onHop?(PlateHops.soundLevel)
    }

    /// Who stands where on the painted Home (`PlateMoves`), advanced by the scene each frame.
    @ObservationIgnored var plateMoves = PlateMoves.State()
    /// Where Pofu and the residents stand now, in world units, by id; empty until the scene has drawn.
    @ObservationIgnored private(set) var plateStands: [String: WorldPoint] = [:]
    @ObservationIgnored private var lastMoveHop: Int?

    /// The scene's frame: where everyone stands now, and the first sighting of a hop plays its quiet sound.
    func notePlateMoves(_ frame: [String: PlateMoves.Placement], plate: HomePlate) {
        plateStands = frame.mapValues { plate.world($0.feet) }
        let hop = frame.values.compactMap(\.hop).first
        if let hop, hop != lastMoveHop { onHop?(PlateMoves.soundLevel) }
        lastMoveHop = hop
    }

    /// Stands `id` at `feet` for a screenshot of a card opened over a character who has changed spots.
    public func stand(_ id: String, at feet: WorldPoint) {
        plateStands[id] = feet
    }

    /// Where `id` ("pofu", "mochi", "findik") stands now: on its move's spot or in it, else its painted spot.
    func standing(_ id: String) -> WorldPoint? {
        if let stand = plateStands[id] { return stand }
        if id == "pofu" { return IslandLayout.pofu }
        return homePlate?.residentFeet(ResidentID(rawValue: id))
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
        guard island == .home, framing != .map, focus == nil, card == nil, engine.rig.pinchStart == nil else { return true }
        // The establishing shot gives way to the arrival.
        establishTask?.cancel()
        // On the plate the visitor stands at the plate's spot, not the sprite island's slot.
        let feet = homePlate.map(PlateLife.visitorSpot) ?? VisitorStage.feet(of: visitor)
        let from = engine.rig.rail.pose(of: .mid)
        let pose = CameraPose(logScale: from.logScale, lookX: feet.x, lookY: from.lookY, anchorY: from.anchorY)
        travel { $0.focus(pose: pose, lens: .island, camera: WorldSprings.residentFocus) }
        kick()
        arrivalTask?.cancel()
        arrivalTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(VisitorStage.momentSeconds))
            guard let self, !Task.isCancelled, self.arrivalStart != nil, self.focus == nil, self.card == nil else { return }
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
        if releasing, focus == nil, card == nil, engine.rig.isFocused {
            travel { $0.releaseFocus() }
        }
    }

    /// The scene saw the island level. When it rises, the dressing that
    /// waited on a slot that has opened leaves in the reveal's puff, and the
    /// island grows (`beginGrow`): at once, after a build's ceremony, or
    /// after the visit's news.
    func noteIslandLevel(_ level: Int, at now: Date) {
        let last = lastIslandLevel
        lastIslandLevel = level
        guard let last else {
            seeFirstLevel(level, at: now)
            return
        }
        guard level != last else { return }
        guard level > last else {
            // The world went back (a reset): the painting follows at once.
            endGrow()
            growTarget = nil
            growGate = nil
            presentLevel(level)
            return
        }
        if !reduceMotion {
            let gone = IslandDressing.leaving(fromLevel: last, toLevel: level)
            if !gone.isEmpty {
                leavingDressing = gone.map { (piece: $0, start: now) }
                holdMoment(seconds: DressingReveal.puffSeconds + 0.05, from: now)
            }
        }
        growTarget = level
        scheduleGrow(at: now)
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

    /// - Parameter levelDefaults: Where the last presented island level is
    ///   remembered across launches; `nil` keeps it in memory (tests,
    ///   screenshots).
    public init(framing: WorldFraming = .mid, levelDefaults: UserDefaults? = nil) {
        let memory = IslandLevelMemory(defaults: levelDefaults)
        self.framing = framing
        self.projectedFraming = framing
        self.engine = SceneEngine(rig: CameraRig(framing: framing))
        self.levelMemory = memory
        // A launch lands on the painting the player last saw.
        self.levelStage = IslandLevelStage(presented: memory.lastPresented)
    }

    /// The plate shows or leaves: the rail takes its stops (the camera
    /// lands on the new framing at once) and the frame redraws.
    public func setHomePlate(_ plate: HomePlate?) {
        guard plate != homePlate else { return }
        homePlate = plate
        engine.rig.setStops(plate?.stops ?? CameraRail.referenceStops, whole: plate?.wholeStop, island: plate?.islandBox)
        kick()
    }

    /// Çağlayan's plate shows, changes state or leaves; the frame redraws (the camera is where
    /// the Island stop puts it either way).
    public func setCaglayanPlate(_ plate: HomePlate?) {
        guard plate != caglayanPlate else { return }
        caglayanPlate = plate
        kick()
    }

    /// Whether a station card is up (the name stays: the app asks it of the scene).
    public var hasSheet: Bool {
        card != nil
    }

    /// The rail position now, clamped to the framings.
    public var railPosition: Double {
        engine.rig.railPosition
    }

    // MARK: - Framings

    public func go(to target: WorldFraming, animated: Bool = true) {
        closeSurfaces()
        // The far stop is the voyage row: it opens on the island the camera is at.
        if target == .map, projectedFraming != .map { voyage.open(on: island) }
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
        engine.rig.jump(to: .mid)
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
        framing = .mid
        projectedFraming = .mid
        engine.isHeld = true
        engine.lastDate = nil
        revision &+= 1
    }

    /// One framing in (Map → mid → near at rest); at near, back to mid (ADR-0027).
    /// A double tap on a station also opens its sheet, so this waits for
    /// the surfaces to be closed.
    public func stepIn() {
        guard focus == nil, card == nil else { return }
        go(to: framing.stepIn ?? .mid)
    }

    /// A double tap at screen point (`x`, `y`) (ADR-0027): on a character, near's rest on him,
    /// his feet at 0.60 of the height and moved up to 0.12 of the width away from the side he
    /// faces; elsewhere one framing in.
    public func doubleTapped(x: Double, y: Double) {
        guard focus == nil, card == nil, island == .home else {
            stepIn()
            return
        }
        let rig = engine.rig
        let world = rig.pose.unproject(x: x, y: y, width: rig.rail.width)
        guard let character = characterFeet(near: world) else {
            stepIn()
            return
        }
        closeSurfaces()
        let shot = NearShot.rest(width: rig.rail.width, height: rig.rail.height, facesLeft: character.facesLeft)
        travel { $0.rest(on: character.feet, screenX: shot.x, screenY: shot.y) }
        framing = .near
        projectedFraming = .near
        kick()
    }

    /// The character whose body holds `world`, with his feet and facing: Pofu or a resident on
    /// the plate (their boxes from the plate's feet and scale).
    func characterFeet(near world: WorldPoint) -> (feet: WorldPoint, facesLeft: Bool)? {
        var found: [(feet: WorldPoint, facesLeft: Bool, box: WorldBox)] = []
        let pofuWidth = HomePlate.pofuArtWidth * (homePlate?.characterScale ?? 1)
        let pofu = standing("pofu") ?? IslandLayout.pofu
        found.append((pofu, false, WorldBox(minX: pofu.x - pofuWidth / 2, minY: pofu.y - pofuWidth * 66 / 64, maxX: pofu.x + pofuWidth / 2, maxY: pofu.y)))
        for resident in IslandLayout.residents {
            let feet = standing(resident.id.rawValue) ?? resident.feet
            let w = 30 * (homePlate?.residentScale(resident.id) ?? 1)
            found.append((feet, feet.x > pofu.x, WorldBox(minX: feet.x - w / 2, minY: feet.y - w * 1.3, maxX: feet.x + w / 2, maxY: feet.y)))
        }
        return found.first { $0.box.contains(world) }.map { ($0.feet, $0.facesLeft) }
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
        let target = stop.controlTarget.framing
        if target == .mid { goHome() } else { go(to: target) }
    }

    /// To Pofu's island: a ride from another island, the Island stop itself from Home.
    public func goHome() {
        if island == .home { go(to: .mid) } else { rideTo(.home) }
    }

    /// A trip to another island from wherever the camera is (a tap on a far island, the place control's menu):
    /// the same ride as the row's verb. From the row she waits moored and they hop aboard; from anywhere else
    /// she comes in carrying them.
    public func rideTo(_ target: IslandID) {
        guard ride == nil,
              let trip = VoyageRide.trip(from: island, to: target, atMap: projectedFraming == .map, focusOpen: focus != nil, reduceMotion: reduceMotion)
        else { return }
        voyage.open(on: island)
        voyage.choose(target)
        startRide(trip)
    }

    /// The verb of the voyage row: the ride to the island in view ("Yola çık"); Home is reached the same way.
    /// The characters hop aboard while the row waits, then the camera flies with her and she moors.
    public func voyageSail() {
        guard ride == nil else { return }
        let target = voyage.island
        guard target != voyage.origin else { return }
        startRide(VoyageRide(from: voyage.origin, to: target, reduceMotion: reduceMotion))
    }

    private func startRide(_ ride: VoyageRide) {
        if !ride.fromRow { closeSurfaces() }
        self.ride = ride
        rideStart = Date()
        rideHeld = nil
        rideTask?.cancel()
        rideTask = Task { @MainActor [weak self] in
            if ride.board > 0 { try? await Task.sleep(for: .seconds(ride.board)) }
            guard !Task.isCancelled, let self else { return }
            self.sail(ride)
            try? await Task.sleep(for: .seconds(max(ride.duration - ride.board, 0)))
            guard !Task.isCancelled else { return }
            self.ride = nil
            self.rideStart = nil
        }
        revision &+= 1
    }

    /// Whether the scene's focus UI (an island's plaque and bubble, a resident's card, a station's card, Home's
    /// tags) stays hidden: for the whole ride, so nothing hangs under her or in the passengers' way. It
    /// returns once the passengers are off and the ride is over.
    public var hidesFocusUI: Bool { VoyageRide.hidesFocusUI(ride) }

    /// The seconds into the ride now, or `nil` when none is under way (a held ride stands at its moment).
    public func rideElapsed(at date: Date) -> Double? {
        guard ride != nil else { return nil }
        if let rideHeld { return rideHeld }
        return rideStart.map { date.timeIntervalSince($0) }
    }

    /// The camera's flight of a ride: its length is the ride's flight beat, so the camera arrives as she moors.
    private func sail(_ ride: VoyageRide) {
        if ride.to == .home {
            closeSurfaces()
            island = .home
            let pose = engine.rig.rail.pose(of: .mid)
            travel { $0.startFlight(to: pose, landing: .rail(.mid), seconds: ride.fly) }
            framing = .mid
            projectedFraming = .mid
            kick()
        } else {
            fly(to: ride.to, seconds: ride.fly, from: matchedStart(of: ride))
        }
    }

    /// The camera the flight of a ride from the row starts at: Home's island where the row draws it, at the
    /// row's scale (the match cut), or `nil` to start where the camera is.
    private func matchedStart(of ride: VoyageRide) -> CameraPose? {
        guard ride.fromRow, ride.from == .home, let plate = homePlate else { return nil }
        let rail = engine.rig.rail
        return VoyageRowLayout(width: rail.width, height: rail.height).homePose(plate: plate)
    }

    /// Holds a ride from `origin` to `target` still at `seconds` into it (screenshots): the row while she is
    /// boarding, then the camera's flight at the matching moment.
    public func holdRide(from origin: IslandID, to target: IslandID, at seconds: Double) {
        closeSurfaces()
        rideTask?.cancel()
        island = .home
        engine.rig.jump(to: .map)
        engine.rig.snapToTargets()
        framing = .map
        projectedFraming = .map
        voyage.open(on: origin)
        voyage.choose(target)
        // Only a ride from Home starts at the row; the way back (from another island) has no boarding.
        let ride = VoyageRide(from: origin, to: target, fromRow: origin == .home)
        self.ride = ride
        rideStart = nil
        rideHeld = seconds
        if seconds >= ride.flightStart {
            sail(ride)
            engine.rig.holdFlight(at: min((seconds - ride.flightStart) / max(ride.fly, 0.1), 1))
        }
        engine.isHeld = true
        engine.lastDate = nil
        revision &+= 1
    }

    /// Flies to another island's Island stop (§1.2): up, across the sea,
    /// down. The home island is reached the same way from another island. `seconds` sets the flight's
    /// length (the ride's); without it the length follows the distance.
    public func fly(to target: IslandID, seconds: Double? = nil, from start: CameraPose? = nil) {
        if target == .home {
            go(to: .mid)
            return
        }
        guard target != island else { return }
        guard let stop = IslandFraming.isleStop(target, width: engine.rig.rail.width, height: engine.rig.rail.height) else { return }
        closeSurfaces()
        let pose = CameraPose(scale: stop.scale, look: stop.look, anchorY: stop.anchorY)
        island = target
        framing = .mid
        projectedFraming = .mid
        travel { $0.startFlight(to: pose, landing: .pose(pose), seconds: seconds, from: start) }
        kick()
        guard let seconds else {
            koke.landed(on: target, model: self)
            caglayan.landed(on: target, model: self)
            return
        }
        // A ride is the arrival: the island's bubble waits until she has come in (a held frame has none).
        guard rideHeld == nil else { return }
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(seconds))
            guard let self, self.island == target else { return }
            self.koke.landed(on: target, model: self)
            self.caglayan.landed(on: target, model: self)
        }
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
        engine.rig.jump(to: .mid)
        engine.rig.focus(pose: CameraPose(scale: stop.scale, look: stop.look, anchorY: stop.anchorY), lens: .island)
        engine.rig.snapToTargets()
        framing = .mid
        projectedFraming = .mid
        engine.isHeld = true
        engine.lastDate = nil
        revision &+= 1
    }

    /// Holds the camera `progress` (0...1) of the way through the flight from Home's Island stop to
    /// `target`'s, still (screenshots): 0.5 is over the sea, at the flight's apex.
    public func holdFlight(to target: IslandID, progress: Double) {
        closeSurfaces()
        guard
            target != .home,
            let stop = IslandFraming.isleStop(target, width: engine.rig.rail.width, height: engine.rig.rail.height)
        else { return }
        island = .home
        engine.rig.jump(to: .mid)
        engine.rig.snapToTargets()
        let pose = CameraPose(scale: stop.scale, look: stop.look, anchorY: stop.anchorY)
        island = target
        framing = .mid
        projectedFraming = .mid
        engine.rig.startFlight(to: pose, landing: .pose(pose))
        engine.rig.holdFlight(at: progress)
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
        syncChrome()
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
        guard engine.rig.layerPosition >= TouchField.minimumZ, focus == nil, card == nil, !isInviting, engine.rig.pinchStart == nil else { return }
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
            let anchor = homePlate?.stationBox(id).map({ WorldPoint(x: $0.midX, y: $0.maxY) }) ?? IslandLayout.stationAnchors[id],
            let pose = plateFocusPose(id) ?? IslandLayout.stationFocusPose(
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
        if card?.station != id { cardExpanded = false }
        card = StationCardItem(station: id)
        kick()
    }

    /// On the plate, a station's painted object centred between the top
    /// band and the room kept below it for its card (`cardFraction` of the
    /// height), filling at most 80 % of either side.
    private func plateFocusPose(_ id: StationID, sheetFraction: Double = 0.28) -> CameraPose? {
        guard let box = homePlate?.stationBox(id) else { return nil }
        let width = engine.rig.rail.width, height = engine.rig.rail.height
        let top = engine.safeTop + 100
        let bottom = height * (1 - sheetFraction)
        let scale = min(2.6 * width / CameraRail.referenceWidth, max(bottom - top, 1) * 0.8 / max(box.height, 1), width * 0.8 / max(box.width, 1))
        return CameraPose(scale: scale, look: WorldPoint(x: box.midX, y: box.midY), anchorY: (top + bottom) / 2)
    }

    /// Focuses a resident and shows their card (§12.2). Behind a station
    /// sheet, a resident means their station.
    public func focusResident(_ id: ResidentID, animated: Bool = true) {
        guard let resident = IslandLayout.resident(id) else { return }
        if card != nil {
            focusStation(resident.station, animated: animated)
            return
        }
        // From another resident, start from the rail's pose so the ×1.3
        // does not compound.
        let from = engine.rig.rail.pose(of: .mid)
        // Whoever is in the air lands first, so the camera and the card meet them where they stand.
        plateMoves.settle()
        if let plate = homePlate, let at = plateMoves.at[id.rawValue] { plateStands[id.rawValue] = plate.world(at) }
        let plateFeet = homePlate == nil ? nil : standing(id.rawValue)
        guard let pose = plateFeet.map({ feet in
            CameraPose(
                logScale: from.logScale + log(1.3),
                lookX: from.lookX + (feet.x - from.lookX) * 0.35,
                lookY: from.lookY + (feet.y - 6 - from.lookY) * 0.35,
                anchorY: from.anchorY
            )
        }) ?? IslandLayout.residentFocusPose(id, from: from) else { return }
        focus = .resident(id)
        // The first resident tapped today starts (wide-eyed for a moment).
        if reactions.noteTap(on: id.rawValue, at: Date()) {
            holdMoment(seconds: ResidentEvent.firstTapOfDay.seconds + 0.1)
        } else {
            react(.tapped, for: [id.rawValue])
            onHop?(1)
        }
        let lines = WorldStrings.residentLines(id)
        let said = linesSaid[id, default: 0]
        residentLine = said < lines.count ? lines[said] : nil
        linesSaid[id] = said + 1
        let lens = Lens.resident(depth: IslandLayout.depth(ofY: (plateFeet ?? resident.feet).y))
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
        guard focus != nil || card != nil else { return }
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
        if card != nil {
            card = nil
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
        koke wonder: WonderStatus = WonderStatus(),
        caglayan flowIsland: WonderStatus = WonderStatus()
    ) {
        // The voyage row takes its own taps (a neighbour glides, the verb sails).
        guard projectedFraming != .map else { return }
        let rig = engine.rig
        // On Koke's island only Koke answers; elsewhere its island answers
        // on the Map once it can be visited.
        var targets = island == .koke
            ? (wonder.isArrived ? [HitTarget(kind: .koke, worldBox: KokeLayout.kokeBox, depth: 0)] : [])
            : island == .caglayan
            ? (flowIsland.isArrived ? [HitTarget(kind: .caglayan, worldBox: CaglayanLayout.tapBox, depth: 0)] : [])
            : homePlate.map { plate in
                WorldHitTest.plateTargets(
                    plate, stations: stations, z: rig.layerPosition, stands: plateStands,
                    visitor: visitor, invitationOpen: invitationOpen, isBedtime: isBedtime,
                    koke: wonder.isArrived ? .arrived : .none,
                    caglayan: flowIsland.isArrived ? .arrived : .none,
                    gezgin: GezginData.shipped.map { Gezgin.presence(koke: wonder, caglayan: flowIsland, data: $0) } ?? .absent
                )
            } ?? WorldHitTest.targets(
                stations: stations, z: rig.layerPosition, visitor: visitor, invitationOpen: invitationOpen, isBedtime: isBedtime,
                koke: wonder.isArrived ? .arrived : .none,
                caglayan: flowIsland.isArrived ? .arrived : .none
            )
        if focus != nil || card != nil {
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
            // The Hap pill, open: the first tap outside closes it back to the pill.
            if cardExpanded {
                cardExpanded = false
                return
            }
            if focus != nil || card != nil {
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
        case .caglayan:
            pulse("caglayan")
            caglayan.tapped(in: self)
        case .gezgin:
            pulse("gezgin")
            var asleep = false
            if let data = GezginData.shipped, let plate = homePlate {
                let age = gezgin.wokeAt.map { Date().timeIntervalSince($0) }
                asleep = Gezgin.pose(light: plate.light, wakeAge: age, data: data) == .asleep
            }
            gezgin.tapped(asleep: asleep, in: self)
            // Tapping her opens the island choice (fi 44); the bottom-right control opens it too.
            go(to: .map)
        case .plateObject(let id):
            pulse("plate-\(id)")
            if onPlateTap?(id) == true { return }
            if let station = homePlate?.plate.object(id)?.station {
                stationTapped(station)
            }
        case .island(let id):
            guard arrived.contains(id) || id == .home else {
                pulse("island-\(id.rawValue)")
                return
            }
            pulse("island-\(id.rawValue)")
            if id == .home {
                goHome()
            } else {
                rideTo(id)
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
        if focus == nil, framing != .mid {
            go(to: .mid)
        }
        focusStation(id)
    }

    func residentTapped(_ id: ResidentID) {
        if focus == nil, framing == .map {
            go(to: .mid)
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
            engine.rig.beginPinch()
            engine.pinchWorldPoint = engine.rig.pose.unproject(x: startX, y: startY, width: engine.rig.rail.width)
            engine.samples = []
        }
        // The world point under the fingers stays under them (ADR-0027).
        let logScale = engine.pinchWorldPoint.map {
            engine.rig.pinch(magnification: magnification, keeping: $0, atScreenX: startX, y: startY)
        } ?? engine.rig.pinch(magnification: magnification)
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

    /// Whether a one-finger drag pans the camera (ADR-0027): at near, on Home, with nothing
    /// focused; at the Map and mid it peeks.
    var pansIsland: Bool {
        island == .home && engine.rig.isNear && focus == nil && card == nil && engine.rig.pinchStart == nil
    }

    func peekChanged(dx: Double, dy: Double) {
        guard engine.rig.pinchStart == nil, !engine.thumb.isZooming, projectedFraming != .map else { return }
        if pansIsland {
            engine.rig.freeDrag(dx: dx, dy: dy)
        } else {
            engine.rig.peek(dx: dx, dy: dy)
        }
        kick()
    }

    func peekEnded(velocityX: Double = 0, velocityY: Double = 0) {
        if engine.rig.freeStart != nil {
            engine.rig.endFreeDrag(vx: velocityX, vy: velocityY)
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

    /// Near's free offset now, in world units on x (the island pan retired with ADR-0027).
    public var panOffset: Double {
        engine.rig.freeX.value
    }

    /// The island pan retired with ADR-0027 (mid shows the whole island); kept for callers, it
    /// returns the camera to mid's own look.
    public func pan(to station: StationID?) {
        engine.rig.fly(to: framing == .map ? .map : .mid)
        kick()
    }

    /// Holds the camera at mid, still (the island pan retired with ADR-0027: mid shows the whole
    /// island, so a frame of the pan is now mid's frame). `start`, `velocity` and `seconds` are
    /// kept for callers.
    public func holdPan(start: Double = 0, velocity: Double = 0, at seconds: Double = 0) {
        closeSurfaces()
        engine.rig.jump(to: .mid)
        framing = .mid
        projectedFraming = .mid
        engine.isHeld = true
        engine.lastDate = nil
        revision &+= 1
    }

    /// Holds near's rest on Pofu, still (screenshots): his feet at 0.60 of the height, moved
    /// 0.12 of the width away from the side he faces. `point` rests the shot on another place of the
    /// island instead (a station's foot, the pond's edge: the near frames of row 3a). `station` rests the
    /// lens's focus on that station's foot, as a tap would (`IslandScene.lensFocus`), without its card or a
    /// camera move.
    public func holdNearRest(on point: WorldPoint? = nil, focusing station: StationID? = nil) {
        closeSurfaces()
        island = .home
        engine.rig.jump(to: .mid)
        let rig = engine.rig
        let shot = NearShot.rest(width: rig.rail.width, height: rig.rail.height, facesLeft: false)
        engine.rig.rest(on: point ?? standing("pofu") ?? IslandLayout.pofu, screenX: shot.x, screenY: shot.y, animated: false)
        engine.rig.snapToTargets()
        framing = .near
        projectedFraming = .near
        focus = station.map { .station($0) }
        syncChrome()
        engine.isHeld = true
        engine.lastDate = nil
        revision &+= 1
    }

    /// Holds the establishing shot's frame, still (screenshots).
    public func holdEstablishingShot() {
        closeSurfaces()
        engine.rig.jump(to: .mid)
        engine.rig.focus(pose: engine.rig.rail.wholeIslandPose, lens: .island)
        engine.rig.snapToTargets()
        framing = .mid
        projectedFraming = .mid
        engine.isHeld = true
        engine.lastDate = nil
        revision &+= 1
    }

    /// The establishing shot retired with ADR-0027: mid is the whole island on opening. Kept for
    /// callers; it only lets go of a pending one.
    public func establish(hold seconds: Double = 0.9) {
        establishTask?.cancel()
        establishTask = nil
    }

    private var establishTask: Task<Void, Never>?

    /// Updates `chromeOpacity` from the rig: live under the fingers, else the target's.
    private func syncChrome() {
        let rig = engine.rig
        let value: Double
        if rig.pinchStart != nil {
            value = rig.chromeOpacity
        } else if rig.flight != nil {
            value = 1
        } else {
            value = rig.rail.chromeOpacity(logScale: rig.rail.logScale(z: rig.z.target))
        }
        let rounded = (value * 50).rounded() / 50
        if rounded != chromeOpacity {
            chromeOpacity = rounded
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
        refreshTouchTier()
        syncChrome()
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

// MARK: - Ada büyüdü

/// The island's growth at one instant of its moment: when it began, or the
/// time a screenshot froze it at.
public struct ActiveIslandGrow: Hashable, Sendable {
    public let moment: IslandGrowMoment
    public let start: Date
    /// A screenshot's moment time; the clock stops.
    public let frozen: Double?
    /// When a tap sent the card away, in moment seconds.
    var leavesAt: Double?
    /// Cues up to this time have played.
    var played = -1.0

    init(moment: IslandGrowMoment, start: Date, frozen: Double? = nil) {
        self.moment = moment
        self.start = start
        self.frozen = frozen
    }

    /// The moment's time at `date`.
    public func time(at date: Date) -> Double {
        frozen ?? date.timeIntervalSince(start)
    }
}

extension IslandSceneModel {
    /// The world as the painting shows it: its island level trails the true
    /// one until the moment's cross-fade begins, and never runs ahead of it.
    func presenting(_ world: WorldSnapshot) -> WorldSnapshot {
        let level = levelStage.shown(worldLevel: world.islandLevel)
        guard level != world.islandLevel else { return world }
        var shown = world
        shown.islandLevel = level
        return shown
    }

    /// The island's growth is playing: Home's chrome steps aside.
    public var isGrowing: Bool {
        grow != nil
    }

    /// The scene presents `level` and remembers it: the player has seen it.
    fileprivate func presentLevel(_ level: Int) {
        levelStage.present(level)
        levelMemory.record(level)
    }

    /// A first look at the world: a launch lands on the painting the player
    /// last saw, and the island grows once the news has spoken; a first
    /// launch, or a level that has not moved, presents the true level.
    fileprivate func seeFirstLevel(_ level: Int, at now: Date) {
        guard let held = levelStage.presented, held < level else {
            presentLevel(level)
            return
        }
        growTarget = level
        scheduleGrow(at: now)
    }

    /// Decides what the rise waits for: a build's ceremony, the visit's news,
    /// or nothing.
    fileprivate func scheduleGrow(at now: Date) {
        if buildFraming != nil {
            growGate = .build
        } else if newsHolds?() == true {
            growGate = .news
        } else {
            beginGrow(at: now)
        }
    }

    /// The build's ceremony is over: the island answers.
    fileprivate func releaseGrowAfterBuild() {
        guard growGate == .build else { return }
        growGate = nil
        scheduleGrow(at: Date())
    }

    /// The visit's news has spoken (its button, or a visit without any):
    /// the island grows now.
    public func newsHasSpoken() {
        guard growGate == .news else { return }
        growGate = nil
        beginGrow(at: Date(), settlesAtIsland: true)
    }

    /// "Ada büyüdü": any sheet closes, the station focus lets go and the
    /// camera travels to the whole island with the old painting still on
    /// screen; the cues of `IslandGrowMoment` follow. Only the last level
    /// plays, never several.
    fileprivate func beginGrow(at now: Date, settlesAtIsland: Bool = false) {
        growGate = nil
        guard let target = growTarget else { return }
        growTarget = nil
        guard let from = levelStage.presented, from < target else {
            presentLevel(target)
            return
        }
        growTask?.cancel()
        growSettlesAtIsland = settlesAtIsland
        // From here the player has seen it begin: no news for this level.
        levelMemory.record(target)
        let moment = IslandGrowMoment(fromLevel: from, toLevel: target, reduceMotion: reduceMotion, lowPower: Self.growIsLowPower)
        grow = ActiveIslandGrow(moment: moment, start: now)
        closeSurfaces()
        if moment.time(of: .pullBack) != nil, island == .home, framing != .map, engine.rig.pinchStart == nil {
            engine.rig.focus(pose: engine.rig.rail.wholeIslandPose, lens: .island)
        }
        holdMoment(seconds: moment.duration + 0.3, from: now)
        kick()
        let times = IslandGrowMoment.Cue.allCases.compactMap { moment.time(of: $0) }.filter { $0 > 0 }.sorted()
        growTask = Task { @MainActor [weak self] in
            for time in times {
                let wait = now.addingTimeInterval(time).timeIntervalSinceNow
                if wait > 0 {
                    try? await Task.sleep(for: .seconds(wait))
                }
                guard !Task.isCancelled, let self, self.grow?.start == now else { return }
                self.advanceGrow(to: time)
            }
        }
    }

    private static var growIsLowPower: Bool {
        ProcessInfo.processInfo.isLowPowerModeEnabled
    }

    /// Plays every cue due by `time`, once.
    fileprivate func advanceGrow(to time: Double) {
        guard var active = grow else { return }
        let cues = active.moment.cues(after: active.played, through: time)
        active.played = max(active.played, time)
        grow = active
        for cue in cues {
            switch cue {
            case .bloom:
                growBlooms += 1
                onIslandGrew?()
            case .crossFade:
                presentLevel(active.moment.toLevel)
                kick()
            case .end:
                endGrow()
            case .pullBack, .card:
                break
            }
        }
    }

    /// The moment is over (or a tap sent the card away): the painting is the
    /// world's and the camera settles.
    fileprivate func endGrow() {
        growTask?.cancel()
        growTask = nil
        guard let active = grow else { return }
        grow = nil
        presentLevel(active.moment.toLevel)
        let settlesAtIsland = growSettlesAtIsland
        growSettlesAtIsland = false
        guard focus == nil, card == nil, engine.rig.pinchStart == nil else {
            kick()
            return
        }
        if settlesAtIsland, island == .home, framing != .mid {
            go(to: .mid)
        } else if active.moment.time(of: .pullBack) != nil, engine.rig.isFocused {
            engine.rig.releaseFocus()
            kick()
        } else {
            kick()
        }
    }

    /// A tap on the card: it leaves now and the camera settles.
    public func dismissGrowCard(at now: Date = Date()) {
        guard var active = grow, active.frozen == nil, active.leavesAt == nil else { return }
        let t = now.timeIntervalSince(active.start)
        guard active.moment.card(at: t) != nil else { return }
        active.leavesAt = t + IslandGrowMoment.cardLeave
        grow = active
        growTask?.cancel()
        let start = active.start
        growTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(IslandGrowMoment.cardLeave))
            guard !Task.isCancelled, let self, self.grow?.start == start else { return }
            self.endGrow()
        }
    }

    /// Holds the painting at `level`, behind the world (screenshots, tests):
    /// the island that has grown while the app was closed.
    public func holdPresentedLevel(_ level: Int) {
        levelStage.present(level)
    }

    /// Holds the island's growth `seconds` into its moment, still and with
    /// the camera on the whole island (screenshots, tests). The painting is
    /// the old one before the cross-fade cue and the new one from it; any
    /// interaction lets go of the hold.
    public func holdIslandGrow(from: Int, to: Int, at seconds: Double) {
        let moment = IslandGrowMoment(fromLevel: from, toLevel: to, reduceMotion: reduceMotion)
        // The scene has seen the true level: its first look starts no moment of its own.
        lastIslandLevel = to
        levelStage.present(moment.presentedLevel(at: seconds))
        grow = ActiveIslandGrow(moment: moment, start: Date(), frozen: seconds)
        closeSurfaces()
        engine.rig.focus(pose: engine.rig.rail.wholeIslandPose, lens: .island)
        engine.rig.snapToTargets()
        engine.isHeld = true
        engine.lastDate = nil
        revision &+= 1
        // Frames keep coming while a painting cross-fades at its own pace.
        if levelStage.presented == to {
            holdMoment(seconds: IslandGrowMoment.crossFadeLength + 0.3)
        }
    }
}

extension IslandSceneModel: WorldCamera {
    /// The build moment pushes in (§2.4): the sheet drops to compact and
    /// the camera comes in to ×1.95 on spring(0.6, 0.1).
    public func beginBuildFraming(_ station: StationID) {
        // On the painting the camera pushes in on the painted station, as
        // `focusStation` does; the sprite island has its own layout.
        let plateAnchor = homePlate?.stationBox(station).map { WorldPoint(x: $0.midX, y: $0.maxY) }
        guard
            let anchor = plateAnchor ?? IslandLayout.stationAnchors[station],
            let pose = plateFocusPose(station, sheetFraction: IslandLayout.compactSheetHeight / max(engine.rig.rail.height, 1))
                ?? IslandLayout.buildFocusPose(
                    station,
                    width: engine.rig.rail.width,
                    height: engine.rig.rail.height,
                    safeTop: engine.safeTop
                )
        else { return }
        buildFraming = station
        focus = .station(station)
        let lens = Lens.station(depth: IslandLayout.depth(ofY: anchor.y))
        travel { $0.focus(pose: pose, lens: lens, camera: $0.springs.buildPush.token) }
        kick()
    }

    /// The sheet returns to medium and the camera settles back to the
    /// station's focus, unless the user already closed the sheet.
    public func revealsLook(_ station: StationID, from: Int, to: Int) -> Bool {
        guard let homePlate else { return false }
        return PlateCompositor(plate: homePlate, levels: [:]).reveals(station, from: from, to: to)
    }

    public func endBuildFraming(_ station: StationID) {
        // The island answers the build once its ceremony is over, whatever
        // the sheet did meanwhile.
        defer { releaseGrowAfterBuild() }
        guard buildFraming == station else { return }
        buildFraming = nil
        // The ceremony is over: the station's resident is proud of it for a while.
        react(.ceremonyDone, for: ResidentReactions.cast(of: station))
        guard card?.station == station else { return }
        let plateAnchor = homePlate?.stationBox(station).map { WorldPoint(x: $0.midX, y: $0.maxY) }
        guard
            let anchor = plateAnchor ?? IslandLayout.stationAnchors[station],
            let pose = plateFocusPose(station)
                ?? IslandLayout.stationFocusPose(
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
