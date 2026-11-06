#if canImport(SwiftUI)
import SwiftUI

/// The primary plaque of the gate and, since UI v3, of the whole app: a
/// thin front for the kit's `PofuPlaqueStyle` (`Kit/KitPlaque.swift`),
/// kept so the Hop! call sites do not change. The prominent plaque is honey
/// wood, the other is cream linen; with a `progress`, honey fills the
/// plaque from the leading edge like a progress bar (the pause rung).
public struct PofuPlaqueButtonStyle: ButtonStyle {
    public var isProminent: Bool
    public var progress: Double?

    public init(isProminent: Bool = false, progress: Double? = nil) {
        self.isProminent = isProminent
        self.progress = progress
    }

    public static let cocoa = Color(red: 0x4A / 255, green: 0x33 / 255, blue: 0x26 / 255)
    public static let cream = Color(red: 0xFF / 255, green: 0xF6 / 255, blue: 0xEC / 255)
    public static let honey = Color(red: 0xF6 / 255, green: 0xC4 / 255, blue: 0x53 / 255)

    public func makeBody(configuration: Configuration) -> some View {
        PofuPlaqueBody(configuration: configuration, kind: isProminent ? .primary : .secondary, progress: progress, haptic: .tap)
    }
}
#endif
