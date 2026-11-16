import Foundation

/// The camera and the lens as springs (interaction spec §1.9, §12.6):
/// a rail position, an off-rail focus pose blended in by an amount, a lens
/// focus blended over the rail's lens, and a screen offset for the peek
/// and the pinch's pull. Pure and deterministic, so tests can drive it.
public struct CameraRig: Hashable, Sendable {
    public private(set) var rail: CameraRail

    /// The rail position (ADR-0027: Map 0, mid 1, near limit 2); may run past 0 or 2 inside a
    /// rubber band.
    public private(set) var z: WorldSpring
    /// How much of the focus pose replaces the rail's (0…1).
    public private(set) var focusAmount: WorldSpring
    public private(set) var focusLogScale: WorldSpring
    public private(set) var focusLookX: WorldSpring
    public private(set) var focusLookY: WorldSpring
    public private(set) var focusAnchorY: WorldSpring

    /// How much of the focus lens replaces the rail's lens (0…1).
    public private(set) var lensAmount: WorldSpring
    public private(set) var lensFocus: WorldSpring
    public private(set) var lensSlab: WorldSpring
    public private(set) var lensGain: WorldSpring

    /// Screen offset, in points: the peek drag and the pinch's pull.
    public private(set) var offsetX: WorldSpring
    public private(set) var offsetY: WorldSpring

    /// Reduce Motion: automatic travel lands in 200 ms, no overshoot.
    public var reduceMotion = false

    /// The camera's springs; the tuning lab panel tunes them live.
    public var springs = CameraSprings.standard

    /// Near's free camera (ADR-0027): world units added to the rail's look on each axis. A
    /// pinch sets it so the world point under the fingers stays there; a one-finger drag at near
    /// moves it inside `CameraRail.nearBounds`; landing on the Map or mid springs it to zero.
    public private(set) var freeX: WorldSpring
    public private(set) var freeY: WorldSpring
    /// The free offset when the finger went down, during a near drag.
    public private(set) var freeStart: WorldPoint?

    /// The pinch in progress: its starting `ln s`.
    public private(set) var pinchStart: Double?

    /// Where a flight ends: on the rail (a framing of the home island) or at
    /// a pose off it (another island's Island stop).
    public enum FlightLanding: Hashable, Sendable {
        case rail(WorldFraming)
        case pose(CameraPose)
    }

    /// The flight in progress (§1.2) and how long it has run.
    public private(set) var flight: CameraFlight?
    public private(set) var flightTime = 0.0
    private var flightLanding = FlightLanding.rail(.mid)

    public init(framing: WorldFraming = .mid, rail: CameraRail = CameraRail()) {
        self.rail = rail
        z = WorldSpring(framing.z)
        focusAmount = WorldSpring(0)
        let pose = rail.pose(of: framing)
        focusLogScale = WorldSpring(pose.logScale)
        focusLookX = WorldSpring(pose.lookX)
        focusLookY = WorldSpring(pose.lookY)
        focusAnchorY = WorldSpring(pose.anchorY)
        lensAmount = WorldSpring(0)
        let lens = Lens.rail(z: Self.layerPosition(z: framing.z))
        lensFocus = WorldSpring(lens.focus)
        lensSlab = WorldSpring(lens.slab)
        lensGain = WorldSpring(lens.gain)
        offsetX = WorldSpring(0)
        offsetY = WorldSpring(0)
        freeX = WorldSpring(0)
        freeY = WorldSpring(0)
        z = WorldSpring(rail.z(of: framing))
    }

    // MARK: - Reading

    /// The camera now.
    public var pose: CameraPose {
        if let flight {
            return flight.pose(at: flightTime)
        }
        var onRail = rail.pose(z: z.value)
        onRail.lookX += freeX.value
        onRail.lookY += freeY.value
        let amount = min(max(focusAmount.value, 0), 1.2)
        guard amount > 0 else { return onRail }
        return CameraPose.mix(onRail, focusPose, amount)
    }

    /// The focus pose the camera blends toward.
    public var focusPose: CameraPose {
        CameraPose(logScale: focusLogScale.value, lookX: focusLookX.value, lookY: focusLookY.value, anchorY: focusAnchorY.value)
    }

    /// The lens now.
    public var lens: Lens {
        let onRail = Lens.rail(z: layerPosition)
        let amount = min(max(lensAmount.value, 0), 1)
        guard amount > 0 else { return onRail }
        return Lens.mix(onRail, Lens(focus: lensFocus.value, slab: lensSlab.value, gain: max(lensGain.value, 0)), amount)
    }

    /// The rail position clamped to the framings.
    public var railPosition: Double {
        min(max(z.value, 0), 2)
    }

    /// The rail position in the layers' older terms (Map 0, the whole island 1, Home 2), which
    /// the depth layers, the lens and the far sky still read: the Map-to-mid segment spans 0 to
    /// 2, so mid draws as Home did, and near draws as Home. WP11 gives near its own lens.
    public var layerPosition: Double {
        Self.layerPosition(z: z.value)
    }

    public static func layerPosition(z: Double) -> Double {
        min(max(z, 0), 1) * 2
    }

    /// The chrome's opacity now (ADR-0027): 1 at mid, 0 from 1.25 x the mid scale in.
    public var chromeOpacity: Double {
        rail.chromeOpacity(logScale: pose.logScale)
    }

    /// The framing the camera is at or heading to.
    public var framing: WorldFraming {
        WorldFraming.nearest(to: z.target)
    }

    public var isFocused: Bool {
        focusAmount.target > 0
    }

    /// Whether every spring is at rest and no pinch is down.
    public var isSettled: Bool {
        flight == nil && pinchStart == nil && freeStart == nil && allSprings.allSatisfy { $0.isSettled(tolerance: 5e-4) }
    }

    /// Whether the camera is moving: a finger driving it, a flight, or a
    /// spring that has not come to rest. Depth of field is off while this
    /// holds and racks in once it ends (§1.2); the lens springs are the
    /// rack itself, so they do not count.
    /// A pan or pinch is in progress: a finger is down on the rail.
    public var isFingerDown: Bool { pinchStart != nil || freeStart != nil }

    public var isMoving: Bool {
        if flight != nil || pinchStart != nil || freeStart != nil { return true }
        let motion = [z, focusAmount, focusLogScale, focusLookX, focusLookY, focusAnchorY, offsetX, offsetY, freeX, freeY]
        return !motion.allSatisfy { $0.isSettled(tolerance: 5e-4) }
    }

    private var allSprings: [WorldSpring] {
        [z, focusAmount, focusLogScale, focusLookX, focusLookY, focusAnchorY, lensAmount, lensFocus, lensSlab, lensGain, offsetX, offsetY, freeX, freeY]
    }

    // MARK: - Time

    /// Advances every spring by `dt` seconds.
    public mutating func advance(_ dt: Double) {
        if let flight {
            flightTime += dt
            let logScale = flight.pose(at: flightTime).logScale
            z.jump(to: min(max(rail.z(logScale: logScale), 0), 1))
            if flight.isFinished(at: flightTime) {
                finishFlight()
            }
            return
        }
        z.step(dt)
        focusAmount.step(dt)
        focusLogScale.step(dt)
        focusLookX.step(dt)
        focusLookY.step(dt)
        focusAnchorY.step(dt)
        lensAmount.step(dt)
        lensFocus.step(dt)
        lensSlab.step(dt)
        lensGain.step(dt)
        offsetX.step(dt)
        offsetY.step(dt)
        freeX.step(dt)
        freeY.step(dt)
        if isSettled {
            snapToTargets()
        }
    }

    /// Puts every spring at its target, at rest.
    public mutating func snapToTargets() {
        z.jump(to: z.target)
        focusAmount.jump(to: focusAmount.target)
        focusLogScale.jump(to: focusLogScale.target)
        focusLookX.jump(to: focusLookX.target)
        focusLookY.jump(to: focusLookY.target)
        focusAnchorY.jump(to: focusAnchorY.target)
        lensAmount.jump(to: lensAmount.target)
        lensFocus.jump(to: lensFocus.target)
        lensSlab.jump(to: lensSlab.target)
        lensGain.jump(to: lensGain.target)
        offsetX.jump(to: offsetX.target)
        offsetY.jump(to: offsetY.target)
        freeX.jump(to: freeX.target)
        freeY.jump(to: freeY.target)
    }

    /// A new viewport: the rail rescales; a focus keeps its targets until
    /// the caller refocuses.
    public mutating func resize(width: Double, height: Double) {
        guard width != rail.width || height != rail.height else { return }
        rail = CameraRail(width: width, height: height, stops: rail.stops, whole: rail.whole, island: rail.island)
    }

    /// New stops for the rail (a plate-first home shows or leaves): the
    /// rail position stays, so the camera lands on the new framing at once.
    public mutating func setStops(_ stops: [CameraRail.Stop], whole: CameraRail.Stop?, island: WorldBox? = nil) {
        guard stops != rail.stops || whole != rail.whole || island != rail.island else { return }
        rail = CameraRail(width: rail.width, height: rail.height, stops: stops, whole: whole, island: island)
    }

    // MARK: - Framings

    /// Flies to a framing, letting go of any focus. Flights to or from the
    /// Map use the farther spring.
    public mutating func fly(to framing: WorldFraming) {
        flight = nil
        let far = framing == .map || self.framing == .map
        let spring = reduceMotion ? WorldSprings.reduced : (far ? springs.far.token : springs.travel.token)
        z.retarget(rail.z(of: framing), duration: spring.duration, bounce: spring.bounce)
        // Every arrival opens on the island's own look.
        freeX.retarget(0, duration: spring.duration, bounce: 0)
        freeY.retarget(0, duration: spring.duration, bounce: 0)
        releaseFocus()
    }

    /// Flies to `target` (§1.2): up over the sea, across, and down. It lasts
    /// `CameraFlight.duration`; under Reduce Motion the camera jumps.
    public mutating func startFlight(to target: CameraPose, landing: FlightLanding) {
        let start = pose
        flightLanding = landing
        focusAmount.jump(to: 0)
        lensAmount.jump(to: 0)
        freeX.jump(to: 0)
        freeY.jump(to: 0)
        if reduceMotion {
            flight = nil
            finishFlight()
            return
        }
        flight = CameraFlight(from: start, to: target, apexLogScale: rail.pose(z: CameraFlight.apexZ).logScale)
        flightTime = 0
    }

    /// Holds the flight in progress at `progress` (0...1) of its length, still (screenshots): the pose
    /// and the rail position are the flight's there.
    public mutating func holdFlight(at progress: Double) {
        guard let flight else { return }
        flightTime = min(max(progress, 0), 1) * flight.duration
        z.jump(to: min(max(rail.z(logScale: flight.pose(at: flightTime).logScale), 0), 1))
    }

    private mutating func finishFlight() {
        flight = nil
        flightTime = 0
        switch flightLanding {
        case .rail(let framing):
            z.jump(to: rail.z(of: framing))
            focusAmount.jump(to: 0)
        case .pose(let pose):
            z.jump(to: WorldFraming.mid.z)
            focusLogScale.jump(to: pose.logScale)
            focusLookX.jump(to: pose.lookX)
            focusLookY.jump(to: pose.lookY)
            focusAnchorY.jump(to: pose.anchorY)
            focusAmount.jump(to: 1)
        }
        lensAmount.jump(to: 0)
        freeX.jump(to: 0)
        freeY.jump(to: 0)
    }

    // MARK: - Focus

    /// Moves the camera to `pose` off the rail and racks the lens to
    /// `lens`. A retarget keeps the current motion.
    public mutating func focus(pose target: CameraPose, lens: Lens, camera spring: (duration: Double, bounce: Double)? = nil) {
        let camera = reduceMotion ? WorldSprings.reduced : (spring ?? springs.focus.token)
        let rack = reduceMotion ? WorldSprings.reduced : WorldSprings.rack
        if flight != nil {
            // Caught mid-flight: continue from where the camera is.
            let now = pose
            flight = nil
            focusAmount.jump(to: 1)
            focusLogScale.jump(to: now.logScale)
            focusLookX.jump(to: now.lookX)
            focusLookY.jump(to: now.lookY)
            focusAnchorY.jump(to: now.anchorY)
        }
        if focusAmount.value < 1e-3 && focusAmount.target == 0 {
            // From the rail: start the focus pose where the camera is, so
            // only the blend animates.
            let now = pose
            focusLogScale.jump(to: now.logScale)
            focusLookX.jump(to: now.lookX)
            focusLookY.jump(to: now.lookY)
            focusAnchorY.jump(to: now.anchorY)
            let railLens = Lens.rail(z: layerPosition)
            lensFocus.jump(to: railLens.focus)
            lensSlab.jump(to: railLens.slab)
            lensGain.jump(to: railLens.gain)
        }
        focusAmount.retarget(1, duration: camera.duration, bounce: 0)
        focusLogScale.retarget(target.logScale, duration: camera.duration, bounce: camera.bounce)
        focusLookX.retarget(target.lookX, duration: camera.duration, bounce: camera.bounce)
        focusLookY.retarget(target.lookY, duration: camera.duration, bounce: camera.bounce)
        focusAnchorY.retarget(target.anchorY, duration: camera.duration, bounce: camera.bounce)
        lensAmount.retarget(1, duration: rack.duration, bounce: 0)
        lensFocus.retarget(lens.focus, duration: rack.duration, bounce: 0)
        lensSlab.retarget(lens.slab, duration: rack.duration, bounce: 0)
        lensGain.retarget(lens.gain, duration: rack.duration, bounce: 0)
    }

    /// Returns the camera and the lens to the rail, where the user came
    /// from (§2.5).
    public mutating func releaseFocus() {
        let back = reduceMotion ? WorldSprings.reduced : WorldSprings.refocus
        let rack = reduceMotion ? WorldSprings.reduced : WorldSprings.rack
        focusAmount.retarget(0, duration: back.duration, bounce: 0)
        lensAmount.retarget(0, duration: rack.duration, bounce: 0)
    }

    // MARK: - Pinch

    /// A pinch begins: the camera stops where it is (a moving camera is caught, §7.3), and a
    /// focus folds into the rail and the free offset at once, so the frame does not move.
    public mutating func beginPinch() {
        let now = pose
        flight = nil
        freeStart = nil
        let banded = rail.bandedLogScale(raw: now.logScale)
        let railZ = rail.z(logScale: banded)
        z.jump(to: railZ)
        let base = rail.pose(z: railZ)
        freeX.jump(to: now.lookX - base.lookX)
        freeY.jump(to: now.lookY - base.lookY + (base.anchorY - now.anchorY) / max(base.scale, 1e-6))
        if focusAmount.target > 0 || focusAmount.value > 0 {
            focusAmount.jump(to: 0)
            releaseFocus()
        }
        offsetX.jump(to: 0)
        offsetY.jump(to: 0)
        pinchStart = banded
    }

    /// The fingers moved: `magnification` since the pinch began. Returns
    /// the banded `ln s`.
    @discardableResult
    public mutating func pinch(magnification: Double) -> Double {
        if pinchStart == nil {
            beginPinch()
        }
        let start = pinchStart ?? rail.logScale(z: z.value)
        let raw = start + log(max(magnification, 1e-3))
        let banded = rail.bandedLogScale(raw: raw)
        z.jump(to: rail.z(logScale: banded))
        return banded
    }

    /// The fingers moved: `magnification` since the pinch began, about the world point `world`
    /// first pinched, which sat at screen point (`x`, `y`): it stays under the fingers.
    @discardableResult
    public mutating func pinch(magnification: Double, keeping world: WorldPoint, atScreenX x: Double, y: Double) -> Double {
        let banded = pinch(magnification: magnification)
        let free = rail.free(keeping: world, atScreenX: x, y: y, z: z.value)
        freeX.jump(to: free.x)
        freeY.jump(to: free.y)
        return banded
    }

    /// The fingers lifted with `velocity` (ln s per second), `idle`
    /// seconds after the last move: the Map, mid, or near where it is (ADR-0027).
    @discardableResult
    public mutating func endPinch(velocity: Double, idle: TimeInterval) -> CameraRelease.Landing {
        pinchStart = nil
        let landing = CameraRelease.landing(logScale: rail.logScale(z: z.value), velocity: velocity, idle: idle, rail: rail)
        let spring: (duration: Double, bounce: Double)
        if reduceMotion {
            spring = WorldSprings.reduced
        } else {
            spring = landing.fromBand ? WorldSprings.cameraFromBand : springs.release.token
        }
        z.retarget(landing.z, duration: spring.duration, bounce: spring.bounce)
        z.velocity = landing.velocityZ
        let free = landing.framing == .near ? rail.clampedFree(x: freeX.value, y: freeY.value, z: landing.z) : (x: 0, y: 0)
        freeX.retarget(free.x, duration: spring.duration, bounce: 0)
        freeY.retarget(free.y, duration: spring.duration, bounce: 0)
        settleOffset()
        return landing
    }

    // MARK: - Peek

    /// The asymptote of the peek drag, in points.
    public static let peekLimit = 30.0

    /// A one-finger drag on the world: the camera follows with a rubber
    /// band (§1.5).
    public mutating func peek(dx: Double, dy: Double) {
        let bandX = CameraRail.rubberBand(abs(dx), limit: Self.peekLimit) * (dx < 0 ? -1 : 1)
        let bandY = CameraRail.rubberBand(abs(dy), limit: Self.peekLimit) * (dy < 0 ? -1 : 1)
        offsetX.jump(to: bandX)
        offsetY.jump(to: bandY)
    }

    /// The peek or the pull springs back.
    public mutating func settleOffset() {
        let spring = reduceMotion ? WorldSprings.reduced : WorldSprings.peek
        offsetX.retarget(0, duration: spring.duration, bounce: spring.bounce)
        offsetY.retarget(0, duration: spring.duration, bounce: spring.bounce)
    }

    /// The parallax tilt from the peek, −1…1 on each axis.
    public var peekTilt: (x: Double, y: Double) {
        (offsetX.value / Self.peekLimit, offsetY.value / Self.peekLimit)
    }

    // MARK: - Near's free pan

    /// Whether the camera is in near's free range (z past 1.12), where a drag pans.
    public var isNear: Bool {
        z.target > WorldFraming.nearAboveZ
    }

    /// A one-finger drag at near, `dx`/`dy` points since it began: the island follows the
    /// finger on both axes while the screen's centre stays inside the island box grown 10 %,
    /// then a 30 pt rubber band.
    public mutating func freeDrag(dx: Double, dy: Double) {
        if freeStart == nil {
            freeStart = WorldPoint(x: freeX.value, y: freeY.value)
        }
        let s = max(rail.pose(z: z.value).scale, 1e-6)
        let start = freeStart ?? WorldPoint(x: 0, y: 0)
        let banded = rail.bandedFree(x: start.x - dx / s, y: start.y - dy / s, z: z.value)
        freeX.jump(to: banded.x)
        freeY.jump(to: banded.y)
    }

    /// The finger lifted at (`vx`, `vy`) points per second: the pan coasts about a third of a
    /// second's worth, like a scroll view, and settles inside the bounds.
    public mutating func endFreeDrag(vx: Double, vy: Double) {
        freeStart = nil
        let s = max(rail.pose(z: z.value).scale, 1e-6)
        let inside = rail.clampedFree(x: freeX.value, y: freeY.value, z: z.value)
        let movedIn = abs(inside.x - freeX.value) < 1e-9 && abs(inside.y - freeY.value) < 1e-9
        let coast = movedIn ? 0.33 : 0
        let target = rail.clampedFree(x: freeX.value - vx / s * coast, y: freeY.value - vy / s * coast, z: z.target)
        let spring = reduceMotion ? WorldSprings.reduced : springs.release.token
        freeX.retarget(target.x, duration: spring.duration, bounce: 0)
        freeY.retarget(target.y, duration: spring.duration, bounce: 0)
        if movedIn {
            freeX.velocity = -vx / s
            freeY.velocity = -vy / s
        }
    }

    /// Near's rest on a character (ADR-0027): the camera at rest scale with `feet` at screen
    /// point (`x`, `y`), kept inside the near bounds. Returns the free offset it aims for.
    @discardableResult
    public mutating func rest(on feet: WorldPoint, screenX x: Double, screenY y: Double, animated: Bool = true) -> (x: Double, y: Double) {
        flight = nil
        freeStart = nil
        let restZ = rail.restZ
        let aim = rail.free(keeping: feet, atScreenX: x, y: y, z: restZ)
        let target = rail.clampedFree(x: aim.x, y: aim.y, z: restZ)
        if animated && !reduceMotion {
            let spring = springs.travel.token
            z.retarget(restZ, duration: spring.duration, bounce: 0)
            freeX.retarget(target.x, duration: spring.duration, bounce: 0)
            freeY.retarget(target.y, duration: spring.duration, bounce: 0)
        } else {
            z.jump(to: restZ)
            freeX.jump(to: target.x)
            freeY.jump(to: target.y)
        }
        releaseFocus()
        return target
    }

    /// Puts the free offset at (`x`, `y`), at rest (screenshots, tests).
    public mutating func jumpFree(x: Double, y: Double) {
        freeStart = nil
        freeX.jump(to: x)
        freeY.jump(to: y)
    }

    // MARK: - Jumps (tests, screenshots, restoring)

    /// Puts the camera on the rail at position `railZ`, at rest, with no
    /// focus (screenshots, tests).
    public mutating func jump(toZ railZ: Double) {
        jump(to: .mid)
        z.jump(to: railZ)
    }

    /// Puts the camera at a framing, at rest, with no focus.
    public mutating func jump(to framing: WorldFraming) {
        flight = nil
        z.jump(to: rail.z(of: framing))
        focusAmount.jump(to: 0)
        lensAmount.jump(to: 0)
        offsetX.jump(to: 0)
        offsetY.jump(to: 0)
        freeX.jump(to: 0)
        freeY.jump(to: 0)
        pinchStart = nil
        freeStart = nil
    }
}
