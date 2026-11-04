# Vertical slice v0: Pofu on the founder's iPhone

_Status: decided by the lead, 2026-11-04. Target: on the founder's iPhone
within two days, before the paid membership (2026-11-24)._

## Why now

Everything so far was judged in screenshots. Feel (timing, touch, sound,
how often the shield interrupts) can only be judged in the hand. A small
slice now finds the real problems a month earlier, and it is the version
he can show a friend.

## What it is

The first three days of Pofu, compressed, running in the existing app on
a free Personal Team ([development.md, "On your iPhone with a free Apple
account"](../development.md)). Screen Time is simulated by **Rehearsal
mode**; the real gate waits for membership day. New work goes into the
shared packages, so nothing is thrown away when the targets merge.

| Beat | In the slice | State |
|---|---|---|
| The moment of resistance | Rehearsal shield: a simulated reach for Instagram, Pofu appears, breath or Hop!, seeds | Built |
| Home | The Living Diorama with Pofu's reactions, sound v1 | Built |
| The island | Home plate **graded** (haze grows toward the background, clear at the centre), the tea stall, garden, bagel cart | Grade: to do |
| The harbor district | İskele as Ayçiçeği's harbor: plate, Simit and her poses, the goat | To do (art exists) |
| Play | The garden minigame **with its painted art** (tiles, soil, blooms, tray) | Art exists, not wired |
| Time | Time-of-day grade; a dev "next day" button to see days 1 to 3 unfold | Grade built; check the day skip |

Out of the slice: wonder islands, the archipelago backdrop, Pofu's soft
body, the match-cut, social, monetization.

## Done means

- It installs from Xcode on his Mac in under 15 minutes following one
  page, with no step that needs the paid membership.
- He can play ten minutes: three rehearsed reaches, one garden round,
  a walk round home and the harbor, a day skip.
- He writes down what felt wrong; that list is the next round's input.

## Order of work

1. Art integration script: approved masters into the asset catalogs,
   repeatable, with a check that every catalog image has a master.
2. Home plate grade (`tools/art/grade_take.py`, depth-aware haze).
3. Garden minigame painted art.
4. İskele harbor with Simit and the goat.
5. Device runbook check (the one page) and a TestFlight-free build.
