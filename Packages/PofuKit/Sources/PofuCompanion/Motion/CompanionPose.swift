import Foundation

/// Everything the renderer needs for one frame of Pofu, derived from the
/// motion simulation. Pure numbers, so it can be tested and logged.
///
/// Lengths are fractions of the character's height, angles are radians.
public struct CompanionPose: Hashable, Sendable {
    /// Horizontal scale about the bottom center.
    public var scaleX: Double = 1
    /// Vertical scale about the bottom center.
    public var scaleY: Double = 1
    /// Horizontal shear of the top relative to the planted feet, as a
    /// fraction of the height (soft-body lean and sway).
    public var lean: Double = 0
    /// Height of the feet above the floor.
    public var hop: Double = 0
    /// Cheek-pouch inflation in `0...1` (drives the shader).
    public var cheekPuff: Double = 0
    /// Upper-lid closure in `0...1`: blinks, sleepiness.
    public var lidClosure: Double = 0
    /// Happy squint in `0...1`: the lower lid rises into a ^ arc.
    public var happiness: Double = 0
    /// Sadness in `0...1`: tilts the upper lids down toward the outer
    /// corners, so a low Pofu reads sad rather than bored.
    public var sadness: Double = 0
    /// Blush intensity in `0...1`.
    public var blush: Double = 0
    /// Color saturation multiplier (vitality drains color).
    public var saturation: Double = 1
    /// Brightness offset in `-1...1` (vitality dims slightly).
    public var brightness: Double = 0
    /// Tuft follow-through angle.
    public var tuftAngle: Double = 0
    /// Contact shadow scale in `0...1`; shrinks while airborne.
    public var shadowScale: Double = 1
    /// Fur ripple strength in `0...1`.
    public var furRipple: Double = 1
    /// Seconds since the simulation started, for shader noise.
    public var time: Double = 0

    public init() {}
}
