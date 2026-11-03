import Foundation
#if canImport(os)
import os
#endif
import PofuCore
import PofuPersistence

/// A button on the shield, as the action extension hears it.
public enum ShieldButton: Hashable, Sendable {
    case primary
    case secondary
    /// The secondary button's submenu item at a 0-based index (iOS 26.4).
    case submenuItem(Int)
}

/// What the shield extensions decide, without the system frameworks: which
/// shield to draw and what a button does, through the files in a storage
/// location (gate v2, section 5).
///
/// The shield configuration and action extensions call it with the App
/// Group, and Rehearsal mode (the free build) calls it with its own folder,
/// so the in-app replica of the shield draws the same shield, writes the
/// same records, and answers the same buttons as the real one. Only the
/// effects that need the system (lifting a shield in ManagedSettings,
/// posting the notification) are passed in.
public struct ShieldExtensionCore: Sendable {
    #if canImport(os)
    private static let log = Logger(subsystem: "com.erendenizk.pofu", category: "shield")
    #endif

    /// A tap belongs to the shield drawn for the app within this window.
    public static let shownWindow: TimeInterval = 30 * 60

    public let location: StorageLocation
    public let calendar: Calendar

    public init(location: StorageLocation, calendar: Calendar) {
        self.location = location
        self.calendar = calendar
    }

    // MARK: - The configuration extension

    /// The shield for an app the system could not identify: no files, no
    /// record.
    public static func fallbackShield(appName: String?, at now: Date, calendar: Calendar, language: ShieldLanguage) -> ShieldCopy {
        let context = ShieldContext(
            appName: appName,
            hour: calendar.component(.hour, from: now),
            submenuAvailable: false
        )
        return ShieldCopy.make(context: context, language: language)
    }

    /// The shield for `app` at `now`, from what the app and the other
    /// extensions wrote. A new reach is recorded as `shieldShown` and
    /// remembered, so the action extension knows what was drawn; a redraw
    /// within seconds returns the same shield without a new record.
    public func drawShield(for app: ShieldedApp, at now: Date, language: ShieldLanguage, submenuAvailable: Bool) -> ShieldCopy {
        let store = ShieldContextStore(location: location)
        let inbox = ScreenTimeInbox(location: location)
        let live = LiveShieldState.file(in: location).read()
        var memory = store.memory.read() ?? ShieldMemory()
        let ended = live?.lastEndedLift(for: [app.token], at: now)
        let inputs = ShieldContextInputs(
            app: app,
            now: now,
            calendar: calendar,
            appState: store.appState.read(),
            pendingRecords: inbox.read().records,
            measuredUsage: store.usage.read(),
            memory: memory,
            openRequest: store.openRequest.read(),
            endedPass: ended.map { (end: $0.until, minutes: $0.minutes) },
            lastQuickCheckEnd: live?.lastQuickCheckEnd,
            submenuAvailable: submenuAvailable
        )
        let context = inputs.context
        let rules = inputs.effectiveRules
        if let redraw = memory.recent(for: app.tokenKey, scene: context.scene, at: now, window: rules.reachDeduplicationWindow) {
            // The system drew the same shield again within seconds (the
            // app switcher, a re-render): the same reach, the same words.
            return redraw
        }
        let copy = ShieldCopy.make(context: context, language: language, rules: rules)
        try? inbox.post(ScreenTimeRecord(at: now, kind: .shieldShown(app: app, scene: copy.scene)))
        memory.note(copy, for: app.tokenKey, at: now, on: LocalDay(containing: now, in: calendar))
        try? store.memory.write(memory)
        return copy
    }

    /// Notes what the system says about the app behind a token, for the
    /// action extension, which is told only the token. Best effort.
    public func remember(_ app: ShieldedApp) {
        let entry = ShieldDirectoryEntry(token: app.token, bundleIdentifier: app.bundleIdentifier, displayName: app.displayName)
        try? ShieldDirectory(location: location).record(entry)
    }

    // MARK: - The action extension

    /// The shield the configuration extension drew last for `app`, if a tap
    /// at `now` can belong to it.
    public func shownShield(for app: ShieldedApp, at now: Date) -> ShieldCopy? {
        ShieldContextStore(location: location).memory.read()?.lastShown(for: app.tokenKey, at: now, within: Self.shownWindow)
    }

    /// What `button` means on the shield `shown`. Without a remembered
    /// shield, the buttons keep their default meaning.
    public static func intent(for button: ShieldButton, shown: ShieldCopy?) -> ShieldIntent {
        switch button {
        case .primary:
            return shown?.primary.intent ?? .skip
        case .secondary:
            return shown?.secondaryIntent ?? .openWithPofu
        case .submenuItem(let index):
            return shown?.submenuIntent(at: index) ?? (index == 0 ? .quickCheck : .openWithPofu)
        }
    }

    /// What the extensions need the system for.
    public struct Effects {
        /// Lifts the shield from the app (its raw token) for a quick check:
        /// pass id, from, until. Throws when nothing could be lifted.
        public var liftForQuickCheck: (ShieldedApp, UUID, Date, Date) throws -> Void
        /// Posts the "Open with Pofu" notification about the app, for a
        /// breath or not; returns whether it was handed to the system.
        public var postNotification: (ShieldedApp, Bool) -> Bool
        /// Withdraws that notification, delivered or not.
        public var withdrawNotification: () -> Void

        public init(
            liftForQuickCheck: @escaping (ShieldedApp, UUID, Date, Date) throws -> Void,
            postNotification: @escaping (ShieldedApp, Bool) -> Bool,
            withdrawNotification: @escaping () -> Void
        ) {
            self.liftForQuickCheck = liftForQuickCheck
            self.postNotification = postNotification
            self.withdrawNotification = withdrawNotification
        }
    }

    /// How the shield should answer.
    public enum Outcome: Hashable, Sendable {
        /// Close the app.
        case close
        /// The shield was lifted from the app: let it through.
        case lifted
        /// An open was requested: redraw into the waiting state, or try
        /// to open Pofu (the day-1 spike, case 23).
        case requested(tryOpenParentalControlsApp: Bool)
    }

    /// Does what `intent` asks for `app` (as the system reported it) at
    /// `now`: records, notes, and the effects.
    public func respond(to intent: ShieldIntent, for app: ShieldedApp, at now: Date, effects: Effects) -> Outcome {
        let store = ShieldContextStore(location: location)
        let inbox = ScreenTimeInbox(location: location)
        let resolved = ShieldDirectory(location: location).resolve(app)
        let appState = store.appState.read()
        let rules = ScreenTimeGateRules.standard.withDailyHour(appState?.dailyHourMinutes)

        switch intent {
        case .skip:
            try? inbox.post(ScreenTimeRecord(at: now, kind: .shieldResisted(app: resolved)))
            return .close

        case .closeAfterPass:
            try? inbox.post(ScreenTimeRecord(at: now, kind: .passEndedClosed(app: resolved)))
            return .close

        case .cancelRequest:
            store.openRequest.remove()
            effects.withdrawNotification()
            try? inbox.post(ScreenTimeRecord(at: now, kind: .openRequestCancelled(app: resolved)))
            return .close

        case .quickCheck:
            let passID = UUID()
            let until = now.addingTimeInterval(TimeInterval(rules.quickCheckMinutes) * 60)
            do {
                try effects.liftForQuickCheck(app, passID, now, until)
            } catch {
                // Could not lift here: the way through Pofu still works.
                #if canImport(os)
                Self.log.error("Quick check lift failed: \(error.localizedDescription, privacy: .public)")
                #endif
                return requestOpen(resolved, breath: false, at: now, store: store, inbox: inbox, appState: appState, effects: effects)
            }
            try? inbox.post(ScreenTimeRecord(at: now, kind: .quickCheckStarted(app: resolved, passID: passID, until: until)))
            return .lifted

        case .openWithPofu:
            return requestOpen(resolved, breath: false, at: now, store: store, inbox: inbox, appState: appState, effects: effects)

        case .breatheWithPofu:
            return requestOpen(resolved, breath: true, at: now, store: store, inbox: inbox, appState: appState, effects: effects)
        }
    }

    /// Records the request, posts the notification, and leaves a note so
    /// the redrawn shield waits for the user.
    private func requestOpen(
        _ app: ShieldedApp,
        breath: Bool,
        at now: Date,
        store: ShieldContextStore,
        inbox: ScreenTimeInbox,
        appState: ShieldAppState?,
        effects: Effects
    ) -> Outcome {
        try? inbox.post(ScreenTimeRecord(at: now, kind: .openRequested(app: app)))
        let posted = effects.postNotification(app, breath)
        try? store.openRequest.write(
            ShieldOpenRequestNote(token: app.token, requestedAt: now, notificationsAllowed: posted, breath: breath)
        )
        return .requested(tryOpenParentalControlsApp: appState?.tryOpenParentalControlsApp == true)
    }
}
