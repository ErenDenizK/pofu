import PofuCore
import PofuDesignSystem
import PofuScreenTime
import SwiftUI

/// Rehearsal mode's stand-in for Apple's Screen Time permission alert
/// (gate v2, O3), labelled as such. The labels follow iOS's; the real
/// ones are recorded on membership day 1.
struct RehearsalPermissionAlert: View {
    /// The user's answer: `true` for Continue.
    let answer: (Bool) -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .accessibilityHidden(true)
            VStack(spacing: PofuSpacing.m) {
                VStack(spacing: 0) {
                    VStack(spacing: PofuSpacing.xs) {
                        Text("“Pofu” Would Like to Access Screen Time")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .accessibilityAddTraits(.isHeader)
                        Text("Providing “Pofu” access to Screen Time may allow it to see your activity data, restrict content, and limit the usage of apps and websites.")
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                    }
                    .padding(PofuSpacing.l)
                    Divider()
                    Button {
                        answer(true)
                    } label: {
                        Text("Continue")
                            .font(.body.weight(.semibold))
                            .frame(maxWidth: .infinity, minHeight: PofuSize.minimumTouch)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.accentColor)
                    Divider()
                    Button {
                        answer(false)
                    } label: {
                        Text("Don’t Allow")
                            .font(.body)
                            .frame(maxWidth: .infinity, minHeight: PofuSize.minimumTouch)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.accentColor)
                }
                .frame(width: 280)
                .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(.regularMaterial))
                RehearsalBadge(text: Text("Rehearsal: on a device, this screen is Apple's"))
            }
        }
    }
}

/// Rehearsal mode's stand-in for Apple's app picker
/// (`FamilyActivityPicker`, gate v2 O5): categories that expand into their
/// apps, a whole category or single apps. It returns the simulated
/// system's opaque tokens.
struct RehearsalAppPicker: View {
    let initial: DistractionSelection
    let done: (DistractionSelection) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selection = DistractionSelection.empty
    @State private var expanded: Set<RehearsalCatalog.Category> = [.social]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(RehearsalCatalog.Category.allCases) { category in
                        categoryRow(category)
                        if expanded.contains(category) {
                            ForEach(RehearsalCatalog.apps(in: category)) { app in
                                appRow(app)
                            }
                        }
                    }
                } header: {
                    Text("All Apps & Categories")
                } footer: {
                    RehearsalBadge(text: Text("Rehearsal: on a device, this screen is Apple's"))
                        .frame(maxWidth: .infinity)
                        .padding(.top, PofuSpacing.m)
                }
            }
            .navigationTitle(Text("Choose Activities"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        done(selection)
                        dismiss()
                    }
                }
            }
        }
        .onAppear { selection = initial }
    }

    private func categoryRow(_ category: RehearsalCatalog.Category) -> some View {
        let isOn = selection.categories.contains(category.token)
        return HStack(spacing: PofuSpacing.m) {
            checkbox(isOn) {
                if isOn {
                    selection.categories.remove(category.token)
                } else {
                    selection.categories.insert(category.token)
                }
            }
            Image(systemName: category.symbolName)
                .foregroundStyle(Color.accentColor)
                .frame(width: 24)
                .accessibilityHidden(true)
            categoryName(category)
            Spacer()
            Button {
                if expanded.contains(category) {
                    expanded.remove(category)
                } else {
                    expanded.insert(category)
                }
            } label: {
                Image(systemName: expanded.contains(category) ? "chevron.down" : "chevron.right")
                    .foregroundStyle(.secondary)
                    .frame(width: PofuSize.minimumTouch, height: PofuSize.minimumTouch)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Show apps"))
        }
    }

    private func appRow(_ app: RehearsalCatalog.CatalogApp) -> some View {
        let inCategory = selection.categories.contains(app.category.token)
        let isOn = inCategory || selection.applications.contains(app.token)
        return HStack(spacing: PofuSpacing.m) {
            checkbox(isOn) {
                if selection.applications.contains(app.token) {
                    selection.applications.remove(app.token)
                } else {
                    selection.applications.insert(app.token)
                }
            }
            .disabled(inCategory)
            Text(verbatim: app.name)
            Spacer()
        }
        .padding(.leading, PofuSpacing.xl)
    }

    private func checkbox(_ isOn: Bool, toggle: @escaping () -> Void) -> some View {
        Button(action: toggle) {
            Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(isOn ? Color.accentColor : Color.secondary)
                .frame(width: 32, height: PofuSize.minimumTouch)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }

    private func categoryName(_ category: RehearsalCatalog.Category) -> Text {
        switch category {
        case .social: Text("Social")
        case .entertainment: Text("Entertainment")
        }
    }
}
