#if os(iOS)
import SwiftUI

/// The crafted layer's SwiftUI pieces for the game HUD and cards
/// (ui-system-v2 §2, layer C): paper plates with a stitched edge and
/// violet-glazed clay buttons. Drawn stand-ins until the painted faces
/// (`ui-face-primary`, the paper plate slices) are generated; the shapes,
/// sizes and states are final, only the fill becomes art.
enum GardenInk {
    static let ink = Color(red: 0.36, green: 0.24, blue: 0.16)
    static let paperTop = Color(red: 1.0, green: 0.975, blue: 0.91)
    static let paperBottom = Color(red: 0.97, green: 0.90, blue: 0.78)
    static let stitch = Color(red: 0.84, green: 0.56, blue: 0.37)
    static let glaze = Color(red: 0.53, green: 0.42, blue: 0.86)
    static let glazeLight = Color(red: 0.66, green: 0.56, blue: 0.95)
    static let glazeLip = Color(red: 0.38, green: 0.29, blue: 0.66)
    static let scrim = Color(red: 0.25, green: 0.16, blue: 0.10)
}

/// Warm paper with a stitched inner edge and a soft shadow.
struct PaperSurface<S: InsettableShape>: View {
    let shape: S
    var stitchInset: CGFloat = 5

    var body: some View {
        shape
            .fill(LinearGradient(colors: [GardenInk.paperTop, GardenInk.paperBottom], startPoint: .top, endPoint: .bottom))
            .overlay {
                shape
                    .inset(by: stitchInset)
                    .stroke(GardenInk.stitch.opacity(0.55), style: StrokeStyle(lineWidth: 1.6, lineCap: .round, dash: [6, 3.5]))
            }
            .shadow(color: GardenInk.ink.opacity(0.22), radius: 8, y: 4)
    }
}

/// A violet-glazed clay capsule: a darker lip under a glossy face. The
/// face sinks onto the lip when pressed.
struct ClayButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        return configuration.label
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 28)
            .frame(minWidth: 200, minHeight: 52)
            .background {
                ZStack {
                    Capsule(style: .continuous)
                        .fill(GardenInk.glazeLip)
                        .offset(y: 4)
                    Capsule(style: .continuous)
                        .fill(LinearGradient(colors: [GardenInk.glazeLight, GardenInk.glaze], startPoint: .top, endPoint: .bottom))
                        .offset(y: pressed ? 3 : 0)
                    Capsule(style: .continuous)
                        .inset(by: 3)
                        .trim(from: 0.55, to: 0.95)
                        .stroke(.white.opacity(0.45), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .offset(y: pressed ? 3 : 0)
                }
            }
            .offset(y: pressed ? 3 : 0)
            .scaleEffect(pressed ? 0.98 : 1)
            .animation(.spring(duration: 0.18, bounce: 0.4), value: pressed)
            .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.6), trigger: pressed) { _, new in new }
    }
}

/// A plain text action on paper ("Enough for today" inside a set).
struct PaperTextButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundStyle(GardenInk.ink.opacity(configuration.isPressed ? 0.45 : 0.75))
            .frame(minHeight: 44)
            .contentShape(Rectangle())
    }
}

/// A sunflower seed, drawn: a dark teardrop with cream stripes (the
/// vector twin of the painted seed, used below 28 pt).
struct SeedGlyph: View {
    var body: some View {
        Canvas { context, size in
            let rect = CGRect(origin: .zero, size: size)
            var path = Path()
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addCurve(
                to: CGPoint(x: rect.midX, y: rect.maxY),
                control1: CGPoint(x: rect.maxX + rect.width * 0.15, y: rect.minY + rect.height * 0.3),
                control2: CGPoint(x: rect.maxX, y: rect.maxY - rect.height * 0.05)
            )
            path.addCurve(
                to: CGPoint(x: rect.midX, y: rect.minY),
                control1: CGPoint(x: rect.minX, y: rect.maxY - rect.height * 0.05),
                control2: CGPoint(x: rect.minX - rect.width * 0.15, y: rect.minY + rect.height * 0.3)
            )
            context.fill(path, with: .color(Color(red: 0.27, green: 0.23, blue: 0.21)))
            context.clip(to: path)
            var stripes = Path()
            for fraction in [0.28, 0.5, 0.72] {
                let x = rect.width * CGFloat(fraction)
                stripes.move(to: CGPoint(x: x, y: rect.height * 0.18))
                stripes.addLine(to: CGPoint(x: x, y: rect.height * 0.9))
            }
            context.stroke(stripes, with: .color(Color(red: 0.93, green: 0.90, blue: 0.82)), lineWidth: max(1, rect.width * 0.09))
        }
        .accessibilityHidden(true)
    }
}

/// A painted bloom from the bundle, as a SwiftUI image.
struct BloomImage: View {
    var small = false

    var body: some View {
        if let image = GardenTextures.image(small ? .bloomSmall : .bloom) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .accessibilityHidden(true)
        }
    }
}
#endif
