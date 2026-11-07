import PofuCompanion
import PofuCore
import PofuDesignSystem
import PofuScreenTime
import SwiftUI
import UIKit

/// Rehearsal mode's replica of the Screen Time shield: the copy, icon and
/// palette the real configuration extension would draw (`ShieldCopy`,
/// `ShieldColors`, `ShieldIconImage`, shared with it), laid out like
/// Apple's shield template. Its buttons go to the same answers as the
/// action extension's.
struct ShieldReplicaView: View {
    let model: AppModel
    let copy: ShieldCopy
    /// The sky the shield is painted from (dawn, day, dusk or night); the
    /// hour's sky unless a screenshot or the Prova panel pins one.
    var sky = ShieldSky(date: Date())

    @Environment(\.colorScheme) private var colorScheme
    @State private var tapped = 0

    private var shieldColors: ShieldColors {
        ShieldColors(palette: copy.palette, sky: sky)
    }

    var body: some View {
        let colors = shieldColors
        ZStack {
            Color(uiColor: colors.background)
                .ignoresSafeArea()
            VStack(spacing: 0) {
                RehearsalBadge(text: Text("Rehearsal: on a device, this screen is Apple's"))
                    .padding(.top, PofuSpacing.s)
                Spacer(minLength: PofuSpacing.l)
                icon
                    .padding(.bottom, PofuSpacing.l)
                Text(verbatim: copy.title)
                    .font(.system(.title2, weight: .bold))
                    .foregroundStyle(Color(uiColor: colors.title))
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                Text(verbatim: copy.subtitle)
                    .font(.system(.body))
                    .foregroundStyle(Color(uiColor: colors.subtitle))
                    .multilineTextAlignment(.center)
                    .padding(.top, PofuSpacing.s)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: PofuSpacing.l)
                buttons(colors)
                homeIndicator
            }
            .padding(.horizontal, PofuSpacing.xl)
        }
        // The system draws the shield in the app's place, light or dark;
        // bedtime and the night sky are always dark; dusk is warm apricot.
        .environment(\.colorScheme, ShieldColors.isDark(palette: copy.palette, sky: sky) ? .dark : colorScheme)
        .sensoryFeedback(.selection, trigger: tapped)
    }

    @ViewBuilder private var icon: some View {
        if let image = ShieldIconImage.image(for: copy.icon, palette: copy.palette, locate: Self.locate) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .accessibilityHidden(true)
        }
    }

    private func buttons(_ colors: ShieldColors) -> some View {
        VStack(spacing: PofuSpacing.s) {
            Button {
                press(.primary)
            } label: {
                Text(verbatim: copy.primary.label)
                    .font(.system(.body, weight: .semibold))
                    .foregroundStyle(Color(uiColor: colors.primaryLabel))
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(uiColor: colors.primaryFill))
                    )
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            if let secondary = copy.secondary {
                let label = Text(verbatim: secondary.label)
                    .font(.system(.body, weight: .medium))
                    .foregroundStyle(Color(uiColor: colors.secondaryLabel))
                    .frame(maxWidth: .infinity, minHeight: PofuSize.minimumTouch)
                    .contentShape(Rectangle())
                if copy.submenu.isEmpty {
                    Button {
                        press(.secondary)
                    } label: {
                        label
                    }
                    .buttonStyle(.plain)
                } else {
                    // iOS 26.4: the secondary button opens its submenu.
                    Menu {
                        ForEach(copy.submenu.indices, id: \.self) { index in
                            Button {
                                press(.submenuItem(index))
                            } label: {
                                Text(verbatim: copy.submenu[index].label)
                            }
                        }
                    } label: {
                        label
                    }
                }
            }
        }
    }

    /// Leaving the shield without a tap: the swipe home. Nothing is drawn:
    /// the system's own home indicator is the cue (founder, 2026-11-07), so
    /// this is only an invisible swipe area at the bottom edge.
    private var homeIndicator: some View {
        Button {
            model.rehearsalGoHome()
        } label: {
            Color.clear
                .frame(maxWidth: .infinity, minHeight: PofuSize.minimumTouch)
                .contentShape(Rectangle())
        }
        .accessibilityLabel(Text("Go home"))
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 20).onEnded { value in
                if value.translation.height < -30 {
                    model.rehearsalGoHome()
                }
            }
        )
        .padding(.top, PofuSpacing.m)
        .padding(.bottom, PofuSpacing.xs)
    }

    private func press(_ button: ShieldButton) {
        tapped += 1
        Task {
            await model.rehearsalShieldButton(button)
        }
    }

    /// The extension's bundle holds the shield icons; in the app, Pofu's
    /// portrait comes from PofuCompanion's resources.
    private nonisolated static func locate(_ name: String) -> URL? {
        ShieldIconImage.mainBundlePNG(named: name) ?? CompanionArt.resourceURL(named: name)
    }
}

/// The small label that marks a screen as Rehearsal mode's stand-in.
struct RehearsalBadge: View {
    let text: Text

    var body: some View {
        HStack(spacing: PofuSpacing.xs) {
            Image(systemName: "theatermasks.fill")
                .accessibilityHidden(true)
            text
        }
        .font(PofuFont.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, PofuSpacing.s)
        .padding(.vertical, PofuSpacing.xs)
        .background(Capsule(style: .continuous).fill(.ultraThinMaterial))
        .accessibilityElement(children: .combine)
    }
}
