# Playbook: what Pofu taught us about building an app with AI agents

Portable lessons for a new project (app + design + UI + generated art,
built by a lead model, sub-agents and an image tool). Written 2026-11-10.

## 1. Decide the visual system before producing assets

- Pick the final look on **real screens**, not on concept sheets. Pofu lost
  weeks because concepts looked great and the app looked like mud.
- Write one living doc for the visual system (ours:
  `docs/design/visual-system.md`): what is one painting, what is a layer,
  how colour, light, states and resolution work. Every brief cites it.
- **Never assemble a scene from separately generated pieces.** Separately
  painted objects never share light, contrast or grounding. Generate the
  whole screen as one picture; separate only what moves (characters,
  motion cut from the picture itself), switchable light and UI.
- **Never plan to fix colour with filters.** Generate at final colour and
  contrast. A filter can only make a picture worse in a new way.
- Run a **ladder** early: the same picture at 2–3 levels (colour,
  contrast, density), judged in the app, then hold the winner with measured
  bands (`tools/plate/colour_metrics.py`).
- Generate at the tool's largest size, at phone aspect, at the in-app
  framing. Never halve deliveries. Upscale only after an in-app A/B.

## 2. Show only the real thing

- The founder reviews real in-app screenshots at device resolution, never
  mock-ups. The lead looks first and is harsh.
- Every image shown is committed the same day with what was decided.

## 3. Roles and models

- **Lead (strongest model):** product, design and engineering judgement;
  writes briefs precise enough for a cheaper model; looks at every visual.
  Keeps its own context lean: reads sheets and short reports, never logs.
- **Builders (mid model):** implement one brief each, in their own
  git worktree and branch; at most three at once.
- **Checkers (small model):** mechanical checks (floating objects, UI
  overlap, metrics in band) returning pass/fail lists.
- **Image tool (Codex here, Higgsfield next):** runs a manifest of jobs
  with fixed prompt blocks; its own model can be the cheap one, because
  the brief does the thinking and the image model does the painting.
- Use the top model only where judgement decides quality: the visual
  system, the first screen, architecture, hard bugs.

### 3.1 Briefing the consultant model (Fable 5.2)

The most capable and most expensive model; its use draws on a shared weekly
limit. Use it where the lead's own judgement is the bottleneck: the four
checkpoints in `docs/state/README.md`, a design that must be a masterpiece,
an architecture that is costly to reverse. Not for building, checking or
anything a brief can make routine.

- **Brief the goal, not the steps.** Say what outcome is wanted, why it
  matters, the constraints that are decided (link them), and what "done"
  looks like. Do not prescribe method; it plans better than a checklist.
- **Give ownership.** It owns the answer and should finish the whole task
  in one pass, not stop to ask; open questions go in its report.
- **Point, don't paste.** Name the exact files and sections to read and the
  ones to skip; it reads them itself.
- **Ask for a report a cold reader can use:** the recommendation first,
  the reasons, the risks, what it would cut; short.
- **Say what it costs.** It may start sub-agents only if a task truly
  needs them; prefer reading itself.
- **Effort:** high by default; max only when the user asks.
- **One pass, then the lead decides.** Its view is advice; the lead keeps
  the context and the decision. Log what it changed in the founder log.

## 4. Briefs

- Name exact files, sections and decisions; say what is out of scope;
  give the acceptance check (a screenshot, a metric, a test).
- State decisions as decided ("do not re-litigate").
- Ask for a short report: PR, CI, verdict, what the brief did not cover.

## 5. Memory lives in the repo, not in the chat

- A founder log (every message, item by item, with how it was handled),
  a tracker, a roadmap, the visual-system doc, few ADRs.
- ADRs only for decisions whose reversal costs days; everything tunable
  lives in config and living docs.
- Then compaction loses little: compact at about 70% of context, and
  `/compact <focus>` at the end of a chapter.

## 6. Process

- Every change through a PR; one logical change per commit; merge only on
  green CI. Commit and push early (cloud containers restart).
- CI without polling: wait once, check once, fix at most twice.
- Pilot one item end to end before scaling a batch; never regenerate what
  a fit can fix, never fit what should be regenerated.
- The image tool never idles: queue its next batch before reviewing the
  last one; keep at least 1 GB free disk for it.
- Repeatable pipelines (delivery review, screen ingest) become scripted
  workflows once they have run by hand twice.

## 7. Mistakes not to repeat

- Tuning runtime light and colour layers on top of a collage.
- Pastel/"muted" style prompts plus a chroma clamp plus a runtime grade:
  three small "safe" choices that together made everything pale.
- Screenshot fixtures with seeded weather: measure the clean state.
- Reporting a cause before verifying it.
