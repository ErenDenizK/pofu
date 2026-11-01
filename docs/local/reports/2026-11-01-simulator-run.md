# T2: First simulator run

Date: 2026-11-01. Device: iPhone 17 simulator, iOS 26.5 (23F77), Xcode
26.6 (17F113), `main` at `d1cd7cd`. Screenshots are in
[`docs/local/screenshots/2026-11-01/`](../screenshots/2026-11-01/),
named `<lang>-<appearance>-<nn>-<screen>.png` and downscaled to 1000 px tall.

## Summary

- **Build: green, zero warnings, zero errors.** The first attempt failed
  only because the Mac lacked Xcode's Metal Toolchain (see the friction
  log).
- **Every screen reachable without Shortcuts works and nothing crashed:**
  the four onboarding steps, Home, the Fill my cheeks sheet, Passes, and
  Settings, in English and Turkish, light and dark.
- **The core loop cannot be exercised in the simulator. Running Pofu's App
  Shortcut, or even adding the Hop in action to a shortcut, fails with
  "Couldn't find AppShortcutsProvider."** This is the most important
  finding. It may be simulator-only, but it has to be ruled out on the
  device in T3 before anything else.
- The rest is polish. The two worst visual problems are the companion halo
  in dark mode and content bleeding through the setup guide's footer.

## Findings, worst first

### 1. App Shortcut and the Hop in action fail (blocker until disproved)

Steps: finish onboarding, open Shortcuts, tap any tile in the Pofu
section (Hop in, Instagram, YouTube, TikTok). Result: an alert, "Unable to
run App Shortcut" (`en-light-12-shortcut-error.png`). In the Shortcuts
editor, searching "Hop in" lists the action, but tapping it inserts
nothing.

Logs (simulator unified log):

```
linkd  [com.apple.appintents:ApplicationService<LegacyApplicationService>]
       Rejecting invalid client due to requiresValidBundle: <NSXPCConnection>
       connection from pid 25861 on mach service named com.apple.linkd.autoShortcut
linkd  [com.apple.appintents:Registry] Registry error:
       Error Domain=LNActionForAutoShortcutPhraseFetchError Code=1
       "Couldn't find AppShortcutsProvider."
Shortcuts [com.apple.shortcuts:Editor] Error creating action for inserting:
       Error Domain=LNMetadataProviderErrorDomain Code=9000 ... (same cause)
```

pid 25861 is a Pofu process that `linkd` launched in the background.

What I ruled out:

- **Metadata is present and correct.**
  `Pofu.app/Metadata.appintents/extract.actionsdata` has
  `autoShortcutProviderMangledName = 4Pofu0A9ShortcutsV`, one auto
  shortcut, and the `CheckInIntent` action. The provider's conformance
  symbol (`$s4Pofu0A9ShortcutsV10AppIntents0cB8ProviderAAMc`) is in the
  binary.
- **Not the debug dylib.** A rebuild with `ENABLE_DEBUG_DYLIB=NO` fails
  the same way.
- **Not the simulator's Shortcuts in general.** Apple's own "Scan Document"
  tile in the same Library runs fine.
- **Signing is not a lever.** Simulator builds are always ad-hoc signed,
  even with `CODE_SIGN_IDENTITY="Apple Development"`.

Not ruled out, for the lead: the `requiresValidBundle` rejection of
Pofu's own background process; whether the provider or the intent needs
a different shape (for example, the parameterized phrase
`\(\.$app)` with `TargetApp`); and whether this reproduces on device.
Shortcuts logged the locale as `en-TR` (the Mac's region), which also
matters for the localized phrases.

### 2. Setup guide: content bleeds through the footer

`en-light-05-setup.png`, `tr-dark-04-setup.png`. The `safeAreaInset`
footer uses `PofuColor.canvas.opacity(0.95)`. The scrolled content behind
it ("Open Shortcuts", "Test it: open Instagram", "kere dene.",
"Kestirmeler'i aç") shows through and collides with "I'll do it later" /
"Sonra yaparım". In dark mode, step 7 is cut mid-line. The footer needs
an opaque background or a material with a clear top edge.

### 3. Setup guide: two primary buttons, and a "Done" that means nothing

`en-light-06-setup-scrolled.png`. "Open Shortcuts" (primary) and "Done"
(primary) sit on screen together. "Done" and "I'll do it later" both call
`model.completeOnboarding()`, and "Done" is enabled while the status
reads "Not working yet". The real next step should be the only primary
button.

### 4. Dark mode: the companion halo turns into a flat mauve plate

`en-dark-06-home.png`, `tr-dark-05-home.png`. The light pink halo behind
Pofu renders as an opaque greyish-mauve disc on the dark background. It
looks like a sticker on a plate, not a glow. It needs a dark variant
(lower opacity or a radial falloff).

### 5. Dark mode: unselected choice tiles lose their shape

`tr-dark-06-earn.png`. In Fill my cheeks, the unselected activity tiles
and duration chips have no visible fill or border in dark mode. They read
as loose labels, not buttons. The onboarding chips in
`en-dark-02-apps.png` keep a fill, so this looks specific to the sheet's
surface color.

### 6. Fill my cheeks: Start overlaps the duration chips

`en-light-08-earn.png`. At the default detent, the Start button covers
the bottom of the 15 / 25 / 45 / 60 chips. The chips also have no unit
("min" / "dk").

### 7. Launch: a white flash before the first frame

On a cold launch, the first screenshot was plain white before the cream
welcome screen appeared. The cause is
`INFOPLIST_KEY_UILaunchScreen_Generation: true` with no launch color, so
the system shows its default background. Set `UILaunchScreen` →
`UIColorName` to the day wash color, with a dark variant.

### 8. Smaller issues

- **App icon is a placeholder:** a flat lavender gradient, seen on the
  Home Screen and in Shortcuts.
- **Home speech bubble:** its tail points at empty space about 100 pt
  above Pofu.
- **Home header:** the seed pill and the settings button differ in height
  and shape.
- **Home "Today" card in Turkish:** the title "Bugün" is followed by
  "Bugün henüz açma isteği yok.", which repeats the word.
- **Onboarding, apps (Turkish):** "Başka bir uygulama" shrinks through
  `minimumScaleFactor` and is visibly smaller than its neighbors.
- **Onboarding, apps:** when an app is selected, its icon is replaced by
  a checkmark, so the label jumps left and loses its identity.
- **Onboarding, name (English):** "What should we call me?" reads oddly;
  the Turkish "Bana ne diyelim?" is better. The text field uses the
  system bold font, not the display font.
- **Activity names (Turkish):** "Üretmek" is a verb among nouns ("Odak",
  "Ders", "Spor"). Consider "Üretim" or "Yaratıcı".
- **Sheet consistency:** Fill my cheeks has a white surface and an ✕
  close button; Passes and Settings have a tinted surface and a "Done"
  button. Section header styles also differ within Passes.
- **Settings in dark mode:** the rows use neutral system grey, while
  other dark surfaces are purple-tinted.
- **Setup guide in Turkish:** step 6 says to tap **Hop in**. Shortcuts
  showed the action as "Hop in" because the simulator ran in `en-TR`;
  check the real Turkish label on device (T3).

## Console and crashes

- No crash reports for Pofu.
- The Pofu process logged a few errors (`containermanager`,
  `app_launch_measurement`, `appintents:Execution`). The simulator
  redacts their text (`<compose failure>`), so they are not readable here.
  The `appintents:Execution` ones line up in time with finding 1.
- Pofu writes nothing under its own subsystem. An `os.Logger` with a
  `com.erendenizk.pofu` subsystem in `CheckInIntent` and `AppModel` would
  make the T3 device run much easier to diagnose.

## Not covered

- The Hop! flow (pause, intent, pay, friend, skipped, hand-off) and the
  focus timer are unreachable without a working check-in (finding 1).
- No VoiceOver or Dynamic Type pass.

## Friction log

Every stumble in this run, tagged by source, so the lead can tell which
ones touch the product.

| What happened | Source | Product impact |
|---|---|---|
| The first build failed: "cannot execute tool 'metal' due to missing Metal Toolchain". Fixed with `xcodebuild -downloadComponent MetalToolchain` (688 MB). | Mac setup | Every new developer machine hits this. Add it to `docs/development.md`. |
| Pofu's App Shortcuts fail; Apple's run fine. | **App** (likely) | Blocks the core loop in the simulator; see finding 1. |
| A white frame before the welcome screen. | **App** | Visible to every user on cold launch; see finding 7. |
| Taps sent during an onboarding step's cross-fade were dropped twice, so the selections did not register. | App or harness, unclear | Possibly real: a quick user could lose taps. Worth checking hit-testing during `.transition(.opacity)`. |
| The simulator panel's screenshots lagged one action behind. | Tooling | None. Waiting about 1 s after each tap fixed it. |
| Error messages in the simulator log are redacted (`<compose failure>`). | Simulator | Diagnosis needs app-side logging; see Console. |
| `gh` is not installed on the Mac, so PRs cannot be opened from the command line. | Mac setup | None. |
| The brief is only on the `docs/local-agent` branch, and its clone URL points to the old `rot` repository. | Process | Merge the brief and fix the URL. |
