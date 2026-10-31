# Product Vision

> Product name: **Pofu** ([ADR-0007](../adr/0007-product-name-pofu.md)).

## One-liner

A character-driven iPhone app that makes reclaiming your attention feel like
caring for someone you love, not like being punished by a parental-control
tool.

## The moment we design for

Pofu is not a general wellbeing or habit app. It is built for one precise
moment: **the reflexive reach for a feed**. You sit down to study, a
sentence gets hard, and your thumb is already on Instagram. You are about
to sleep, and "just one more" Reels becomes an hour. Pofu stands in that
gap, in the half second between the impulse and the scroll, and makes the
better choice the easier one.

Everything else (the economy, the companion, friends) exists to make that
moment work, and to make people come back to it.

## The problem

Short-form feeds are engineered to be compulsive. Most people who want to cut
back already know the facts; what they lack is a mechanism that interrupts
the reflex at the moment it fires and makes the healthier alternative feel
rewarding.

Existing solutions fall into three camps, and each fails in a predictable way:

| Camp | Examples | Failure mode |
|---|---|---|
| Hard blockers | Opal, Screen Time | Feels like punishment; users disable it within days. |
| Friction tools | one sec, ScreenZen | Effective but joyless; no reason to come back. |
| Character / economy apps | Brainrot, Unrot | Right idea, but paywalled from the first screen, easy to cheat, no social layer, and expensive outside the US. |

## Who it is for

1. **Primary (now):** the founder and their friends: university-age iPhone
   users in Türkiye who know they scroll too much and want help that does not
   feel like a lecture.
2. **Secondary (launch):** iPhone users in Türkiye, served with native Turkish
   copy and fair local pricing.
3. **Tertiary (growth):** the global English-speaking market, where most of
   the revenue potential lies.

The product is designed **global-first with a first-class Turkish
experience**. Both languages are authored natively, never machine-translated.

## Core loop

```
        ┌──────────── Protect ────────────┐
        │  Schedules and shields stop the │
        │  reflex; graduated friction      │
        │  asks "do you really need this?" │
        └───────────────┬─────────────────┘
                        │
   Together ◄───────────┼───────────► Earn
   Friends approve,     │        Real-life activities earn
   share streaks,       │        energy, with a bonus when
   compete weekly       │        they are verified
                        │
        ┌───────────────┴─────────────────┐
        │  Nurture: the companion thrives  │
        │  when you live and wilts when    │
        │  you rot. Spend energy to unlock │
        │  apps for a bounded time.        │
        └──────────────────────────────────┘
```

1. **Protect.** The user picks distracting apps and schedules. Opening one hits
   a shield, and the shield escalates through a friction ladder (see below).
2. **Earn.** Real-life activities (focus sessions, walks, workouts, study,
   music practice, chores) earn energy. Activities are trusted by default and
   earn a bonus when the system can verify them (ADR-0004).
3. **Spend.** Energy buys bounded unlock windows for blocked apps. Prices rise
   at night and with repeated unlocks, so the economy cannot be gamed into
   infinite scrolling.
4. **Nurture.** A companion character whose wellbeing mirrors the user's
   behavior. It is the emotional core of the product, not decoration.
5. **Together.** Friends act as accountability partners: they can approve
   emergency unlocks, share streaks, and compete in weekly leagues.

### The friction ladder

Each attempt to open a blocked app climbs one rung higher within a time
window. The ladder resets after a healthy gap.

1. **Pause:** a short breathing moment before anything else.
2. **Intent:** "What are you opening this for?" with quick answers. The answer
   is logged and reflected back later ("You opened Instagram 9 times 'just to
   check one thing' this week").
3. **Pay:** spend energy for a bounded window.
4. **Ask a friend:** past the daily budget, only a friend can approve
   (ADR-0005).

## Product principles

1. **Care over control.** Every interaction should feel like the companion is
   on your side. Never shame, never nag; be warm, funny, and honest.
2. **Trust the user, reward proof.** Self-reported activities always count.
   Verification is a bonus, never a gate.
3. **The core is free, forever.** Blocking, schedules, the friction ladder,
   the companion, and streaks are never paywalled. We monetize delight, not
   relief (see [Monetization research](../research/monetization.md)).
4. **Private by construction.** Usage data never leaves the device. Social
   features share only what the user explicitly chooses to share.
5. **Native, not generic.** Built with Apple's frameworks and conventions:
   widgets, Live Activities, Dynamic Island, Shortcuts, Control Center. It
   should feel like Apple could have made it, with more personality.
6. **Craft is the moat.** Animation, haptics, sound, and copy are the product,
   not polish to add later.
7. **Ruthless scope.** One thing done exceptionally beats five things done
   adequately. Features must earn their place.

## Non-goals (for now)

- Android. Revisited after iOS product-market fit (see ADR-0002).
- Parental control. The product is for adults managing themselves.
- Web or macOS blocking.
- Advertising-based revenue, in any form.
- AI chat companions. The character speaks through authored, crafted copy.

## What success looks like

**North-star metric: impulses resisted.** The number of times a user reached
for a distracting app and chose not to open it. Every soft-gate check-in is
a measured attempt ([ADR-0008](../adr/0008-hybrid-intervention-delivery.md)),
so this is counted exactly, not estimated. The founder's personal target:
**half of all reflexive opens resisted.**

| Horizon | Signal |
|---|---|
| Private alpha | The founder uses it daily for 30 days and their weekly screen time on chosen apps drops measurably. |
| Friends beta (TestFlight) | 10+ friends, D30 retention above 40%, at least one unprompted "this changed my habits". |
| Public launch (Türkiye) | Organic word of mouth; App Store rating of 4.7+; featured-quality screenshots. |
| Global | Sustainable revenue that funds professional illustration and continued development. |
