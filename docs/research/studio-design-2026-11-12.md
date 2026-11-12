# How the Pofu studio should work

Fable 5.2, 2026-11-12. The proposal as the founder and the lead reviewed
it, kept as the record of why the studio is built the way it is. The
founder approved it the same day and Fable applied it. **Where this page
and [studio.md](../studio.md) differ, studio.md wins:** his answers to
section 4 changed four things (they are at the end of that section), and
the role files gained an art-reviewer.

How to read it: section 1 is the whole design on one page. Section 2 is the
evidence it rests on, with what I measured myself. Sections 3 and 4 are the
decisions and what only the founder can settle. Section 5 applies the design
to the twelve days before the demo. Section 6 names the rule files.
Section 7 is how it was to be applied and how to tell whether it works.

---

## 1. The design on one page

The studio does not lose time because its builders are weak. A precise spec
(`docs/design/game-solid-v1.md`) became six merged pull requests in one day.
It loses time in four other places, and the design answers each.

1. **Work is built on claims nobody checked.** Weeks of tuning went into a
   collage, a 54-job art batch was queued on a wrong idea, a brief was
   written for three islands that are not in the app. So: truth is the code
   and the pixels. Every brief carries facts checked at a named commit, a
   builder who finds a false fact stops and says so, and status pages are
   replaced by status that is computed from the repository.
2. **The lead does everything, in a context that grew to 898,000 tokens.**
   It made 827 shell calls and 192 merge calls, opened 55 pull requests and
   looked at 187 images itself. Every turn re-reads the whole context, so
   the lead alone cost about 31% of the session, four fifths of that for
   re-reading. So: the lead is a producer. It decides, briefs, looks once
   and talks to the founder. It hands off every code change and every first
   look, starts a fresh session per chapter, and keeps its context under
   about 150,000 tokens.
3. **Looking is done late, by the wrong eyes, at the wrong size.** Builders
   looked at dozens of whole frames and still handed back mirrored seas and
   halo boxes; the lead found them at 1:1 an hour or two later. A written
   rule even said "numbers first, pixels second". So: a critic with a fresh
   context looks at 1:1 crops against the approved reference before the
   lead sees one sheet, and every defect an eye catches becomes an
   automated check, as it already does.
4. **The founder's phone left the loop.** He last played a build on
   2026-11-05. The moving sky and the plate's living layer have never run
   on a device. So: every chapter ends with a build for his iPhone and a
   seven-line Turkish checklist, starting now.

Around these four, the rest follows:

- **Who builds is chosen by how the work is accepted,** not by "Opus plans,
  Sonnet builds". A named test accepts it: Sonnet. An eye accepts it and it
  is the first of its kind: Opus. A fact is wanted: Haiku. Per token,
  Sonnet costs about 0.6 of Opus and Haiku about 0.18, so the model choice
  matters less than one avoided review round. Effort is cheap (the words a
  model writes are about a seventh of its cost), so it is high by default.
- **Fable is used at four kinds of moment** instead of four fixed
  checkpoints: before a method or a large batch is scaled, when the same
  failure survives two fixes, on the real thing before a milestone, and for
  the studio's own design. Three consults so far cost about $3 of $749 and
  removed, among other things, 38 jobs from one batch.
- **The art factory keeps running, but its queue is split:** Demand (the
  app waits for it; reviewed within a day) and Stock (keeps the line busy;
  reviewed only when pulled). The queue file holds only rows that can run:
  about 5 KB instead of 31 KB.
- **Rules are short, carry their reason, and prefer a mechanism to a
  sentence.** `CLAUDE.md` is loaded into every agent, so it holds only what
  every agent needs. The lead's manual is one file, `docs/studio.md`. Four
  role files give the smaller models exact procedures.

The founder's view on rules, weighed: I agree that rules should give a
model reach and reasons. I would shift one thing. The split is less
"open principles for capable models, precise definitions for small ones"
than **be precise about facts and acceptance for every model, and open
about method**. The capable models here did not fail for lack of freedom;
they failed on wrong facts. And the small ones need the reason as much as
the definition: a builder stopped fixing visible defects because a rule
about CI runs said "fix at most twice", and Codex opened a blocker pull
request about a tool it never needed.

---

## 2. What the evidence says

Marks: **[measured]** I computed it from the transcript, the cost record
or git in this pass. **[verified]** I checked the evidence pack's claim
against the repository. **[pack]** taken from the evidence pack as written.

### 2.1 Cost is context times turns

[measured] The session's cost record (from 2026-11-04 18:15 UTC to
2026-11-12 06:46 UTC) reads $748.76: Opus $424.55, Sonnet $315.85, Haiku
$4.82, Fable $3.54. Per-turn usage in the transcripts reproduces it within
3%, with these implied prices per million input tokens: Haiku about $0.45,
Sonnet $1.5, Opus $2.5, Fable $6 (cache reads at a tenth, output at five
times). The weekly limit may weigh models differently from these prices; I
could not check that.

| Who | Turns | Context per turn | Estimated cost |
|---|---|---|---|
| Lead (Opus), 9 days | 1,999 | median 317k, 90th percentile 699k, peak 898k | $223 |
| 90 Sonnet agents | 63 each | average 188k | $317 ($3.52 each, median $2.18) |
| 32 Opus agents | 68 each | average 203k | $180 ($5.61 each, median $4.36) |
| 6 Haiku agents | 32 each | average 205k | $4 |
| 3 Fable consults | 6 each | average 87k | $3 |

- The two busiest days (11-05 and 11-06, 99 merged PRs at the peak) cost
  the lead $143 of its $223, at an average context of about 450k.
- For the lead, re-reading its own context is about 80% of its cost and
  the words it wrote about 7%. Across all agents, context (re-reading and
  writing it) is about 85% of cost and words written 13 to 15%.
- Eight of the ten costliest agents were look and plate builds ($11 to $40
  each). The costliest, "Çağlayan day on a sky set" (Sonnet, about $40),
  ran 275 turns, read 66 images and reached a 606k context because two
  review rounds were sent back into the same agent.
- A builder's context is mostly shell output (300 to 400 thousand
  characters in the large ones) and images.

What follows: a lean lead matters more than a cheap lead; a fresh agent
for a fix round is cheaper than a continued one once the first has passed
about 200k; effort level is a small cost and context discipline a large
one.

### 2.2 The large losses were wrong premises, not weak building

- [pack] 11-02 to 11-08: every look fix tuned light and colour on top of a
  collage of separately painted sprites; the lead: "I looked at numbers,
  not the picture." The founder: "yine aynı çamur".
- [pack] 11-11: batch-75 queued 54 portrait jobs to repaint a backdrop
  that barely differs between stages; a Fable pass cut it to 16 nine hours
  later, after Codex had been given the row.
- [pack] 11-12: a brief for three islands that are not in the app; the
  lead's revert in #392 of masters the app does not use.
- [verified] The tracker said Koke's stages 3 and 4 were not in the app
  and that the flow audit was not started; the game-solid spec found both
  wrong by reading the code.
- [measured] `docs/state/plates.yaml`, the "machine-readable truth", marks
  one home cell as in the app. `plate-home.json` ships eleven (nine day
  stages, plus golden and night at level 10). The one field of that file
  that is typed by hand is the stale one.
- [verified] Builders with a precise brief mostly finished in one or two
  CI runs. The six game-solid PRs (#394 to #400) merged within a day.

### 2.3 Hand-kept status goes stale; computed status does not

[verified] `docs/handoff.md` says the lead restarts daily and was last
written on 11-06. The roadmap's status is dated 11-07. The tracker (35 KB)
needed a "corrections" block on 11-12. The moved art queue showed 20
delivered rows as READY and Codex began redoing one.

[measured] A 60-line script over `changes/*.md` (the one-line fragments
user-visible PRs already add) shows the drift at a glance. Run on the
commit before the game-first decision, the five days from 11-07 hold two
player-visible lines, both about plates, against about fifty merged PRs:

```
What changed for the player on 84ef52d8 since 2026-11-07 (2 lines):
  2026-11-10  feat-caglayan-plates   Added: Çağlayan is drawn from its painted plates ...
  2026-11-08  feat-home-plate        Added: at Tam Çiçek, by day in clear weather, Home is drawn ...
```

### 2.4 Looking

- [pack] #382 and #387: the builder's hand-back did not name a mirrored
  sea, night stripes, doubled stars, stamped clouds, a sea seam and dark
  halo boxes. The lead found them at 1:1; each round took 85 to 165
  minutes and ended with a new check in `tools/plate/screen_check.py`.
- [measured] Those builders did look: 24 and 66 image reads. A whole
  1206 x 2622 frame reaches a model reduced, so defects a few pixels wide
  are gone before it looks.
- [verified] `tools/review/README.md` still says the lead reviews one
  small sheet and "Numbers first ... pixels second". That is the rule the
  11-08 failure followed.
- [pack] Where the same agent kept the picture, the look and the fixing
  (#110, Opus, the first plate-first home) the founder's verdict was the
  first good one.

### 2.5 The founder

- [pack] One device test in the window (11-05). It found lag, heat and
  overlapping UI that no screenshot had shown.
- [pack] Three statements to him from memory had to be corrected in one
  week (the veil as the cause, Fable's limit, the missing search result).
- [pack] He cannot follow the tracks and said so: "takip etme sorumluluğu
  sende." He wants short, visual answers and few questions.
- [pack] Part of the one-track drift followed his own words on 11-08
  ("diğer her şeyi bırakalım"). The failure was not obeying them; it was
  that nothing brought the other tracks back once the look was solved.

### 2.6 The art factory

- [pack] The founder's main pain is a factory that stops unnoticed: "3
  dakika sonra durmuş. Ben bunu 5 saat sonra bakıyorum."
- [verified] `QUEUE.md` is 31 KB; two of its roughly fifty rows can run.
  Codex re-reads it before every batch.
- [pack] Six deliveries waited six days for review (#296 to #350). The
  slow side of the art line is the lead's review, not the painting.
- [measured] Home night at levels 2 to 9 is painted and picked
  (batch-72, batch-74) and not in the app, so a tester below level 10 sees
  the old sprite island at dusk and night.

### 2.7 Small frictions with a mechanical fix

- [pack] Linux Swift builds were killed for memory in at least six
  hand-backs; the machine has 15 GB and no swap, and two builders compiled
  at once.
- [pack] "Fix at most twice" was read by two builders as a limit on
  fixing visible defects, so unfinished work came back to the lead.
- [measured] Every sub-agent receives `CLAUDE.md` whole, including the
  lead's duties (talk to the founder, log his messages, merge, pick models).

---

## 3. Decisions I made, with the alternative I set aside

| # | Decision | Alternative set aside, and why |
|---|---|---|
| 1 | The lead stays Opus 5.5 and becomes a producer with a lean context | Fable as lead. At the measured context it would cost about 2.4 times the lead's $223. A lean Fable lead might be affordable; decide after a week of measured lean running, not during the demo sprint |
| 2 | Choose the model by how the work is accepted (test, eye, fact) | "Opus plans, Sonnet builds, Haiku looks". Sonnet saves 40% per token, and one extra review round costs more than that. Haiku is not the eye for taste |
| 3 | Effort high by default; low only for scouts; max is the lead's call for a spec that a week of work hangs on | Tuning effort per task to save budget. Output is a seventh of cost |
| 4 | A fresh critic does the 1:1 looking; the lead looks once at a sheet with the critic's list | The lead looks at everything (today: defects found late, context swollen), or metrics first (failed on 11-08) |
| 5 | Status is computed where it can be (pulse, `in_app`, queue check); one hand-kept page of at most 60 lines, `docs/now.md` | Keeping tracker, roadmap status and handoff current by discipline. Every one of them went stale |
| 6 | A fresh lead session per chapter and auto-compact low enough to hold the context near 200k | One long session compacting at 70% of a million-token window |
| 7 | A builder merges its own test-accepted PR on green; the lead merges what an eye must accept | The lead merges everything (192 merge calls in its own context) |
| 8 | A fix round goes to a fresh builder when the first one's context is past 200k | Always continue the live agent. Right for small agents, the costliest path for large ones |
| 9 | Fable by trigger with a standing allowance of two bounded consults a week | Four fixed checkpoints and asking the founder each time. Three of the four checkpoints are months away; the losses happen where methods are scaled |
| 10 | Codex never idles, on a two-tier queue (Demand, Stock) that lists only runnable rows | Stopping Codex when the app needs nothing. It would spare the plan's limit, but the founder's standing wish is a line that never stops, and Stock in its own repository costs the lead nothing until pulled |
| 11 | No multi-agent workflow tool before the demo | Scripting delivery review as a workflow now. It is costly, needs opt-in, and the role files give most of the gain |
| 12 | Three builders at once; scouts and critics do not count; Swift builds queue behind a lock in the script | A higher cap. Memory and the lead's attention are the limits, not agents |
| 13 | Role procedures live in `.claude/agents/`; every brief's first line also names the file, so it works whether or not the session loads agent types | Pasting procedures into each brief (the lead's output, every time) |
| 14 | The founder log stays; the lead reads only the standing decisions and the entries since its last session | Reading all 66 KB at every start, or dropping the log he relies on |
| 15 | The demo is taken to mean: the founder or a friend plays Rehearsal mode on his iPhone for ten to fifteen minutes | A recorded video only. A hands-on demo is the harder case and sets the cut (he can correct this; section 4) |
| 16 | Painted states for the levels a 21-day tester meets are proposed as the next look chapter | Leaving the sprite island at dusk and night below level 10, as the game-solid spec did when the art had not landed. The lead decides after one frame sheet (section 5) |
| 17 | `AGENTS.md` in pofu-art gets three small edits, not a rewrite | Rewriting an 18 KB brief that was stabilised today, with no way to pilot it before it runs |

---

## 4. Only the founder can decide or do

1. **Play the build on his iPhone now, then at the end of each chapter**
   (about every two or three days until the demo). Ten minutes and a voice
   note. Only he has the phone and the Mac.
2. **Fable's allowance.** Two bounded consults a week on the lead's own
   call, logged with their reason and cost, or stay with "ask me first".
   To size it, he reads the weekly and the Fable meters after this pass and
   tells the lead how far each moved.
3. **The lead's session setting.** Either auto-compact low enough that the
   lead's context stays near 200k (his claude.ai setting), or he opens a new
   chat when the lead says a chapter is done. Both is best.
4. **What the demo is and who watches.** I assumed hands-on play on his
   phone (decision 15).
5. **Restarting Codex.** Today only he can. If he connects Codex to the
   `pofu-art` repository on GitHub, the lead can try starting it with an
   `@codex` comment on an issue there. I could not test whether a task
   started that way has the image tool; one trial settles it.

---

### The founder's answers (2026-11-12, views rather than fixed rules)

1. Fable is not rationed. It has a real limit, of which the project has
   used a few percent; use it whenever the work needs it, and when unsure
   the lead asks him and they agree what it will do. So decision 9's
   allowance is dropped.
2. He installs builds through a separate cloud session. How device
   testing is run will be designed later, so no chapter-end checklist is
   a rule.
3. Sessions are still to be discussed. The lean context stays the goal;
   decision 6's "fresh session per chapter" is one possible means.
4. The demo is his own iPhone, hands-on, sometimes shown to friends; no
   TestFlight before the membership. Decision 15 stands.
5. He runs Codex by hand. Restarting the art line is future work.

## 5. To the demo (about 2026-11-24)

A proposal for the lead to correct. A chapter is one goal the founder can
see; each ends with a recording and a device build.

| Chapter | Goal the founder sees | Who | Gate |
|---|---|---|---|
| 1. Hands on (now) | The Rehearsal path recorded (game-solid §8) and the same build on his phone | lead; recording from CI | none |
| 2. What his thumbs found | His device notes fixed, performance first (the moving sky has never run on a phone) | Opus spec from his notes, Sonnet builders | lead |
| 3. No collage in the demo | The levels a tester meets in 21 days (IL1 to about IL7) painted at every hour he will reach. First a scout lists which states of days 1 to 21 still draw the sprite island and renders one sheet of them. Night IL2 to IL9 and IL1 day are painted and picked already; golden and rain are not | scout, then Opus spec, then one Opus builder for the first state and Sonnet for the rest | lead, after the sheet |
| 4. The islands at other hours | Çağlayan golden and night from batch-76 when delivered | Sonnet with the day recipe | critic |
| Taste gate (about 11-19) | A cut list for the last days | Fable, one pass: the recording, device frames, his notes | founder sees the list |
| Freeze (11-21) | Fixes only; a device build on 11-22 | | |

The app desk stays paused until after the demo, as he decided. Its first
step afterwards, the Door and onboarding spec, is a premise gate for Fable.

---

## 6. The rule files

The proposal carried the exact text of every rule file. They are now the
files themselves: `CLAUDE.md`, [studio.md](../studio.md),
[now.md](../now.md), `.claude/agents/` (scout, spec, builder, critic,
art-reviewer), and in `pofu-art` `QUEUE.md`, `QUEUE-LOG.md` and three
edits to `AGENTS.md`. The scripts are `tools/studio/pulse.py`,
`tools/studio/session_cost.py`, `tools/art/check_queue.py`, the lock in
`tools/swift/test-linux.sh` and the `in_app` check in
`tools/state/check_plates.py`.

---

## 7. Applying it, and telling whether it works

**Order.** Each step is one PR and can be accepted or dropped by itself.

1. Rules (docs only, the lead writes it): 6.1 to 6.5. Then pilot the
   role files on the next real brief: one scout, one builder. If the
   session does not load `.claude/agents/`, the brief's first line still
   points the agent at its file.
2. Tools (one Sonnet builder): 6.8.
3. The art queue (one Sonnet builder in `pofu-art`): 6.6 and 6.7, with the
   moved rows checked against `git diff` so nothing is lost.
4. The founder's five items (section 4), in one short Turkish message with
   the first device checklist.

**What goes away:** `docs/handoff.md`; the tracker's "Current" blocks; the
four fixed Fable checkpoints; "Opus plans, Sonnet builds, Haiku looks";
"fix at most twice"; "numbers first"; 26 KB of the queue file; and
`CLAUDE.md` shrinks for the sub-agents that carried the lead's duties.

**Measures,** read from the scripts, reported to the founder in one line a
week:

| Measure | Was | Aim |
|---|---|---|
| The lead's average context | 317k median, 898k peak | under 150k |
| The lead's share of cost | about 31% | under 20% |
| Review rounds per eye-accepted PR after hand-back | 1 to 2 | at most 1 |
| Briefs where a builder found a false fact | at least two noted | found by the scout instead, before the brief |
| Days since the founder played a build | 7 | at most 3 |
| A desk missing from the pulse for three days without a line in `now.md` | 5 days, unnoticed | never |
| Art delivery to picks | up to 6 days | within 1 |
| Corrections of something the lead told the founder | 3 in a week | none |

**Review this again after the demo.** The next review needs no evidence
pack: the pulse, the session cost, `now.md` and the founder log are the
record.

## 8. What I could not check

- The prices are implied by one cost record, and the weekly limit may
  weigh the models differently.
- I did not render or look at any app frame. What a tester sees at dusk
  and night below level 10 is read from the plate file, the state table
  and the docs; chapter 3 starts with a scout and a sheet for that reason.
- Whether this session loads `.claude/agents/`, whether `gh pr checks
  --watch` works inside a sub-agent, and whether an `@codex` comment
  starts a task with the image tool. Each needs one trial.
- Codex's own logs. How long the factory stood still is not visible from
  here.
- I verified the evidence pack where the design leans on it (the cost
  record, the agent counts, the merge and tool counts, the state of the
  queue, the plate table, the rule texts). I did not re-check its founder
  quotes against the transcript.
