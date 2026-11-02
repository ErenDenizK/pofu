# T5: iOS 27 automation import (research, device check pending)

Date: 2026-11-01. Brief: `docs/local-agent.md` (T5), started before T3 at
the founder's request. The founder's iPhone 17 is on **iOS 26.6.2**, so
nothing below has been tried on a device yet. This report is part 1: what
the sources say, and the plan to verify it. Part 2 follows once a device
runs iOS 27.

## Context from T3 so far

On the iPhone (iOS 26.6.2, Personal Team build of `main` at `492be6e`),
running Pofu's App Shortcut from the Shortcuts library **works**: Hop!
opens. The simulator failure in the T2 report is simulator-only. The
founder could **not** create the "App is opened" automation by following
the in-app guide; the exact failing step is not yet recorded (T3 will).

## How the import works

It is not an App Intents API. iOS 27 changed Shortcuts itself:

- **Triggers became actions.** Automations are no longer a separate tab;
  each trigger is a "special action" at the top of a shortcut, and one
  shortcut can stack several triggers. A page lists every shortcut that
  contains automations. ([MacStories][macstories], [Viticci][viticci])
- **Shortcuts that contain triggers can be shared.** An iCloud shortcut
  link (`https://www.icloud.com/shortcuts/<id>`) or a `.shortcut` file now
  carries the triggers. Importing one creates the personal automations.
  ([Derek Seaman][seaman], [ForwardSMS][forwardsms])
- **Imported automations arrive disabled** and greyed out; the user turns
  them on with the toggle at the top of the shortcut, and they then run
  with the creator's configuration. ([MacStories][macstories])

So an app "installs" an automation by opening a prepared shortcut link.
one sec's flow matches this: in one sec, tap **+**, **App**, pick the app
and the mode, then **Add Intervention to Shortcuts**; Shortcuts opens an
import dialog where the user turns the automation on and taps **Add
Shortcut**. ([one sec help][onesec])

## Answers to the brief's questions

| Question | Answer | Confidence |
|---|---|---|
| Which API or URL triggers the import? | No dedicated API. The app opens an iCloud shortcut link (or a signed `.shortcut` file) with `openURL`; Shortcuts shows its import sheet. | High for the mechanism (several independent sources); how one sec hosts its links is not public. |
| Can one import cover several apps? | One shortcut can stack several triggers, so technically yes. But Pofu's `CheckInIntent` takes the app as a parameter and deliberately never reads it from Shortcuts input, so one shortcut per app is the safe design. A multi-app shortcut would need the trigger to tell the action which app opened, which no source confirms for the App trigger. | Medium. |
| Can the automation run `CheckInIntent` with the app preset? | Yes for apps we prepare: the shared shortcut contains the **Hop in** action with `App = Instagram` already set. one sec notes that apps "not pre-configured by the team" need the user to pick the app again during import, which points to import questions for the rest. | Medium-high; needs a device check. |
| What does the user see, and how many taps? | Tap in Pofu → Shortcuts opens → import sheet → turn the automation on → **Add Shortcut**. About 3 to 4 taps per app, versus about 12 with today's manual guide. | Medium; exact labels unverified. |
| How does it fail, and what is the fallback? | (1) **Add Shortcut** does nothing on the last step: a known iOS 27 bug reported by one sec as FB24252363; the workaround is **Skip Setup**. (2) The user does not flip the toggle, so the automation stays off; Pofu cannot see this directly, but the existing "Test it" check catches it. (3) Shortcuts is not installed; prompt to get it. (4) iOS 26 or earlier: fall back to the manual guide. | High for (1) and (2), from two independent apps. |

Open points that only a device can settle:

- Whether an imported **App** trigger keeps **Run Immediately** (no
  confirmation each time). If it does not, the soft gate's three-second
  skip is lost.
- Whether a Personal Team build's action (`com.erendenizk.pofu.dev`)
  resolves inside a shortcut created on another device. The link must be
  authored against the same bundle ID it will run with.
- The real Turkish labels.

## Plan to verify on a device

1. Update the iPhone to iOS 27. **Blocker first:** this Mac has only Xcode
   26.6 (iOS SDK 26.5). Deploying to an iOS 27 device most likely needs
   Xcode 27, and the free Personal Team build must be re-signed every
   7 days. Install Xcode 27 before updating the phone.
2. On the iPhone, build one shortcut: **App** trigger (Instagram, Is
   Opened, Run Immediately) plus **Hop in** (App: Instagram). Share it as
   an iCloud link.
3. Delete the local automation, then open the link the way Pofu would
   (from Safari or Notes), go through the import, and record each screen,
   the tap count, and whether Run Immediately survived.
4. Repeat with a two-app shortcut to see what the action receives.
5. If the founder agrees, install one sec and record its flow as a
   reference.

## Recommendation

The import is the right path for "Live Pofu" on iOS 27 (ADR-0013): it
cuts setup from about 12 manual steps to about 3 taps per app, and it
needs no new API, only prepared links per supported app plus an in-app
button. Keep the manual guide for iOS 26. Do not build on it until step 3
above confirms that Run Immediately survives the import.

[macstories]: https://www.macstories.net/stories/ios-and-ipados-27-review/13/
[viticci]: https://x.com/viticci/status/2099546903461413005
[seaman]: https://www.derekseaman.com/2026/07/perfect-shortcut-focus-mode-tracking-for-ios-27-and-ipados-27.html
[forwardsms]: https://forwardsmsapp.com/blog/how-to-set-up-shortcuts-automation-on-ios-27/
[onesec]: https://tutorials.one-sec.app/en/articles/10309122
