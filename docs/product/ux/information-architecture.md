# Information Architecture

_Status: proposal v1, for founder review. Last updated: 2026-10-31._

> **Superseded in part (2026-11-01).** This document describes the room-era
> Home, seed prices, and the passes store. Those were replaced by
> [ADR-0015](../../adr/0015-care-over-currency.md) (seeds never buy screen
> time), [ADR-0016](../../adr/0016-pre-planned-idle-archipelago.md) (the
> island), and [ADR-0018](../../adr/0018-visual-system-v1.md). The gate
> setup, Hop!, and settings sections still describe the shipping app. A
> rewrite follows the founder's first gate week; see the
> [decision audit](../../archive/decision-audit.md), C2.
_Companion docs: [user flows](user-flows.md), [clickable prototype](../../../design/prototypes/ux/README.md)._

This document defines how Pofu is organized: where things live, how people
move between them, and what is free. It assumes the decisions of tonight:
Pofu is a **round, very fluffy hamster** drawn in a soft storybook style,
the UI is warm cream and peach with deep violet `#6C4FD8` as the accessible
accent, and interventions arrive through the hybrid model of
[ADR-0008](../../adr/0008-hybrid-intervention-delivery.md).

## 1. The shape of Pofu usage

An information architecture should follow how a product is actually used.
Pofu has an unusual profile: **most of its moments happen outside the app**,
and success means the user spends *less* time on their phone, including in
Pofu.

| Moment | How it starts | Frequency (founder, day 1) | Duration | Navigation needed |
|---|---|---|---|---|
| **Hop!** (intervention) | Shortcuts automation, on every open of a protected app | 15–60 a day | 1–8 s | None. A modal moment with one decision. |
| **Hand-off** back to the target app | Inside Hop! | Up to half of the above | < 1 s | None |
| **Earning** (focus, activities) | Home, widget, Control Center, Live Activity | 1–4 a day | Start: 5 s. Session: minutes to hours, phone down. | One sheet |
| **Check-in** ("how is Pofu?") | Opening the app | 1–5 a day | 10–30 s | Home only |
| **Evening recap** | Notification at the user's wind-down time | 1 a day | 30–60 s | One sheet |
| **Spending outside Hop!** (planning a window) | Home | Rare | 10 s | One sheet |
| **Friends** (pair, approve a request) | Universal link, Home | Rare | 10–30 s | One sheet |
| **Settings, setup health** | Home | Rare | Varies | One sheet, pushed rows |

Three conclusions shape everything below:

1. **The most important screen is not a destination.** Hop! is reached from
   iOS, not from navigation. It must carry the product on its own, with no
   chrome, no tabs, and no way to get lost.
2. **The app's own surface is small.** Outside Hop!, people come to see Pofu,
   start earning, read the day, and leave. That is one home and a handful of
   tasks, not five places.
3. **Dwelling is a failure mode.** An IA that invites browsing (feeds,
   tabs full of stats, badges to collect) contradicts the mission. We want
   short, warm, complete visits.

## 2. Navigation model

### Options

| | A. Five tabs (Brainrot) | B. Three tabs | C. One home + sheets (**recommended**) |
|---|---|---|---|
| Structure | Home, Block, Focus, Stats, Settings | Home, Journal, Together | Pofu's room is the only root. Every task is a sheet or a full-screen cover that returns to Pofu. |
| Strengths | Familiar; every feature is one tap away; easy to grow into. | Conventional iOS shape; room for a weekly journal and social features. | Pofu is always the centre of the experience; minimal surface to learn; sheets keep Pofu visible behind them (iOS 26 glass sheets at medium detent); naturally short sessions. |
| Weaknesses | Each tab must justify itself and most would be thin (Stats and Block are both "settings for the gate"). Tabs make Pofu one destination among five, diluting the character. Invites browsing. | Journal and Together are empty for weeks for a new user (one friend, a few days of history). Empty tabs read as an unfinished product. | Secondary features (friends, history) are less discoverable. Requires discipline: a sheet must never become a hidden app inside the app. |
| Fit with "monetize delight, care over control" | Weak | Medium | Strong |

### Decision (proposed)

**Option C: a single home, "Pofu's room", with sheets.** Hop! and focus
sessions are full-screen covers; everything else is a sheet. No tab bar.

Discoverability is solved by the character, not by chrome:

- **Pofu's speech bubble** is a contextual entry point. It surfaces the one
  thing worth doing now ("Deniz said yes twice this week. Say thanks?",
  "Instagram hasn't called me since Tuesday. Check on it?"). Tapping it
  opens the relevant sheet.
- **Notifications, widgets, Control Center, and the Live Activity**
  deep-link into the right sheet, so most secondary entries never start
  from Home.

**Revisit trigger.** If Pofu ever has three or more destinations that people
visit *weekly by choice* (for example a weekly journal, leagues, and the
neighbors' village), move to option B with three tabs. Never five.

### Home anatomy

```
┌──────────────────────────────────────────┐
│ status bar                                │
│ (seeds pouch: 42)          (friend) (gear)│  top bar, glass buttons
│                                           │
│        "Seven skips today. I'm getting    │  speech bubble = contextual entry
│         so fluffy."                       │
│                                           │
│              [  POFU  ]                   │  Pofu in its room; tap to squish
│      wheel (still)        seed bowl       │  the wheel stands idle when you do well
│                                           │
│ ┌ Today ─────────────────────────────── ┐ │
│ │ 7 of 11 skipped   ●●○●●○●○○●●         │ │  impulse beads: the north star
│ │ Goal: half. You're at 64%.            │ │  tap → Today / recap sheet
│ └───────────────────────────────────────┘ │
│                                           │
│ [ ( Fill my cheeks ) ]  ( ticket )        │  primary: earn; secondary: passes
└──────────────────────────────────────────┘
```

Three Home concepts (the room, a ledger of reaches, a wheel of beads) are
compared side by side in the
[prototype README](../../../design/prototypes/ux/README.md#home-three-concepts);
the room is recommended and drawn above.

Rules for Home:

- **One primary action.** "Fill my cheeks" (start earning). Spending has a
  secondary button, because spending mostly happens inside Hop!.
- **Turkish:** the card reads "11'de 7 vazgeçiş" (suffix from the harmony
  helper).
- **The north star is the only number with a hero position.** Impulses
  resisted today, as *beads*: one bead per reach, filled violet when you
  skipped it, an empty ring when you opened the app. It is honest, glanceable,
  and never shows a percentage without the raw count.
- **The seed balance lives in Pofu's cheeks** first and in a number second
  (the pouch capsule top left).
- **Nothing scrolls.** Home fits on one screen at the default text size. At
  accessibility text sizes, it becomes a scroll view with the same order.

### Presentation rules

| Pattern | Used for | Why |
|---|---|---|
| Full-screen cover, no chrome | Hop!, focus session, onboarding, bedtime Hop! | Moments that need the whole stage and a single decision. |
| Sheet, medium detent, expandable | Earn picker, passes store, Today/recap, friend request | Pofu stays visible above; the task is short. |
| Sheet, large detent, with navigation stack | Settings, protected apps and setup health, friends management, history | Settings-like content where iOS conventions (grouped lists, pushes) are expected. |
| Inline in the speech bubble | Single-sentence nudges with one action | Avoids modal interruptions inside our own app. |
| Live Activity / Dynamic Island | Active pass countdown, focus session | Visible while the user is outside Pofu, which is the goal. |

## 3. Screen inventory

Columns: **Type** is root, cover (full-screen), sheet, or system surface.
**Entry** is how people arrive. **Free / Plus** follows the monetization
principle "monetize delight, not relief".

### Core

| # | Screen | Type | Entry | Purpose | Free / Plus |
|---|---|---|---|---|---|
| 1 | **Pofu's room (Home)** | Root | App launch | See Pofu's mood and cheeks, today's skips, start earning. | Free |
| 2 | **Hop!** (pause, intent, pay, ask a friend rungs) | Cover | `CheckInIntent` from the Shortcuts automation | Interrupt the reflex warmly; let the user skip in under 3 s or continue with a pass. | Free, always |
| 3 | **Skipped!** (resist celebration) | State of 2 | Skipping, or leaving Hop! without choosing | Make the resist feel good; count it; offer a tiny alternative. | Free |
| 4 | **Hand-off** | State of 2 | Choosing to open | Confirm the pass and return the user to the target app. | Free |
| 5 | **Bedtime Hop!** | Variant of 2 | Hop! inside the bedtime window | Quieter, darker, night prices. | Free |
| 6 | **Earn picker** ("Fill my cheeks") | Sheet | Home CTA, widget, Control Center | Choose an activity and a duration. | Free |
| 7 | **Focus / activity session** | Cover + Live Activity | Earn picker | Run the timer; Pofu focuses with you. | Free |
| 8 | **Cheeks-fill moment** | State of 7 | Session end | Credit seeds with the signature cheeks animation. | Free |
| 9 | **Passes** (unlock store) | Sheet | Home secondary button, pouch capsule | Plan a window ahead of time; see active passes and current prices. | Free |
| 10 | **Today / evening recap** | Sheet | Home "Today" card, evening notification | Reflect on the day, set tomorrow's intention, tuck Pofu in. | Free (7 days of history); Plus: full history and trends |
| 11 | **Ask a friend** (requester) | Sheet over 2 | Top rung, or "Ask a friend" in Hop! | Send a signed request; enter the code fallback. | Free |
| 12 | **Approve** (friend's side) | Sheet | Universal link | See context; approve 5 or 10 minutes, or decline kindly. | Free |

### Setup and management

| # | Screen | Type | Entry | Purpose | Free / Plus |
|---|---|---|---|---|---|
| 13 | **Onboarding** (welcome, apps, name, practice Hop!, Shortcuts setup, verification, notifications) | Cover | First launch | Get to a working soft gate on at least one app. | Free |
| 14 | **Shortcuts setup guide** | Cover + Picture in Picture | Onboarding, setup health, add app | Guide the user through the automation, one app at a time. | Free |
| 15 | **Protected apps and setup health** | Sheet (large) | Settings, speech bubble when an app falls silent | Per-app status (working, silent since…, never verified), test, reconnect, add, remove. | Free |
| 16 | **Friends** | Sheet (large) | Home top bar | Pair (QR, link), see your friend, unpair. | Free: one friend. Plus: up to five. |
| 17 | **Settings** | Sheet (large) | Home top bar | Ladder (pause length, free pass length), bedtime window, notifications, language, take a break, data, Plus. | Free |
| 18 | **Take a break** | Sheet (medium) | Settings, long-press on Home's gear | Legitimately pause Pofu for 1 hour or until tomorrow, instead of deleting the automation. | Free |
| 19 | **Screen Time shields** (hard gate) | Sheet (large) | Settings (after the paid membership) | Schedules and budget enforcement via the system picker. | Free |
| 20 | **Plus** | Sheet (large) | Contextual only (tapping a Plus item), Settings | Explain Plus; annual and lifetime; tip jar ("Buy Pofu a simit"). | n/a |

### Later: Pofu's neighbors

The other concept species (bunny, kitten, chinchilla) become **neighbors**
(TR: *komşular*), not "friends". "Friends" is reserved for real people who
approve requests (ADR-0005); using the same word for collectible characters
would confuse the most trust-sensitive feature in the app. *Komşuluk* is also
a warm, very Turkish idea: neighbors drop by, bring something, stay for tea.

| # | Screen | Type | Entry | Purpose | Free / Plus |
|---|---|---|---|---|---|
| 21 | **Neighbors** | Sheet (large) | Speech bubble when a neighbor visits; Settings → Pofu | See who has moved in nearby and how they were unlocked. | First neighbor free at a milestone (proposal: 100 skips). Others: Plus or milestones. |

How neighbors fit the IA without a new destination: they **visit Pofu's
room** (appear in the Home scene for a day), so the collection is something
you notice, not a screen you farm. The companion data model should treat the
species as a parameter of a character (`CompanionSpecies`), with exactly one
*companion* (Pofu) and any number of *neighbors*. The user's companion stays
a hamster at launch; letting someone swap their main companion is a separate,
later decision.

## 4. Naming

User-facing names proposed for decision (the domain names in `PofuCore`
stay as they are):

| Concept | Domain name | English | Türkçe | Why |
|---|---|---|---|---|
| Currency | `Energy` | **seeds** | **çekirdek** | Hamsters stuff seeds in their cheeks; sunflower seeds (*çekirdek çitlemek*) are a beloved Turkish ritual. At the base price, **1 seed buys 1 minute**, which makes prices self-explanatory. |
| Intervention | soft gate, `CheckInIntent` | **Hop!** | **Hop!** | "Hop!" means *whoa, hold on* in Turkish and is the hamster's hop off the wheel in English. |
| Resisting | `resisted` | **skip** (button: "Skip it") | **vazgeçmek** (button: "Vazgeç") | Plain, lightweight words. "Resist" sounds like a battle; skipping is easy. "Never mind" was rejected in prototype review: it can be read as "never mind *you*, let me in". *Vazgeç* is also iOS's own Turkish "Cancel", so it reads as "cancel the open". |
| Opening anyway | `proceeded` | **open** | **açmak** | Neutral, never "give in". |
| A reach | attempt | **reach** | **açma isteği** | "Reach" is the gesture we design for. |
| Unlock window | `Pass` | **pass** | **izin** | *İzin* (permission, leave) is the natural Turkish word. |
| Earning | activity session | **Fill my cheeks** | **Yanaklarımı doldur** | The cheeks are the economy made visible. |
| Daily summary | — | **Pofu's day** | **Pofu'nun günü** | Framed as Pofu's day, not your report card. |
| Collectibles | — | **neighbors** | **komşular** | See above. |
| Friend | — | **friend** | **arkadaş** | Real people only. |

## 5. Free and Plus

The principle from [monetization research](../../research/monetization.md)
holds without exception: **nothing that helps someone stop scrolling sits
behind the paywall.**

| Area | Free forever | Plus |
|---|---|---|
| Hop! | Every rung, every app, unlimited apps, bedtime variant | Alternative Hop! scenes (seasonal) |
| Economy | Earning, spending, passes, all activity kinds | — |
| Pofu | The hamster, all moods, all animations, the room | Room decor, outfits, seasonal themes, extra neighbors |
| Neighbors | First neighbor at a milestone | All neighbors, earlier |
| Insight | Today, the evening recap, 7 days of history | Full history, trends ("your hardest hour"), reason patterns over months |
| Friends | One accountability friend, approvals | Up to five friends; later: shared streaks, leagues |
| Ecosystem | Focus Live Activity, pass countdown, one widget size | All widget sizes and styles, alternative app icons |
| Support | — | Tip jar: "Buy Pofu a simit" (IAP, also available to free users) |

**Proposal: no paywall in onboarding.** The monetization research recommends
a soft paywall at the end of onboarding. We argue against it for Pofu:
onboarding already asks for the most expensive commitment in the product
(the Shortcuts automation), and a paywall right after it competes with the
verification step that decides whether Pofu works at all. Instead, offer
Plus **after the first weekly recap**, when the user has seen a week of
skips and Pofu has visibly changed. This needs founder sign-off because it
trades conversion at the highest-intent moment for activation.

## 6. Deep links and system entry points

| Entry | Target | Notes |
|---|---|---|
| `CheckInIntent(app:)` (Shortcuts automation) | Hop! | Background completion when a valid pass exists or a break is active (ADR-0008). |
| `pofu://earn`, `pofu://earn/focus?minutes=25` | Earn picker, or a session directly | Widget, Control Center control, Siri. |
| `pofu://today` | Today / recap sheet | Evening notification. |
| `pofu://passes` | Passes sheet | Pass-ended notification ("want 5 more?" is **not** offered from a notification; see flows). |
| `pofu://setup/{app}` | Setup health for one app | Silence nudge. |
| `https://<domain>/r/<challenge>` | Approve (friend's device) | Universal link (ADR-0005). |
| `https://<domain>/g/<grant>` | Redeem grant (requester's device) | Universal link, six-digit code fallback. |
| `https://<domain>/p/<invite>` | Pair | QR or link. |

## 7. Accessibility and localization rules that shape the IA

- **Dynamic Type.** Every screen is designed at the default size and at
  AX3. Home and Hop! reflow into a single column; Pofu's illustration
  shrinks to keep the primary action above the fold. The skip action is never
  pushed below the fold at any size.
- **VoiceOver.** Hop! announces "Hop! Instagram. One breath first." and
  focuses the skip action first. Beads read as "7 of 11 reaches skipped".
- **Reduce Motion.** Springs become crossfades; the breath becomes a
  calm opacity pulse with a text countdown.
- **Turkish morphology.** Turkish suffixes change with the noun ("Instagram'ı",
  "YouTube'u", "TikTok'u"; "Deniz'den", "Ece'den"). Strings that combine an
  app or a person's name with a suffix use a small, tested vowel-harmony
  helper, or are phrased to avoid the suffix ("5 dakikalığına aç"). This is
  an engineering requirement, not a copy preference.
- **Never colour alone.** Bead states differ by fill *and* shape (filled
  dot vs. ring); passes show time remaining as text.
