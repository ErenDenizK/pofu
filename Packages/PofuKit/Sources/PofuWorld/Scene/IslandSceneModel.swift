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

    /// Whether the timeline must run: springs moving, or the phone's tilt
    /// feeding parallax.
    var needsFrames: Bool {
        isAnimating || isVisiting || (isDeviceTiltEnabled && !reduceMotion)
    }

    /// The look's live window after the scene appears (look-dev B): the
    /// HD-2D layers animate during a visit and while the camera moves;
    /// otherwise the settled frame is cached and costs nothing.
    public private(set) var isVisiting = false
    private var visitTask: Task<Void, Never>?

    /// Starts (or extends) a visit: the look animates for `seconds`.
    /// Reduce Motion skips it.
    public func beginLookVisit(seconds: Double = LookTuning.visitSeconds) {
        guard !reduceMotion, seconds > 0 else { return }
        visitTask?.cancel()
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
        if animated {
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

    /// One framing in (Map → Island → Home); at Home, the Island (§1.4).
    public func stepIn() {
        go(to: framing.stepIn ?? .island)
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

    /// A tap on a station: at the Island framing or behind a sheet it
    /// focuses; at Home the world is one soft target (§1.4).
    func stationTapped(_ id: StationID) {
        if focus == nil, framing == .home {
            go(to: .island)
            return
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

    /// A tap on the world's background, at a screen point.
    func backgroundTapped(x: Double, y: Double) {
        if focus != nil || sheet != nil {
            // A tap outside a transient surface dismisses it and is
            // consumed (§7.3).
            dismissFocus()
            return
        }
        switch framing {
        case .home:
            go(to: .island)
        case .island:
            break
        case .map:
            let point = engine.rig.pose.unproject(x: x, y: y, width: engine.rig.rail.width)
            let dx = point.x / (IslandLayout.lawnRadiusX + 20)
            let dy = (point.y - 30) / 110
            if dx * dx + dy * dy <= 1 {
                go(to: .island)
            }
        }
    }

    // MARK: - Pinch and peek

    func pinchChanged(magnification: Double, startX: Double, startY: Double, time: Date) {
        if engine.rig.pinchStart == nil {
            closeSurfaces()
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

    func peekChanged(dx: Double, dy: Double) {
        guard engine.rig.pinchStart == nil else { return }
        engine.rig.peek(dx: dx, dy: dy)
        kick()
    }

    func peekEnded() {
        engine.rig.settleOffset()
        kick()
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
        if isAnimating, engine.rig.isSettled, engine.crossfade == nil, !isDeviceTiltEnabled, !engine.settleScheduled {
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
        travel { $0.focus(pose: pose, lens: lens, camera: WorldSprings.buildPush) }
        kick()
    }

    /// The sheet returns to medium and the camera settles back to the
    /// station's focus, unless the user already closed the sheet.
    public func endBuildFraming(_ station: StationID) {
        guard buildFraming == station else { return }
        buildFraming = nil
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
