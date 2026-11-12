# The lead's context, the improvement loop, reaching Fable, briefing each model

Fable 5.2, 2026-11-12. A proposal: nothing it describes is applied yet.
Part A is what I measured, part B the decisions, part C the exact text to
apply (the lead applies it on top of #403), part D what the founder
decided on reading the first version, part E what the data cannot say.

## The short version

1. **Context.** The "under 150k" goal I wrote was wrong and is withdrawn.
   A compaction leaves the lead at about 100k, so 150k left no room to
   work. The aim is a balance (the founder: "neither at the limits nor at
   the bottom"): enough context to remember well, lean enough for a
   budget many agents share. That is a working band of about 100k to
   400k. Up to 250k it costs a few dollars a day and is not worth a
   single lost thought; from 250k the lead offers a ready `/compact`
   line at each pause; past about 400k it asks more firmly, at the next
   pause and never in the middle of work. The founder compacts by hand.
   Nothing is set to compact the lead automatically.
2. **The thread.** It cannot depend on choosing the moment, because the
   platform already compacts the lead by itself: five of the eight
   compactions since 11-05 happened unasked after he had been away 80 to
   156 minutes. The thread is made safe three ways: write first and act
   second (a pushed handoff branch), compaction instructions in
   `CLAUDE.md`, and a recall tool over the transcripts on disk, where every
   dropped message still is.
3. **Improvement.** One touch from Fable, not three ceremonies: a route
   at the day's start and whenever the board empties, which also checks
   the roles and triages the friction log. The studio then follows it
   for hours; it is one pass, not a standing orchestration.
   Tool defects are fixed the same day. A rule changes only on a recorded
   incident, at most one rules PR a day, under line caps. Any change to
   the studio system itself reaches the founder before it is applied. No
   separate
   review every 3 to 4 days: all ten friction rows so far are tool defects
   or slips in a brief, and none is a rule.
4. **Reaching Fable.** The lead spawns it; the route uses a standing
   brief that runs without being shown again. The side channel is the founder's own door and the place
   to judge the lead itself. No scheduled session for now.
5. **Briefing.** The guidance was one template for every model. It now
   says what each model is given, what is left open and what is asked
   back, adds the missing scout brief, and gives the Opus roles licence to
   say the goal is wrong. Who writes a task: Opus the routine briefs
   inside a route, Fable the route and, at the lead's judgement, the spec
   of large or first-of-its-kind work. The kind of work decides.

---

## A. Measurements

Source: the lead's two transcripts on this machine
(under `~/.claude/projects/`: one of 1,999 turns, 11-03 to 11-12
morning, and one of 268 turns, to 11-12 evening), 2,199 distinct lead turns after removing the
overlap. Prices as in `session_cost.py` (Opus $2.5 per million input,
cache read 0.1, output 5), except that the lead's cache writes are
one-hour writes and are priced at 2.0, not 1.25. Lead total by this
reckoning: $260. The analysis scripts were throwaway and are not in the repository; C11
puts the useful parts into `tools/studio/`.

**A1. Where the lead's money went.** Cache reads $198 (76%), cache writes
$43, output $18. Reading the context again on every turn is the cost.

**A2. Cost per turn against context size.**

| Context | Turns | $ per turn | Share of lead cost |
|---|---|---|---|
| under 100k | 38 | 0.056 | 1% |
| 100 to 200k | 488 | 0.068 | 13% |
| 200 to 300k | 455 | 0.093 | 16% |
| 300 to 400k | 413 | 0.115 | 18% |
| 400 to 500k | 320 | 0.134 | 17% |
| 500 to 800k | 433 | 0.15 to 0.20 | 29% |
| over 800k | 52 | 0.299 | 6% |

The slope is $0.025 per turn for each 100k of context, on a base of about
$0.04. At the lead's 220 turns a day, each 100k costs about $5.50 a day.
The studio spends about $83 a day ($749 in nine days).

**A3. What a cap would have saved** (same turns, context cut off at the cap):

| Cap | Lead total | Saved against the actual $260 |
|---|---|---|
| 400k | $223 | $37 |
| 300k | $199 | $61 |
| 250k | $182 | $78 |
| 200k | $163 | $97 |
| 150k | $141 | $119 |

Going from 400k down to 250k saves $41 in ten days; going on from 250k to
150k saves the same again but is not reachable (A4). 37% of the turns were
above 400k and they were 52% of the cost.

**A4. The floor.** The smallest context of any lead turn was 73k (the
system prompt, the tool list, `CLAUDE.md`). After each of the eight
compactions the first turn was at 93k to 108k. So a compaction returns the
lead to about 100k, never lower.

**A5. What happens after a compaction.** Context at turn 1, 10, 20, 40
after each compaction: about 100k, 105 to 138k, 117 to 198k, 152 to 241k.
That is the lead's ordinary growth (mean 1.7k a turn, median 1.1k), so
there is no visible burst of re-reading. The first turn afterwards writes
27k to 57k of cache ($0.14 to $0.29). The summary is 14,000 to 23,000
characters. A manual compaction took 61 to 99 seconds; the automatic one
at 901k took 109 seconds.

**A6. What a compaction costs and when it pays.** About $0.30 to $0.50 in
all at 300k (the summary pass, the summary's output, the first cache
write). It then saves $0.05 a turn, so it has paid for itself after about
seven turns. Cost never argues against compacting; only the thread does.
Below 200k it saves less than $0.025 a turn and is not worth anything.

**A7. The platform compacts the lead by itself.** Eight compactions since
11-05: three manual (816k, 366k, 502k), one automatic at the window's end
(901k, in the middle of a turn), and four marked `auto, precomputed`, at
479k, 229k, 375k and 314k, each on the first turn after the session had
been idle for 80 to 156 minutes. The documentation calls this idle
compaction and gives 200k as its default lower bound
(`CLAUDE_CODE_IDLE_COMPACT_MIN_TOKENS`). It is not dependable: other
pauses of the same length above 200k (85 minutes at 238k, 463 minutes at
221k) were not compacted. Nobody chose those four moments, and the lead at
220k today can be compacted at the founder's next long pause.

**A8. Coming back cold.** The cache lives one hour. Of 30 pauses longer
than an hour, 22 were followed by a turn that wrote the whole context
again, at $0.31 (108k) to $4.06 (864k); $24 in all, 9% of the lead's cost.
At 220k a cold return costs $1.10, at 100k $0.50.

**A9. The auto-compact threshold can be set.** The brief says it cannot.
The session sets `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=92` itself (I read it in
this session's environment) and the documentation says that value cannot
be overridden. But the window it is a percentage of can: by typing
`/autocompact 400k` in the session, or with `CLAUDE_CODE_AUTO_COMPACT_WINDOW`
in the cloud environment's variables (read when the session's machine next
wakes). At 92% a 400k window compacts near 370k. I did not test either,
and the founder has decided not to use them (part D): he does not want
the lead compacted automatically in the middle of work.

**A10. Repository hooks do not reach the lead.** The lead's session holds
two repositories and starts above them, and the documentation says such a
session reads no hooks or `env` from a repository's `.claude/settings.json`.
So a hook that re-reads `now.md` after a compaction is not available. Role
files in `.claude/agents/` do load (the new lead confirmed it).

**A11. Nothing a compaction drops is gone.** Both transcripts are on disk
with every message since 11-03, including the 3.8 million tokens the
compactions dropped. The founder can also scroll up in the app.

**A12. What agents cost** (for the "do it yourself" line). A small Sonnet
build: about $1 (five of the six game-solid PRs, 29 to 48 turns). A Haiku
scout: $0.67. A bounded Fable consult: $1.09 (three of them, six turns
each). An unbounded Fable pass: the studio design cost $26 (74 turns, 422k).
This pass was at $3.30 after 18 turns. A lead turn at 250k: $0.10.

**A13. The friction log's first ten rows** (`docs/studio/friction.md` on
#403): six are tool or platform defects (one of them a transcript read
wrongly), four are slips in a brief, a spec or `now.md`. None is a rule
that misled.

---

## B. Decisions, each with the alternative set aside

### B1. Context and compaction

**Decision.** No average target and no ceiling to fear: a working band,
with the founder compacting by hand.

- **About 100k to 400k is the band.** The bottom is where a compaction
  leaves the lead (A4). The top is where a turn costs twice what it does
  at 150k and where more than half of the lead's money went (A2).
- **Up to 250k: work, and never compact to save money.** The whole range
  from 100k to 250k costs at most $8 a day more than a floor nobody can
  hold.
- **250k or more at a pause:** the lead finishes the handoff and ends its
  message with one ready line the founder can paste, written for that
  moment. If he does not, nothing is wrong.
- **Past about 400k:** at the next pause the lead asks more firmly, in
  one sentence ("400k'yı geçtim; şimdi sıkıştırmak iyi olur"). Never in
  the middle of work, and it does not stop working to ask.
- **No backstop.** Nothing is set to compact the lead automatically. The
  founder expects the lead rarely to pass 400k, and the measurement
  agrees once the lead no longer builds in its own context.
- The lead does not act on context size in any other way, and does not
  report an average.

*Set aside:* "under 150k on average" (mine: unreachable, and it pushed the
lead to hand off small reads that cost more as an agent than as a read);
an automatic backstop near 370k (my first version; the founder declined
it, because a compaction in the middle of work is the one he least
wants, and by hand at a pause he chooses the moment); a fresh session per chapter (the founder does not want it, and a
compaction reaches the same 100k while keeping the chat he can scroll).

**The thread is protected in layers.** The founder chooses the moment
of his own compactions but not of the platform's (A7), so the layers
stay.

1. *Write first, then act.* A founder message that changes direction, a
   decision, an agent sent out: each is written to `now.md` or the founder
   log and pushed to the day's open handoff branch before the work it
   causes starts. (The lead already keeps such a branch: #403.) Today the
   rule is "at every pause"; the platform's idle compaction comes
   without the lead having known that the pause would be a long one.
2. *Compaction instructions in `CLAUDE.md`,* which is re-read from disk
   after every compaction and steers the summary, also the unasked ones.
3. *Recall.* A small script searches the lead's transcripts for the exact
   words of a dropped message. A scout runs it, so the lead's context
   stays small. "The summary lost a detail" becomes a question with an
   answer.
4. *A daily cold read.* The route (B2) is done by a model that
   sees only the repository. If it cannot tell what is in flight, the
   handoff is not true, and that is found within a day.

**The lead's own work.** My design forbade the lead to "read code beyond
one file" and to do anything over five tool calls. The measurement does
not support that: a 4k-token file costs $0.001 a turn while it stays in
the context, and the smallest agent costs $0.67 to $1 (A12). What cost
money on 11-05 and 11-06 was 500 to 600 turns a day at 450k: the lead
building and running fix loops. And the losses that hurt were premises the
lead did not check itself (friction rows 5, 6 and 10). So: the lead reads
what a decision needs and does not build. The line moves from five tool
calls to about ten.

### B2. The improvement loop

**Decision: a route from Fable when the day starts and when the board
empties, and friction handled by its kind.**

- **Friction line** in every hand-back: kept as in #403. A script collects
  the lines from the sub-agents' transcripts; the lead does not copy them
  by hand, and "none" is not logged.
- **Each row has a kind and is handled within a day:** `tool` (a builder
  fixes it today or it gets a line in `now.md`), `brief` (nothing changes
  unless it repeats), `rule` (goes to the route), `platform` (noted; told
  to the founder if only he can change it).
- **Hygiene is computed, not performed.** The pulse prints the leftovers:
  merged worktrees still on disk, pull requests open more than two days,
  friction rows with no "Handled", rule files over their line caps, the
  date of the last route. No agent, no rule change, no founder.
- **The route.** Two triggers, both about the work and not the clock:
  the first founder message after a gap of six hours or more, and the
  board emptying (`now.md` has no next step that can start). The lead
  spawns Fable with the standing brief (C7). Fable reads the pushed
  repository only and returns at most 40 lines: whether the thread can
  be picked up cold; the route; the premise most worth checking before
  the largest spend; whether the roles are enough; which friction rows
  need a fix today; at most one rule change with its text. When
  `now.md` has a plan, Fable amends it. When the board is empty, Fable
  writes the route: the next goals in order, each with who writes its
  spec. The studio then follows it for hours. It is one pass, about a
  dollar (A12), and not a standing orchestration: the lead still runs
  the day, and applies or declines each point in one line in `now.md`.
- **The brake.** A role file or a brief template changes on one recorded
  incident, without the founder, and is listed in the lead's next report
  to him. A change to the studio system itself (`CLAUDE.md`, a principle
  in `studio.md`, this loop, how models are routed or briefed) needs two
  incidents, or one that cost more than a day, and reaches the founder
  before it is applied: the system is his responsibility. At most one
  rules PR a day. Line caps: `CLAUDE.md` 80, each role file 80,
  `studio.md` 330; at the cap, a new rule replaces or merges an old one.
- **The loop is itself on trial.** After seven routes, count those that
  changed something. Fewer than three: the route moves to chapter starts
  and on request.

*Set aside:* a rule review every 3 to 4 days. On the evidence so far it
would have had nothing to review (A13), tool defects should not wait for
it, and the founder asked for short cycles. A deeper pass on the studio
remains what `studio.md` §8 item 5 already allows, when the route asks for
it. *Also set aside:* Fable as a standing planner that the lead waits
on. While a plan exists the lead owns it and Fable amends; a second
planner would divide the responsibility. An empty board is different:
there is nothing to amend, "what next?" is a wide judgement (§8 item 4),
and my first version was wrong to rule the written route out. *Also set
aside:* a route on a fixed schedule. The founder's days are irregular
(11-09 had two lead turns), and the two triggers follow the work.

**The roles today.** Enough for what `now.md` lists (the one-world PRs,
art review, ingest, the recording). Two gaps the friction log shows are
not role gaps: the critic could not look at 1:1 because the frames on
`screenshots/*` are 460 x 1000 (a tool fix, C8), and a brief built from CI
frames must say whether a defect is the fixture's or the game's (a
brief-template line, C3). The test for a missing role, from now on: the
lead has written the same procedure into two briefs, or an agent has
handed back the wrong shape twice.

### B3. How Fable is reached

| Door | Context it starts with | Cost | Right for | Wrong for |
|---|---|---|---|---|
| **The lead spawns it** | Fresh; the brief plus what it reads | About $1 bounded (A12); up to 40 lines land in the lead's context | The route; a large spec; the moments in §8 (a premise, a second failure, taste, a wide judgement) | Judging the lead: the lead would choose what its judge sees |
| **The side channel spawns it** (the previous lead session) | Fresh; the founder is present and sees the brief | The same, plus the side channel's own turns (it sits near 130k: $0.07 a turn) | Anything the founder starts; judging the lead or the studio; this pass | Routine: it needs him there |
| **A scheduled task opens a fresh session** | Fresh clone of a 713 MB repository; nothing unpushed | Not measured; I estimate $2 to $3 a firing. Fires on days with no work (11-09 had two lead turns) | A cadence that must not depend on the lead | Now: it adds a session to his list every day, it must address the lead by a session id that changes with each new lead, and its model must be set to Fable by him |

**Decision.** The lead spawns Fable for the route, for §8's moments and,
at its own judgement, for the spec of large work (B4).
For the route the brief is a file passed word for word, so the lead's view
does not shape it; the only thing the lead adds is the name of the handoff
branch. The side channel is the founder's door and the only place the lead
itself is judged. A scheduled session is held back with a stated trigger:
if the route is skipped on two working days in one week, schedule it.

A live Fable agent can be continued with SendMessage the same day while it
is under about 200k; past that a fresh one is cheaper.

### B4. Briefing each model

The founder's three beliefs hold, with one amendment I made before and
keep: every model gets exact facts and exact acceptance. What differs is
how much of the *why* and the *method* is handed over.

What was not good enough:

1. **One template for all.** The 40-line brief with "Decided, do not
   reopen" is right for a Sonnet build accepted by tests. Given to Opus on
   work an eye accepts, it withholds what Opus is there for: why the thing
   matters, the founder's words on taste, what failed before, and leave to
   take a better route.
2. **No scout brief.** Haiku does best with closed questions and a fixed
   answer shape; the manual had no template for it.
3. **Sonnet got exactness on files and tests but not on words.** Project
   terms (plate, sky set, IL, Demand) were assumed. Three of the friction
   rows are a brief or a spec stating something loosely.
4. **The Opus roles had no licence to challenge the goal.** The spec role
   is told to remove judgement from the builders, but not that it may
   judge the goal it was given. The critic has it only under the
   "contrarian" lens.
5. **The lead's own rules held it down in one place** (B1: the reading
   limit).
6. **§8 requires showing the founder every Fable brief.** He has now
   drawn the line by what the work touches (part D): anything that
   changes the studio system reaches him first; a consult on a part of
   the work the system already covers runs at the lead's judgement; the
   route's standing brief runs without being shown again.

7. **Who writes the task.** The manual gave every spec to Opus. The
   founder leans towards Fable for large work and leaves the choice to
   the lead; I agree, and on the same test the manual already uses for
   everything else, the kind of work. Opus writes the routine briefs
   inside a route: it holds the live context, and a brief is a few
   hundred tokens of its own output. Fable writes the spec when more
   than about a week of agent work hangs on it, when it is the first of
   its kind, or when it sets a direction of taste. The numbers allow it:
   the game-solid spec cost $7.37 on Opus; at Fable's price that is
   under $20, about what the six PRs built from it cost ($18), and far
   less than the days a wrong large spec costs. It is the lead's call each time, not
   a rule: a large spec that is mostly reading code at a commit is
   still Opus's. Such a spec is work the system already covers, so it
   runs without asking the founder (part D, 3).

The changes are in C3 to C6.

---

## C. Exact text changes

Apply on top of #403 (`claude/exciting-cori-1t8br2`), which already
carries `docs/studio/friction.md` and the friction line in the five role
files. One rules PR; the scripts in C8 are a separate builder PR.

### C1. `CLAUDE.md`: add at the end (71 lines becomes 79)

```markdown

## Compact instructions

When this conversation is summarised, keep word for word: the founder's
messages that are not yet in `docs/product/founder-input.md`; every agent
in flight with its id, branch and pull request; decisions made but not
yet in `docs/now.md`; the paths of files not yet committed. The rest is
in the repository.
```

### C2. `docs/studio.md` §1, principle 2: replace the whole item

```markdown
2. **Cost is context times turns, and turns are the larger half.** Every
   turn re-reads the whole context: about $0.025 a turn for each 100,000
   tokens. On 2026-11-05 and 11-06 the lead ran 500 to 600 turns a day
   at about 450,000 tokens, and those two days cost more than half of
   its ten-day total. What costs is building and fixing in your own
   context, and long stretches above 400,000. Reading what a decision
   needs does not. Give each agent a small context of its own.
```

### C3. `docs/studio.md` §2 and §4

In the §2 table, replace the Lead row:

```markdown
| **Lead** (Opus 5.5, high) | Decides. Checks premises, reading what the decision needs. Writes briefs. Reads hand-backs. Looks once at the final sheet. Merges what an eye must accept. Keeps `now.md`. Talks to the founder | Build, or run a fix loop. Take the first look at frames. Poll CI |
```

In the §4 routing table, replace the "A spec" row with two rows, and the
last row's first cell with "The route, a premise, a second failure, a
milestone look, the studio itself":

```markdown
| A spec | spec, Opus | high | The spec carries the judgement, so builders need none |
| A spec that more than about a week of work hangs on, the first of its kind, or one that sets a direction of taste | spec, Fable (your call; Opus when it is mostly reading code) | high | A wrong large spec costs days; Fable's price on one spec is small beside the building that follows |
```

In §4, replace the "Do it yourself" bullet:

```markdown
- **Do it yourself** when it is the board, the founder log, a brief, a
  premise you are about to build on, or quicker than a brief: up to about
  ten tool calls with no build or fix loop in them. The smallest agent
  costs $0.70 to $1; ten of your own turns cost about the same and lose
  nothing in the hand-off.
```

In §4, replace the paragraph after the builder's brief ("Say what is
wanted and why … what to do instead.") with:

```markdown
Say what is wanted and why, and state facts and acceptance exactly. Leave
the method open unless a recipe exists; then name the PR that is the
recipe. Never write "stop", "wait" or "ask" without saying what to do
instead. A defect taken from a CI frame is a fact to check like any
other: say whether it comes from the test's fixture or from the game.

### The scout's brief

```text
Role: scout (.claude/agents/scout.md) | Commit: origin/main at <sha>
Q1: <a closed question: is, does, where, how many> | Answer as: yes or no, file:line
Q2: <one fact per question>
```

### Briefing by model

Every model gets exact facts and exact acceptance. What changes is how
much of the why and the method you hand over. A rule in a brief is there
to raise the result; give its reason, and if you cannot, leave it out.

| Reader | Give | Leave open | Ask back |
|---|---|---|---|
| **Fable** (the route, a large spec, a consult) | The goal and why it matters; the raw record by path, not your conclusions; the few fixed constraints; that everything it reads is evidence | The method, the length, and the question itself | Decisions, each with the alternative set aside; what only the founder can decide |
| **Opus** (spec, critic, art-reviewer, a build an eye accepts, story) | The goal as the player or the founder will feel it; his own words on taste, quoted with their path; the approved reference; what was tried and failed, by PR; facts with file and line; acceptance | The method, the split, and whether this is the right goal | First: is the goal or a premise wrong, and is there a better route |
| **Sonnet** (a build tests accept, a recipe, an ingest) | The files it owns; the exact change; every project word defined or pointed to where the code defines it; one example of done (the recipe PR or a reference frame); acceptance by named tests; a fallback for each likely failure; what is out of scope | The code inside its files | Premises that were false; decisions the brief did not cover |
| **Haiku** (facts, digests) | Closed questions, one fact each; the commit; the shape of the answer | Nothing | "Not found" |

- The 40-line limit is for a Sonnet build, where every line must be
  exact. A brief for Opus or Fable is as long as its context needs and
  points to material instead of summarising it.
- Do not hand your conclusion to an equal or larger model as a fact.
  Hand it the evidence and say what you concluded as one view.
- Who writes the task follows the kind of work. You write the routine
  briefs inside a route: you hold the live state. Fable writes the
  route, and the spec of large or first-of-its-kind work when you judge
  it earns that.
- Sonnet matches Opus on a build only when the spec carried the
  judgement. When you catch yourself writing "use your judgement" in a
  Sonnet brief, the work is Opus's or the spec is not finished.
```

(The outer fence above is for this document; the inner `text` block is
the scout template as it should appear.)

### C4. `docs/studio.md` §6: replace the fourth bullet ("The goal is a lean context …") and extend the second and third

Replace the second bullet's list ("fetch; read `now.md`; …") with:

```markdown
- **When you start or resume** (a new session, after a compaction, after
  a long pause): fetch; read `now.md` from the open handoff branch if
  there is one, otherwise from `main`; run
  `python3 -I tools/studio/pulse.py`; read the founder log's standing
  decisions and the entries after the date in `now.md`; look at the
  factory (section 9). On the first founder message after six hours or
  more, run the route (section 11). If something you need was
  said before a compaction, a scout finds the exact words with
  `python3 -I tools/studio/recall.py "<words>"`.
```

Replace the third bullet with:

```markdown
- **Write first, then act.** A founder message that changes direction, a
  decision, an agent sent out: write it to `now.md` or the founder log
  and push it to the day's handoff branch (one open docs PR a day)
  before the work it causes starts. The platform compacts this session
  by itself, at the window's end and after a pause of an hour or more
  above 200,000 tokens; four of the first eight compactions came that
  way. If the pushed `now.md` is true, none of them loses anything.
```

Replace the fourth bullet with:

```markdown
- **Your context: a working band.** The aim is a balance: enough to
  remember well and never lose the thread, lean enough for a budget many
  agents share. After a compaction you are at about 100,000 tokens; that
  is the bottom. Up to 250,000, work, and never compact to save money:
  the whole range costs a few dollars a day. At 250,000 or more, when
  you reach a pause, finish the handoff and end your message to the
  founder with one line he can paste, written for that moment:
  `/compact Keep word for word: <his messages not yet logged; agents in
  flight; decisions not yet in now.md>. The rest is in docs/now.md.`
  Past about 400,000, where a turn costs twice what it does at 150,000,
  ask him more firmly at the next pause, never in the middle of work.
  He compacts by hand; nothing is set to do it for him.
  `python3 -I tools/studio/session_cost.py --now` shows where you are.
```

### C5. `docs/studio.md` §8: two edits

Replace "When you are unsure whether a task earns it, ask the founder,
and agree together what Fable will do. Show him the full brief before it
runs. Log each use in the founder log with the reason and the usage
line." with:

```markdown
Who sees it turns on what the work touches. A brief or an answer that
changes the studio system itself (`CLAUDE.md`, a principle on this page,
the improvement loop, how models are routed or briefed) reaches the
founder before it runs or is applied: the system is his responsibility.
A consult or a spec on a part of the work the system already covers
(how an in-game UI system should work, a premise, a look) runs at your
judgement. The route's brief (`studio/route-brief.md`) stands and runs
without being shown again; a system change it proposes goes to him
first. When you are unsure which side a task is on, ask him. Log each
use in the founder log with the reason and the usage line; a route is
logged as one line in `now.md`.
```

Add after the numbered list of moments:

```markdown
Three doors. You spawn Fable for the route, for the moments above and
for a large spec. The founder's side channel spawns it for anything he starts and
whenever the lead or the studio is what is being judged: you do not
choose what your own judge reads. A scheduled session is held back; it
is the answer if the route is skipped on two working days in a week.
Continue a live Fable agent with SendMessage while it is under about
200,000 tokens.
```

### C6. `docs/studio.md`: new section 11, after section 10

```markdown
## 11. The studio improves itself

- **Friction.** Every hand-back ends with a `Friction:` line.
  `python3 -I tools/studio/friction.py` collects the new ones;
  add those that are not "none" to `studio/friction.md` with a kind:
  `tool`, `brief`, `rule` or `platform`. For your own slips, add your
  context size and the turns since the last compaction. Each row is
  handled within a day: a `tool` row is fixed by a builder or gets a
  line in `now.md`; a `brief` row changes nothing unless it repeats.
- **Hygiene is what the pulse prints:** merged worktrees still on disk,
  pull requests open more than two days, friction rows not handled,
  rule files over their caps, the date of the last route. Clear them
  at a pause. It never changes a rule and never needs the founder.
- **The route.** At the day's start (the first founder message after
  six hours or more) and whenever the board empties (no next step in
  `now.md` can start), spawn Fable with `studio/route-brief.md`, word
  for word, adding only the handoff branch and which trigger it is.
  With a plan in `now.md` it amends; on an empty board it writes the
  route, and the studio follows it for hours. It reads the pushed
  repository as a stranger would, so it is also the test that the work
  can be picked up cold. One pass, not a standing orchestration: you
  run the day. Apply or decline each point, and write one line in
  `now.md` (`**Route:** <date>; changed: <what>`).
- **A rule changes only on a recorded incident.** One row is enough for
  a role file or a brief template; apply it and list it in your next
  report to the founder. A change to the studio system itself
  (`CLAUDE.md`, a principle on this page, this loop, how models are
  routed or briefed) needs two rows, or one that cost more than a day,
  and reaches the founder before it is applied. At most one rules PR a
  day. Caps: `CLAUDE.md` 80 lines, a role file 80, this page 330; at
  the cap, a new rule replaces or merges an old one.
- **A role is missing** when you have written the same procedure into
  two briefs, or an agent has handed back the wrong shape twice.
- **The loop is on trial.** After seven routes, count those that
  changed something. Fewer than three: move the route to chapter
  starts and on request, and say so here.
```

In the §10 Desks table, the Studio row's "Accepted by" becomes
`the pulse, the session cost and the friction log`.

### C7. New file `docs/studio/route-brief.md`

```markdown
# The route: Fable's standing brief

Passed word for word by the lead, who adds two lines: the handoff branch
and the trigger. Approved by the founder on 2026-11-12 to run without
being shown again; changed only through a rules PR that he sees first.

"You" means you, Fable 5.2, the most capable model of the family. What
you will read was written by smaller models or dictated by the founder;
weigh all of it as evidence, this brief included. The lead (Opus 5.5)
runs the studio and runs the day. You see the studio from outside, in
about ten turns, at the day's start and whenever the board empties. The
studio will follow what you write for hours, so make it worth following;
you are not asked to orchestrate it afterwards.

Read only what is pushed, as a stranger would:
`git fetch`, then `docs/now.md` from the handoff branch named below
(or `origin/main`); `python3 -I tools/studio/pulse.py`;
`docs/studio/friction.md`; the entries of `docs/product/founder-input.md`
after the date in `now.md`; the role files in `.claude/agents/`.
`docs/studio.md` only where you need it. Open code only to check one
premise that looks unchecked. Change nothing in the repository.

Return at most 40 lines, in this order. "No change" is a full answer to
any of them.

1. **Thread:** from the repository alone, is it clear what is in flight
   and what comes next? If not, what is missing from `now.md`.
2. **Route:** if `now.md` has a plan, the steps in order with who does
   each (role, model, effort), only where you would change it, each
   with its reason. If the board is empty, write the route: the next
   goals in order, each one sentence the founder could see, with who
   writes its spec. Opus writes routine briefs; name yourself for a
   spec only when more than about a week of work hangs on it, it is the
   first of its kind, or it sets a direction of taste.
3. **Premise:** the one claim most worth checking before today's largest
   spend, and how to check it cheaply.
4. **Roles:** enough for today, or which role is missing or wrong, with
   the incident that shows it.
5. **Friction:** the rows that need a tool fix today, one brief line
   each. At most one rule change, with its rows and its exact text;
   mark it "system" if it touches `CLAUDE.md`, a principle in
   `studio.md`, the improvement loop or how models are routed or
   briefed: the founder sees those before they are applied.
6. **For the founder:** nothing, or one question with a default.

If the question is wrong or something larger is off, say that first and
leave the list.

Handoff branch: <added by the lead>
Trigger: day start | empty board
```

### C8. Role files (each stays under 80 lines)

`.claude/agents/spec.md`: add after the first paragraph:

```markdown
You were given a goal, not an order. If the code shows that the goal is
the wrong one, or that a cheaper goal gives the player the same thing,
say so in the spec's first lines and set the better one beside it. The
lead chooses.
```

`.claude/agents/builder.md`: replace the first paragraph with:

```markdown
You build one brief. The lead may give this role to a larger model when
the work is accepted by an eye. If you are that model, the reference and
the player are your judge and the brief's method is a starting point:
take the better route inside your files and say in the hand-back what
you changed and why.
```

and add to item 2:

```markdown
   A project word the brief does not define is defined by the code:
   take the reading the code supports and name it in your hand-back.
```

`.claude/agents/critic.md`: replace item 1 with:

```markdown
1. Answer the question in the brief first, in one line: ship, fix or
   redo. If it is the wrong question to ask of this artifact, say so in
   one more line and answer the right one too.
```

`.claude/agents/scout.md`, `art-reviewer.md`: no change.

### C9. `docs/studio/friction.md`: replace the header paragraph

```markdown
Every agent's hand-back ends with one `Friction:` line: what slowed it
down, or which rule misled it. `tools/studio/friction.py` collects them;
the lead adds those that are not "none" here, with a kind (`tool`,
`brief`, `rule`, `platform`), and handles each within a day. For the
lead's own slips, "Who" carries its context size and the turns since the
last compaction (`lead, 310k, 140 turns`), so that in two weeks this
table can say whether slips follow context size. The route reads
this log. A rule changes only when rows here back the change
(`docs/studio.md` section 11).
```

and change the table head to `| Date | Who | Kind | Friction | Handled |`
(the ten rows: 1, 2, 3, 4, 9 `tool` or `platform`; 5, 6, 8, 10 `brief`;
7 `tool`). The header's "Agreed with the founder 2026-11-12" comes out:
the cadence it described was a proposal.

### C10. `docs/now.md`

Remove the "Lead session cost … Aim: an average under 150k" line (it is
already gone on #403). Add under "Founder log read up to":
`**Route:** none yet.` In "Open with the founder", remove "keeping the
lead lean": part D settles it.

### C11. One builder brief for the scripts (Sonnet, medium, accepted by tests)

```text
Role: builder (.claude/agents/builder.md) | Desk: studio | Base: origin/main at <sha>
Goal: the lead sees its context, its leftovers and its sub-agents' friction from three commands, and can find the exact words of a message a compaction dropped.
Facts, checked at the base commit:
- session_cost.py reads one transcript and prints "target: average context under 150k" (tools/studio/session_cost.py:63)
- a transcript line with "subtype":"compact_boundary" marks a compaction; a founder message is "type":"user" whose message.content is a string or holds a "text" part, without "isMeta" or "isCompactSummary"
- sub-agent transcripts are <session>/subagents/*.jsonl, with the description in *.meta.json (session_cost.py:66-70)
You own: tools/studio/*. Do not touch: anything else.
Change:
1. session_cost.py: drop the 150k target line. Add --now: one line with the last turn's context, the turns since the last compact_boundary, today's turns and dollars, and today's turns above 400k. Price a one-hour cache write (usage.cache_creation.ephemeral_1h_input_tokens) at 2.0 and a five-minute one at 1.25.
2. recall.py "<regex>" [--who founder|lead|all] [--since YYYY-MM-DD] [--max 20]: search every lead transcript under ~/.claude/projects/*/*.jsonl (not subagents/), print timestamp, who, and up to 400 characters around each match, oldest first.
3. friction.py [SESSION.jsonl] [--since YYYY-MM-DD]: for each sub-agent transcript, the last assistant text's line starting "Friction:"; skip "none"; print date, the agent's description, the line.
4. pulse.py: after its present output, a "Leftovers" block: worktrees whose branch is merged into origin/main; open PRs older than 48 hours (gh api, skip quietly without network); rows in docs/studio/friction.md with an empty last cell; line counts over the caps (CLAUDE.md 80, .claude/agents/*.md 80, docs/studio.md 330); the "**Route:**" line of docs/now.md.
Decided, do not reopen: standard library only; run with python3 -I; no new files outside tools/studio.
Done when: python3 -I -m unittest discover -s tools/studio passes with new tests for each of 1 to 4 on small fixture transcripts written in the tests.
Merge: self on green
```

The frames on `screenshots/*` being 460 x 1000 (friction row 9) is a
separate `tool` row for the lead to brief; I did not look at the CI
workflow and do not prescribe the fix.

---

## D. What the founder decided (2026-11-12, on the first version)

1. **No backstop.** He will not set `/autocompact` or the environment
   variable: he does not want the lead compacted automatically in the
   middle of work. He compacts by hand when the lead pauses and offers a
   `/compact` line, and expects the lead rarely to pass 400k. Past about
   400k the lead asks more firmly at the next pause.
2. **The aim is a balance,** "neither at the limits nor at the bottom":
   enough context to remember well and never lose the thread, lean
   enough for the budget, since many agents run. Hence a working band
   and not a ceiling.
3. **Who sees Fable's work.** A Fable brief or answer that changes the
   studio system itself reaches him before it is applied; that is his
   responsibility. A consult on a part of the work the system already
   covers runs at the lead's judgement. The route's standing brief runs
   without being shown again; a system change it proposes goes to him
   first. Role-file changes apply without him and are listed in the
   lead's report.
4. **The side channel stays open:** the previous lead session, as his
   door to Fable and the place the lead is judged.
5. **Pasting the `/compact` line is his choice each time.** With no
   backstop, the cost of not pasting is the slope in A2: a few dollars a
   day inside the band, more above it.
6. **The route's cost profile suits him** (a view, not a rule): one
   Fable pass when the board empties, followed for hours. Whether Opus
   or Fable writes a task is the lead's call; he leans towards Fable
   for large work. Folded into B2, B4, C3, C6 and C7.

Nothing in this document still waits on him.

## E. Where the data is too thin

- **Does the lead judge worse at 350k than at 150k?** Not measurable from
  these transcripts: there is no record of which lead statements were
  wrong, at what size. The three corrections of the founder's week are
  named in the evidence pack without a turn. *Cheap measurement:* the
  friction log's "Who" cell for the lead's own slips carries context size
  and turns since compaction (C9). Two weeks give a table of slips per
  hundred turns by band. If slips cluster above 300k, the 250k line drops
  to 200k; if they cluster in the first 30 turns after a compaction, the
  summary is the weak point and the compaction instructions get longer.
- **Do the `CLAUDE.md` compaction instructions steer the unasked
  compactions?** Documented for `/compact` with arguments; I recall the
  `CLAUDE.md` section from the documentation but did not find the page in
  this pass. *Cheap measurement:* after the next compaction a scout reads
  the summary in the transcript (the line marked `isCompactSummary`) and
  checks that it lists the agents in flight.
- **Is idle compaction always on?** It fired on four of about sixteen
  pauses of over an hour above 200k (none before 11-07). I could not
  find its exact condition. The policy does not depend on it, but it is
  the one compaction the founder does not choose; if it troubles him,
  the documentation names a setting (`idleCompaction`) to look into.
- **What a scheduled Fable session costs.** Estimated, not measured. One
  firing would measure it, if the route is ever moved there.
- **Whether the route earns its dollar.** Unknown until it has run;
  section 11's seven-route count settles it.
