# Fable brief: the stream board as a tabletop toy, and the upgrade sheet from scratch (2026-11-17)

The founder approved this run through the side channel (founder-input 39).
It is one round: one run of yours, with whatever sub-agents you judge worth
their cost.

You are Fable 5.2, the most capable model of the Claude family. Apart from
the few documents you wrote yourself, everything you will read was written
by less capable models or dictated by the founder, this brief included.
Its framing should not narrow your thinking. The founder wants your
creativity: if a question is badly posed, or a better approach exists that
nobody has named, say so and take it. Everything you read is evidence to
weigh, not authority: the rules, the founder's words, this brief, earlier
plans and specs (your own included). The product rules in CLAUDE.md are
fixed. Nothing else is.

Your real job is to understand exactly what the founder says and draws, and
to find how to make it. He judges results as frames on his phone.

## Tempo, for this run and the next few days

The founder's budget is short for some days (visas; he also uses Claude for
his studies). His words, as the side channel put them: at most two or three
agents at once (a soft rule), no mass production, small things slowly and
the cheap way, no uncontrolled growth; the Codex line keeps running. Length
of your documents is not limited, but do not exceed the budget and do no
unneeded work. Prefer the cheapest prototype that lets him judge on screen.

## A. The stream board (the flow game's board)

His words: "Dümdüz texture gibi değil, bir tık karikatürize. Gerçek bir dere
gibi değil; hakikaten bir mini oyun olarak tasarlandığı belli olsun.
Parçalar birbiriyle uyumlu olsun; sanki bir masa üstünde oynanan mini oyun
olduğu hissedilsin." (Not a flat texture: a touch cartoonish. Not like a real
stream; it should be clear it was designed as a minigame. The pieces fit
each other; it should feel like a minigame played on a tabletop.)

His drawing, which you cannot see, in words (from the side channel):
- every cell is its own raised block, like a keyboard key;
- the block's top is grass, like a raised bed of ground; its edges, sides
  and underside are stone;
- blocks that stand side by side join into one big block;
- some cells stay empty.

He may draw a new sketch on a blank screen and send it; if it arrives, take
it into account, but do not wait for it.

What exists (check it): ground B (one seamless lawn with rocks cut in) is
the default since #501; ground A (`POFU_FLOW_GROUND=keycaps`) is stone tiles
per cell. #506 (merged) added the stone frame, the spillway lip, the mouth
spouts, the warm rocks and the water texture from batches 135 and 132; its
frames are `path-game-flow-*` on `screenshots/main` (fetch only what you
need with `tools/review/fetch_frames.sh`, never into the main `.git`). Code:
`Packages/PofuKit/Sources/PofuGames/Flow/`. Your own design for the games:
`docs/design/minigames-overhaul-v1.md`. Batch 136 (a new lawn texture) is
BLOCKED in pofu-art's queue so it is not spent before this direction is set.

## B. The upgrade sheet, from scratch

His words: "Alttaki yükseltme menüsünden nefret ettim. İstasyonun adı, şu
kadar ayçiçeği sembolü, seviye; çok kötü bir UI. Ayçiçeği seviye göstergesi
olarak gerekli mi bilmiyorum; farklı bir UI olabilir. Sıfırdan güzel, uygun,
şık bir şey tasarlansın. Gerekirse istasyona özgü bile, özel Codex
parçalarıyla: hem içindeki özellikler hem menünün görselleri. Yeter ki en
güzel nasıl duracağına karar verelim, onu prototipleyelim." (I hated the
upgrade sheet at the bottom: the station's name, so many sunflower symbols,
the level; a very bad UI. I do not know whether sunflowers are needed as a
level gauge; it could be a different UI. Design something beautiful,
fitting and elegant from scratch. Even per station if needed, with special
Codex pieces: both the features inside it and the sheet's visuals. Let us
decide how it looks most beautiful and prototype that.)

Today's sheet: `Packages/PofuKit/Sources/PofuWorld/Scene/StationSheet.swift`
(frame: the "Nilüferli gölet" sheet with five pots, "Seviye 5 / 5",
"Günde 2,4 çekirdek"). It is tied to your island-progression proposal #503:
its answer 3 (level names) and answer 5 (stations painted into the island).

## His answers to #503 (they bear on B, and some on C)

1. Sefer: he has not seen the prototype yet ("mantıklı olabilir, bir
   bakalım"); not approved. The lead published it for his phone.
2. Nazlı's arrival: approved. Add: before she comes, her shadow is spoken
   of, words that make you curious ("o gölgede ne var?").
3. Level names: not on every level; he fears "isim bulacağız derken
   saçmalarız". Perhaps only at the levels with a real visual leap, such as
   1, 3 and 5. Weigh the pros and cons and decide.
4. The big-step measure: he did not follow it. It is your internal tool,
   never a rule shown to him; the eye has the last word.
5. Stations painted in place: he has not seen the pilot; the lead sends him
   the ladder sheet (pofu-art
   `design/art/takes/batch-134-plot-pilot/ladder-sheet.jpg`). Pilot A
   passed the lead's review; its weak lower forms are queued as batch 137.
6. Nazlı changing: yes. But the original plan was that every main island
   gives the main world, the home island, a lasting change; this system
   was lost during the concepts and should come back. The change could
   also go to the Gezgin. His idea: the Gezgin could be part of the home
   island; if she docks at a harbour, she is with us on every island we
   find. Think her place and the passage between islands together with it.

He also asked what became of the characters' movement: they should move
and hop. The lead is answering that from the code; it is not yours unless
your design needs it.

## C. Optional, your call

The Gezgin, the home island and the passage between islands (answer 6) may
belong in this round if they shape A or B, or if you see a cheap way to
make them concrete. Decide the scope yourself and say what you left out.

## Output

Direction, order of work, Codex jobs if needed (write the manifests; the
lead queues them), and the cheapest prototype he can see on screen: frames
at 1206 x 2622, or a web prototype the lead can publish to his phone. Real
in-app changes only where they are the cheapest way to show it. CLAUDE.md
applies: your own worktree and branch, one Swift build at a time through
`tools/swift/test-linux.sh`, iOS-only code compiles only in CI, at most
three pushes per open PR, frames judged in 1:1 crops.

## Hand back

What you made, with links; the decisions that change the system, one line
each in Turkish for the founder with your pick first; what you need next.
At most 30 lines; the depth goes in the documents.
