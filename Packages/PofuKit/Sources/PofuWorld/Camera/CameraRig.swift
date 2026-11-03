import Foundation

/// The camera and the lens as springs (interaction spec §1.9, §12.6):
/// a rail position, an off-rail focus pose blended in by an amount, a lens
/// focus blended over the rail's lens, and a screen offset for the peek
/// and the pinch's pull. Pure and deterministic, so tests can drive it.
public struct CameraRig: Hashable, Sendable {
    public private(set) var rail: CameraRail

    /// The rail position; may run past 0 or 2 inside a rubber band.
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

    /// The island pan (look round 4): world units added to the Island
    /// stop's look x, faded out toward the Map and toward Home, so the
    /// Island framing is a horizontal pan across the island at a scale
    /// where Pofu is at least 80 pt.
    public private(set) var pan: WorldSpring
    /// The pan when the finger went down.
    public private(set) var panStart: Double?

    /// The pinch in progress: its starting `ln s`.
    public private(set) var pinchStart: Double?

    public init(framing: WorldFraming = .home, rail: CameraRail = CameraRail()) {
        self.rail = rail
        z = WorldSpring(framing.z)
        focusAmount = WorldSpring(0)
        let pose = rail.pose(of: framing)
        focusLogScale = WorldSpring(pose.logScale)
        focusLookX = WorldSpring(pose.lookX)
        focusLookY = WorldSpring(pose.lookY)
        focusAnchorY = WorldSpring(pose.anchorY)
        lensAmount = WorldSpring(0)
        let lens = Lens.rail(z: framing.z)
        lensFocus = WorldSpring(lens.focus)
        lensSlab = WorldSpring(lens.slab)
        lensGain = WorldSpring(lens.gain)
        offsetX = WorldSpring(0)
        offsetY = WorldSpring(0)
        pan = WorldSpring(0)
    }

    // MARK: - Reading

    /// The camera now.
    public var pose: CameraPose {
        var onRail = rail.pose(z: z.value)
        onRail.lookX += pan.value * panWeight
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
        let onRail = Lens.rail(z: z.value)
        let amount = min(max(lensAmount.value, 0), 1)
        guard amount > 0 else { return onRail }
        return Lens.mix(onRail, Lens(focus: lensFocus.value, slab: lensSlab.value, gain: max(lensGain.value, 0)), amount)
    }

    /// The rail position clamped to the framings, for chrome.
    public var railPosition: Double {
        min(max(z.value, 0), 2)
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
        pinchStart == nil && panStart == nil && allSprings.allSatisfy { $0.isSettled(tolerance: 5e-4) }
    }

    private var allSprings: [WorldSpring] {
        [z, focusAmount, focusLogScale, focusLookX, focusLookY, focusAnchorY, lensAmount, lensFocus, lensSlab, lensGain, offsetX, offsetY, pan]
    }

    // MARK: - Time

    /// Advances every spring by `dt` seconds.
    public mutating func advance(_ dt: Double) {
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
        pan.step(dt)
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
        pan.jump(to: pan.target)
    }

    /// A new viewport: the rail rescales; a focus keeps its targets until
    /// the caller refocuses.
    public mutating func resize(width: Double, height: Double) {
        guard width != rail.width || height != rail.height else { return }
        rail = CameraRail(width: width, height: height, stops: rail.stops)
    }

    // MARK: - Framings

    /// Flies to a framing, letting go of any focus. Flights to or from the
    /// Map use the farther spring.
    public mutating func fly(to framing: WorldFraming) {
        let far = framing == .map || self.framing == .map
        let spring = reduceMotion ? WorldSprings.reduced : (far ? springs.far.token : springs.travel.token)
        z.retarget(framing.z, duration: spring.duration, bounce: spring.bounce)
        // Every arrival opens centred on Pofu.
        pan.retarget(0, duration: spring.duration, bounce: 0)
        releaseFocus()
    }

    // MARK: - Focus

    /// Moves the camera to `pose` off the rail and racks the lens to
    /// `lens`. A retarget keeps the current motion.
    public mutating func focus(pose target: CameraPose, lens: Lens, camera spring: (duration: Double, bounce: Double)? = nil) {
        let camera = reduceMotion ? WorldSprings.reduced : (spring ?? springs.focus.token)
        let rack = reduceMotion ? WorldSprings.reduced : WorldSprings.rack
        if focusAmount.value < 1e-3 && focusAmount.target == 0 {
            // From the rail: start the focus pose where the camera is, so
            // only the blend animates.
            let now = pose
            focusLogScale.jump(to: now.logScale)
            focusLookX.jump(to: now.lookX)
            focusLookY.jump(to: now.lookY)
            focusAnchorY.jump(to: now.anchorY)
            let railLens = Lens.rail(z: z.value)
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

    /// A pinch begins: the camera stops where it is (a moving camera is
    /// caught, §7.3), and a focus folds back into the rail.
    public mutating func beginPinch() {
        let now = pose
        let banded = rail.bandedLogScale(raw: now.logScale)
        let railZ = rail.z(logScale: banded)
        z.jump(to: railZ)
        if focusAmount.target > 0 || focusAmount.value > 0 {
            // The focus pose glides back into the rail while the fingers
            // drive the scale.
            releaseFocus()
        }
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

    /// The fingers lifted with `velocity` (ln s per second), `idle`
    /// seconds after the last move.
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
        z.retarget(landing.framing.z, duration: spring.duration, bounce: spring.bounce)
        z.velocity = landing.velocityZ
        settleOffset()
        return landing
    }

    /// The pinch's 35 % pull toward keeping the pinched point under the
    /// fingers (§1.3): `world` is the point first pinched, which sat at
    /// screen point (`x`, `y`).
    public mutating func pull(toward world: WorldPoint, screenX x: Double, screenY y: Double) {
        let now = pose.project(world, width: rail.width)
        offsetX.jump(to: (x - now.x) * 0.35)
        offsetY.jump(to: (y - now.y) * 0.35)
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

    // MARK: - Island pan

    /// How much of the pan shows at the rail position: all of it at the
    /// Island framing, none by the Map's half-way point or at Home.
    public var panWeight: Double {
        let z = z.value
        if z <= 0.5 || z >= 2 { return 0 }
        if z < 1 {
            let t = (z - 0.5) / 0.5
            return t * t * (3 - 2 * t)
        }
        return 2 - z
    }

    /// The pan's band past either end, in points.
    public static let panBand = 60.0

    /// A horizontal drag at the Island framing: the island follows the
    /// finger (`dx` points since the drag began) and rubber-bands past its
    /// ends.
    public mutating func panDrag(dx: Double) {
        if panStart == nil {
            panStart = pan.value
        }
        let s = max(rail.pose(of: .island).scale, 1e-3)
        let raw = (panStart ?? 0) - dx / s
        let range = IslandFraming.panRange
        let band = Self.panBand / s
        let banded: Double
        if raw > range.upperBound {
            banded = range.upperBound + CameraRail.rubberBand(raw - range.upperBound, limit: band)
        } else if raw < range.lowerBound {
            banded = range.lowerBound - CameraRail.rubberBand(range.lowerBound - raw, limit: band)
        } else {
            banded = raw
        }
        pan.jump(to: banded)
    }

    /// The finger lifted at `velocity` points per second: the pan coasts
    /// with momentum and settles on the snap point nearest where it would
    /// have stopped (a station or Pofu). Returns the snap.
    @discardableResult
    public mutating func endPan(velocity: Double) -> Double {
        panStart = nil
        let s = max(rail.pose(of: .island).scale, 1e-3)
        let range = IslandFraming.panRange
        let v = -velocity / s
        let inside = range.contains(pan.value)
        // UIScrollView's normal deceleration coasts about a third of a
        // second's worth of the release velocity.
        let projected = min(max(pan.value + (inside ? v * 0.33 : 0), range.lowerBound), range.upperBound)
        let target = IslandFraming.panSnaps.min { abs($0 - projected) < abs($1 - projected) } ?? projected
        let spring = reduceMotion ? WorldSprings.reduced : springs.release.token
        pan.retarget(target, duration: spring.duration, bounce: inside ? spring.bounce : 0)
        pan.velocity = inside ? v : 0
        return target
    }

    /// Glides the pan to `target` on the release spring.
    public mutating func panTo(_ target: Double) {
        panStart = nil
        let spring = reduceMotion ? WorldSprings.reduced : springs.release.token
        pan.retarget(target, duration: spring.duration, bounce: 0)
    }

    /// Puts the pan at `value`, at rest (screenshots, tests).
    public mutating func jumpPan(to value: Double) {
        panStart = nil
        pan.jump(to: value)
    }

    // MARK: - Jumps (tests, screenshots, restoring)

    /// Puts the camera at a framing, at rest, with no focus.
    public mutating func jump(to framing: WorldFraming) {
        z.jump(to: framing.z)
        focusAmount.jump(to: 0)
        lensAmount.jump(to: 0)
        offsetX.jump(to: 0)
        offsetY.jump(to: 0)
        pan.jump(to: 0)
        pinchStart = nil
        panStart = nil
    }
}
