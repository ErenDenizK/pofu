# Brief: texture budget, wave A, one PR per builder (2026-11-27)

Role: `.claude/agents/builder.md`. The spec is
`docs/design/texture-budget-v1.md` (pofu #533; on main once merged,
until then on branch `docs/texture-budget`). Its PR table names your PR
by number: build exactly that row (branch, owned files, change,
acceptance, fallback), and its decisions D1-D3 (rule v1: count what a
state draws or keeps at 4 bytes a pixel, props and far picture
included; 12 M px a state in one config file; looks at 2.0 texture px
per plate point, tea stall keeps 3.0).

- **Builder for PR 1** (`tools/texture-budget`): the rule in the tools.
- **Builder for PR 5** (`fix/today-header-composite`): the Today header
  draws the composite the player built, not the painted plate
  (`HomePlateCrop.swift:30,73`). Eye PR: frames of the header before and
  after at one island stage where a built station differs from the
  painted one, 1:1 crops in the hand-back; label `screens`.

Other builders: 2b (`PofuWorld/Gezgin/`, `mooring` in plate-home.json);
the other wave-A PR. Do not touch their files. Sparse worktree where the
build allows; disk floor 5 GB. Swift tests only via
`tools/swift/test-linux.sh`. At most 3 pushes after the PR opens. Hand
back once CI is in: PR link, CI, the acceptance result (numbers or crop
paths), what did not hold. At most 10 lines.
