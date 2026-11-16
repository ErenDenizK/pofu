import Foundation

/// Near's rest on a character (ADR-0027): the camera at `CameraRail.nearRestScale` with the
/// character's feet at 0.60 of the height and at the middle of the width moved up to 0.12 of
/// the width away from the side he faces, so there is room in front of him. The numbers are
/// `world-map.json`'s `near` (feet) and the spec's look room.
public enum NearShot {
    /// The feet's row, as a share of the height.
    public static let feetY = WorldMap.shipped?.nearFeetY ?? 0.60
    /// The feet's column, as a share of the width, before the look room.
    public static let feetX = WorldMap.shipped?.nearFeetX ?? 0.50
    /// The look room: the feet move this share of the width away from the side he faces.
    public static let lookRoom = 0.12

    /// The screen point the feet rest at, on a `width` x `height` screen.
    public static func rest(width: Double, height: Double, facesLeft: Bool) -> (x: Double, y: Double) {
        let x = (feetX + (facesLeft ? lookRoom : -lookRoom)) * width
        return (x, feetY * height)
    }
}
