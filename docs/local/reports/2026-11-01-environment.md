# T1: Local environment on the founder's Mac

Date: 2026-11-01. Brief: `docs/local-agent.md` (T1), read from the
unmerged `docs/local-agent` branch because it is not on `main` yet.

## Result

The Mac is ready to build Pofu. `xcodegen generate` succeeds and the
project lists the expected schemes.

| Item | State |
|---|---|
| Machine | MacBook Pro, Apple M1 Pro, macOS 26.3.1 (a) |
| Xcode | 26.6 (17F113), selected at `/Applications/Xcode.app` |
| Simulator runtime | iOS 26.5 (23F77); iPhone 17 available |
| Homebrew | 6.0.22 |
| XcodeGen | 2.46.0, installed in this task with the founder's approval |
| `Config/Local.xcconfig` | Created from the example; git-ignored |
| Bundle ID | `com.erendenizk.pofu.dev` |
| Team | Free Personal Team, read from Xcode's signed-in account |
| Schemes | Pofu, PofuCompanion, PofuCore, PofuDesignSystem, PofuPersistence, PofuScreenTime |

## Notes for the lead

- `docs/local-agent.md` lives only on the `docs/local-agent` branch.
  Merge it so the brief and the `CLAUDE.md` pointer reach `main`.
- The brief's clone URL is `ErenDenizK/rot.git`; the repository is now
  `ErenDenizK/pofu`. Update the URL when you merge the brief.
- The GitHub CLI (`gh`) is not installed on the Mac. Branches are pushed
  with git over HTTPS.
- No secrets are committed. The team ID stays in the git-ignored
  `Config/Local.xcconfig`.
