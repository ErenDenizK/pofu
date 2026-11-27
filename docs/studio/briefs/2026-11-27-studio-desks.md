# Brief: the studio's desks, rules and take auto-merge (2026-11-27)

Role: `.claude/agents/builder.md`. The founder approved the desks
(founder-input 49, card 3 item 1); the lead decided item 2: take-only
Codex deliveries merge by a workflow; pofu code stays lead-merged. The
design is `docs/studio/desks-2026-11-26.md` on main (sections 2, 4, 5,
6). Draft PR #524 (`docs/desks-proposal-1126`) holds the books but also
#523's commits, which are now squashed into main, so it cannot merge.

Three PRs:
1. **ST1 + ST2, pofu, branch `chore/studio-desks`** from `origin/main`:
   the desk books (`docs/desks/**` taken from #524's head
   `fb74b4da`), the patch `docs/studio/proposals/desks-2026-11-26.patch`
   applied to `docs/studio.md` and `CLAUDE.md`, and the art-reviewer line
   (section 5 item 3). Adjust to facts since: S6(a) GitHub auto-merge for
   pofu is NOT adopted (lead-merged after a frame look); S6(c) the
   scheduled wake was refused twice by the permission check, so write the
   fallback (agents' hand-backs and his messages wake the lead; pofu-art
   takes merge by workflow). Keep `docs/studio.md` under 4,500 words and
   `CLAUDE.md` at most 81 lines; run `python3 -I tools/docs/check_links.py`.
   Then close #524 with a one-line comment pointing at the new PR.
2. **ST4, pofu-art, branch `chore/merge-takes`**: the workflow of
   section 4b (`.github/workflows/merge-takes.yml`) that merges a PR
   whose every changed path is under `design/art/takes/` (merge commit,
   never squash), leaves anything touching `QUEUE.md` or code alone, and
   the `AGENTS.md` paragraph of section 5 item 4. Check pofu-art's
   Actions permissions allow a workflow to merge (GITHUB_TOKEN with
   `contents: write`, `pull-requests: write`); say if a repository
   setting the lead cannot change blocks it.
3. ST3 (the board tool) is out of scope for now.

Sparse worktrees (docs only); disk floor 5 GB. Git identity: user.name
"Eren Deniz Kuyucaklıoğlu", user.email
"109629701+ErenDenizK@users.noreply.github.com"; commits end with
exactly `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` and
`Claude-Session: https://claude.ai/code/session_01GwfTHREtdp7pj7j3uZDC2i`.
PR bodies end with `🤖 Generated with [Claude Code](https://claude.com/claude-code)`,
a blank line and the session URL. Open PRs with the GitHub MCP tool; do
not merge. Hand back: both PR links, the word and line counts, and what
did not apply. At most 10 lines.
