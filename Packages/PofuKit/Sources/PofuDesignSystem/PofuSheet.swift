import Foundation

// Sheets: glass when cheap, paper at large (experience-v1 section 3.1) and
// the five-slot anatomy of section 3.2. The rules are pure so they are
// tested on any platform.

/// What a sheet's surface is made of.
public enum PofuSheetSurfaceMode: Equatable, Sendable {
    /// Native glass over the frozen world.
    case glass
    /// Opaque paper.
    case paper
}

/// When the surface is glass and when it is paper.
public enum PofuSheetSurfaceRule {
    /// From this share of the screen's height, nothing shows behind the
    /// sheet any more: the large detent.
    public static let paperFraction = 0.8

    /// - Parameters:
    ///   - sheetFraction: the sheet's height as a share of the screen's.
    ///   - worldIsFrozen: the world beneath is a still, flattened frame
    ///     (`View.pofuFlattenWhenCovered`). Glass over a moving world would
    ///     re-sample it every frame, so it is never glass then.
    ///   - reduceTransparency: Reduce Transparency switches everything to
    ///     paper.
    public static func mode(sheetFraction: Double, worldIsFrozen: Bool, reduceTransparency: Bool) -> PofuSheetSurfaceMode {
        guard worldIsFrozen, !reduceTransparency, sheetFraction < paperFraction else { return .paper }
        return .glass
    }
}

/// How the world beneath a sheet steps back: one grade parameter, no blur.
public enum PofuSheetBackdrop {
    /// Darkened by this share.
    public static let dim = 0.12
    /// Desaturated by this share.
    public static let desaturation = 0.10
    /// Seconds to reach it, and to come back.
    public static let duration = 0.25
}

#if canImport(SwiftUI)
import SwiftUI

/// Whether the world is frozen under a sheet or a cover. The world's view
/// sets it through `pofuFlattenWhenCovered`; the sheet surface reads it.
@MainActor
@Observable
public final class PofuWorldFreeze {
    public static let shared = PofuWorldFreeze()
    public var isFrozen = false
    private init() {}
}

extension View {
    /// Freezes then flattens: while `covered`, the subtree is drawn once
    /// into a single offscreen texture, so glass over it samples a still
    /// image and the grade and depth passes stop running. On close the
    /// world resumes from the same frame. Apply it to a render subtree that
    /// keeps its state outside the view (the model), because the flattened
    /// and live subtrees are different view identities.
    @ViewBuilder
    public func pofuFlattenWhenCovered(_ covered: Bool) -> some View {
        if covered {
            drawingGroup()
                .onAppear { PofuWorldFreeze.shared.isFrozen = true }
                .onDisappear { PofuWorldFreeze.shared.isFrozen = false }
        } else {
            self
        }
    }

    /// The world beneath a sheet steps back by `PofuSheetBackdrop`.
    public func pofuSheetDim(_ covered: Bool) -> some View {
        brightness(covered ? -PofuSheetBackdrop.dim : 0)
            .saturation(covered ? 1 - PofuSheetBackdrop.desaturation : 1)
            .animation(.easeOut(duration: PofuSheetBackdrop.duration), value: covered)
    }
}

#if canImport(UIKit)
import UIKit

/// A sheet's surface: glass over the frozen world at partial detents,
/// paper at large. It crossfades between them as the sheet grows.
struct PofuSheetSurface: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorScheme) private var scheme
    private var freeze = PofuWorldFreeze.shared

    var body: some View {
        GeometryReader { proxy in
            let fraction = Double(proxy.size.height / max(Self.screenHeight, 1))
            let mode = PofuSheetSurfaceRule.mode(
                sheetFraction: fraction,
                worldIsFrozen: freeze.isFrozen,
                reduceTransparency: reduceTransparency
            )
            ZStack {
                if mode == .glass {
                    Color.clear
                        .glassEffect(.regular.tint(PofuColor.canvas.opacity(scheme == .dark ? 0.2 : 0.3)), in: Rectangle())
                }
                PofuColor.sunken
                    .opacity(mode == .paper ? 1 : 0)
            }
            .animation(.easeOut(duration: PofuSheetBackdrop.duration), value: mode)
        }
        .ignoresSafeArea()
    }

    private static var screenHeight: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.screen.bounds.height ?? 852
    }
}

extension View {
    /// The sheet surface of the design system: glass over the frozen
    /// world at partial detents, opaque paper at large. Content is never
    /// glass; cards are paper.
    public func pofuSheetBackground() -> some View {
        presentationBackground { PofuSheetSurface() }
    }
}
#endif

#if canImport(UIKit)
/// The painted header plate of a sheet (112 pt): a vignette on paper, the
/// name in SF Pro Rounded title2 bold, optional drawn level pips, and a
/// close button.
public struct PofuHeaderPlate: View {
    let paint: PofuPaint?
    let title: String
    let subtitle: String?
    let pips: (level: Int, max: Int)?
    let compact: Bool
    let onClose: (@MainActor () -> Void)?
    let closeLabel: Text

    public static let height: CGFloat = 112

    public init(
        paint: PofuPaint?,
        title: String,
        subtitle: String? = nil,
        pips: (level: Int, max: Int)? = nil,
        compact: Bool = false,
        closeLabel: Text = Text(verbatim: "Close"),
        onClose: (@MainActor () -> Void)? = nil
    ) {
        self.paint = paint
        self.title = title
        self.subtitle = subtitle
        self.pips = pips
        self.compact = compact
        self.closeLabel = closeLabel
        self.onClose = onClose
    }

    public var body: some View {
        HStack(alignment: .center, spacing: PofuSpacing.m) {
            if let paint, paint.isAvailable {
                PofuPaintedIcon(paint, size: compact ? 40 : 64)
                    .padding(PofuSpacing.xs)
                    .background { PofuPaperPanel() }
            }
            VStack(alignment: .leading, spacing: PofuSpacing.xs) {
                Text(verbatim: title)
                    .font(PofuFont.title2)
                    .foregroundStyle(PofuColor.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                if let subtitle {
                    Text(verbatim: subtitle)
                        .font(PofuFont.subheadline)
                        .foregroundStyle(PofuColor.textSecondary)
                }
                if let pips {
                    HStack(spacing: 6) {
                        ForEach(1...max(pips.max, 1), id: \.self) { level in
                            Circle()
                                .fill(level <= pips.level ? PofuColor.accent : PofuColor.hairline)
                                .frame(width: 10, height: 10)
                        }
                    }
                    .accessibilityHidden(true)
                }
            }
            Spacer(minLength: 0)
            if let onClose {
                Button(action: onClose) {
                    PofuDuoIcon(.duoClose, size: 24, fallback: "xmark")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color(red: 0.24, green: 0.18, blue: 0.14))
                        .frame(width: PofuSize.minimumTouch, height: PofuSize.minimumTouch)
                        .background { Circle().fill(PofuColor.card) }
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(closeLabel)
            }
        }
        .frame(minHeight: compact ? nil : Self.height - PofuSpacing.l)
    }
}

#endif

/// The sheet anatomy of section 3.2: the grabber (the system's), a header
/// plate, **the one thing**, one primary action pinned at the bottom with
/// any secondary action as a text button, and one flavour line in Pofu's
/// voice. At most three blocks sit above the fold at the medium detent.
public struct PofuSheetScaffold<Plate: View, Thing: View, Action: View, Flavour: View>: View {
    let plate: Plate
    let thing: Thing
    let action: Action
    let flavour: Flavour

    public init(
        @ViewBuilder plate: () -> Plate,
        @ViewBuilder thing: () -> Thing,
        @ViewBuilder action: () -> Action,
        @ViewBuilder flavour: () -> Flavour
    ) {
        self.plate = plate()
        self.thing = thing()
        self.action = action()
        self.flavour = flavour()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: PofuSpacing.l) {
            plate
            ScrollView {
                thing
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollBounceBehavior(.basedOnSize)
            VStack(spacing: PofuSpacing.s) {
                action
                flavour
            }
        }
        .padding(.horizontal, PofuSpacing.screen)
        .padding(.top, PofuSpacing.xl)
        .padding(.bottom, PofuSpacing.l)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        #if os(iOS)
        .presentationDragIndicator(.visible)
        #endif
    }
}
#endif
