# 0007. Product and character name: Pofu

- **Status:** Accepted
- **Date:** 2026-10-31

## Context

The working codename "Rot" names the product after the problem and sits in
the shadow of Brainrot and Unrot. Three directions were explored in
[naming-exploration.md](../archive/naming-exploration.md): Kor (ember), Pofu
(fluffball), and Hop (interjection).

## Decision

The product and its companion are named **Pofu**, from the Turkish
_pofuduk_ ("fluffy, puffy"). "Pofu" is both the app name and the companion's
species; each user can give their own Pofu a personal name.

"Hop!" survives as Pofu's catchphrase in the intervention moment
(_"Hop! Nereye?"_ / _"Hop! Where to?"_).

Identifiers:

| Item | Value |
|---|---|
| App display name | Pofu |
| Bundle identifier prefix | `com.erendenizk.pofu` |
| App Group | `group.com.erendenizk.pofu` |
| Swift module prefix | `Pofu` (for example `PofuCore`) |

Bundle identifiers cannot change after the first App Store submission, and
the Family Controls distribution entitlement is requested per identifier.
These values are therefore final.

## Consequences

- Code, modules, and documents use "Pofu" from now on. "Rot" remains only as
  the repository name, which can be renamed on GitHub later (old URLs redirect
  automatically).
- Before launch: trademark checks (TÜRKPATENT, EUIPO, USPTO), domain, and
  social handles. If a blocking conflict appears, the in-app character name
  can stay while the store listing name changes.
