# Decision Audit: Are We Sure?

_Independent red-team review. Date: 2026-11-01. Scope: every ADR (0001 to
0018), the vision, roadmap, research, economy, game design v2, UX, design,
brand, local reports, the simulation, and the code on `main` at `975577d`
plus the unmerged branch `docs/visual-system-v1`. This document changes no
decision by itself; it says which ones deserve to stand._

## The short answer

No, we should not be at peace. Most individual decisions are well reasoned,
and several are excellent (ADR-0003, ADR-0013, ADR-0017, "Skip it" as the
primary button). But taken together the project has a **sequencing
problem and a validation problem**:

- **The core loop has intercepted zero real reaches.** On 2026-11-01 the
  founder could not create the Shortcuts automation from the in-app guide
  ([ios27 report](../local/reports/2026-11-01-ios27-automation-import.md),
  "Context from T3 so far"): he searched Shortcuts for "Insta" and "Pofu",
  which finds actions, not the App trigger, and the guide did not redirect
  him. Hop! has only ever been opened by running the App Shortcut by hand.
  There is no T3 device report.
- **Meanwhile the paper product grew to roughly 70,000 words** across 18
  ADRs, a 9,700-word game design, a 10-island-month economy simulation, an
  art bible, a prompt library, two design reviews, and a visual-system ADR,
  **all written in two calendar days** (56 commits on 2026-10-31, 65 on
  2026-11-01). ADR-0015 replaced a tested economy and was amended the same
  day. ADR-0012 was amended by two ADRs within 24 hours. These are not
  expensive-to-reverse decisions recorded once; they are a design diary
  using the ADR format.
- **The pre-membership measurement that the game design rests on is
  wrong** in a way that rewards scrolling (section 2, C1).
- **The iteration plan puts the founder's dogfood week at I11 of 12**,
  behind art batches, painted icons, widgets, and the archipelago map.

The right next week is boring: get one automation firing, dogfood the gate
that already exists, fix the measurement hole, and use the paid membership
the moment it lands to build the Screen Time default (ADR-0013). The world
and the art wait for evidence.

---

## 1. Verdict per decision

Verdicts: **Keep** (sound and evidenced enough), **Revise** (direction
right, content wrong or stale), **Retire** (should stop being a live
document or decision), **Unproven** (may be right; nothing yet shows it).

### ADRs

| ADR | Verdict | One-line reason | Evidence |
|---|---|---|---|
| 0001 Record decisions | **Revise** | The process is right, but ADRs are being used for tunable numbers and same-day reversals, which devalues them. | 0015 amended same day (breath 10/20/30 s → 5/10 s); 0012 amended by 0015 and 0016 within 24 h; breath lengths and seed gifts are config defaults, not ADR material. |
| 0002 Native SwiftUI, iOS 26 min | **Keep** | Screen Time extensions and App Intents' `.foreground(.dynamic)` need native iOS 26 anyway. | `CheckInIntent` uses `supportedModes = [.background, .foreground(.dynamic)]`; Apple deprecates `ForegroundContinuableIntent` in iOS 26 in favor of it ([Apple, supportedModes][ai-modes]). |
| 0003 Modules + Screen Time boundary | **Keep** | The best engineering call in the repo: it let the whole app be built pre-membership. | `SimulatedScreenTimeService` + tests; CI green; T2 build "zero warnings, zero errors". |
| 0004 Trust-first verification | **Revise** | After 0015, verification only makes calm grow 1.5× faster; HealthKit and camera reps now buy almost nothing, so the ADR's cost (permissions, Vision work) no longer has a payoff. | game-design §5 "Verified focus session: calm grows 1.5× faster"; roadmap Phase 3 still plans "HealthKit passive earning" and camera reps. |
| 0005 Serverless friend approval | **Revise** | Its premise ("after the daily budget is exhausted") is gone, and ADR-0015 now routes the fourth rapid reach to a friend feature that does not exist and needs a domain and the paid membership. Without it, the fourth reach is a lockout once the emergency pass is used. | ADR-0015 "The fourth rapid reach still requires a friend"; `tools/sim/island_economy.py` lines 391–399 (friend approves 50 % of the time; otherwise emergency; otherwise the reach is **counted as resisted**). |
| 0006 Code-native rendering | **Retire** (already superseded) | Correctly superseded by 0010. | — |
| 0007 Name Pofu | **Keep**, with an action | Name is good; but bundle IDs are declared "final" while the trademark check is still "before launch". A blocking conflict found later costs more than a search now. | ADR-0007 Consequences; no TÜRKPATENT/EUIPO search on record. |
| 0008 Hybrid delivery | **Keep**, **Unproven** on device | The architecture matches one sec, the only friction app with published field evidence. Nothing about it has run end to end on the founder's phone. | PNAS 2023 one sec study ([Grüning et al.][pnas]); T5 report: App Shortcut runs on device, automation not yet created. |
| 0009 XcodeGen, one package | **Keep** | Works; local agent generated and built on first try. | T1 and T2 reports. |
| 0010 Illustrated hamster | **Keep**, amend clause 4 | Art direction is the founder's strongest conviction and is coherent. Clause 4 (bunny, kitten, chinchilla as Plus collectibles) contradicts 0016, where the same species are free residents. Production depends on an account that is not the founder's (section 4). | ADR-0010 §4 vs ADR-0016 "Neighbors arrive with stages"; `docs/local-agent.md` T4 "The ChatGPT account belongs to the founder's uncle". |
| 0011 Companion motion | **Unproven** | Builds in CI, never run on a device; shader performance and the look of lids and cheeks are unknown. | ADR-0011 status "pending on-device validation"; roadmap "Companion motion validated on the founder's iPhone" unchecked. |
| 0012 UX v1 | **Revise** (keep 2, 4, 6) | Decision 4 ("Skip it" primary) is the single best-evidenced product decision we have. Decisions 1, 3 and 5 are dead or half-dead. | PNAS follow-up: "the option to dismiss had the strongest effect; the deliberation message was not effective" ([pnas]). |
| 0013 Zero-setup default gate | **Keep** (most important) | Correctly identifies that mainstream users will not build automations by hand, which the founder has now proven on himself. | T5 report: founder could not create the automation. |
| 0014 Quiet-time earning | **Revise** | Pre-membership, quiet time resumes at **pass expiry**, but nothing ends the session at expiry. A user who keeps scrolling after a 5-minute free pass accrues quiet seeds, calm, and (under 0015/0016) station production while scrolling. | economy.md "Quiet resumes when the pass ends: at its expiry"; no expiry notification or shield in `App/` (grep finds no `UNUserNotificationCenter`). |
| 0015 Care over currency | **Unproven** (principle Keep) | "Seeds never buy screen time" is sound and simpler. But the decision was made from a browser prototype playtest, retires a tested mechanism before the gate was ever used, and its hard limit (the breath) has no direct evidence and runs on the broken measurement above. | ADR-0015 Consequences: "The breath's effect is an assumption"; sim `BREATH_RESIST = 0.2 # ASSUMPTION`. |
| 0016 Idle archipelago | **Revise** (scope) | Five islands, 16 stations × 5 levels, six residents, 1,944,103 seeds of content and ~190 images is a launch-scale content plan adopted before a single real day of use. Keep the home island; postpone islands 2–5. | game-design §5, §7, §15 counts; iteration plan "Launch: five islands with 8 stations × 5 levels". |
| 0017 Pofu never dies | **Keep** | Cheap, ethical, and aligned with retention of the people who relapse. | Art bible §9; ADR-0017 reasoning. |
| 0018 Visual system v1 (unmerged) | **Revise** before merge | Proportion and the continuous camera are fine. Glass++ commits to ~30 more images plus a hand-traced custom SF Symbol per domain icon, the most expensive per-unit design work in the plan, with the lowest behavioral payoff. | ADR-0018 Consequences: "about 88 images … plus roughly 30 for Glass++"; "every painted domain icon needs a hand-traced custom SF Symbol twin". |

### Plans and documents

| Plan | Verdict | One-line reason | Evidence |
|---|---|---|---|
| Vision (`docs/product/vision.md`) | **Revise** | "The moment we design for" and the north star are excellent. The core loop (Earn → Spend energy to unlock; Pay rung; "wilts when you rot") describes economy v0. | vision "Core loop" items 2–4, "The friction ladder" rung 3 "Pay". |
| Roadmap (`docs/roadmap.md`) | **Revise** (stale) | No island, breath, `PofuWorld`, or ADR-0015 work appears; Phase 2 still has "Spend flow: unlock windows bought with energy"; Phase 3 is mostly moot. "Last updated: 2026-10-31." | roadmap Phases 1–3. |
| Competitive analysis | **Revise** | "Nobody is fair on price outside the US" and "every reference app paywalls the core" are contradicted by ScreenZen (free, donation-funded, ~4.8 stars, 30K+ ratings) and Brainrot's US annual plans at $19.99–$29.99. | Section 4 below. |
| Platform constraints | **Revise** | Constraint 10 ("cannot be created programmatically") is outdated for iOS 27; constraint 2 may be outdated (distribution request reportedly moved to an account-level form). | Section 4 below. |
| Monetization research | **Keep** (deferred) | Reasonable and correctly deferred; Türkiye numbers are explicitly unverified. Its "Earn/spend economy" free row is stale. | monetization.md table "Free forever". |
| Economy (`docs/product/economy.md`) | **Revise** | It is the only accurate spec of the code that ships, but it is headed "largely superseded" with eight inline notes; a reader cannot tell what is true today. | economy.md header and section notes. |
| Game design v2 | **Unproven** | Thoughtful anti-addiction rules (A1–A14), but its pacing evidence is circular (section 3, U5), §6's measurement table is wrong (C1), and it has not decided whether Pofu interrupts the reflex or substitutes for it, which is the founder's stated condition (section 3, U15). | `tools/sim/island_economy.py` archetypes; game-design §6, A1, A9. |
| IA (`docs/product/ux/information-architecture.md`) | **Retire** (mark superseded) | Describes Pofu's room, a seed pouch on Home, a passes store, "1 seed buys 1 minute", and neighbors at 100 skips. Every one of those is reversed. Still labeled "proposal v1, for founder review". | IA §2 "Home anatomy", §3 screens 6–9 and 21, §4 naming. |
| User flows | **Revise** | Flow 1 (setup) and flow 2's skip path are still the core; Pay rung, passes store, earn picker, night prices and "out of seeds" friend copy are dead. | user-flows §2 "Pay", §3, §4, §5 "Bedtime", §6 prefilled message. |
| Design language | **Revise** | Principles, color, contrast, type evaluation, and motion tokens are strong. §2/§9 are being overridden by ADR-0018, §12 uses v0 vitality bands, and the Baloo 2 decision it asks for an ADR on was never recorded. | design-language §12, §16 item 2. |
| Art bible | **Keep** | The process discipline (anchors, edits not regenerations, provenance) is the right answer to AI drift. Missing: whose account generates, and what that means for ownership. | art-bible §13–14. |
| Prompt library | **Revise** | Still prioritizes room-era assets (6r room plate, hamster wheel, wilting plate, meadow plates). | prompt-library P0 items 6r, 6, 8, 10. |
| Companion motion spec | **Unproven** | Good engineering; no device frame has been measured. | ADR-0011. |
| Home directions, Review 01 | **Keep** as records | Honest self-critiques; they are decisions' evidence, not live specs. | review-01 §6. |
| Iteration plan (branch) | **Revise** | Dogfood is I11 of 12 and depends on I8, which depends on I6 (art + icons + world). The one test that can falsify the product comes last. | iteration-plan table, I8 "Depends on I6, T3", I11 "Depends on I8". |
| Local agent brief | **Revise** | T3 is blocked on automation creation and needs a concrete protocol; T4 uses a third party's ChatGPT account. | `docs/local-agent.md` T3, T4. |
| Economy simulation | **Revise** | Behavior change is an input, not an output; lockouts are counted as resists; a non-existent friend approves half the time; users leave exactly when passes expire. | sim lines 201–209, 391–399, 432. |

---

## 2. Contradictions and stale documents

### C1. The measurement claim that underpins the game (highest impact)

- **game-design §6**, row "Daily threshold for the breathing break":
  "Over-counts someone who leaves early; **under-counts nothing, because
  every reopen after a pass expires is a new check-in**."
- **Reality on iOS 26 without Screen Time:** a pass is a record in our
  database. Nothing closes Instagram at expiry. The Shortcuts trigger is
  "App, Is Opened"; it does not fire while the user stays in the app. A
  5-minute free pause pass followed by 60 minutes of scrolling is logged as
  5 minutes.
- **Consequences in other documents:** economy.md "Quiet time" ("Quiet
  resumes when the pass ends: at its expiry") and ADR-0014 credit quiet
  seeds during the scroll; game-design §5 stations "make seeds … while no
  guarded app is open" (they cannot know); the 60-minute breath threshold
  under-counts; the simulation (`pass_until = t + minutes`, line 432)
  assumes perfect compliance. game-design §17 even states the opposite
  risk ("someone who leaves Instagram after one minute … reaches the
  breathing break early").
- **Fix (small):** a local notification at pass expiry ("Time's up. Back to
  me?"), a pass-expiry deep link that counts as the end of the session
  only when tapped, and treating the time between expiry and the next sign
  of life as **unobserved** for quiet time, calm, and production. Correct
  measurement arrives only with DeviceActivity thresholds (paid
  membership).

### C2. Room-era UX against the island direction

| Document, section | Says | Superseded by |
|---|---|---|
| IA §2 "Home anatomy" | Pofu's room, seeds pouch top-left, wheel, "Fill my cheeks" primary | ADR-0016 (Home on the island); game-design §5 ("seed pill … never on Home") |
| IA §3 screens 6–9 | Earn picker, focus session earns seeds, cheeks-fill, Passes store | ADR-0015 (activity no longer earns; no prices) |
| IA §3 screen 21, §4 Naming | First neighbor at 100 skips; "1 seed buys 1 minute" | ADR-0015, ADR-0016 |
| IA §5 Free/Plus | "Room decor, outfits" as Plus | game-design §10 (style variants, cosmetic residents) |
| user-flows §1 step 11 | "Here are 15 seeds to start" (daily allowance) | ADR-0015 (no allowance) |
| user-flows §2 Pay rung, §4 passes store, §5 bedtime night prices | Prices, escalation, refunds | ADR-0015 |
| user-flows §6 prefilled message | "Pofu's out of seeds. Can I have 10 minutes?" | ADR-0015 (friend at the fourth rapid reach) |
| prompt-library P0 6r, 8, 10 | Room plate, wilting day plate, wheel prop | ADR-0016, ADR-0017 (no "wilting"), game-design §15 batch |

Neither IA nor flows carries a "superseded" banner; both still say "for
founder review".

### C3. economy.md against game design v2 and the code

- economy.md is labeled "largely superseded" but is the **only accurate
  description of what `PofuCore` does** (Wallet, prices, refunds, vitality
  EMA). game-design §13 is labeled "proposed, not yet implemented". So the
  spec of the running app is the deprecated one, and the live spec
  describes code that does not exist. CLAUDE.md says "Keep
  `docs/product/economy.md` in sync with `PofuCore`", which today means
  keeping the obsolete design documented.
- Vitality: economy.md "Companion vitality" (0…1 EMA, bands thriving /
  content / tired / wilting) vs. game-design §5 wellbeing (5–100, bands Cozy
  / Content / Tired / Unwell / Curled up, "sleeps it off"). `PofuCompanion`
  is driven by 0…1 vitality (ADR-0011 §3); design-language §12 maps the
  v0 bands to scenes.
- Seeds sources: economy.md "Earning" (honor, verified, steps) vs. game-design
  §5 (quiet, stations, skips only). Roadmap Phase 3 still schedules
  HealthKit earning.

### C4. Vision and roadmap against ADR-0015 and ADR-0017

- vision "Core loop" 3: "Energy buys bounded unlock windows … Prices rise at
  night" vs. ADR-0015 "Seeds never buy screen time."
- vision "Nurture: the companion thrives when you live and wilts when you
  rot"; competitive-analysis "Synthesis" 1: "a reason to stop (the companion
  wilts)". ADR-0017 and art bible §9 forbid the sick look; "wilting" no
  longer exists as a band.
- vision "The friction ladder" 4: "past the daily budget, only a friend can
  approve" vs. ADR-0015 (no budget; breath is the limit).
- roadmap Phase 1 "Pofu's room v1" checked as done; no line for the island,
  `CareLedger`, `BreathRules`, or `PofuWorld`. Phase 2 "Spend flow: unlock
  windows bought with energy." Phase 3 "Earn for real" has no purpose under
  0015.

### C5. ADR against ADR

- **ADR-0010 §4** (other species unlocked through Plus or milestones) vs.
  **ADR-0016** (Mochi the bunny, Simit the kitten, Bulut the chinchilla are
  free residents) vs. **game-design §10** (Plus residents "produce
  nothing").
- **ADR-0016** "Home is **Pofu up close** on his island (Home direction B)"
  vs. **ADR-0018** decision 1 "balanced diorama … Pofu is about 20 % of the
  screen width". ADR-0018 does not say it amends 0016.
- **ADR-0015** fourth rapid reach → friend vs. **ADR-0005** (friend feature
  is Phase 5 and needs universal links on a domain). Until then, after the
  daily emergency pass, the fourth rapid reach has **no way to open**. That
  contradicts game-design A14 ("never a dead end") and economy.md "Never
  stuck". The simulation hides it by counting the lockout as a resist.
- **ADR-0005** Context ("after the user's daily budget is exhausted") has no
  referent after ADR-0015.
- **ADR-0018 / iteration plan I6** put the **seed jar** on Home as a world
  indicator whose rule is "repeat state that also has a native readout";
  game-design §5 keeps the seed pill "off Home". On Home, the jar has no
  native twin.

### C6. Docs against the code and the device

- **Setup guide** (`App/Setup/SetupGuideView.swift`): a static list of 7
  text steps. user-flows §1 "The guided Shortcuts setup" specifies a PiP
  video guide, a Live Activity fallback, and a verification open. The PiP
  guide was never built, and the founder failed the text guide.
- **platform-constraints §10** "It cannot be created programmatically" vs.
  T5 report and ADR-0013: on iOS 27, a shared shortcut link carries
  triggers and imports them. The founder's phone is on iOS 26.6.2.
- **local-agent.md** T1 clone URL `ErenDenizK/rot.git` (fixed in main to
  `pofu`), and T4 still asks for "prompt 1 (the base, R1)" while ADR-0018
  and the iteration plan start art with game-design §15's batch.
- **CLAUDE.md** "Current state" still says the founder's first on-device
  test is the top priority; the merged work since then is game, art and
  design.

---

## 3. Unvalidated assumptions, ranked

Score = P(wrong) × cost if wrong, each 1–5. "Who" is who can run the
cheapest test: **Cloud** (this agent), **Mac** (the local agent),
**Founder** (on the iPhone).

| # | Assumption | P | Cost | Score | Cheapest test that settles it | Who |
|---|---|---|---|---|---|---|
| U1 | The founder (and later users) can create the iOS 26 automation from our guide. | 5 (already failed once, see below) | 5 (no dogfood, no product) | **25** | Founder screen-records one attempt following the guide while the Mac agent watches; record the exact failing screen. If it fails again, the Mac agent builds the automation with him by voice, and we rewrite the guide from the recording with Turkish labels as seen on his phone. | Founder + Mac |
| U2 | Pre-membership usage is measured well enough for quiet time, calm, production, and the 60-minute breath threshold (C1). | 5 | 4 (rewards scrolling; corrupts the dogfood week's numbers) | **20** | Unit test: grant a 5-minute pass, emit no events for 60 minutes, assert quiet seeds credited. It will pass today, which proves the hole. On device: take a 5-minute pass, scroll 20 minutes, open Pofu. | Cloud, then Founder |
| U3 | The gate changes the founder's behavior toward "half of reflexive opens resisted". | 3 | 5 | **15** | 7-day dogfood on current `main` with the event log: attempts, resisted ratio, time to Hop!, automation silences. No new features required; `ImpulseMetrics` already computes it. | Founder |
| U4 | Hop! arrives fast and reliably enough (no long glimpse of the feed, no loop, works on cold launch, survives the 7-day re-sign). | 3 | 5 | **15** | 20 consecutive opens across the three apps, screen-recorded at 60 fps; measure ms from tap to Hop!; repeat after reinstalling a re-signed build to see whether automations still resolve the action. one sec documents a "glimpse" problem and a fix ([one sec help][onesec-glimpse]). | Founder + Mac |
| U5 | The island game increases resisting and retention rather than becoming a second checking habit or being ignored. | 4 | 4 (most of the planned effort) | **16** | Not testable before U3. Then A/B on one person: week 1 gate only, week 2 gate + a static, code-drawn island with real seeds. Watch Pofu opens per day vs. reaches (game-design's own metric). The simulation cannot answer this: in it, the heavy scroller's resist probability rises from 0.15 to 0.55 and reaches fall from 3.0 to 1.2 per hour **as inputs** (sim lines 201–202), so "feed time falls from 183 to 40" is assumed, not predicted. | Founder, later 5 friends |
| U6 | A 5-second, user-started breath after 60 minutes is a meaningful limit. | 4 | 3 | **12** | Dogfood metric: share of over-limit opens ending in "skip" in week 1 vs. week 2. Evidence today: one sec's study supports a short delay and especially a dismiss option; it found the deliberation message ineffective ([pnas]). Nothing tests a tap-to-start breath with "Open" right after it. | Founder |
| U7 | Family Controls distribution approval will arrive in time and covers all extensions. | 3 | 4 | **12** | Submit the request on day 1 of the membership (roadmap checklist). Reports say the request moved to an account-level form and may cover all bundle IDs, with waits of weeks to months ([forum 828085][fc-dist], [forum 829398][fc-pending]). | Founder |
| U8 | We may generate production art with the uncle's ChatGPT account through Codex. | 4 | 3 | **12** | Read the terms: OpenAI's Terms of Use say "You may not share your account credentials or make your account available to anyone else" ([OpenAI terms][oai-terms]). The fix is the founder's own Plus account; a 10-minute decision, not a test. | Founder |
| U9 | The free Shortcuts-based gate is what users will set up (ADR-0013 already says no; but onboarding and the guide still assume it). | 4 | 3 | **12** | After membership: build the shield-only onboarding (permission + picker) and time it against the manual guide on one friend's phone. | Cloud + Founder |
| U10 | iOS 27 import keeps "Run Immediately" and resolves a Personal Team bundle ID. | 3 | 3 | **9** | T5 part 2: update the phone to iOS 27 (with Xcode 27 on the Mac first), share a one-app shortcut, import, check. I am not sure whether Xcode 27 runs on the Mac's macOS 26.3.1. | Mac + Founder |
| U11 | GPT Image can hold the art bible across ~120 images as edit chains. | 3 | 3 | **9** | Iteration I1 as planned, but stop at the 8 images and judge on the phone. | Founder + Mac |
| U12 | The archipelago pacing (nobody finishes before day 40, everyone builds weekly) matters to anyone. | 3 | 2 | **6** | Irrelevant until U3 and U5 pass. | — |
| U13 | Turkish users will pay about 350 TL a year for Plus. | 3 | 2 | **6** | Fake-door "Plus" button in the friends beta. | Later |
| U14 | "Pofu" is registrable as a trademark in Türkiye and the EU. | 2 | 4 | **8** | TÜRKPATENT and EUIPO (TMview) searches in classes 9 and 42: 30 minutes. | Cloud or Founder |
| U15 | The game can be a healthy alternative to the Reels reflex without becoming a new one. | 3 | 4 | **12** | See "The founder's condition on the game" below: define the guardrail metric before building, then read it in week 2 of the dogfood. | Founder |

### First-hand evidence: how the setup failed (founder, 2026-11-01)

This is the only real-user test of the core gate setup so far, and it is
more informative than any document in the repository.

- **His mental model was "if Instagram opens, then do X".** That is exactly
  the right model; the automation is that rule.
- **He searched for "Insta" and "Pofu" inside Shortcuts.** Search in
  Shortcuts surfaces **actions** (including Pofu's "Hop in"), not the
  **App trigger** in the Automation tab. Searching is the natural move for a
  user who thinks "make a rule about Instagram", and it leads to the wrong
  place: a regular shortcut with Pofu's action and no trigger, which never
  runs.
- **The guide did not stop him.** `SetupGuideView` step 1 is a single
  sentence ("Open Shortcuts and tap **Automation** at the bottom"), with no
  screenshot, no "do not search" warning, and no picture of the trigger
  list. Step 6 even tells the user to "Search **Pofu**", which reinforces
  search as the way in.

What this changes:

1. **U1 is no longer an assumption; it is a known failure** with a known
   mechanism. The fix is design, not engineering: a guide built around
   screenshots of the exact iOS 26 screens in Turkish, an explicit "don't
   use search; tap Automation at the bottom" in step 1, a picture of the
   trigger list with **App** highlighted, and step 6 rephrased so that
   search happens only inside "Add Action". The Mac agent can capture
   those screenshots on the iPhone in under an hour. I am not sure a URL
   exists that opens Shortcuts directly on the Automation tab; test
   `shortcuts://` variants on the device before relying on one.
2. **It is evidence for ADR-0013, not against the gate.** If the founder,
   the most motivated user Pofu will ever have, needs live help, the manual
   iOS 26 setup cannot be mainstream onboarding. The Screen Time picker
   (membership) and the iOS 27 import (T5) are the two real answers. The
   manual guide only has to get **one person** through it this week.
3. **It argues for a different question in the onboarding copy.** Users
   think in "if X opens, then Y"; the guide should use that sentence
   ("We're making a rule: when Instagram opens, Pofu hops in") so the
   mental model and the screen agree.

### The founder's condition on the game

The founder is fine with Pofu being a game **as long as it does not
become a new addiction and works as a healthy alternative to the Reels
reflex**. That condition exposes a tension in game design v2 that should
be decided explicitly, not discovered later:

- **Interrupt or substitute?** Game-design A1 and A9 make Pofu a place you
  visit for 1–2 minutes and leave ("opening Pofu does nothing for
  production"; "on the fourth Pofu open in an hour he is bored"). That is
  an **interrupter**: it breaks the reflex and hands you back to life. A
  "healthy alternative to the Reels reflex" is a **substitute**: the thumb
  goes somewhere else and something pleasant happens. Substitutes are what
  turn into the new habit.
- **My recommendation:** keep Pofu an interrupter by default, and allow at
  most one bounded substitute at the moment of the skip (for example, the
  skip celebration offers one 20–30 second island moment, at most a few
  times a day, that always ends in "All caught up"). This satisfies the
  founder's wish without adding an open-ended loop.
- **Guardrail metric, set before building:** Pofu opens per day (outside
  Hop!) must stay below reaches per day, and median time in Pofu outside
  Hop! must stay under 90 seconds (game-design A10). If week 2 of the
  dogfood with the island breaks either, the island is the problem, not
  the user.

---

## 4. Research freshness check

Searched on 2026-11-01. `apps.apple.com`, `developers.openai.com`, and
`tutorials.one-sec.app` were not reachable from this environment, so App
Store prices and the official Codex docs were read only through search
snippets and third-party pages. Treat prices as indicative.

### Friction interventions

| Claim in our docs | Status | Source |
|---|---|---|
| "one sec … Friction alone measurably reduces opens" (competitive-analysis table) | **Supported, with caveats.** PNAS 2023, 280 participants over 6 weeks: users closed the target app 36 % of the times one sec interfered; attempts fell 37 % from week 1 to week 6; 57 % fewer opens overall. A follow-up online experiment (N = 500) found the **dismiss option had the strongest effect**, time delay helped, and the **deliberation message was not effective**. Co-authored by one sec's founder; the field part has no separate control group. | [Grüning, Riedel, Lorenz-Spreen 2023][pnas], [Time][time] |
| Pofu's ladder relies on an intent question (rung 2) | **Weakened.** The only evidence we cite found deliberation prompts ineffective. Keep the intent rung for data and copy, not as a lever, and measure its skip rate separately. | [pnas] |
| Breathing pause as the hard limit (ADR-0015) | **Unsupported.** I found no independent study of a short, user-initiated breath before opening an app. one sec's own pages describe its pause as a breathing exercise, but the evidence is about the pause plus dismissal, not breathing. A registered RCT on a ~5-second delay exists but has not reported. | [clinicaltrials NCT07829211][nct], [one sec Max Planck page][onesec-study] |
| Hard limits as a comparison | **Context.** Allcott, Gentzkow and Song: optional commitment limits cut tracked app time by about 22 minutes a day (17 %); self-control problems explain about 31 % of social media use. Our "half of reflexive opens" goal is ambitious but not absurd against one sec's 36 % in-the-moment dismissals. | [NBER w28936][nber] |
| No evidence on long-term decay | **Open.** No 2024–2025 trial I found measures habituation to friction beyond 6 weeks. game-design §17's worry about a 5-second tap-through becoming muscle memory is legitimate and unmeasured. | search, no result |

### Screen Time APIs

| Claim | Status | Source |
|---|---|---|
| Personal Teams cannot use Family Controls, not even development (platform-constraints §1) | **Confirmed** by Apple DTS replies on the forums; no 2026 change found. | [forum 852204][fc-personal], [forum 803362][fc-test] |
| Distribution needs approval **per bundle identifier** (§2) | **Possibly outdated.** A 2026 forum thread reports the request moved to an account-level form and was enabled for all bundle IDs under the team; another reports a request pending since 2026-06-02. Single-source; verify on the developer portal on day 1. | [forum 828085][fc-dist], [forum 829398][fc-pending] |
| iOS 27 changes to FamilyControls / DeviceActivity / ManagedSettings | **Unclear.** WWDC 2026 revamped consumer parental controls; Apple promised new APIs, but I found no confirmed developer-framework change. One competitor (Habit Doom, self-interested) says the framework was not improved and callback issues persist. | [AppleInsider][ai-pc], [Habit Doom][habitdoom] |
| Shield cannot open the app; report extension cannot export (§4, §5) | **Not contradicted** by anything found. | — |

### Shortcuts automations

| Claim | Status | Source |
|---|---|---|
| Automations "cannot be created programmatically" (platform-constraints §10) | **Outdated for iOS 27.** Triggers are now actions inside a shortcut; shortcuts with triggers can be shared and imported. one sec documents "Add Intervention to Shortcuts" on iOS 27 and a known bug (FB24252363) on the last step. | [MacStories iOS 27 review][macstories], [one sec iOS 27 setup][onesec27] |
| iOS 26: "App, Is Opened, Run Immediately" works for a free account (ADR-0008) | **Confirmed** in principle (Apple's guide; developer write-ups). A one sec-style open-source app reports the re-open loop and fixes it with iOS 26's foreground modes, the same approach as `CheckInIntent`. A single report says iOS 26.6 "When App Is Closed" automations misfire. | [Apple Shortcuts guide][sc-guide], [dev.to write-up][devto], [forum 841128][sc-bug] |
| Imported iOS 27 automations keep "Run Immediately" | **Unknown.** No source confirms; T5 part 2 is the test. | — |

### Liquid Glass

| Claim | Status | Source |
|---|---|---|
| `glassEffect`, `GlassEffectContainer`, `.glassProminent` (design-language §8) | **Confirmed** as iOS 26 APIs. | [Apple GlassEffectContainer][glass] |
| Glass appearance is stable | **Changed in iOS 27.** Reported refinements: more diffusion for legibility and a **user-facing opacity slider**. Designs must not rely on a specific glass transparency over the painted world; test at both ends of the slider. Details are from secondary coverage. | [SiliconANGLE][glass27], [WWDC26 SwiftUI notes][swiftui27] |

### Image and video generation

| Claim | Status | Source |
|---|---|---|
| Codex CLI can generate images with a ChatGPT login (iteration plan I1, local-agent T4) | **Probably yes, unofficial.** Several third-party tools describe a built-in Codex image tool gated to ChatGPT auth on paid plans, drawing on the plan's limits. I could not read OpenAI's own docs from here. | [codex-imagegen-cli][codex1], [Codex pricing][codex-price] |
| Using the uncle's ChatGPT account | **Conflicts with OpenAI's terms** ("You may not share your account credentials or make your account available to anyone else"). It also muddies the provenance record the art bible §13 requires. | [OpenAI terms][oai-terms] |
| Sora discontinued (ADR-0011) | **Confirmed**: announced 2026-03-24, app closed 2026-04-26, API scheduled to end 2026-09-24 (the final date is confirmed only by secondary sources). | [Neowin][sora] |

### Competitors

| Product | Our docs say | What I found | Status |
|---|---|---|---|
| Opal | ~$19.99/mo or ~$99.99/yr; "users disable it within days" (vision) | ~$99/yr cited by third parties; TR listing is free with IAP, no TL price visible; Turkish reviewers complain about missing Turkish. The "disable within days" claim has no source in our docs. | Price plausible; behavioral claim **unsourced** |
| one sec | ~$4.99/mo or ~$49.99/yr; "joyless; no reason to come back" | Price not verified. It has the only peer-reviewed field evidence in the category and a 6-week effect, which undercuts "no reason to come back". Free tier: one target app. | **Revise** the framing |
| ScreenZen | "Unclear; donation-based or ~$4.99/mo" | Free, donation-supported (tips $5–$40), ~4.8 stars with 30K+ ratings. | **Contradicts** "every reference app paywalls the core" and "nobody is fair on price" |
| Brainrot | Subscription; implied expensive | US: $3.99/month, $19.99–$29.99/year; hard paywall at the end of onboarding. | Not expensive in USD; TL unknown |
| Unrot | Mandatory subscription | Paid subscription required; IAPs from ~$9.99 to $69.99 (labels unclear). | Confirmed |
| Finch | Freemium cosmetics, D1/D7 54 %/37 % | Finch Plus about $9.99/month, $40–$70/year (sources conflict). D1/D7 is a third-party estimate. | Price confirmed roughly; retention **unverified** |
| Forest | "Paid / freemium" | One 2026 review says Forest moved from a $3.99 paid app to a free download with a ~$59.99/year subscription in December 2025. Single source. | **Possibly outdated** |
| Türkiye prices for all of the above | Not in the docs | Not verifiable from here (App Store blocked). | **Gap**: the local agent can read TR prices from the App Store on the Mac in 10 minutes |

---

## 5. Sequencing critique

**What happened.** In two days the team shipped a real soft-gate app
(#14) and then spent the next ~15 PRs on Home directions, an island game,
an economy simulation, an archipelago, a breathing redesign, art tests,
design review 01, and Glass++. The founder's only on-device contact with
the core is running the App Shortcut by hand. The automation, which is the
product pre-membership, has never fired. When the founder tried, he did
what any user would do: he searched Shortcuts for "Insta" and "Pofu",
found actions instead of the App trigger, and the one-line guide did not
redirect him (section 3, "First-hand evidence"). The cost of that failure
is the whole dogfood, and the fix is an afternoon of screenshot-based
guide work, yet none of the ~15 PRs since #14 touched the guide beyond
button hierarchy.

**Why that order is wrong.**

1. **The cheapest falsifier is the gate, and it is already built.** If the
   founder does not resist a meaningful share of reaches in a week, no
   island fixes that. If he does, we learn which rung does the work, and
   the game can be designed around a real number instead of
   `BREATH_RESIST = 0.2`.
2. **Game design is now ahead of measurement.** Calm, production, the
   breath threshold, and wellbeing all consume "guarded minutes", which
   are wrong pre-membership (C1). Every design iteration on those numbers
   before DeviceActivity is tuning noise.
3. **The paid membership changes the plan in about two weeks.** ADR-0013
   makes Screen Time the default gate. The shield path (picker,
   ManagedSettings, DeviceActivity thresholds, ShieldAction counting) is
   the launch onboarding and the only honest measurement. It is not in
   the iteration plan at all.
4. **Art is the longest-lead, least-reversible spend**, and the plan
   commits to ~120 images (88 world + ~30 Glass++) plus vector twins
   before the world has run on a phone once.
5. **Decision churn is a symptom.** Three ADRs a day means the team is
   deciding from prototypes, not from use. Real use would have settled the
   price-check question (ADR-0015) in an afternoon.

**The order I would follow.**

| Step | When | What | Exit check |
|---|---|---|---|
| 1 | Now (Founder + Mac) | Create one automation (Instagram) with the Mac agent guiding live, starting from the Automation tab and never from search; screen-record; capture every screen in Turkish; write the T3 report. Then YouTube and TikTok. | Hop! fires from a real reach on all three apps. |
| 2 | Now (Cloud, ≤1 day) | Rewrite the setup guide from those screenshots ("When Instagram opens, Pofu hops in"; "don't search, tap Automation"; App trigger highlighted). Close the measurement hole (C1): pass-expiry notification; post-expiry time unobserved. | A second person (a friend) completes setup from the guide alone; unit tests for unobserved post-expiry time. |
| 3 | Days 1–7 (Founder) | Dogfood the current gate (economy v0 is fine: pause, intent, skip are the same in v2). No new features in that build. | Daily: attempts, resisted ratio, time to Hop!, silences. A one-line note per day. |
| 4 | Membership day 1 | Enroll, request Family Controls distribution, enable capabilities (roadmap checklist). | Request submitted, date recorded. |
| 5 | Week 2–3 (Cloud) | Build the Screen Time default: authorization, picker, shield with Pofu's line, ShieldAction resist counting, DeviceActivity thresholds at 15/30/45/60 min. | Founder's second week runs on shield + Live Pofu; usage minutes are measured, not estimated. |
| 6 | After the week-1 data | Implement the minimal ADR-0015 slice that the data asks for: likely the breath and removal of prices. Skip gifts and calm only if the week shows the gate alone does not hold. | Week-2 resisted ratio vs. week 1. |
| 7 | After two weeks of daily use | The home island vertical slice (I1, I2, I4, I5, I6) with one island, three stations, Mochi, and art batch 01. | Pofu opens per day stays below reaches; the founder still uses the gate. |
| 8 | After the friends beta starts | Islands 2+, Glass++ icon family, widgets, app icon layers, rituals. | Friends' D7 and resisted ratio. |

---

## 6. What to cut or postpone

**Stop now**

- Writing ADRs for tunable values and same-day reversals. Breath seconds,
  seed gifts, thresholds, and island names belong in config and the game
  design; ADRs are for things that cost weeks to undo.
- Generating production art through the uncle's ChatGPT account.
- New game or design documents until the dogfood week has data. Polish
  feedback is already "collected, not acted on"; extend that to design
  exploration.

**Postpone until after two weeks of daily use**

- Islands 2–5 (İskele, Yıldız, Kaplıca, Kitap), their rituals (postcards,
  constellations, warm spring, Bulut's story), the archipelago map, the
  cloud pass, and the 30 pt map pin.
- Glass++: painted domain icon family, hand-traced SF Symbol twins, seed
  jar and calm lantern, painted widgets, the layered app icon (ADR-0018 §2,
  §4–5). Keep native glass and SF Symbols until then.
- 15 of the 20 emotions in game-design §12 and 6 of the 11 face edits. Ship
  proud, pout, easy-going, breathing, and unwell first.
- Station levels 4–5, the windmill and workshop, and every resident except
  Mochi.
- The PiP video setup guide (user-flows §1). iOS 27 import replaces most of
  it; a better text guide covers iOS 26.
- Baloo 2 with rewritten font metrics. SF Pro Rounded Heavy is the stated
  fallback and costs nothing.

**Retire or rescope**

- Roadmap Phase 3 ("Earn for real"): HealthKit earning and camera reps
  have no reward left after ADR-0015. Keep verified focus as a calm boost
  only if the founder uses focus sessions at all.
- ADR-0005 friend approval as a rung requirement. Until it ships, the
  fourth rapid reach must fall back to the breath, not to a lockout.
- The IA and room-era flows as live documents: mark superseded today,
  rewrite after step 5 of the order above.

---

## 7. Top 10 actions, in order

1. **Get one automation firing on the founder's iPhone today** (Founder +
   Mac): screen-record the attempt, note the failing step, finish all
   three apps, and file the T3 report. Nothing else on this list matters
   if this fails.
2. **Close the pre-membership measurement hole** (Cloud): pass-expiry
   notification; treat post-expiry time as unobserved for quiet time and
   any future calm or production; tests for both. Correct game-design §6
   and economy.md "Quiet time" in the same PR.
3. **Run a 7-day dogfood on the current gate** (Founder), with no feature
   changes during the week, and a daily metrics readout from the event log
   (attempts, resisted ratio, time to Hop!, silences).
4. **Rewrite the setup guide from the recording** (Cloud): one screenshot
   per step with the exact iOS 26 Turkish labels, the "if Instagram opens,
   Pofu hops in" sentence, an explicit "don't use search, tap Automation"
   in step 1, search only inside "Add Action", and a "Test it" open as the
   only primary action. Plan the iOS 27 import button for after T5 part 2.
5. **On membership day 1, request Family Controls distribution** (Founder)
   and record the date; then **make the Screen Time shield path the next
   engineering milestone** (Cloud), ahead of `PofuWorld`.
6. **Replace the uncle's ChatGPT account** with the founder's own before
   any production art (Founder), and add the account to each provenance
   record.
7. **Mark stale documents superseded in one PR** (Cloud): vision core loop,
   roadmap phases 1–3, IA, user flows §2–§6, prompt-library room items,
   ADR-0005 context, ADR-0010 clause 4. Split economy.md into "v0 as
   implemented" and a pointer to the game design.
8. **Cut ADR-0018 and the iteration plan before merging** (Cloud): keep
   proportion and the camera; move Glass++ painted icons, widgets and the
   app icon to after the friends beta; move the dogfood from I11 to I1.
9. **Fix the simulation's honesty** (Cloud): make behavior change an
   explicit scenario rather than a baseline; count lockouts separately from
   resists; remove the 50 % friend until ADR-0005 ships; model use past
   pass expiry. Re-run before quoting its numbers again.
10. **Run the trademark search for "Pofu"** in TÜRKPATENT and EUIPO
    (Cloud or Founder, 30 minutes) before the bundle IDs are used for a
    distribution request.

## What I could not verify

- Türkiye App Store prices for any competitor (the App Store was not
  reachable from this environment).
- OpenAI's official Codex documentation on image generation with a
  ChatGPT login; only third-party descriptions were reachable.
- Whether iOS 27 changed the Screen Time developer frameworks.
- Whether imported iOS 27 automations keep "Run Immediately".
- Whether Xcode 27 runs on the founder's macOS 26.3.1.
- Whether the Shortcuts automation keeps resolving Pofu's action after a
  7-day free re-sign and reinstall.
- one sec's and Opal's current prices; Finch's retention figures.

[pnas]: https://pmc.ncbi.nlm.nih.gov/articles/PMC9974409
[time]: https://time.com/6240981/social-media-addiction-app
[onesec-study]: https://one-sec.app/max-planck-study
[nct]: https://clinicaltrials.gov/study/NCT07829211
[nber]: https://www.nber.org/system/files/working_papers/w28936/w28936.pdf
[fc-personal]: https://developer.apple.com/forums/thread/852204
[fc-test]: https://developer.apple.com/forums/thread/803362
[fc-dist]: https://developer.apple.com/forums/thread/828085
[fc-pending]: https://developer.apple.com/forums/thread/829398
[ai-pc]: https://appleinsider.com/articles/26/06/08/revamped-parental-controls-are-coming-to-iphone-mac-and-more
[habitdoom]: https://habitdoom.com/blog/wwdc-2026-screen-time-wishlist
[macstories]: https://www.macstories.net/stories/ios-and-ipados-27-review/13/
[onesec27]: https://tutorials.one-sec.app/en/articles/10309122
[onesec-glimpse]: https://tutorials.one-sec.app/en/articles/3312258
[sc-guide]: https://support.apple.com/en-ca/guide/shortcuts/apd690170742/9.0/ios/26
[devto]: https://dev.to/eliguzz/building-an-open-source-one-sec-alternative-breaking-the-shortcuts-infinite-loop-thanks-to-ios-26-ka4
[sc-bug]: https://developer.apple.com/forums/thread/841128
[ai-modes]: https://developer.apple.com/documentation/appintents/appintent/supportedmodes
[glass]: https://developer.apple.com/documentation/swiftui/glasseffectcontainer
[glass27]: https://siliconangle.com/2026/06/08/apple-refines-liquid-glass-design-expands-child-safety-tools-wwdc/
[swiftui27]: https://dev.to/arshtechpro/wwdc26-whats-new-in-swiftui-a-developers-breakdown-1333
[codex1]: https://github.com/jdmnk/codex-imagegen-cli
[codex-price]: https://chatgpt.com/codex/pricing/
[oai-terms]: https://openai.com/terms
[sora]: https://www.neowin.net/amp/openai-to-shut-down-sora-app-and-apis-as-it-shifts-focus-to-coding-ai/
