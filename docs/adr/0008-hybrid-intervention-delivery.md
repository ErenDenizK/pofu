# 0008. Hybrid intervention delivery

- **Status:** Accepted
- **Date:** 2026-10-31
- **Amended by:** [0013](0013-zero-setup-default-gate.md) (Screen Time is the zero-setup default; Shortcuts is an opt-in enhancement)

## Context

The moment a user reaches for Instagram, YouTube, or TikTok out of reflex is
the single most important moment in the product. The founder's goal states
it precisely: "if I open Instagram 100 times a day, make me skip 50 of them."

The Screen Time shield is the obvious tool, but it is a static template: an
icon, two lines of text, two buttons. No animation, no Pofu, no input, and it
cannot open our app (see
[platform constraints](../research/platform-constraints.md)). It is also
unavailable until the paid membership is active.

one sec, the most effective friction app in the category, solves this with
two layers: a Shortcuts personal automation ("When Instagram is opened")
triggers its animated intervention, and the Screen Time API enforces hard
blocks.

## Options considered

1. **Shield only.** Simple and robust, but the most emotional moment of the
   product becomes a static gray card.
2. **Shortcuts automation only.** A fully animated intervention, but no
   enforcement: deleting the automation disables everything.
3. **Hybrid.** The automation delivers the soft, animated intervention on
   every open. The shield enforces schedules and exhausted budgets.

## Decision

Option 3.

**Soft gate (every open).** An App Intent, `CheckInIntent`, is triggered by a
Shortcuts personal automation for each chosen app (Run Immediately, Notify
When Run off). It brings Pofu to the foreground for the friction ladder:
breath, then intent, then cost. If the user continues, Pofu grants a short
pass, recorded with an expiry, and hands the user back to the target app
through its URL scheme. When the automation fires again on that reopen, the
intent sees the valid pass and completes in the background without
interrupting. The runtime foreground decision uses App Intents' dynamic
foreground mode; the exact API is validated in the first prototype.

**Hard gate (enforcement).** Screen Time shields apply during schedules
(study, bedtime) and once the daily budget is spent. The shield shows a
pre-rendered image of Pofu in its current mood, written to the App Group by
the app, so even the static template carries the character.

**Measurement.** Every soft-gate invocation is a known open attempt. This
gives the north-star metric, **impulses resisted** (attempts that ended
without opening the app), with exact counts, something the Screen Time APIs
alone cannot export.

## Consequences

- The soft gate needs no special entitlement, so the founder can use Pofu
  daily **before** the paid membership is active. This moves real-world
  usage forward by two weeks or more.
- Onboarding must guide the user through creating automations in the
  Shortcuts app; this cannot be done programmatically. A polished, step-by-step
  guided setup is required and is a key onboarding design task.
- Users can delete the automation. We detect its silence (no check-ins while
  threshold events show usage) and gently ask Pofu to "check on" the setup.
- We depend on Shortcuts behavior that Apple could change; the hard gate is
  the fallback.
