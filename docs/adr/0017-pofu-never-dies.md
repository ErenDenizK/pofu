# 0017. Pofu never dies

- **Status:** Accepted
- **Date:** 2026-11-01

## Context

Opening a guarded app now costs Pofu's wellbeing (ADR-0015). A companion
whose state depends on behavior raises the question every virtual-pet
product must answer: what happens at the bottom? Forest kills your tree;
Tamagotchi-style pets die or run away; Finch never lets the bird come to
harm. Our art bible (§9) already forbids sick, crying, or bandaged Pofu.

## Options considered

1. **Pofu can die or leave** after sustained neglect. Maximum stakes;
   maximum shame.
2. **Pofu can be lost temporarily** (he "goes away" until you earn him
   back). Softer, but still a loss event at the worst moment.
3. **Pofu never dies.** Wellbeing has a floor; the lowest state is
   "curled up" in deep sleep, always recoverable.

## Decision

Option 3. Pofu can be tired, unwell, curled up in deep sleep, ash-tinted
and matted. He **cannot die, run away, or be taken away**.

- Wellbeing has a floor of 5 ("curled up": eyes closed, flattened,
  matted, desaturated, a slow breath, residents gathered around him).
- Recovery is always visible: one quiet hour lifts him a band, and every
  night he "sleeps it off" (below 60, 30 % of the way back to 60).
- The relapse is when Pofu is most welcoming ("You're back!"), never a
  grave, a guilt line, or a lost streak.
- Nothing built is ever taken away: stations, levels, islands and
  postcards are permanent.

## Consequences

- **Death is an uninstall.** The users who most need Pofu are the ones
  who relapse; a dead pet after a bad weekend is a reason to delete the
  app and the automation with it, ending the intervention.
- Shame does not change habits; it hides them. Recovery becomes the
  story, which teaches that one evening is not a failure.
- The consequence of scrolling is felt (a tired, then unwell Pofu, a
  slower island, a reset calm) but bounded. We accept weaker stakes than
  a death mechanic in exchange for long-term retention of the people who
  need the product most.
- Copy and art reviews enforce it: no tears, no sickness props, no "you
  hurt me" (game-design.md, guardrails).
