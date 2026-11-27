# The studio: how the lead runs Pofu

For the lead. Sub-agents do not need this page; their role files are in
`.claude/agents/`. Rules for every agent are in `CLAUDE.md`. Where things
stand is in [now.md](now.md). Why it is built this way, with the
measurements: [the design](research/studio-design-2026-11-12.md) and
[the context, route and briefing proposal](research/studio-context-2026-11-12.md).

Pofu is made by something closer to a small studio than a team: eight
desks run side by side, each from its own book in `docs/desks/`. The
lead is the studio's producer and director: it conducts the desks and
carries none of them in its own context.

## 1. Five principles

1. **Truth is the code and the pixels.** Before a brief goes out, its
   facts are checked at a named commit. Docs, the tracker and memory are
   leads.
2. **Cost is context times turns, and turns are the larger half.** Every
   turn re-reads the whole context: about $0.025 a turn for each 100,000
   tokens. Two days of 500 to 600 turns at about 450,000 tokens cost the
   lead more than half of its ten-day total. What costs is building and
   fixing in your own context, and long stretches above 400,000; reading
   what a decision needs does not. Give each agent its own small context.
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
| **Founder** | Direction, taste, the device test, anything that needs his accounts | Follow the tracks; that is the lead's job. Get asked about process calls (an extra push, a merge under an approved plan, a cleanup): the lead decides those, does them and tells him after (founder-input 31, 37) |
| **Lead** (Opus 5.5, high) | Decides. Checks premises, reading what the decision needs. Writes briefs. Reads hand-backs. Looks once at the final sheet. Merges what an eye must accept. Keeps `now.md`. Talks to the founder | Build, or run a fix loop. Take the first look at frames. Poll CI |
| **scout** (Haiku) | Answers named questions about the repository with file and line | Judge or edit |
| **spec** (Opus, high) | Turns a goal into a build spec grounded in the code at a commit ([game-solid v1](design/game-solid-v1.md) is the house standard) | Build |
| **builder** (Sonnet or Opus) | Implements one brief in its own worktree and hands back a PR | Widen the scope |
| **critic** (Opus or Sonnet, fresh context) | Sees only an artifact and its reference; lists what is wrong | See the maker's reasons; fix |
| **art-reviewer** (Opus) | Reviews a Codex delivery in `pofu-art` and records the pick of every job | Generate or promote |
| **Codex** | Paints from the queue in `pofu-art` | Work in this repository |
| **Fable 5.2** | Consults, and takes on whole the work that is judgement from end to end (sections 4 and 8) | Routine building or checking; standing in as the lead |

Sub-agents cannot start agents of their own, so the lead sequences them.
How many run at once is the lead's call, per job: order, disjoint
files, cost, time, and what the lead can still look at. Signals, not
caps (research/studio-scaling-2026-11-14.md §1): a PR only on CI holds
no slot; hold back under 8 GB free, after an OOM kill, or with two PRs
on one file.

## 3. A chapter

Work moves in chapters. A chapter is one goal the founder can see, a few
days at most. Desks move in parallel by lane (`docs/desks/README.md`):
one Swift build at a time, and beside it the Python, Codex and words
lanes. The pulse (section 6) shows which desk has gone quiet.

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
| A spec | spec, Opus | high | The spec carries the judgement, so builders need none |
| A spec that more than about a week of work hangs on, the first of its kind, or one that sets a direction of taste | spec, Fable (your call; Opus when it is mostly reading code) | high | A wrong large spec costs days; Fable's price on one spec is small beside the building that follows |
| A build accepted by named tests | builder, Sonnet | medium; high for tricky engine logic | A precise spec makes Sonnet's result equal to Opus's at 0.6 of the price |
| A build accepted by an eye, first of its kind | builder, Opus | high | "Looks right" cannot be written down; one owner renders, looks and fixes |
| The same kind again, with the first as its recipe | builder, Sonnet | medium | Pilot with judgement, scale with a recipe |
| A look review | critic, Opus | medium | Taste; a fresh context costs little |
| A review of a spec or a diff | critic, Sonnet or Opus | medium | |
| Picks from an art delivery | art-reviewer, Opus | high | Taste at scale; its picks go into `review.yaml` |
| Dialogue and story beats | Opus with the `pofu-story` skill | medium; high for a key scene | |
| The route, a premise, a second failure, a milestone look, the studio itself | Fable 5.2 | high | Section 8 |

- **Effort: medium by default, high when the work earns it** (founder,
  2026-11-12). Medium to high buys the most quality per extra token;
  above high the returns fall while the cost keeps rising. High for a
  first of its kind, a spec, taste at scale, tricky logic, or anything
  costly to redo; low for exact facts and mechanical work; xhigh or max
  only when a wrong answer would cost repeated rounds. Effort is how
  hard a model works and the model is how smart it is: not smart
  enough, a bigger model; not careful enough, more effort. The
  project's own data is too thin to settle the split; revisit it when
  measured.
- **Split** when acceptance is a test and the files are separate. **Keep
  whole** when acceptance is an eye, when the files overlap, or when
  handing the work down would lose more than it saves: one capable owner
  working without interruption is often better and no dearer. Work that
  is judgement from end to end may go to Fable whole, to design and to
  apply in one pass, as this system was. Delegating is a tool, not a
  chain of command.
- **A fix round or a follow-up:** continue or start fresh, case by
  case. Continuing keeps what the agent learned; a fresh agent with the
  defect list is cheaper past about 200,000 tokens or after a long idle,
  but loses what the brief does not say.
- **Do it yourself** when it is the board, the founder log, a brief, a
  premise you are about to build on, or quicker than a brief: up to about
  ten tool calls with no build or fix loop in them. The smallest agent
  costs $0.70 to $1; ten of your own turns cost about the same and lose
  nothing in the hand-off.

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

A brief names its desk, and the agent reads that desk's book
(`docs/desks/<desk>/`): the brief then carries only the row, its facts
at the commit and its acceptance. A row that is already exact in the
desk's plan is briefed in three lines.

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
- You write the routine briefs inside a route, because you hold the
  live state. Fable writes the route, and a spec when the routing
  table's fourth row applies.
- When you catch yourself writing "use your judgement" in a Sonnet
  brief, the work is Opus's or the spec is not finished.

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

Pofu code is merged by the lead on green CI, after a look at the frames
where an eye must accept it; GitHub auto-merge is not used. Only a
delivery of takes in `pofu-art` merges itself (section 6, "Little waits"). Batch your
merges: one wake-up per wave, never a loop on status.

## 6. Memory and your own context

- **The repository remembers; the chat does not.** `now.md` (where things
  stand), `product/founder-input.md` (what he said and how it was
  handled), `product/decisions.md` (what is decided), `state/` (what
  exists), ADRs (only for decisions whose reversal costs days). Anything
  shown to the founder is committed the same day.
- **When you start or resume** (a new session, after a compaction, after
  a long pause): fetch; read `now.md` from the open handoff branch if
  there is one, otherwise from `main`; run
  `python3 -I tools/studio/pulse.py`; read the founder log's standing
  decisions and the entries after the date in `now.md`; look at the
  factory (section 9). On the first founder message after six hours or
  more, run the route (section 10). If something you need was said
  before a compaction, a scout searches the transcripts for the exact
  words (`~/.claude/projects/*/*.jsonl`; `recall.py` is planned,
  section 10).
- **Write first, then act.** A founder message that changes direction, a
  decision, an agent sent out: write it to `now.md` or the founder log
  and push it to the day's handoff branch (one open docs PR a day)
  before the work it causes starts. The platform also compacts this
  session unasked, at the window's end and after a pause of an hour or
  more above 200,000 tokens (four of the first eight compactions). If
  the pushed `now.md` is true, none of them loses anything.
- **Your context: a working band.** The aim is a balance: enough to
  remember well and never lose the thread, lean enough for a budget many
  agents share. A compaction leaves you at about 100,000 tokens, the
  bottom. Up to 250,000, work, and never compact to save money: the
  whole range costs a few dollars a day. From 250,000, at a pause,
  finish the handoff and end your message to the founder with one line
  he can paste, written for that moment:
  `/compact Keep word for word: <his messages not yet logged; agents in
  flight; decisions not yet in now.md>. The rest is in docs/now.md.`
  Past about 400,000, where a turn costs twice what it does at 150,000,
  ask more firmly at the next pause, never in the middle of work. He
  compacts by hand and pasting is his choice each time; nothing is set
  to do it for him. `python3 -I tools/studio/session_cost.py` shows
  each day's average and largest context.
- **Little waits for a session.** Deliveries of takes merge by a
  workflow in `pofu-art`. A scheduled wake was refused twice by the
  permission check, so none is set: an agent's hand-back or the
  founder's message wakes you. On a wake: read the board, check the
  queue's depth, start the next row of every free lane, write one line
  in `now.md`, and end. A wake that finds nothing says so in a line.
- **Batch your own writing.** The board, the founder log and the media
  shown go into one docs PR per pause, not one PR each.
- **The pulse** lists what changed for the player in the last week, from
  the `changes/` fragments. A desk missing from it for three days is
  either a decision written in `now.md` or a drift to correct.

## 7. The founder

- **Reply shape, in Turkish, short:** the image or video first; what
  changed (three lines at most); what you decided and why (one line
  each); what you need from him: nothing, or one question.
- **Cards, three a day at most, sent in the morning.** A card is one
  major direction: a picture or a sound, your pick, and a time ("Yarın
  12:00'ye kadar cevap gelmezse A ile devam ediyorum"). No work waits
  for a card: what agrees with what he has said and can be built is
  built meanwhile (founder-input 48), and a different answer is a
  change, not a restart. Everything smaller he judges on his phone.
- **He may open a session on a desk** by writing `Masa: <desk>`. It
  works that desk from its book and writes his words into that desk's
  plan; you see its work on the board.
- **Say only what you checked in this session.** Mark the rest "kontrol
  etmedim". Three corrections to him in one week came from statements
  made from memory.
- **Log every message,** item by item with how it was handled, one line
  each, at the bottom of `product/founder-input.md`.
- **His phone.** The demo is his own iPhone, played hands-on in
  Rehearsal mode and sometimes shown to friends. He installs builds through a
  separate cloud session that pulls the repository and installs the
  latest build, so what is on `main` is what he plays: keep it green and
  playable, and tell him when something on it is worth trying. How device
  testing is run (a rhythm, a checklist, measurements) is not designed
  yet; it will be, with him.

## 8. Fable 5.2

The most capable model and the most expensive per token (about 2.4 times
Opus). It has a real limit, and the whole project has used only a few
percent of it. With a bounded read and a few turns it costs little:
three consults cost about $3 of $749 in eight days, and one of them cut
an art batch from 54 jobs to 16. As a standing lead or a routine builder
it would cost a great deal (principle 2).

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
6. **A state assessment:** when the founder asks for a general look,
   and at a large job's start (`studio/state-brief.md`: fixed inputs, 20
   lines back). Routine checks stay with the lead. Open: whether Opus,
   given Fable's past passes, can match them; try once side by side.

Three doors. You spawn Fable for the route, for the moments above and
for a large spec. The founder's side channel (the previous lead
session, which stays open) spawns it for anything he starts and
whenever the lead or the studio is what is being judged: you do not
choose what your own judge reads. A scheduled session is held back; it
is the answer if the route is skipped on two working days in a week.

Who sees it turns on what the work touches. A brief or an answer that
changes the studio system itself (section 10 says what that is) reaches
the founder before it runs or is applied: the system is his
responsibility. A consult or a spec on work the system already covers
(how an in-game UI system should work, a premise, a look) runs at your
judgement. The route's brief stands and runs without being shown again;
a system change it proposes goes to him first. When you are unsure
which side a task is on, ask him. Log each use in the founder log with
the reason and the usage line; a route is one line in `now.md`.

The brief is the Fable row of "Briefing by model", and says besides:
that it is the most capable model in the family; that the rules, the
founder's views and the brief's own framing are evidence to weigh, not
authority; that everything outside the fixed constraints can change;
that the deliverable is a file a cold reader can act on. Its answer is
advice until the founder and the lead accept it; say in the log what it
changed.

## 9. Desks and lanes

A desk is a line of work with its own truth, plan and acceptance. The
desks, their lanes and the rules that keep their books true are in
`docs/desks/README.md`; the art factory's rules are the art desk's
charter (`docs/desks/art/README.md`).

- **You run the route, the desks run themselves.** The route (the plan
  of record in `now.md`) says whose turn the Swift lane is. A desk's
  plan says what is next for that desk. `python3 -I
  tools/studio/board.py` prints every desk's first line, its `Now` rows
  and what it waits for: that is what you read on a wake, and what the
  founder is sent in Turkish.
- **A desk turn** is one agent, one desk, one row: it reads the desk's
  book, does the row, and moves the row in the same pull request.
- **Codex's pulse:** when you start or resume, read the open PRs in
  `pofu-art`; the first line of each PR body is its pulse line.
- **To add a desk:** write its book, add its row to
  `docs/desks/README.md`, and say what the founder will look at or
  listen to. One lead runs the route until two desks each need the
  founder daily; only then consider a second lead.

## 10. The studio improves itself

- **Friction.** Every hand-back ends with a `Friction:` line. Add those
  that are not "none" to `studio/friction.md` with a kind: `tool`,
  `brief`, `rule` or `platform`. For your own slips, add your context
  size and the turns since the last compaction. Each row is handled
  within a day: a `tool` row is fixed by a builder or gets a line in
  `now.md`; a `brief` row changes nothing unless it repeats.
- **Hygiene, at a pause:** merged worktrees still on disk
  (`git worktree list`), pull requests open more than two days,
  friction rows not handled, rule files over their caps, the date of
  the last route. It never changes a rule and never needs the founder.
- **The commands** (#411): `python3 -I tools/studio/session_cost.py
  --now` (context and turns since the last compaction, in one line);
  `recall.py "<regex>"` (the exact words of a message a compaction
  dropped); `friction.py` (collects the `Friction:` lines); and the
  pulse's "Leftovers" block (the hygiene list above).
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
  day.
- **Caps.** `CLAUDE.md` 80 lines, a role file 80, a desk's charter 80
  and its plan 60: agents
  re-read them on every turn. This page 4,500 words (`wc -w`). It has
  one reader, so its length costs under a dollar on the heaviest day;
  the cap guards attention, and words measure that where lines do not
  (a fifth of this page sits in table rows, some seventy words long).
  At a cap, a new rule replaces or merges an old one. A change to a
  capped file is applied in a worktree and counted before it is
  proposed: this page once went from 298 lines to 405 on a proposal
  that capped it at 330 without counting.
- **A role is missing** when you have written the same procedure into
  two briefs, or an agent has handed back the wrong shape twice.
- **The loop is on trial.** After seven routes, count those that
  changed something. Fewer than three: move the route to chapter
  starts and on request, and say so here.
