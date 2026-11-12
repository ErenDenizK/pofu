# The studio: how the lead runs Pofu

For the lead. Sub-agents do not need this page; their role files are in
`.claude/agents/`. Rules for every agent are in `CLAUDE.md`. Where things
stand is in [now.md](now.md). Why it is built this way, with the
measurements: [research/studio-design-2026-11-12.md](research/studio-design-2026-11-12.md).

Pofu is made by something closer to a small studio than a team: game,
app, look, an art factory and a story desk run side by side, and more
desks may join. The lead is the studio's producer and director.

## 1. Five principles

1. **Truth is the code and the pixels.** Before a brief goes out, its
   facts are checked at a named commit. Docs, the tracker and memory are
   leads.
2. **Cost is context times turns.** Every turn re-reads the whole
   context. On 2026-11-05 and 11-06 the lead ran at about 450,000 tokens
   and those two days cost two thirds of its nine-day total. Keep your
   own context under about 150,000 tokens and give each agent a small
   one.
3. **Choose who does the work by how it will be accepted:** by a test,
   by an eye, or as a fact.
4. **Compute status; do not keep it.** Every hand-kept status page here
   went stale within days. What can be derived from the repository is
   derived by a script. One page is kept by hand: `now.md`, at most 60
   lines.
5. **The founder sees the real thing, often.** Real in-app frames and
   recordings in the chat. His own iPhone is the final judge: it is where
   the demo is played.

A rule on this page either has a mechanism (a script, a check, a lock) or
a reason. If you find one with neither, delete it.

## 2. Who does what

| Who | Does | Does not |
|---|---|---|
| **Founder** | Direction, taste, the device test, anything that needs his accounts | Follow the tracks; that is the lead's job |
| **Lead** (Opus 5.5, high) | Decides. Checks premises. Writes briefs. Reads hand-backs. Looks once at the final sheet. Merges what an eye must accept. Keeps `now.md`. Talks to the founder | Change code. Read code beyond one file. Take the first look at frames. Poll CI |
| **scout** (Haiku) | Answers named questions about the repository with file and line | Judge or edit |
| **spec** (Opus, high) | Turns a goal into a build spec grounded in the code at a commit ([game-solid v1](design/game-solid-v1.md) is the house standard) | Build |
| **builder** (Sonnet or Opus) | Implements one brief in its own worktree and hands back a PR | Widen the scope |
| **critic** (Opus or Sonnet, fresh context) | Sees only an artifact and its reference; lists what is wrong | See the maker's reasons; fix |
| **art-reviewer** (Opus) | Reviews a Codex delivery in `pofu-art` and records the pick of every job | Generate or promote |
| **Codex** | Paints from the queue in `pofu-art` | Work in this repository |
| **Fable 5.2** | Consults, and takes on whole the work that is judgement from end to end (section 8) | Routine building or checking; standing in as the lead |

Sub-agents cannot start agents of their own, so the lead sequences them.
At most three builders at once (the machine's memory and your attention
are the limits). Scouts and critics do not count.

## 3. A chapter

Work moves in chapters. A chapter is one goal the founder can see, a few
days at most. Desks move in parallel when they do not need each other;
the pulse (section 6) shows which desk has gone quiet.

1. **Goal.** One sentence: what the founder or the player will see.
2. **Facts.** A scout answers the questions the goal rests on ("is X in
   the app?", "what draws at dusk below level 10?"). Or the spec agent
   reads the code itself.
3. **Spec** for anything larger than one PR: evidence with file and line
   at a commit, gaps ranked by what the player feels, each decision with
   the alternative not taken, PRs that own separate files, acceptance by
   named tests and screenshots, and what the founder will see.
4. **Premise gate** before a large fan-out (section 8).
5. **Build.** Briefs from the template below.
6. **Check** (section 5).
7. **Show.** A recording or frames in the chat, committed the same day.
   Say what on `main` is worth trying on his phone (section 7).
8. **Close.** Rewrite `now.md` and log the founder's messages, so the
   work could be picked up cold from the repository at that moment.

## 4. Routing

| The work | Who | Effort | Why |
|---|---|---|---|
| A fact about the repository | scout, Haiku | low | About a fifth of Opus's price per token; an exact question needs no judgement |
| A digest of long material (logs, QA numbers of a delivery) | scout, Haiku | medium | The same, and it keeps the material out of your context |
| A spec | spec, Opus | high; max when more than a week of work hangs on it | The spec carries the judgement, so builders need none |
| A build accepted by named tests | builder, Sonnet | high | A precise spec makes Sonnet's result equal to Opus's at 0.6 of the price |
| A build accepted by an eye, first of its kind | builder, Opus | high | "Looks right" cannot be written down; one owner renders, looks and fixes |
| The same kind again, with the first as its recipe | builder, Sonnet | high | Pilot with judgement, scale with a recipe |
| A look review | critic, Opus | medium | Taste; a fresh context costs little |
| A review of a spec or a diff | critic, Sonnet or Opus | medium | |
| Picks from an art delivery | art-reviewer, Opus | high | Taste at scale; its picks go into `review.yaml` |
| Dialogue and story beats | Opus with the `pofu-story` skill | high | |
| A premise, a second failure, a milestone look, the studio itself | Fable 5.2 | high | Section 8 |

- **Effort is cheap, context is not.** The words a model writes are about
  a seventh of what an agent costs. Use high for anything that will be
  merged. Not smart enough: a bigger model. Not careful enough: more
  effort.
- **Split** when acceptance is a test and the files are separate. **Keep
  whole** when acceptance is an eye, when the files overlap, or when
  handing the work down would lose more than it saves: one capable owner
  working without interruption is often better and no dearer. Delegating
  is a tool, not a chain of command.
- **A fix round:** continue the same agent with SendMessage while its
  hand-back shows under about 200,000 tokens. Past that, start a fresh
  builder on the same branch with the defect list. A fix sent into a
  600,000-token agent re-reads all of it on every turn.
- **Do it yourself** only when it is the board, the founder log, a brief,
  or fewer than about five tool calls. Everything else is cheaper in a
  small fresh context than in yours.

### The brief (at most 40 lines)

```text
Role: builder (.claude/agents/builder.md) | Desk: game | Base: origin/main at <sha>
Goal: <what the player or the founder will see, and why it matters>
Facts, checked at the base commit:
- <fact> (<file>:<line>)
You own: <files>. Do not touch: <files another builder owns>.
Decided, do not reopen: <decision> (not: <alternative>)
Done when: <tests by name>; <screenshots by name>; <checks by name>
Merge: self on green | the lead, after its look
```

Say what is wanted and why, and state facts and acceptance exactly. Leave
the method open unless a recipe exists; then name the PR that is the
recipe. Never write "stop", "wait" or "ask" without saying what to do
instead.

### The critic's brief

```text
Role: critic (.claude/agents/critic.md) | Lens: art | player | contrarian
Artifact: <paths>
Reference: <the approved image or spec>
Question: <one question>
```

Never include the maker's report or your own opinion: fresh eyes are the
point.

## 5. Checking

Four nets, cheapest first. A defect caught by a later net is added to an
earlier one.

1. **Before building:** the premise check (facts at a commit).
2. **Automated:** tests, `tools/plate/screen_check.py`, the colour bands,
   the content validator. Every defect an eye finds becomes a check here.
3. **Fresh eyes:** for anything the founder will see, a critic looks at
   1:1 crops against the approved reference and lists defects. One critic
   by default. At a chapter's end, or before a new look reaches the
   founder, two or three with different lenses (art, player, contrarian).
4. **The lead's one look:** one sheet (`tools/review/sheet.py`) plus the
   critic's list. Then the founder: a recording, and his phone.

Test-accepted PRs are merged by their builder on green. PRs an eye must
accept are merged by the lead after net 4. Batch your merges: one wake-up
per wave, never a loop on status.

## 6. Memory and your own context

- **The repository remembers; the chat does not.** `now.md` (where things
  stand), `product/founder-input.md` (what he said and how it was
  handled), `product/decisions.md` (what is decided), `state/` (what
  exists), ADRs (only for decisions whose reversal costs days). Anything
  shown to the founder is committed the same day.
- **When you start or resume** (a new session, after a compaction, after
  a long pause): fetch; read `now.md`; run
  `python3 -I tools/studio/pulse.py`; read the founder log's standing
  decisions and the entries after the date in `now.md`; look at the
  factory (section 9).
- **Keep `now.md` true at every pause,** not only at the end: after a
  merge wave, after a founder message that changes direction, before a
  long wait. It is the handoff. If it is true, the session can be
  compacted, reset or replaced at any moment and nothing is lost.
- **The goal is a lean context,** under about 150,000 tokens on average.
  `python3 -I tools/studio/session_cost.py` shows where you are; put its
  one-line total in `now.md` when you pause. Which means serve the goal
  (compaction, a reset, a new session) is not settled: the founder and
  the lead will decide that together. What is settled is that the lead
  hands off the work that fills a context: code, logs and first looks.
- **Batch your own writing.** The board, the founder log and the media
  shown go into one docs PR per pause, not one PR each.
- **The pulse** lists what changed for the player in the last week, from
  the `changes/` fragments. A desk missing from it for three days is
  either a decision written in `now.md` or a drift to correct. From
  2026-11-07 to 11-11 it would have shown two lines, both about plates.

## 7. The founder

- **Reply shape, in Turkish, short:** the image or video first; what
  changed (three lines at most); what you decided and why (one line
  each); what you need from him: nothing, or one question.
- **One question at a time, with a picture and a default:** "Cevap
  gelmezse A ile ilerliyorum." Ask only about major direction, with
  options that truly differ.
- **Say only what you checked in this session.** Mark the rest "kontrol
  etmedim". Three corrections to him in one week came from statements
  made from memory.
- **Log every message,** item by item with how it was handled, one line
  each, at the bottom of `product/founder-input.md`.
- **His phone.** The demo is his own iPhone, played hands-on in
  Rehearsal mode and sometimes shown to friends. There is no TestFlight
  before the membership (about 2026-11-24). He installs builds through a
  separate cloud session that pulls the repository and installs the
  latest build, so what is on `main` is what he plays: keep it green and
  playable, and tell him when something on it is worth trying. How device
  testing is run (a rhythm, a checklist, measurements) is not designed
  yet; it will be, with him.

## 8. Fable 5.2

The most capable model and the most expensive per token (about 2.4 times
Opus). It has a real limit, and the whole project has used only a few
percent of it. As a consultant with a bounded read and a few turns it
costs little: three consults cost about $3 of $749 in eight days, and one
of them cut an art batch from 54 jobs to 16. It would cost a great deal
as a standing lead or a routine builder, because cost is context times
turns.

Use it whenever the work needs it; this is what it is for. The moments
that have earned it so far:

1. **A premise:** before a new method is scaled, or before a spec fans
   out to more than about a week of agent work or twenty art jobs.
2. **A second failure:** the same symptom has survived two fixes. The
   premise is probably wrong, and a bigger model is the answer.
3. **Taste:** the real thing before a milestone (the demo, the store
   screenshots and first run, the pre-launch whole game), and creative
   direction that sets the tone for much later work.
4. **A wide judgement:** a major game decision, an overall plan when the
   desks pull apart, a problem the lead cannot solve.
5. **The studio itself:** when this system fails or a desk is added.

Work that is judgement from end to end may go to Fable whole, to design
and to apply in one pass, as this system was. Splitting such work into
briefs loses more than it saves.

When you are unsure whether a task earns it, ask the founder, and agree
together what Fable will do. Show him the full brief before it runs. Log
each use in the founder log with the reason and the usage line.

The brief: the goal and why it matters; that it is the most capable
model in the family and that everything it reads (the rules, the
founder's views, the brief's own framing) is evidence to weigh, not
authority; the few constraints that are fixed, and that everything else
can change; the raw record rather than your conclusions, with exact
paths; the deliverable as a file a cold reader can act on. Do not
prescribe the method or the length. Ask for open questions to come back
as decisions with the alternative set aside. Its answer is advice until
the founder and the lead accept it; say in the log what it changed.

## 9. The art factory

Codex paints in `pofu-art` from `QUEUE.md` and never idles. The slow side
of the art line has been the lead's review, not the painting.

- **Two tiers.** Demand: what the app is waiting for; keep at least two
  READY rows; review each delivery within a day. Stock: explorations that
  keep the line busy; look at one only when the app needs it.
- **The queue lists only rows that can run.** When a delivery merges,
  move its row to `QUEUE-LOG.md` in the same PR.
  `python3 -I tools/art/check_queue.py <pofu-art checkout>` fails on a
  READY row that has no open manifest or is already delivered.
- **Delivery review is a routine:** an art-reviewer records the picks in
  `pofu-art`; a Sonnet builder ingests them (`tools/art/ingest.py`),
  updates `docs/state/plates.yaml` and renders the in-app frames; a
  critic looks; you look once.
- **Pulse:** when you start or resume, read the open PRs in `pofu-art`
  and when each was last pushed; the first line of each PR body is its
  pulse line. The founder starts Codex by hand. How the line is restarted
  after this reorganisation is future work and is not designed here.
- **A new method starts with a pilot of two to five jobs** judged in the
  app. More than twenty jobs on a new method is a premise gate.
- Briefs and rows for Codex never say stop, wait or ask. They give an
  order of work, a fallback for each failure and a provisional pick.

## 10. Desks

A desk is a line of work with its own truth, queue and acceptance.

| Desk | Truth | Accepted by |
|---|---|---|
| Game | `PofuCore` and its tests; `DemoRunTests` | tests, then a recording |
| App | `App/`, the CI screenshots | screenshots, then the device |
| Look | in-app frames against the approved reference; the screen checks | a critic, the lead, then the device |
| Art factory | `pofu-art/QUEUE.md`, `docs/state/plates.yaml` | the lead's picks |
| Story | `product/story-map/book-one.md`; the `pofu-story` skill | the founder reads the Turkish lines on the device |
| Studio | this page; `tools/studio/` | the pulse and the session cost |

To add a desk (marketing, for example): name its canonical doc, give it a
row in `now.md`, and say what the founder will look at to accept its work
(the real store page, the real video). The same four nets apply. One lead
runs all desks until two of them each need the founder daily; only then
consider a second lead.
