#if os(iOS)
import CoreMotion
import Foundation

/// Device-tilt parallax (interaction spec §12.3 a): the phone's attitude
/// at 30 Hz, ±18° as full tilt, with the zero point recentring by 1 % per
/// update the way iOS wallpapers do. Attitude needs no permission prompt
/// in a native app. Behind `IslandSceneModel.isDeviceTiltEnabled`.
@MainActor
final class DeviceTilt {
    private let manager = CMMotionManager()
    private var zeroRoll: Double?
    private var zeroPitch: Double?
    /// −1…1 on each axis.
    private(set) var x = 0.0
    private(set) var y = 0.0

    static let fullTilt = 18.0 * Double.pi / 180
    static let recentring = 0.01

    func start() {
        guard manager.isDeviceMotionAvailable, !manager.isDeviceMotionActive else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 30
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let motion else { return }
            let roll = motion.attitude.roll
            let pitch = motion.attitude.pitch
            MainActor.assumeIsolated {
                self?.update(roll: roll, pitch: pitch)
            }
        }
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
        zeroRoll = nil
        zeroPitch = nil
        x = 0
        y = 0
    }

    private func update(roll: Double, pitch: Double) {
        let baseRoll = zeroRoll ?? roll
        let basePitch = zeroPitch ?? pitch
        zeroRoll = baseRoll + (roll - baseRoll) * Self.recentring
        zeroPitch = basePitch + (pitch - basePitch) * Self.recentring
        x = min(max((roll - baseRoll) / Self.fullTilt, -1), 1)
        y = min(max((pitch - basePitch) / Self.fullTilt, -1), 1)
    }
}
#endif
