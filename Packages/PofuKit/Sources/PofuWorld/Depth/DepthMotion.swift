import Foundation

/// How fast the camera moves at one instant: the look point in world units
/// per second and the scale in ln s per second.
public struct CameraMotion: Hashable, Sendable {
    public var lookX: Double
    public var lookY: Double
    public var logScale: Double
    /// How strongly layers parallax for this motion, as a multiple of the
    /// authored lead (the tuning lab panel's `depth.parallax`).
    public var parallax: Double = 1

    public init(lookX: Double, lookY: Double, logScale: Double) {
        self.lookX = lookX
        self.lookY = lookY
        self.logScale = logScale
    }

    /// This motion with its parallax scaled by `gain`.
    public func parallax(_ gain: Double) -> CameraMotion {
        var copy = self
        copy.parallax = max(gain.isFinite ? gain : 1, 0)
        return copy
    }

    /// At rest.
    public static let still = CameraMotion(lookX: 0, lookY: 0, logScale: 0)

    /// 0 at rest, 1 at a typical flight's peak (a Home ↔ Island flight peaks
    /// near 1.5 ln s per second; a station pan near 200 units per second).
    public var speed: Double {
        let pan = hypot(lookX, lookY) / DepthMotion.referencePan
        let zoom = abs(logScale) / DepthMotion.referenceZoom
        let s = max(pan, zoom)
        return s.isFinite ? min(s, 1) : 0
    }
}

/// Depth in motion (look round 2, the founder's HD-2D note: "moving back and
/// forth in that 2.5D world, the blur strengthens the 3D perception").
///
/// While the camera moves, each layer is offset by its distance from the
/// focus plane times the camera's velocity, so near layers sweep past
/// faster and far ones lag: motion parallax. The offset follows velocity,
/// not displacement, so it is zero when the camera starts and when it
/// rests, and the settled composition is exactly the authored one. The
/// depth of field strengthens with speed (the focus slab narrows), then
/// settles back to the framing's lens. At rest nothing is added, so a
/// settled world still costs nothing; Reduce Motion turns it off.
public enum DepthMotion {
    /// The flight speeds that count as 1 (see `CameraMotion.speed`).
    static let referencePan = 200.0
    static let referenceZoom = 1.5

    /// How far ahead of the camera, in seconds, a layer one depth unit off
    /// the focus plane leads or lags, per unit of depth.
    public static let panLead = 0.11 * 0.005
    /// The same for a zoom, as a fraction of the point's distance from the
    /// look point.
    public static let zoomLead = 0.11 * 0.0045
    /// The largest offset, in world units: enough to read on a phone (round
    /// 2's first take, 5, was invisible in the strip), small enough that the
    /// plate's bands, which overlap by 8 units, never part.
    public static let maxShift = 8.0
    /// How much stronger the depth of field is at full speed.
    public static let lensBoost = 0.9

    /// The extra offset, in world units, of a layer anchored at `point` at
    /// `depth`, for a camera looking at `look` with lens focus `focus`.
    public static func shift(
        point: WorldPoint,
        depth: Double,
        focus: Double,
        look: WorldPoint,
        motion: CameraMotion
    ) -> WorldPoint {
        guard motion != .still else { return .zero }
        let k = depth - focus
        // A pan: nearer layers move further against it, farther ones lag.
        var dx = -k * panLead * motion.lookX
        var dy = -k * panLead * motion.lookY
        // A zoom: nearer layers spread from the look point faster.
        dx += (point.x - look.x) * k * zoomLead * motion.logScale
        dy += (point.y - look.y) * k * zoomLead * motion.logScale
        dx *= motion.parallax
        dy *= motion.parallax
        let length = hypot(dx, dy)
        guard length.isFinite else { return .zero }
        let cap = maxShift * max(motion.parallax, 1)
        if length > cap {
            dx *= cap / length
            dy *= cap / length
        }
        return WorldPoint(x: dx, y: dy)
    }

    /// The lens during a move: the depth of field strengthens with speed.
    public static func lens(_ lens: Lens, motion: CameraMotion) -> Lens {
        let speed = motion.speed
        guard speed > 0 else { return lens }
        return lens.tiltShifted(by: 1 + lensBoost * speed)
    }
}

extension CameraRig {
    /// How fast the camera moves now, from the springs' own velocities (a
    /// look ahead of 1/120 s); `still` when settled or under Reduce Motion,
    /// where travel is a cross-fade.
    public var motion: CameraMotion {
        guard !reduceMotion, !isSettled else { return .still }
        let h = 1.0 / 120
        var ahead = self
        ahead.advance(h)
        let a = pose, b = ahead.pose
        let m = CameraMotion(lookX: (b.lookX - a.lookX) / h, lookY: (b.lookY - a.lookY) / h, logScale: (b.logScale - a.logScale) / h)
        return m.lookX.isFinite && m.lookY.isFinite && m.logScale.isFinite ? m : .still
    }
}
