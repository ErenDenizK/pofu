#if canImport(SwiftUI)
import SwiftUI

/// A painted-looking plaque for screens that sit on a postcard (the gate):
/// a cream card with cocoa ink and a soft inner shadow, never glass and
/// never the system tint. The prominent plaque is honey, 52 pt tall; the
/// quiet one is cream, a little lower. With a `progress`, honey fills the
/// plaque from the leading edge like a progress bar (the pause rung).
public struct PofuPlaqueButtonStyle: ButtonStyle {
    public var isProminent: Bool
    public var progress: Double?

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(isProminent: Bool = false, progress: Double? = nil) {
        self.isProminent = isProminent
        self.progress = progress
    }

    public static let cocoa = Color(red: 0x4A / 255, green: 0x33 / 255, blue: 0x26 / 255)
    public static let cream = Color(red: 0xFF / 255, green: 0xF6 / 255, blue: 0xEC / 255)
    public static let honey = Color(red: 0xF6 / 255, green: 0xC4 / 255, blue: 0x53 / 255)

    public func makeBody(configuration: Configuration) -> some View {
        let shape = Capsule(style: .continuous)
        configuration.label
            .font(PofuFont.headline)
            .multilineTextAlignment(.center)
            .foregroundStyle(isEnabled ? Self.cocoa : Self.cocoa.opacity(0.55))
            .padding(.horizontal, PofuSpacing.xl)
            .frame(maxWidth: .infinity, minHeight: isProminent ? PofuSize.buttonHeight : PofuSize.minimumTouch + 4)
            .background {
                ZStack(alignment: .leading) {
                    shape.fill(isProminent ? Self.honey : Self.cream)
                    if let progress {
                        GeometryReader { proxy in
                            Rectangle()
                                .fill(Self.honey)
                                .frame(width: proxy.size.width * min(max(progress, 0), 1))
                        }
                    }
                    // The inner shadow: a soft cocoa rim pushed down, clipped
                    // to the plaque, and a bright top edge.
                    shape
                        .strokeBorder(Self.cocoa.opacity(0.2), lineWidth: 4)
                        .blur(radius: 2.5)
                        .offset(y: 2)
                        .clipShape(shape)
                    shape
                        .strokeBorder(
                            LinearGradient(colors: [.white.opacity(0.85), Self.cocoa.opacity(0.18)], startPoint: .top, endPoint: .bottom),
                            lineWidth: 1.5
                        )
                }
                .clipShape(shape)
                .brightness(configuration.isPressed ? -0.06 : 0)
                .shadow(color: Self.cocoa.opacity(isEnabled ? 0.28 : 0.1), radius: 8, y: 4)
            }
            .opacity(isEnabled ? 1 : 0.7)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .animation(PofuMotion.respecting(reduceMotion, PofuMotion.squish), value: configuration.isPressed)
            .contentShape(shape)
    }
}
#endif
