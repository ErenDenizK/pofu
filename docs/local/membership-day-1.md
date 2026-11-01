# Membership day 1: the Screen Time gate on the iPhone

A script for the founder and the local Mac agent, for the first day of the
paid Apple Developer membership. It takes the Screen Time gate (the
`PofuLive` scheme) from "compiles in CI" to "verified on the iPhone 17".
Background: [ADR-0013](../adr/0013-zero-setup-default-gate.md) (permission
plus picker is the default gate), [platform constraints](../research/platform-constraints.md),
and [development.md, "Membership day 1"](../development.md#membership-day-1-the-screen-time-build).

Development builds can use Family Controls as soon as the paid team exists;
only TestFlight and the App Store wait for Apple's distribution approval.
So everything below works on day 1.

Write the results to `docs/local/reports/<YYYY-MM-DD>-membership-day-1.md`
in a `local/membership-day-1` PR: every step's date and outcome, each
case's result (pass, fail, or "different": what happened instead), iOS
version, and screenshots of the shield in light and dark mode. Never commit
the team ID, profiles, or certificates.

## Part 1: Accounts and identifiers (founder, about an hour plus Apple's wait)

1. **Enroll** in the Apple Developer Program as an individual
   ([developer.apple.com/programs/enroll](https://developer.apple.com/programs/enroll/)).
   Record the date enrollment completed.
2. **Note the team ID** (Membership details, 10 characters). It goes only
   into `Config/Local.xcconfig`, which git ignores.
3. **Bundle identifiers are final.** Do not change them after the request
   in step 4; Apple approves each one.

   | Target | Bundle identifier |
   |---|---|
   | App (`PofuLive`) | `com.erendenizk.pofu` |
   | Shield configuration | `com.erendenizk.pofu.ShieldConfiguration` |
   | Shield action | `com.erendenizk.pofu.ShieldAction` |
   | Device activity monitor | `com.erendenizk.pofu.DeviceActivityMonitor` |

   App Group: `group.com.erendenizk.pofu`.
4. **Request Family Controls (Distribution)** at
   [developer.apple.com/contact/request/family-controls-distribution](https://developer.apple.com/contact/request/family-controls-distribution)
   for **every** identifier in the table. If the form is per account rather
   than per identifier (decision audit, U7), say in the request that the
   app has three extensions and list all four identifiers. Record the date
   and the exact wording of any confirmation. This does not block anything
   below; it only blocks TestFlight, and it reportedly takes weeks.
5. **Capabilities.** Xcode's automatic signing registers the identifiers,
   the App Group, and Family Controls (Development) the first time it
   signs `PofuLive` (Part 2). If it reports that a profile lacks
   `com.apple.developer.family-controls`, open Certificates, Identifiers &
   Profiles, Identifiers, and enable **Family Controls** and **App Groups**
   (with `group.com.erendenizk.pofu`) on each of the four identifiers by
   hand, then let Xcode try again.

## Part 2: Build to the iPhone (local agent with the founder, about 20 minutes)

1. `git pull` on `main`, then edit `Config/Local.xcconfig`:
   - `DEVELOPMENT_TEAM` = the paid team ID.
   - Delete the `PRODUCT_BUNDLE_IDENTIFIER = com.erendenizk.pofu.dev`
     line. (`PofuLive` ignores it anyway; the default `Pofu` scheme should
     now use the final identifier too.)
2. `xcodegen generate`, then open `Pofu.xcodeproj`.
3. Choose the **PofuLive** scheme and the iPhone as the destination.
4. In the project, select each of the four targets (`PofuLive`,
   `PofuShieldConfiguration`, `PofuShieldAction`, `PofuActivityMonitor`),
   Signing & Capabilities: the paid team, "Automatically manage signing"
   on, and no red errors. Family Controls and App Groups appear as
   capabilities on all four.
5. Run (⌘R). Record any signing error verbatim.
6. **Data note.** The free build was `com.erendenizk.pofu.dev`, a different
   app with its own data. The live build starts fresh, and the existing
   Shortcuts automations still run the old app's **Hop in**. Delete the old
   app once the live one works; re-adding automations is optional (Live
   Pofu, case 12).
7. Console: filter by subsystem `com.erendenizk.pofu`, categories
   `screentime`, `hop`, `routing`. Keep it open for every case.

## Part 3: Cases

Use the iPhone in Turkish, as daily. Expected copy is given in Turkish.

| # | Do | Expected |
|---|---|---|
| 1 | Fresh install: open Pofu, tap through the welcome. | "Kapıda ben durayım" with **Ekran Süresi'ne izin ver**. No app list, no Shortcuts guide. |
| 2 | Tap **Ekran Süresi'ne izin ver**. | The system Screen Time sheet asks for Face ID or the passcode. After approving: "Seni içine çeken uygulamaları seç". |
| 3 | **Uygulamaları seç**, pick Instagram, YouTube, and TikTok (apps, not the Social category), Done. | The picker closes, iOS asks to allow notifications (allow), the screen says "Kapıdayım". **Tamam** leads to naming, then Home. |
| 4 | Open Instagram from the Home Screen. | The shield, at once: Pofu's face, "Hop! Nereye?", "Instagram bekleyebilir. Ben buradayım.", primary **Boş ver** (violet), secondary **Pofu'yla konuş**. Calm cream colors; night colors in dark mode. Screenshot both. |
| 5 | Tap **Boş ver**. Then open Pofu. | Instagram closes to the Home Screen. In Pofu, today's beads show one more filled bead; Console: `Ingested 1 Screen Time records`. |
| 6 | Open Instagram, tap **Pofu'yla konuş**. | The shield closes; within about 2 s a notification "Pofu: Instagram hakkında Pofu'yla konuşmak için dokun." (or "Pofu'yla konuşmak için dokun" if the name is unknown). |
| 7 | Tap the notification. | Pofu opens and Hop! starts for Instagram within about a second. If Hop! says "Başka uygulama" instead, the shield could not record the app's identity: note it (case 7b below). |
| 7b | Only if case 7 showed "Başka uygulama". | Hop! still works; after a pass it says to open the app yourself. Record this: it means the shield configuration extension cannot write to the App Group on this iOS version. |
| 8 | In Hop!, choose to continue (free pass). | The hand-off opens Instagram, with **no shield**. Console: `Shield lifted for 5 min`. |
| 9 | Stay in Instagram past the pass (5 minutes). | The shield returns over Instagram within about a minute after the pass ends, even with Pofu closed. Record the exact delay. |
| 10 | Get a pass again (case 6 to 8), go to Pofu, end the pass early (Passes sheet). | Opening Instagram shows the shield again immediately. |
| 11 | Get a pass, then force-quit Pofu from the app switcher. | The shield still returns at the pass's end (the monitor extension does it). Record the delay. |
| 12 | Optional Live Pofu: Settings, "Canlı Pofu (isteğe bağlı)", set up one automation for YouTube. Open YouTube. | Hop! appears through Shortcuts **and** the shield is there too. Note which comes first and whether it feels doubled; ADR-0013 says the automation should take over (not built yet). |
| 13 | Use the guarded apps (with passes) for more than 15 minutes in total today, then open Pofu, Settings. | "Ekran Süresi" section: Kalkan **Açık**, "Bugün korunan süre: en az 15 dk". Repeat at 30, 45, 60 if the day allows. |
| 14 | Tap **Pofu'yla konuş**, ignore the notification for 11 minutes, then open Pofu yourself. | No Hop! (the request expired after 10 minutes). Within 10 minutes, opening Pofu by hand does start Hop!. |
| 15 | Settings, **Uygulamaları seç**, add the Social category, save. Open an app in it that was not picked by name (for example, Facebook or X). | The shield. **Pofu'yla konuş** then Hop! leads to "Başka uygulama"; a pass lifts the shield from the **whole category** until it ends. |
| 16 | iOS Settings, Screen Time, turn Pofu off (Apps with Screen Time Access). Open Pofu, Settings. | Kalkan **Kapalı**, an **Ekran Süresi'ne izin ver** row. Instagram opens without a shield. |
| 17 | Restart the iPhone, unlock, open Instagram. | The shield is still there. |
| 18 | Next day after midnight. | "Bugün korunan süre" starts again from "15 dk'dan az". |
| 19 | Switch to the **Pofu** scheme and Run. | It builds and signs without Family Controls; Settings has no "Ekran Süresi" section; onboarding is the Shortcuts path. (Same identifier, so it replaces the live app; switch back after.) |

Also watch Console for `EXC_RESOURCE` or jetsam messages from
`PofuShieldConfiguration`, `PofuShieldAction`, or `PofuActivityMonitor`:
the extensions have a few megabytes of memory.

## What to send back

The report, with the table above filled in, the dates from Part 1, the
measured restore delays (cases 9 and 11), and any copy that reads wrong in
Turkish on the real shield (line breaks, truncation).
