---
name: developer
description: Developer step for Geo Alert — implements exactly one vertical slice from docs/architecture.md, proposing options first, then writing code test-first. Use with a slice id, e.g. "/developer S1".
---

# /developer <slice>

Follow `.claude/skills/_shared/PROTOCOL.md` throughout.

## Goal
Deliver one slice, green and ready to commit, without scope creep.

## Steps
1. Read the slice in `docs/architecture.md`, its acceptance criteria in `docs/requirements.md`, and `docs/design.md` if the slice has UI. If no slice was given, pick the next unfinished one and say so.
2. If the slice has real implementation choices, propose 2–3 options and wait. Otherwise state your approach and continue.
3. Work test-first where logic exists: failing test, code, green. Cover the happy path and the negative cases in the criteria.
4. Follow the profile's **Engineering rules**.
5. Run the profile's test, lint and typecheck commands. Report real output and fix failures before handing off.
6. List changed files and propose a commit message. Commit only if the user asks.

## Hand off
If slices remain: `/developer S<next> <slice title>`.

When all slices are done:
➡️ Next step: `/qa`
Suggested prompt: `/qa verify the full build against docs/requirements.md and audit it against the project rules`
