import Foundation
import PofuCore
import Testing

private let instagramID = "com.burbn.instagram"
private let youtubeID = "com.google.ios.youtube"

private func context(
    app: String? = "Instagram",
    bundle: String? = instagramID,
    hour: Int = 13,
    _ adjust: (inout ShieldContext) -> Void = { _ in }
) -> ShieldContext {
    var context = ShieldContext(appName: app, bundleIdentifier: bundle, hour: hour)
    adjust(&context)
    return context
}

private func tr(_ context: ShieldContext) -> ShieldCopy {
    ShieldCopy.make(context: context, language: .turkish)
}

private func en(_ context: ShieldContext) -> ShieldCopy {
    ShieldCopy.make(context: context, language: .english)
}

/// Every context the ladder can reach, for the length and tone checks.
private var everyContext: [ShieldContext] {
    var contexts: [ShieldContext] = []
    let apps: [(String?, String?)] = [
        ("Instagram", instagramID),
        ("YouTube", youtubeID),
        ("TikTok", "com.zhiliaoapp.musically"),
        ("youtube.com", nil),
        ("Kitapçıkolik", nil),
        ("A very long app name indeed", nil),
        (nil, nil),
    ]
    for (name, bundle) in apps {
        for hour in [0, 7, 13, 19, 23] {
            for reachesThisHour in [1, 2, 3, 11, 23] {
                for reachesToday in [0, 1, 12, 99] {
                    var base = ShieldContext(appName: name, bundleIdentifier: bundle, hour: hour)
                    base.reachesThisHour = reachesThisHour
                    base.reachesToday = reachesToday
                    base.resistedToday = reachesToday
                    base.isBedtime = hour >= 23 || hour < 6
                    for calm in [nil, 1.0, 1.8] as [Double?] {
                        var variant = base
                        variant.calm = calm
                        contexts.append(variant)
                    }
                    var tired = base
                    tired.wellbeing = 0.1
                    contexts.append(tired)
                    var breath = base
                    breath.isPastDailyHour = true
                    breath.overLimitOpensToday = 5
                    contexts.append(breath)
                    var waiting = base
                    waiting.waiting = .notification
                    contexts.append(waiting)
                    waiting.waiting = .byHand
                    contexts.append(waiting)
                    var ended = base
                    ended.endedPassMinutes = 15
                    ended.calm = 1.6
                    contexts.append(ended)
                }
            }
        }
    }
    return contexts
}

@Suite("Shield copy: limits and tone")
struct ShieldCopyLimitTests {
    @Test(arguments: ShieldLanguage.allCases)
    func everyShieldFitsTheSystemLayout(language: ShieldLanguage) {
        for context in everyContext {
            let copy = ShieldCopy.make(context: context, language: language)
            #expect(copy.title.count <= ShieldCopy.Limit.title, "\(copy.title)")
            let lines = copy.subtitle.split(separator: "\n", omittingEmptySubsequences: false)
            #expect(lines.count <= 2, "\(copy.subtitle)")
            if let first = lines.first {
                #expect(first.count <= ShieldCopy.Limit.subtitleLine, "\(first)")
            }
            if lines.count == 2 {
                #expect(lines[1].count <= ShieldCopy.Limit.tally, "\(lines[1])")
            }
            #expect(copy.primary.label.count <= ShieldCopy.Limit.button, "\(copy.primary.label)")
            if let secondary = copy.secondary {
                #expect(secondary.label.count <= ShieldCopy.Limit.button, "\(secondary.label)")
            }
            #expect(copy.submenu.count <= 3)
            for item in copy.submenu {
                #expect(item.label.count <= ShieldCopy.Limit.submenuItem, "\(item.label)")
            }
        }
    }

    @Test(arguments: ShieldLanguage.allCases)
    func theShieldNeverScoldsOrShouts(language: ShieldLanguage) {
        let banned = ["engellendi", "blocked", "limit", "penalty", "ceza", "%"]
        for context in everyContext {
            let copy = ShieldCopy.make(context: context, language: language)
            let text = ([copy.title, copy.subtitle, copy.primary.label] + [copy.secondary?.label].compactMap { $0 } + copy.submenu.map(\.label))
                .joined(separator: " ")
            for word in banned {
                #expect(!text.lowercased().contains(word), "\(text)")
            }
            #expect(text.filter { $0 == "!" }.count <= 1, "\(text)")
        }
    }
}

@Suite("Shield copy: the tally")
struct ShieldTallyTests {
    /// Experience v1, section 3.4: the subtitle counts resists only, never
    /// opens. The tally line is the second line; it carries the resisted
    /// count and no other number, and no word about opening.
    @Test(arguments: ShieldLanguage.allCases)
    func theSecondLineNeverMentionsOpens(language: ShieldLanguage) {
        let openWords = ["aç", "open", " of ", "/", "reach", "ulaş"]
        for context in everyContext {
            let copy = ShieldCopy.make(context: context, language: language)
            let lines = copy.subtitle.split(separator: "\n", omittingEmptySubsequences: false)
            guard lines.count == 2 else { continue }
            let tally = String(lines[1])
            #expect(tally.contains("\(min(context.resistedToday, context.reachesToday))"), "\(tally)")
            let digits = tally.filter(\.isNumber)
            #expect(digits == "\(min(context.resistedToday, context.reachesToday))", "\(tally)")
            for word in openWords {
                #expect(!tally.lowercased().contains(word), "\(tally)")
            }
        }
    }
}

@Suite("Shield copy: the ladder")
struct ShieldCopyLadderTests {
    @Test func aFirstReachAtMiddayIsTheDayLine() {
        let copy = tr(context())
        #expect(copy.scene == .reach)
        #expect(copy.line == .day)
        #expect(copy.icon == .curious)
        #expect(copy.palette == .day)
        #expect(["Hop! Bir saniye.", "Instagram bekleyebilir."].contains(copy.title))
        #expect(copy.subtitle == "Ben buradayım.")
        #expect(copy.primary == .init(label: "Boş ver", intent: .skip))
    }

    @Test func theHourPicksTheLine() {
        #expect(tr(context(hour: 7)).line == .morning)
        #expect(tr(context(hour: 12)).line == .day)
        #expect(tr(context(hour: 18)).line == .evening)
        #expect(tr(context(hour: 3)).line == .day)
    }

    @Test func calmShowsOnlyWhenItExists() {
        #expect(tr(context(hour: 8) { $0.calm = 1.4 }).subtitle == "Güne akışla başlamayalım. Huzur ×1,4.")
        #expect(en(context(hour: 8) { $0.calm = 1.4 }).subtitle == "Let's not start the day with the feed. Calm ×1.4.")
        #expect(tr(context(hour: 19) { $0.calm = 1.8 }).subtitle == "Bu saatler en zoru. Huzur ×1,8, neredeyse dolu.")
        #expect(tr(context(hour: 19) { $0.calm = 1.2 }).subtitle == "Bu saatler en zoru. Huzur ×1,2 · büyüyor.")
        #expect(tr(context(hour: 19)).subtitle == "Bu saatler en zoru.")
    }

    @Test func theTallyCountsResistsOnlyAndStartsAtTheFirstOne() {
        #expect(!tr(context()).subtitle.contains("\n"))
        // Reaches without a resist: nothing to count, and no number about opens.
        #expect(!tr(context { $0.reachesToday = 3; $0.resistedToday = 0 }).subtitle.contains("\n"))
        let second = tr(context { $0.reachesToday = 1; $0.resistedToday = 1 })
        #expect(second.subtitle.hasSuffix("\nBugün 1 kez vazgeçtin."))
        let english = en(context { $0.reachesToday = 7; $0.resistedToday = 5 })
        #expect(english.subtitle.hasSuffix("\nYou skipped 5 times today."))
        #expect(en(context { $0.reachesToday = 1; $0.resistedToday = 1 }).subtitle.hasSuffix("\nYou skipped 1 time today."))
    }

    @Test func theSecondReachThisHour() {
        let copy = tr(context { $0.reachesThisHour = 2 })
        #expect(copy.line == .second)
        #expect(["Az önce de geldik.", "Bir daha mı?"].contains(copy.title))
    }

    @Test func theThirdReachThisHourIsJealousWithinItsBudget() {
        let jealous = tr(context { $0.reachesThisHour = 3 })
        #expect(jealous.line == .jealous)
        #expect(jealous.icon == .jealous)
        #expect(["Yine mi Instagram?", "Hı. Instagram. Anladım."].contains(jealous.title))
        #expect(jealous.subtitle == "Bu saat 3. kez. Onda olup bende olmayan ne?")
        #expect(en(context { $0.reachesThisHour = 3 }).subtitle == "3rd time this hour. What does it have that I don't?")

        // Never twice in a row, never more than three a day.
        let afterJealous = tr(context { $0.reachesThisHour = 4; $0.lastWasJealous = true })
        #expect(afterJealous.line == .kind)
        #expect(afterJealous.title == "Buradayım.")
        #expect(afterJealous.subtitle == "Bu saat 4. kez. Acele yok.")
        #expect(tr(context { $0.reachesThisHour = 5; $0.jealousLinesToday = 3 }).line == .kind)
        #expect(en(context { $0.reachesThisHour = 11; $0.jealousLinesToday = 3 }).subtitle == "11th time this hour. No rush.")
    }

    @Test func aTiredPofuIsKind() {
        let copy = tr(context { $0.wellbeing = 0.2; $0.reachesThisHour = 4 })
        #expect(copy.line == .tired)
        #expect(copy.icon == .unwell)
        #expect(copy.title == "Biraz yorgunum.")
    }

    @Test func bedtimeIsDarkAndSaysGoodnight() {
        let copy = tr(context(hour: 23) { $0.isBedtime = true })
        #expect(copy.line == .bedtime)
        #expect(copy.palette == .night)
        #expect(copy.icon == .breathe)
        #expect(copy.primary == .init(label: "İyi geceler", intent: .skip))
        #expect(copy.subtitle == "Instagram da uyuyor. (Uyumuyor. Ama uyumalı.)")
        #expect(copy.secondary?.label == "Açmam lazım")
        let youtube = tr(context(app: "YouTube", bundle: youtubeID, hour: 23) { $0.isBedtime = true })
        #expect(youtube.subtitle.hasPrefix("YouTube da uyuyor."))
        let unknown = tr(context(app: nil, bundle: nil, hour: 23) { $0.isBedtime = true })
        #expect(unknown.subtitle.hasPrefix("Bu da uyuyor."))
    }

    @Test func variantsNeverRepeatTheLastTitle() {
        for day in 1...30 {
            for reaches in 0...5 {
                let base = context { $0.dayOfYear = day; $0.reachesToday = reaches }
                let first = tr(base)
                var next = base
                next.lastTitle = first.title
                #expect(tr(next).title != first.title)
            }
        }
    }

    @Test func longOrUnknownNamesAreNotQuoted() {
        let long = tr(context(app: "A very long app name indeed", bundle: nil) { $0.reachesThisHour = 3 })
        #expect(!long.title.contains("very"))
        let unknown = en(context(app: nil, bundle: nil) { $0.reachesThisHour = 3 })
        #expect(["Again?", "Oh. I see."].contains(unknown.title))
        let website = tr(context(app: "youtube.com", bundle: nil) { $0.dayOfYear = 1; $0.reachesToday = 0 })
        #expect(["Hop! Bir saniye.", "youtube.com bekleyebilir."].contains(website.title))
    }

    @Test func proudAfterThreeSkipsAndHalf() {
        #expect(tr(context { $0.reachesToday = 5; $0.resistedToday = 3 }).icon == .proud)
        #expect(tr(context { $0.reachesToday = 7; $0.resistedToday = 3 }).icon == .curious)
        #expect(tr(context { $0.reachesToday = 2; $0.resistedToday = 2 }).icon == .curious)
    }
}

@Suite("Shield copy: states and buttons")
struct ShieldCopyStateTests {
    @Test func theDefaultOffersTheSubmenu() {
        let copy = tr(context())
        #expect(copy.secondary?.label == "Açmam lazım")
        #expect(copy.submenu.map(\.label) == ["3 dakika bakacağım", "Pofu'yla aç"])
        #expect(copy.submenuIntent(at: 0) == .quickCheck)
        #expect(copy.submenuIntent(at: 1) == .openWithPofu)
        #expect(copy.submenuIntent(at: 2) == nil)
        #expect(copy.secondaryIntent == nil)
        #expect(en(context()).submenu.map(\.label) == ["Just 3 minutes", "Open with Pofu"])
    }

    @Test func withoutTheSubmenuTheSecondaryOpensWithPofu() {
        let copy = tr(context { $0.submenuAvailable = false })
        #expect(copy.submenu.isEmpty)
        #expect(copy.secondary == .init(label: "Pofu'yla aç", intent: .openWithPofu))
        #expect(copy.secondaryIntent == .openWithPofu)
    }

    @Test func theChainRuleHidesTheQuickCheck() {
        let copy = tr(context { $0.quickCheckAllowed = false })
        #expect(copy.submenu.isEmpty)
        #expect(copy.secondary == .init(label: "Pofu'yla aç", intent: .openWithPofu))
    }

    @Test func pastTheDailyHourTheOnlyWayIsABreath() {
        let copy = tr(context { $0.isPastDailyHour = true })
        #expect(copy.scene == .breath)
        #expect(copy.line == .breath)
        #expect(copy.palette == .breath)
        #expect(copy.icon == .breathe)
        #expect(copy.title == "Bugünkü saatimiz doldu.")
        #expect(copy.subtitle == "Açmadan önce benimle bir nefes: 5 saniye.")
        #expect(copy.secondary == .init(label: "Pofu'yla nefes al", intent: .breatheWithPofu))
        #expect(copy.submenu.isEmpty)
        let fourth = tr(context { $0.isPastDailyHour = true; $0.overLimitOpensToday = 3 })
        #expect(fourth.subtitle == "Açmadan önce benimle bir nefes: 10 saniye.")
        // At night, the breath wins with the night palette.
        let night = tr(context(hour: 23) { $0.isPastDailyHour = true; $0.isBedtime = true })
        #expect(night.palette == .night)
        #expect(night.title == "Şşş. Önce bir nefes.")
        #expect(night.primary.label == "İyi geceler")
    }

    @Test func waitingForTheNotification() {
        let copy = tr(context { $0.waiting = .notification; $0.reachesToday = 4 })
        #expect(copy.scene == .waiting)
        #expect(copy.title == "Bildirime dokun ↑")
        #expect(copy.subtitle == "Yukarıda seni bekliyorum.")
        #expect(copy.icon == .excited)
        #expect(copy.primary == .init(label: "Boş ver", intent: .cancelRequest))
        #expect(copy.secondary == nil)
        #expect(copy.submenu.isEmpty)
    }

    @Test func withNotificationsOffTheShieldSaysOpenPofuYourself() {
        let copy = tr(context { $0.waiting = .byHand })
        #expect(copy.line == .waitingForHand)
        #expect(copy.title == "Pofu'yu kendin aç")
        #expect(copy.subtitle == "Bildirimler kapalı. 10 dakika içinde açarsan seni beklerim.")
        #expect(copy.primary.intent == .cancelRequest)
    }

    @Test func theReturningShieldIsNotASkip() {
        let copy = tr(context { $0.endedPassMinutes = 3; $0.quickCheckAllowed = false })
        #expect(copy.scene == .passEnded)
        #expect(copy.icon == .relieved)
        #expect(copy.title == "Süre doldu.")
        #expect(copy.subtitle == "3 dakika bitti. Kapıya döndüm.")
        #expect(copy.primary == .init(label: "Bitti, kapat", intent: .closeAfterPass))
        #expect(copy.secondary == .init(label: "Biraz daha", intent: .openWithPofu))
        let afterOpen = tr(context { $0.endedPassMinutes = 15; $0.calm = 1.6 })
        #expect(afterOpen.subtitle == "15 dakika bitti. Huzur ×1,6 seni bekliyor.")
        #expect(afterOpen.secondary?.label == "Biraz daha")
        #expect(afterOpen.submenu.count == 2)
    }

    @Test func scenesFollowTheTableOrder() {
        let all = context {
            $0.waiting = .notification
            $0.endedPassMinutes = 3
            $0.isPastDailyHour = true
        }
        #expect(all.scene == .waiting)
        var ended = all
        ended.waiting = nil
        #expect(ended.scene == .passEnded)
        ended.endedPassMinutes = nil
        #expect(ended.scene == .breath)
        #expect(ShieldScene.reach.countsAsReach)
        #expect(ShieldScene.breath.countsAsReach)
        #expect(!ShieldScene.waiting.countsAsReach)
        #expect(!ShieldScene.passEnded.countsAsReach)
    }

    @Test func theCopyRoundTripsForTheActionExtension() throws {
        let copy = tr(context())
        let decoded = try JSONDecoder().decode(ShieldCopy.self, from: JSONEncoder().encode(copy))
        #expect(decoded == copy)
    }
}

@Suite("The Open with Pofu notification")
struct GateNotificationCopyTests {
    @Test func turkishNamesTakeTheirSuffix() {
        #expect(GateNotificationCopy(appName: "Instagram", bundleIdentifier: instagramID, breath: false, language: .turkish).title == "Instagram'ı mı açalım?")
        #expect(GateNotificationCopy(appName: "YouTube", bundleIdentifier: youtubeID, breath: false, language: .turkish).title == "YouTube'u mu açalım?")
        #expect(GateNotificationCopy(appName: "Kitap", bundleIdentifier: nil, breath: false, language: .turkish).title == "Açalım mı?")
        #expect(GateNotificationCopy(appName: "Instagram", bundleIdentifier: instagramID, breath: false, language: .english).title == "Opening Instagram?")
        #expect(GateNotificationCopy(appName: nil, bundleIdentifier: nil, breath: false, language: .english).title == "Open it?")
    }

    @Test func theBodySaysWhatHappensNext() {
        #expect(GateNotificationCopy(appName: nil, bundleIdentifier: nil, breath: false, language: .turkish).body == "Dokun, kararı birlikte verelim.")
        #expect(GateNotificationCopy(appName: nil, bundleIdentifier: nil, breath: true, language: .turkish).body == "Dokun, önce bir nefes alalım.")
        #expect(GateNotificationCopy(appName: nil, bundleIdentifier: nil, breath: true, language: .english).body == "Tap and we'll take a breath first.")
    }

    @Test func theLanguageFollowsTheLocalization() {
        #expect(ShieldLanguage(localization: "tr") == .turkish)
        #expect(ShieldLanguage(localization: "tr-TR") == .turkish)
        #expect(ShieldLanguage(localization: "en") == .english)
        #expect(ShieldLanguage(localization: nil) == .english)
    }
}
