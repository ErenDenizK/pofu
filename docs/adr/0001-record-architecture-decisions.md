# 0001. Record architecture decisions

- **Status:** Accepted
- **Date:** 2026-10-31

## Context

The project is built by a founder working with an AI engineering agent across
many separate sessions. Neither party keeps reliable memory between sessions,
so the reasoning behind decisions must live in the repository itself.

## Decision

We record every expensive-to-reverse decision as an ADR in `docs/adr`, using
the template in this directory. ADRs are numbered sequentially and never
edited after acceptance except to update their status.

## Consequences

- Any future session can reconstruct why the system looks the way it does.
- Re-litigating settled decisions requires a new ADR, which forces new
  arguments rather than repeated ones.
