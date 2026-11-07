# Consolidation audit: shared brief (2026-11-07)

You are one of three Opus auditors consolidating the Pofu project (a cozy iOS game tied to a Screen Time app; repo at /home/user/pofu, read-only for you; work only in this folder).

The founder (2026-11-07), translated: we drifted from the concept he approved; his best document is the two-page Book One story map; his likes and decisions are scattered across chat, and he fears they were lost. He asks the lead to look at every thread, merge the disconnected pieces into one solid record, and NOT invent or guess: where in doubt, ASK him; list possibly-wrong "stated as fact" details; show visuals for visual questions. Then they discuss and decide (concepts approved: "Çağlayan should look like this, these mini-games, these upgrades, this side island", fillers). Pricing details later (he will give them). The lead plans each island's gameplay systems. One example of his: in the map, Çağlayan's stream comes out of an otter-shaped statue (not travertine), but that may change (the island already has Damla the otter; water effects may be hard technically).

## Sources (use all that touch your area; cite every claim)
1. **His own words, verbatim:** `founder-messages.md` here (60 messages from 2026-11-03 to 2026-11-07, timestamps), `hub-notes.md` here (Hub answers, notes, island scores), and `/home/user/pofu/docs/product/founder-input.md` (the log of every message since earlier days, with "Handled:" notes written by the lead; the "Handled" notes are the lead's interpretation, not his words: treat them as claims to verify).
2. **The story map:** `storymap-p1.png`, `storymap-p2.png` here (Read them as images; crop with Pillow into this folder if text is small) and its transcription `docs/product/story-map/book-one.md` (check the transcription against the images; report any error).
3. **Docs:** `docs/tracker.md`, `docs/roadmap.md`, `docs/product/*.md`, `docs/design/*.md`, `docs/adr/`, `docs/research/` (read sections relevant to you).
4. **Code (to verify what is BUILT):** `Packages/PofuKit/Sources/**`, `App/**` (grep).
5. **Art:** `design/art/masters/*` (promoted), `design/art/takes/<batch>/<job>/` (concepts; contact.jpg; review.yaml), `docs/design/concept-inventory.md`; screenshots: `git -C /home/user/pofu show origin/screenshots/main:<file>` (list with `git -C /home/user/pofu ls-tree --name-only origin/screenshots/main`; also branches `origin/screenshots/feat-*`); extract images into your own subfolder here to look at them.

## Output: one file `<area>.md` in this folder (English, dense, ≤ 450 lines)
1. **Confirmed by the founder:** each item with his verbatim words (Turkish) + date + source. Only what HE said or chose.
2. **Lead decisions not confirmed by him:** item, where written, and whether he reacted (silence ≠ confirmation for anything big).
3. **Contradictions and possibly-wrong facts:** doc vs doc, doc vs code, doc vs his words, doc vs the map; give evidence for each.
4. **Built vs designed:** what exists in code/art now (verify), what is only on paper.
5. **Questions for the founder:** numbered `Q-<AREA>-n`, each with: the question in Turkish (short, plain, he has ADHD), 2–3 options (A/B/C) with one-line trade-offs, the lead's recommendation and why, and **image paths** that show the options (absolute paths to concept takes, masters, screenshot files you extracted, or map crops you made). Visual questions MUST have images. Only ask what truly needs him (taste, direction, things only he knows, conflicts between his own statements); decide the rest yourself under §6.
6. **Proposed decisions** (the lead will adopt or change): what you recommend we lock, per item, with reasoning.
7. **Next steps** for your area (concrete, ordered by value; no dates).

Be rigorous: never present a guess as fact; mark uncertainty explicitly. Do not modify the repo. Report back in ≤ 15 lines: the file path, counts per section, and the 5 most important findings.
