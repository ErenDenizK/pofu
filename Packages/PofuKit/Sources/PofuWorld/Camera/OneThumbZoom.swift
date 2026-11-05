import Foundation

/// One-thumb zoom (§1.2): double tap, hold, then drag down to zoom in or
/// up to zoom out, as in Apple Maps. A small state machine fed with touch
/// events; it reports the magnification to give the pinch.
public struct OneThumbZoom: Sendable {
    /// The second touch must land this soon after the first lifts (s).
    public static let doubleTapWindow = 0.35
    /// ... and this close to it (pt).
    public static let slop = 30.0
    /// The drag must travel this far before the zoom starts (pt).
    public static let dragStart = 8.0
    /// Points of drag per e-fold of scale.
    public static let pointsPerE = 160.0

    private var lastUp: (time: Double, x: Double, y: Double)?
    private var armed = false
    private var startY = 0.0
    public private(set) var isZooming = false
    /// Where the zoom is anchored on screen.
    public private(set) var anchor: (x: Double, y: Double) = (0, 0)

    public init() {}

    /// A finger touched down.
    public mutating func touchDown(time: Double, x: Double, y: Double) {
        armed = false
        isZooming = false
        if let up = lastUp,
           time - up.time <= Self.doubleTapWindow,
           abs(x - up.x) <= Self.slop, abs(y - up.y) <= Self.slop {
            armed = true
            startY = y
            anchor = (x, y)
        }
    }

    /// The finger moved to `y`. Returns the magnification to apply since
    /// the zoom began, or `nil` while it has not started.
    public mutating func touchMoved(y: Double) -> Double? {
        guard armed else { return nil }
        if !isZooming {
            guard abs(y - startY) >= Self.dragStart else { return nil }
            isZooming = true
        }
        return Self.magnification(dragged: y - startY)
    }

    /// The finger lifted. Returns whether a one-thumb zoom just ended.
    @discardableResult
    public mutating func touchUp(time: Double, x: Double, y: Double) -> Bool {
        let wasZooming = isZooming
        armed = false
        isZooming = false
        // A zoom (or the second tap of a double tap) uses the pair up.
        if wasZooming {
            lastUp = nil
        } else if let up = lastUp, time - up.time <= Self.doubleTapWindow {
            lastUp = nil
        } else {
            lastUp = (time, x, y)
        }
        return wasZooming
    }

    /// Down is in, up is out.
    public static func magnification(dragged dy: Double) -> Double {
        exp(dy / pointsPerE)
    }
}
