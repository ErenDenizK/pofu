import Foundation

/// The languages the shield speaks. The extensions pick one from the
/// user's preferred languages, like the app (English and Turkish).
public enum ShieldLanguage: String, Hashable, Sendable, Codable, CaseIterable {
    case english = "en"
    case turkish = "tr"

    /// Turkish for any Turkish localization, English otherwise.
    public init(localization: String?) {
        self = (localization?.lowercased().hasPrefix("tr") ?? false) ? .turkish : .english
    }
}

/// What a shield button does, so the action extension can answer the
/// button the configuration extension drew (gate v2, section 5.5).
public enum ShieldIntent: String, Hashable, Sendable, Codable, CaseIterable {
    /// "Skip it" / "Goodnight": the reach is resisted.
    case skip
    /// "Done, close it" on the shield that returned at a pass's end: not a
    /// resisted reach.
    case closeAfterPass
    /// "Skip it" while waiting for the notification tap: the request is
    /// withdrawn and the reach resisted.
    case cancelRequest
    /// "Just 3 minutes": the shield lifts for a quick check, with no app.
    case quickCheck
    /// "Open with Pofu": a notification leads to Hop!.
    case openWithPofu
    /// "Breathe with Pofu": past the daily hour, the way through is a
    /// breath in Pofu.
    case breatheWithPofu
}

/// Pofu's face on the shield (section 5.3). The raw value is the image's
/// resource name in the configuration extension.
public enum ShieldIcon: String, Hashable, Sendable, Codable, CaseIterable {
    case curious = "pofu"
    case proud = "pofu-proud"
    case jealous = "pofu-jealous"
    case breathe = "pofu-breathe"
    case relieved = "pofu-relieved"
    case unwell = "pofu-unwell"
    case excited = "pofu-excited"
}

/// The shield's colors (section 5.2).
public enum ShieldPalette: String, Hashable, Sendable, Codable, CaseIterable {
    /// Cream by day, night in dark mode.
    case day
    /// Always dark: bedtime.
    case night
    /// Lavender: past the daily hour.
    case breath
}

/// Which row of the copy table the shield used (section 5.6).
public enum ShieldLine: String, Hashable, Sendable, Codable, CaseIterable {
    case waiting
    case waitingForHand
    case passEnded
    case breath
    case bedtime
    case tired
    case jealous
    case kind
    case second
    case morning
    case day
    case evening
}

/// Everything the shield's copy depends on, at the moment it is drawn.
public struct ShieldContext: Hashable, Sendable {
    /// How the shield waits for the user to reach Pofu after "Open with
    /// Pofu".
    public enum Waiting: Hashable, Sendable {
        /// A notification is on its way: tap it.
        case notification
        /// Notifications are off: open Pofu by hand.
        case byHand
    }

    /// The name the system gives the app (or the web domain).
    public var appName: String?
    /// The app's bundle identifier, when the system gave one.
    public var bundleIdentifier: String?
    /// The local hour, 0–23.
    public var hour: Int
    /// The local day of the year, for rotating variants.
    public var dayOfYear: Int
    public var isBedtime: Bool
    /// Reaches today before this one.
    public var reachesToday: Int
    /// Resisted reaches today.
    public var resistedToday: Int
    /// Reaches in the last hour, counting this one.
    public var reachesThisHour: Int
    /// Pofu's wellbeing, `0...1`.
    public var wellbeing: Double
    /// Calm, as a multiplier (ADR-0015); `nil` until calm exists in
    /// `PofuCore`, and the copy then leaves it out.
    public var calm: Double?
    /// Today's measured guarded time reached the daily hour.
    public var isPastDailyHour: Bool
    /// Opens past the daily hour today before this one.
    public var overLimitOpensToday: Int
    /// Jealous lines shown today.
    public var jealousLinesToday: Int
    /// Whether the last shield was jealous.
    public var lastWasJealous: Bool
    /// The last shield's title, never shown twice in a row.
    public var lastTitle: String?
    /// Waiting for the user to reach Pofu, if "Open with Pofu" was tapped
    /// for this app.
    public var waiting: Waiting?
    /// Minutes of the pass for this app that just ended, if one did.
    public var endedPassMinutes: Int?
    /// The chain rule allows a quick check now.
    public var quickCheckAllowed: Bool
    /// The system can show the secondary button's submenu (iOS 26.4).
    public var submenuAvailable: Bool

    public init(
        appName: String? = nil,
        bundleIdentifier: String? = nil,
        hour: Int = 12,
        dayOfYear: Int = 1,
        isBedtime: Bool = false,
        reachesToday: Int = 0,
        resistedToday: Int = 0,
        reachesThisHour: Int = 1,
        wellbeing: Double = 0.6,
        calm: Double? = nil,
        isPastDailyHour: Bool = false,
        overLimitOpensToday: Int = 0,
        jealousLinesToday: Int = 0,
        lastWasJealous: Bool = false,
        lastTitle: String? = nil,
        waiting: Waiting? = nil,
        endedPassMinutes: Int? = nil,
        quickCheckAllowed: Bool = true,
        submenuAvailable: Bool = true
    ) {
        self.appName = appName
        self.bundleIdentifier = bundleIdentifier
        self.hour = hour
        self.dayOfYear = dayOfYear
        self.isBedtime = isBedtime
        self.reachesToday = reachesToday
        self.resistedToday = resistedToday
        self.reachesThisHour = reachesThisHour
        self.wellbeing = wellbeing
        self.calm = calm
        self.isPastDailyHour = isPastDailyHour
        self.overLimitOpensToday = overLimitOpensToday
        self.jealousLinesToday = jealousLinesToday
        self.lastWasJealous = lastWasJealous
        self.lastTitle = lastTitle
        self.waiting = waiting
        self.endedPassMinutes = endedPassMinutes
        self.quickCheckAllowed = quickCheckAllowed
        self.submenuAvailable = submenuAvailable
    }

    /// The scene this context draws.
    public var scene: ShieldScene {
        if waiting != nil { return .waiting }
        if endedPassMinutes != nil { return .passEnded }
        if isPastDailyHour { return .breath }
        return .reach
    }
}

/// One shield, as the configuration extension draws it and the action
/// extension answers it (gate v2, sections 5.3–5.6).
public struct ShieldCopy: Hashable, Sendable, Codable {
    public struct Button: Hashable, Sendable, Codable {
        public var label: String
        public var intent: ShieldIntent

        public init(label: String, intent: ShieldIntent) {
            self.label = label
            self.intent = intent
        }
    }

    /// Length limits, in characters, that keep every line on the fixed
    /// system layout (section 5.6).
    public enum Limit {
        public static let title = 26
        public static let subtitleLine = 60
        public static let tally = 32
        public static let button = 18
        public static let submenuItem = 22
        /// Longer app names are not quoted; the shield says "This".
        public static let appName = 12
    }

    public var scene: ShieldScene
    public var line: ShieldLine
    public var icon: ShieldIcon
    public var palette: ShieldPalette
    public var title: String
    /// Line 1, the context, and from the second reach of the day line 2,
    /// the tally, joined by a newline.
    public var subtitle: String
    public var primary: Button
    /// The secondary button; it opens `submenu` when that is not empty.
    public var secondary: Button?
    /// Up to three submenu items (iOS 26.4).
    public var submenu: [Button]

    public init(
        scene: ShieldScene,
        line: ShieldLine,
        icon: ShieldIcon,
        palette: ShieldPalette,
        title: String,
        subtitle: String,
        primary: Button,
        secondary: Button?,
        submenu: [Button]
    ) {
        self.scene = scene
        self.line = line
        self.icon = icon
        self.palette = palette
        self.title = title
        self.subtitle = subtitle
        self.primary = primary
        self.secondary = secondary
        self.submenu = submenu
    }

    /// What the secondary button does when it has no submenu.
    public var secondaryIntent: ShieldIntent? {
        submenu.isEmpty ? secondary?.intent : nil
    }

    /// What the submenu item at `index` (0-based) does.
    public func submenuIntent(at index: Int) -> ShieldIntent? {
        submenu.indices.contains(index) ? submenu[index].intent : nil
    }

    /// The shield for `context`, in `language`.
    public static func make(
        context: ShieldContext,
        language: ShieldLanguage,
        rules: ScreenTimeGateRules = .standard
    ) -> ShieldCopy {
        ShieldCopyWriter(context: context, words: ShieldWords(language: language), rules: rules).make()
    }
}

/// The notification that answers "Open with Pofu" (section 5.7).
public struct GateNotificationCopy: Hashable, Sendable {
    public static let identifier = "pofu.gate.request"
    public static let threadIdentifier = "pofu.gate"

    public var title: String
    public var body: String

    public init(appName: String?, bundleIdentifier: String?, breath: Bool, language: ShieldLanguage) {
        let naming = ShieldAppNaming(appName: appName, bundleIdentifier: bundleIdentifier)
        switch language {
        case .turkish:
            title = naming.turkishOpenQuestion ?? "Açalım mı?"
            body = breath ? "Dokun, önce bir nefes alalım." : "Dokun, kararı birlikte verelim."
        case .english:
            title = naming.name.map { "Opening \($0)?" } ?? "Open it?"
            body = breath ? "Tap and we'll take a breath first." : "Tap and we'll decide together."
        }
    }
}

// MARK: - Names

/// How the shield names an app: the brand name for known apps (so the
/// Turkish suffixes are right), the system's name otherwise, and nothing
/// for a name too long to fit.
struct ShieldAppNaming {
    let name: String?
    let known: ProtectedApp?

    init(appName: String?, bundleIdentifier: String?) {
        let known = bundleIdentifier.flatMap(ProtectedApp.init(bundleIdentifier:))
        self.known = known
        let raw = known?.brandName ?? appName?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let raw, !raw.isEmpty, raw.count <= ShieldCopy.Limit.appName {
            name = raw
        } else {
            name = nil
        }
    }

    /// "Instagram'ı mı açalım?", "YouTube'u mu açalım?": the accusative
    /// and the question particle both follow vowel harmony, so they come
    /// from a table; `nil` for apps Pofu does not know, so the copy never
    /// guesses a wrong suffix.
    var turkishOpenQuestion: String? {
        switch known {
        case .instagram: "Instagram'ı mı açalım?"
        case .youtube: "YouTube'u mu açalım?"
        case .tiktok: "TikTok'u mu açalım?"
        case .x: "X'i mi açalım?"
        case .snapchat: "Snapchat'i mi açalım?"
        case .reddit: "Reddit'i mi açalım?"
        case .facebook: "Facebook'u mu açalım?"
        case .other, nil: nil
        }
    }

    /// "Instagram da", "X de", "Bu da": the Turkish "too" after the name.
    var turkishWithToo: String {
        switch known {
        case .instagram, .youtube, .tiktok, .facebook: return "\(name ?? "Bu") da"
        case .x, .snapchat, .reddit: return "\(name ?? "Bu") de"
        case .other, nil:
            guard let name else { return "Bu da" }
            return "\(name) \(Self.turkishToo(after: name))"
        }
    }

    /// "da" or "de" by the last vowel (vowel harmony); "da" when there is
    /// no vowel.
    static func turkishToo(after word: String) -> String {
        let front: Set<Character> = ["e", "i", "ö", "ü", "E", "İ", "Ö", "Ü"]
        let back: Set<Character> = ["a", "ı", "o", "u", "A", "I", "O", "U"]
        for character in word.reversed() {
            if front.contains(character) { return "de" }
            if back.contains(character) { return "da" }
        }
        return "da"
    }
}

// MARK: - Words

/// Every word on the shield, in one language. The Turkish is the
/// original; the English mirrors it (gate v2, section 5.6).
struct ShieldWords {
    let language: ShieldLanguage

    private func pick(_ turkish: String, _ english: String) -> String {
        language == .turkish ? turkish : english
    }

    private func calmText(_ calm: Double) -> String {
        let text = String(format: "%.1f", locale: Locale(identifier: "en_US_POSIX"), calm)
        return "×" + (language == .turkish ? text.replacingOccurrences(of: ".", with: ",") : text)
    }

    private func ordinal(_ number: Int) -> String {
        if language == .turkish { return "\(number)." }
        let tens = number % 100
        let suffix: String
        if (11...13).contains(tens) {
            suffix = "th"
        } else {
            switch number % 10 {
            case 1: suffix = "st"
            case 2: suffix = "nd"
            case 3: suffix = "rd"
            default: suffix = "th"
            }
        }
        return "\(number)\(suffix)"
    }

    // Buttons

    var skip: String { pick("Boş ver", "Skip it") }
    var goodnight: String { pick("İyi geceler", "Goodnight") }
    var needIt: String { pick("Açmam lazım", "I need it") }
    func quickCheck(minutes: Int) -> String { pick("\(minutes) dakika bakacağım", "Just \(minutes) minutes") }
    var openWithPofu: String { pick("Pofu'yla aç", "Open with Pofu") }
    var breatheWithPofu: String { pick("Pofu'yla nefes al", "Breathe with Pofu") }
    var doneClose: String { pick("Bitti, kapat", "Done, close it") }
    var aBitMore: String { pick("Biraz daha", "A bit more") }

    // Lines

    func tally(resisted: Int, of reaches: Int) -> String {
        pick("Bugün \(resisted) / \(reaches) boş verdin.", "Today: skipped \(resisted) of \(reaches).")
    }

    var waitingTitle: String { pick("Bildirime dokun ↑", "Tap the notification ↑") }
    var waitingSubtitle: String { pick("Yukarıda seni bekliyorum.", "I'm waiting up there.") }
    var byHandTitle: String { pick("Pofu'yu kendin aç", "Open Pofu yourself") }
    func byHandSubtitle(minutes: Int) -> String {
        pick("Bildirimler kapalı. \(minutes) dakika içinde açarsan seni beklerim.", "Notifications are off. Open me within \(minutes) min.")
    }

    var passEndedTitle: String { pick("Süre doldu.", "Time's up.") }
    func passEndedSubtitle(minutes: Int, calm: Double?) -> String {
        if let calm {
            return pick("\(minutes) dakika bitti. Huzur \(calmText(calm)) seni bekliyor.", "\(minutes) minutes are up. Calm is waiting at \(calmText(calm)).")
        }
        return pick("\(minutes) dakika bitti. Kapıya döndüm.", "\(minutes) minutes are up. I'm back at the door.")
    }

    func breathTitle(atNight: Bool) -> String {
        atNight ? pick("Şşş. Önce bir nefes.", "Shh. A breath first.") : pick("Bugünkü saatimiz doldu.", "We've had our hour today.")
    }
    func breathSubtitle(seconds: Int) -> String {
        pick("Açmadan önce benimle bir nefes: \(seconds) saniye.", "One breath with me first: \(seconds) seconds.")
    }

    var bedtimeTitles: [String] { [pick("Şşş, geç oldu.", "Shh, it's late."), pick("Gece yarısı akışı mı?", "A midnight scroll?")] }
    func bedtimeSubtitle(_ naming: ShieldAppNaming) -> String {
        pick("\(naming.turkishWithToo) uyuyor. (Uyumuyor. Ama uyumalı.)", "\(naming.name ?? "This") is asleep too. (It isn't. But it should be.)")
    }

    var tiredTitle: String { pick("Biraz yorgunum.", "I'm a bit tired.") }
    var tiredSubtitle: String { pick("Birlikte biraz ara verelim mi?", "Shall we take a little break together?") }

    func jealousTitles(_ naming: ShieldAppNaming) -> [String] {
        guard let name = naming.name else {
            return [pick("Yine mi?", "Again?"), pick("Hı. Anladım.", "Oh. I see.")]
        }
        return [pick("Yine mi \(name)?", "\(name) again?"), pick("Hı. \(name). Anladım.", "Oh. \(name). I see.")]
    }
    func jealousSubtitle(reachesThisHour: Int) -> String {
        pick("Bu saat \(ordinal(reachesThisHour)) kez. Onda olup bende olmayan ne?", "\(ordinal(reachesThisHour)) time this hour. What does it have that I don't?")
    }

    var kindTitle: String { pick("Buradayım.", "I'm here.") }
    func kindSubtitle(reachesThisHour: Int, calm: Double?) -> String {
        if calm != nil {
            return pick("Bu saat \(ordinal(reachesThisHour)) kez. Huzur yine büyür, acele yok.", "\(ordinal(reachesThisHour)) time this hour. Calm grows back; no rush.")
        }
        return pick("Bu saat \(ordinal(reachesThisHour)) kez. Acele yok.", "\(ordinal(reachesThisHour)) time this hour. No rush.")
    }

    var secondTitles: [String] { [pick("Az önce de geldik.", "We were just here."), pick("Bir daha mı?", "Once more?")] }
    func secondSubtitle(calm: Double?) -> String {
        if let calm {
            return pick("Huzur \(calmText(calm)) · büyüyor. Boş verirsen büyümeye devam eder.", "Calm \(calmText(calm)) · growing. Skip it and it keeps growing.")
        }
        return pick("Boş vermek hâlâ tek dokunuş.", "Skipping is still one tap.")
    }

    var morningTitles: [String] { [pick("Günaydın. Önce ben.", "Morning. Me first."), pick("Güne akışla mı başlıyoruz?", "Starting with the feed?")] }
    func morningSubtitle(calm: Double?) -> String {
        if let calm {
            return pick("Güne akışla başlamayalım. Huzur \(calmText(calm)).", "Let's not start the day with the feed. Calm \(calmText(calm)).")
        }
        return pick("Güne akışla başlamayalım.", "Let's not start the day with the feed.")
    }

    func dayTitles(_ naming: ShieldAppNaming) -> [String] {
        let wait = naming.name.map { pick("\($0) bekleyebilir.", "\($0) can wait.") } ?? pick("Bu bekleyebilir.", "This can wait.")
        return [pick("Hop! Bir saniye.", "Hop! One second."), wait]
    }
    func daySubtitle(calm: Double?) -> String {
        if let calm {
            return pick("Ben buradayım. Huzur \(calmText(calm)) · büyüyor.", "I'm right here. Calm \(calmText(calm)) · growing.")
        }
        return pick("Ben buradayım.", "I'm right here.")
    }

    var eveningTitles: [String] { [pick("Akşam akışı mı?", "Evening scroll?"), pick("Günün en zor saati.", "The hardest hour.")] }
    func eveningSubtitle(calm: Double?) -> String {
        guard let calm else { return pick("Bu saatler en zoru.", "These hours are the hardest.") }
        if calm >= 1.8 {
            return pick("Bu saatler en zoru. Huzur \(calmText(calm)), neredeyse dolu.", "These hours are the hardest. Calm \(calmText(calm)), almost full.")
        }
        return pick("Bu saatler en zoru. Huzur \(calmText(calm)) · büyüyor.", "These hours are the hardest. Calm \(calmText(calm)) · growing.")
    }
}

// MARK: - The ladder

/// Picks the first matching row of the copy table (section 5.6, rule 1),
/// then the buttons of its state (section 5.4).
private struct ShieldCopyWriter {
    let context: ShieldContext
    let words: ShieldWords
    let rules: ScreenTimeGateRules

    private var naming: ShieldAppNaming {
        ShieldAppNaming(appName: context.appName, bundleIdentifier: context.bundleIdentifier)
    }

    private var tally: String? {
        guard context.reachesToday >= 1 else { return nil }
        let resisted = min(max(0, context.resistedToday), context.reachesToday)
        return words.tally(resisted: resisted, of: context.reachesToday)
    }

    private var palette: ShieldPalette {
        if context.isBedtime { return .night }
        return context.scene == .breath ? .breath : .day
    }

    func make() -> ShieldCopy {
        switch context.scene {
        case .waiting:
            let byHand = context.waiting == .byHand
            return copy(
                line: byHand ? .waitingForHand : .waiting,
                icon: .excited,
                title: byHand ? words.byHandTitle : words.waitingTitle,
                lineOne: byHand ? words.byHandSubtitle(minutes: Int(rules.openRequestLifetime / 60)) : words.waitingSubtitle,
                withTally: false,
                primary: .init(label: words.skip, intent: .cancelRequest),
                open: nil
            )
        case .passEnded:
            return copy(
                line: .passEnded,
                icon: .relieved,
                title: words.passEndedTitle,
                lineOne: words.passEndedSubtitle(minutes: context.endedPassMinutes ?? 0, calm: context.calm),
                withTally: false,
                primary: .init(label: words.doneClose, intent: .closeAfterPass),
                open: openPath(label: words.aBitMore)
            )
        case .breath:
            let ordinal = context.overLimitOpensToday + 1
            return copy(
                line: .breath,
                icon: .breathe,
                title: words.breathTitle(atNight: context.isBedtime),
                lineOne: words.breathSubtitle(seconds: rules.breathSeconds(forOverLimitOpen: ordinal)),
                withTally: true,
                primary: primary,
                open: openPath(label: words.needIt)
            )
        case .reach:
            return reach()
        }
    }

    private var primary: ShieldCopy.Button {
        .init(label: context.isBedtime ? words.goodnight : words.skip, intent: .skip)
    }

    private func reach() -> ShieldCopy {
        let open = openPath(label: words.needIt)
        if context.isBedtime {
            return copy(line: .bedtime, icon: .breathe, title: variant(words.bedtimeTitles), lineOne: words.bedtimeSubtitle(naming), withTally: true, primary: primary, open: open)
        }
        if context.wellbeing < 0.25 {
            return copy(line: .tired, icon: .unwell, title: words.tiredTitle, lineOne: words.tiredSubtitle, withTally: true, primary: primary, open: open)
        }
        if context.reachesThisHour >= 3 {
            let jealousAllowed = context.jealousLinesToday < rules.jealousLinesPerDay && !context.lastWasJealous
            if jealousAllowed {
                return copy(
                    line: .jealous,
                    icon: .jealous,
                    title: variant(words.jealousTitles(naming)),
                    lineOne: words.jealousSubtitle(reachesThisHour: context.reachesThisHour),
                    withTally: true,
                    primary: primary,
                    open: open
                )
            }
            return copy(
                line: .kind,
                icon: .curious,
                title: words.kindTitle,
                lineOne: words.kindSubtitle(reachesThisHour: context.reachesThisHour, calm: context.calm),
                withTally: true,
                primary: primary,
                open: open
            )
        }
        if context.reachesThisHour == 2 {
            return copy(line: .second, icon: .curious, title: variant(words.secondTitles), lineOne: words.secondSubtitle(calm: context.calm), withTally: true, primary: primary, open: open)
        }
        let proud = context.resistedToday >= 3 && context.resistedToday * 2 >= context.reachesToday
        let icon: ShieldIcon = proud ? .proud : .curious
        switch context.hour {
        case 6..<11:
            return copy(line: .morning, icon: icon, title: variant(words.morningTitles), lineOne: words.morningSubtitle(calm: context.calm), withTally: true, primary: primary, open: open)
        case 17..<24:
            return copy(line: .evening, icon: icon, title: variant(words.eveningTitles), lineOne: words.eveningSubtitle(calm: context.calm), withTally: true, primary: primary, open: open)
        default:
            return copy(line: .day, icon: icon, title: variant(words.dayTitles(naming)), lineOne: words.daySubtitle(calm: context.calm), withTally: true, primary: primary, open: open)
        }
    }

    /// The way to open: past the daily hour only "Breathe with Pofu"; with
    /// the submenu and the chain rule's leave, `label` opens "Just 3
    /// minutes" and "Open with Pofu"; otherwise "Open with Pofu" directly.
    private func openPath(label: String) -> (button: ShieldCopy.Button, submenu: [ShieldCopy.Button]) {
        if context.isPastDailyHour {
            return (.init(label: words.breatheWithPofu, intent: .breatheWithPofu), [])
        }
        if context.submenuAvailable && context.quickCheckAllowed {
            return (
                .init(label: label, intent: .openWithPofu),
                [
                    .init(label: words.quickCheck(minutes: rules.quickCheckMinutes), intent: .quickCheck),
                    .init(label: words.openWithPofu, intent: .openWithPofu),
                ]
            )
        }
        let direct = label == words.aBitMore ? label : words.openWithPofu
        return (.init(label: direct, intent: .openWithPofu), [])
    }

    /// Variant `(dayOfYear + reachesToday) % count`, never the last title
    /// again (rule 2).
    private func variant(_ titles: [String]) -> String {
        guard !titles.isEmpty else { return "" }
        var index = abs(context.dayOfYear + context.reachesToday) % titles.count
        if titles.count > 1, titles[index] == context.lastTitle {
            index = (index + 1) % titles.count
        }
        return titles[index]
    }

    private func copy(
        line: ShieldLine,
        icon: ShieldIcon,
        title: String,
        lineOne: String,
        withTally: Bool,
        primary: ShieldCopy.Button,
        open: (button: ShieldCopy.Button, submenu: [ShieldCopy.Button])?
    ) -> ShieldCopy {
        var subtitle = lineOne
        if withTally, let tally {
            subtitle += "\n" + tally
        }
        return ShieldCopy(
            scene: context.scene,
            line: line,
            icon: icon,
            palette: palette,
            title: title,
            subtitle: subtitle,
            primary: primary,
            secondary: open?.button,
            submenu: open?.submenu ?? []
        )
    }
}
