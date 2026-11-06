import PofuDesignSystem
import SwiftUI

/// One look for every sheet over Home: the sunken surface, an inline
/// title, and a close button (✕) at the leading edge. Apply it to the root
/// view inside the sheet's `NavigationStack`; set the title at the call
/// site with `navigationTitle`.
struct PofuSheetChrome: ViewModifier {
    /// Runs before the sheet closes, for sheets that save on the way out.
    var onClose: (@MainActor () -> Void)?

    @Environment(\.dismiss) private var dismiss

    func body(content: Content) -> some View {
        content
            .scrollContentBackground(.hidden)
            .background(PofuColor.sunken)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        PofuHaptics.shared.play(.tap)
                        onClose?()
                        dismiss()
                    } label: {
                        PofuDuoIcon(.duoClose, size: 24, fallback: "xmark")
                    }
                    .accessibilityLabel(Text("Close"))
                }
            }
    }
}

/// A row label with a painted icon in place of an SF Symbol.
struct PaintedLabel: View {
    let title: LocalizedStringKey
    let paint: PofuPaint

    init(_ title: LocalizedStringKey, paint: PofuPaint) {
        self.title = title
        self.paint = paint
    }

    var body: some View {
        Label {
            Text(title)
        } icon: {
            PofuPaintedIcon(paint, size: 26)
        }
    }
}

/// The section header of every sheet and list: `subheadline` in
/// `text.secondary`, in sentence case.
struct PofuSectionHeader: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(PofuFont.subheadline)
            .foregroundStyle(PofuColor.textSecondary)
            .textCase(nil)
    }
}

extension View {
    /// Pofu's sheet chrome; see `PofuSheetChrome`.
    func pofuSheetChrome(onClose: (@MainActor () -> Void)? = nil) -> some View {
        modifier(PofuSheetChrome(onClose: onClose))
    }

    /// Pofu's section header style; see `PofuSectionHeader`.
    func pofuSectionHeader() -> some View {
        modifier(PofuSectionHeader())
    }
}
