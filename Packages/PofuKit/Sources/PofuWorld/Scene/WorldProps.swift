#if os(iOS)
import SwiftUI

/// The camera at one frame, for views that live in the world (experience
/// v1 §1.4): the home objects are projected with the same pose as Pofu, so
/// they never lag or bob.
@MainActor
public struct WorldPropsFrame {
    public let pose: CameraPose
    public let size: CGSize
    /// The peek or pinch offset, in points.
    public let offset: CGSize
    /// The rail position.
    public let z: Double
    /// Something is focused: the home objects step aside.
    public let isFocused: Bool
    let model: IslandSceneModel

    /// The screen point of a world point at this frame.
    public func point(of world: WorldPoint) -> CGPoint {
        let p = pose.project(world, width: Double(size.width))
        return CGPoint(x: p.x + Double(offset.width), y: p.y + Double(offset.height))
    }

    /// The factor that keeps an object drawn at its Home size in step with
    /// the world: 1 at the Home framing, smaller as the camera pulls out.
    public var homeFactor: Double {
        pose.scale / (IslandFraming.homeScale * Double(size.width) / CameraRail.referenceWidth)
    }

    /// How present the home objects are at this camera: gone on the
    /// Archipelago, full from the Island framing in.
    public var presence: Double {
        guard !isFocused else { return 0 }
        return min(max((z - 0.35) / 0.4, 0), 1)
    }

    /// The squish of a tapped prop.
    public func pulse(of prop: HomeSlots.Prop) -> Int {
        model.pulses["prop-\(prop.rawValue)", default: 0]
    }

    /// Reports a prop's projected centre, for the screenshot tests.
    public func report(_ prop: HomeSlots.Prop, _ frame: CGRect) {
        model.reportProp(prop, frame)
    }
}

/// What the world draws for the home objects, supplied by Home (§1.4): the
/// jar, the lantern and the pots in the world canvas, and the jar's count
/// tag and Collect action as screen overlays. The tap itself goes through
/// the one resolver; `IslandSceneModel.onPropTap` answers it.
public struct WorldProps {
    /// The objects, in the world's depth-of-field group.
    public var world: (WorldPropsFrame) -> AnyView
    /// The tag and the Collect action, in screen points, never graded.
    public var screen: (WorldPropsFrame) -> AnyView

    public init(world: @escaping (WorldPropsFrame) -> AnyView, screen: @escaping (WorldPropsFrame) -> AnyView) {
        self.world = world
        self.screen = screen
    }
}

/// A tapped target's squish (§1.3): a quick press and spring back, about
/// its base, answering within the frame.
struct TapSquish: ViewModifier {
    let trigger: Int
    let anchor: UnitPoint

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        let calm = reduceMotion
        return content.keyframeAnimator(initialValue: 1.0, trigger: trigger) { view, scale in
            view.scaleEffect(x: calm ? 1 : 1 + (1 - scale) * 0.6, y: calm ? 1 : scale, anchor: anchor)
        } keyframes: { _ in
            KeyframeTrack {
                CubicKeyframe(0.92, duration: 0.07)
                SpringKeyframe(1.0, duration: 0.28, spring: .bouncy)
            }
        }
    }
}
#endif
