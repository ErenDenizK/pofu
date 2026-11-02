# Local Agent Brief

> **Status (2026-11-02):** the founder no longer runs a local Claude
> session; this brief is a reference. Art runs on Codex in the cloud
> (`AGENTS.md`); membership day 1 follows `docs/local/membership-day-1.md`.

This is the standing brief for a **Claude Code session running on the
founder's Mac** (folder `/Users/edk/projects/pofu`). The cloud session is the
lead: it plans, writes most code, reviews, and merges. The local session is
its hands on the Mac: Xcode, the simulator, the iPhone, and image generation.

Read [`CLAUDE.md`](../CLAUDE.md) and [`CONTRIBUTING.md`](../CONTRIBUTING.md)
first. Every rule there applies here: English in the repo, the founder's
commit identity, Conventional Commits, and no pushes to `main`. Talk to the
founder in Turkish.

## How the two sessions talk

- **GitHub is the bridge.** The local session never merges. It pushes a
  branch named `local/<topic>` and opens a pull request into `main`. The
  cloud lead reads the PR, reviews it, and merges it.
- **Reports go in the PR.** Each task ends with a report at
  `docs/local/reports/<YYYY-MM-DD>-<topic>.md` and evidence such as
  screenshots and logs in the same PR. Keep images optimized: PNG, each
  under 600 KB.
- **Pull before work.** Run `git pull` on `main` before every task. The
  lead changes code often.
- **Never commit secrets:** no account tokens, `.env` files, provisioning
  profiles, or team IDs. `Config/Local.xcconfig` is already git-ignored.

## Task list (in order; each task is one PR)

### T1. Environment

1. If the folder is empty, clone the repository into it:
   `git clone https://github.com/ErenDenizK/pofu.git .`
   Then set the commit identity from `CLAUDE.md`.
2. Check the tools and fix what is missing, asking the founder before any
   `sudo` or installer:
   - `xcodebuild -version` (Xcode 26 or newer, selected with `xcode-select`);
   - Homebrew;
   - `xcodegen` (`brew install xcodegen`);
   - the Metal Toolchain (`xcodebuild -downloadComponent MetalToolchain`).
3. Create `Config/Local.xcconfig` from the example. Use bundle ID
   `com.erendenizk.pofu.dev`. For `DEVELOPMENT_TEAM`, the founder must be
   signed in with their Apple ID in Xcode (Settings, Accounts). Read the
   Personal Team ID from there, or ask the founder.
4. Run `xcodegen generate`.

### T2. Simulator run and screenshots

1. Build for an iPhone 17 simulator on iOS 26 with `xcodebuild`, then boot,
   install, and launch the app with `xcrun simctl`.
2. Capture screenshots (`xcrun simctl io <device> screenshot`) of every
   screen you can reach: onboarding and Home, in light and dark mode, in
   English and Turkish. Switch language with launch arguments
   `-AppleLanguages "(tr)" -AppleLocale tr_TR`.
3. Collect build warnings, runtime console errors
   (`xcrun simctl spawn <device> log stream --predicate 'subsystem CONTAINS "pofu"'`
   or the app's process), and any crash logs.
4. Open a PR named `local/simulator-run` with the screenshots in
   `docs/local/screenshots/<date>/` and a report. The report gives an honest
   first impression: what looks broken, misaligned, or unfinished.

### T3. On the iPhone (needs the founder's hands)

1. With the iPhone 17 connected and trusted, and Developer Mode on, build
   and run on the device (`xcodebuild -destination 'id=<udid>'`, or ask the
   founder to press Run in Xcode).
2. Guide the founder through the Shortcuts automations
   ([development.md](development.md), "Use Pofu daily"). Then record what
   happens for each case:
   - Pofu comes to the foreground from the automation, with or without a
     prompt, and how fast;
   - silent pass-through during a valid pass;
   - cold launch;
   - hand-off to Instagram, YouTube, and TikTok;
   - the real Turkish labels in Shortcuts.

   Ask the founder for screen recordings where useful.
3. Write the report in PR `local/device-validation`. This is the most
   important evidence in the project right now.

### T4. Image generation (batch 01 open for the W1 test, D1–D8 only)

Production art is generated **only on the founder's own OpenAI account**:
his own ChatGPT plan through the Codex CLI, or his own API key through the
pipeline's `openai-api` backend. Using anyone else's account is against
OpenAI's terms and would muddy the provenance of shipped art. The founder
chose his own ChatGPT plan (2026-11-01). Batch 01 is open for the eight-image
W1 test (D1–D8, run with `--only`); batch 02 stays blocked until the friends
beta.

The operator is **OpenAI Codex on the Mac**, briefed by
[`AGENTS.md`](../AGENTS.md) (who, rules, decisions, stop conditions), in
a separate clone such as `~/projects/pofu-art`. A local Claude session
may operate it instead with the same rules. Everything else is in
[art-pipeline.md](design/art-pipeline.md):

1. When the lead opens a batch, do the
   [first-run checklist](design/art-pipeline.md#first-run-checklist) with
   the founder: account fields in `tools/imagegen/config.yaml`, venv and
   tests, and either the Codex checks (signed in with ChatGPT as the
   founder, `OPENAI_API_KEY` unset, one test image outside the repo,
   transparency and the image folder confirmed) or the API checks (key in
   the Keychain, model and prices verified).
2. Round by round: `plan`, `run`, `post`, the founder picks on the contact
   sheet, `promote`, PR `art/<batch>` into `main`. Never merge.
3. Small batches only (the pipeline enforces 1 image at a time, 90 s
   apart, 3 takes per job, 12 images per run). Stop and report on any
   limit, sign-in, refusal or timeout message.

Never set `OPENAI_API_KEY` for the Codex path, never automate chatgpt.com
in a browser, never commit anything from `~/.codex` or a key.

### T5. Spike: iOS 27 automation import (after T3)

one sec reports that from iOS 27 an app can install a Shortcuts personal
automation for the user ("Add to Shortcuts", then confirm in an import
sheet). Find out how this works on the founder's iPhone and in Apple's
iOS 27 documentation, then answer these questions:

- Which API or URL does the app use to trigger the import?
- Can one import cover several apps?
- Can the automation run Pofu's `CheckInIntent` with the app parameter
  preset?
- What does the user see, and how many taps does it take?
- How does it fail, and what is the fallback?

If one sec is installed or can be installed, record its flow as reference;
ask the founder first. Write the report in PR `local/ios27-automation-import`.
It decides how "Live Pofu" is onboarded
([ADR-0013](adr/0013-zero-setup-default-gate.md)).

## Etiquette

- Ask the founder before anything destructive or anything that installs
  system software.
- Do not change product code beyond what a task needs. If you find a bug,
  describe it in the report; the lead fixes it unless it blocks your task.
- Be brutally honest in reports. A clear "this is broken" is worth more than
  a polished summary.
