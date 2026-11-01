---
name: qa
description: QA and final-review step for LeaveCheck — maps each requirement to a test, runs all checks and a manual smoke run, audits the code against project rules, and checks release readiness. Use after the last /developer slice.
---

# /qa

Follow `.claude/skills/_shared/PROTOCOL.md` throughout.

## Steps
1. **Checklist:** in `docs/qa-report.md`, map each acceptance criterion to its covering test, or `manual`. Mark gaps.
2. **Run** the profile's typecheck, lint and test commands and paste real results. Start the app and smoke-test the main journey plus abuse cases from the negative criteria.
3. **Audit** the code against the profile's **Engineering rules**: boundary violations, duplication, dead code. Cite `file:line`.
4. Propose each fix as fix now, defer, or ignore, with a recommendation. Wait, then apply the chosen fixes, or hand larger ones to `/developer` if that skill exists.
5. **Release readiness:** accurate README and run instructions, an env example if needed, no committed secrets, and a clean install and run from scratch.

## Hand off
If gaps remain, fix them first. Otherwise:
➡️ Next step: `/marketer`
Suggested prompt: `/marketer create product facts, positioning and a launch plan`
