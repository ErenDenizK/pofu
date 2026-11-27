# Brief: PR 1a, station looks per light (2026-11-26)

Role: `.claude/agents/builder.md`. Step 1 of the main-flow plan
(`docs/design/mainflow-plan-2026-11-26.md` on main, #519): stations grow
on the island. Read section 4 (D1-D3) and section 6, row **1a**; that
row is your spec (branch `feat/looks-per-light`, owned files, change,
acceptance, fallback). No art in this PR.

In short: `StationLooks.light` becomes `lights: [String: [Int]]` (light
to base stages); golden draws the day look under `harmony`'s golden
grade; a missing look draws the nearest lower one; the old key still
decodes. New cases in `PlateCompositorTests` and `HomePlateDataTests`;
the `path-stall-*` frames must stay unchanged byte for byte (label the
PR `screens` once it is open, to render them, and compare against
`screenshots/main` with `tools/review/fetch_frames.sh`).

Check every claim in the plan against the code before you build on it;
a false premise is a result. Own worktree from `origin/main`; Swift
tests only through `tools/swift/test-linux.sh`. Add
`changes/feat-looks-per-light.md` only if the change is user-visible
(it should not be). At most 3 pushes after the PR opens.

Hand back: the PR link, CI state, the frame comparison result, and
anything in the plan that proved wrong. At most 12 lines.
