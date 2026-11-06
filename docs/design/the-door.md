# The Door: one place instead of six screens

**Status:** lead decision, 2026-11-06. Replaces the screen list of
[gate v2](../product/ux/gate-v2.md) §6 (the landing, skipped, a minute with
Pofu, the hand-off, the breathing room) with one scene; the rules,
numbers and copy system of gate v2 stay. Art: the round door
(`batch-58`, ADR-0020 materials). The founder (2026-11-06): "the shield, the
breath and the gate feel very close to me; with a clear head, how many
screens, how, when and why; criticise the gate harshly."

## 1. The verdict on today

Six in-app destinations for one moment, three of them a variant of
"Pofu asks you to wait": the Hop! landing, the skipped screen, a minute
with Pofu, the hand-off, the breathing room (its own lavender orb, no
world). They read as three similar screens because they are: same
question, different furniture.

**The gate as built (#265), harshly:**

1. **Three messages compete.** "Hop!", "Önce bir nefes.", "Nefes al…",
   a footnote and two buttons: the eye has nowhere to land.
2. **It breathes on every open.** Gate v2 keeps the breath for past 60
   guarded minutes; the built landing makes everyone wait through
   "Nefes al…" every time. Drift from the spec, and the main source of
   "these screens are the same".
3. **"5 dakikalığına aç" looks disabled** (a pale bar filling); the real
   options of the care rung (3 dk bak, 15 dk aç) are gone.
4. **"Vazgeç" is the wrong word**: the shield says "Boş ver"; one word
   for one act.
5. **The postcards fight Pofu**: a second painted hamster, Pofu floating,
   a scrim that washes the painting, a glass "Instagram" chip from another
   product.
6. **Nothing happens.** Pofu stands; no door, no gesture, no consequence
   you can see when you choose.

## 2. The decision: two places

| # | Place | Owner | When | Why it exists |
|---|---|---|---|---|
| 1 | **The shield** | Apple's template | every reach for a guarded app | the pause; one tap ("Boş ver") is the whole product working |
| 2 | **The Door** | ours, one scene | only after "Açmam lazım" (the notification) or from Today | a real need to open: Pofu meets you at his door |

Everything else is a **state of the Door**, never a new screen. The camera
never cuts; the door, Pofu and the plaques carry every state.

| State | When | What happens at the door |
|---|---|---|
| **Arrive** | always first | the door swings open (0.6 s), Pofu leans out, one line in his voice naming the app ("Instagram mı? Bir saniye."), the three plaques swing into view |
| **Breath** | only past 60 guarded minutes (gate v2 §6.5) | the plaques wait; a ring of warm light grows around the doorway on the in-breath and shrinks on the out-breath, Pofu breathes with it, the haptic swells; 1 cycle (2 from the 4th over-limit open); "Şimdi değil" stays as a quiet plaque |
| **Choose** | after Arrive (or Breath) | plaques: **Boş ver** (honey, primary) · **3 dk bak** · **15 dk aç** (cream, quiet); the care-rung numbers in one small line under them |
| **Boş ver** | tap | the seal stamps on the big plaque, Pofu hops proud, a seed drops to the jar, the door closes softly; 4 s later the scene rests (gate v2 §6.2's skipped, here) |
| **A minute** | the skipped state's secondary ("Pofu'yla bir dakika", ≤ 3 a day) | the camera slips through the doorway into the burrow (the `interior` layer): tea, the fur brush, 60 s, Pofu's closing line; out again |
| **Hand-off** | 3 dk / 15 dk | Pofu hands over a small hourglass, the door stays ajar, the Live Activity starts, the app opens (gate v2 §6.4's copy) |

**Payoff, not a screen:** the next time the app opens after resists, the
home shows the day's seals pressed on the door's plaque for 2 s (UI v3
§3b), then the world. Built as `DoorStamp` (once per open, any tap skips).

## 3. Rules

- One word per act: **Boş ver** everywhere (shield, Door, copy).
- The breath only past 60 minutes; never as a toll on every open.
- No choice hides: the care rung's options are always visible after
  Arrive (and Breath).
- The Door is a place: the same round door at every hour (sky by code),
  in every weather, at night with its lantern (the night relight).
- Nothing is lost by leaving: a swipe away counts as Boş ver (gate v2).

## 4. Build

1. Wave 1 (in flight) yields the reusable `BreathRing`, `BreathHaptics`
   and `PofuBreathing` and the plaque kit.
2. When `batch-58` lands: `DoorScene` (layers, door swing, plaques on the
   rope), the states above as one state machine in `App/Hop` (pure, tested
   transitions), `BreathRoom` and the skipped screen retired into states.
3. Screenshot sheet: every state at 12:00 and 22:30, plus Breath at XXL
   text.
