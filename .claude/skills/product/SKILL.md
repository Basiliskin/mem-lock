---
name: product
description: Product-owner step for Geo Alert — turns the brief into user stories with testable acceptance criteria and a scope cut. Use first in the chain, or when requirements or scope need revisiting.
---

# /product

Follow `.claude/skills/_shared/PROTOCOL.md` throughout.

## Goal
Produce `docs/requirements.md`, the single source of truth for what gets built.

## Steps
1. Read the brief and other sources named in the profile. If the brief is `unknown`, ask for it before drafting. The brief wins over any inspiration material.
2. Draft user stories: `As a <user> I want … so that …`.
3. Write Given/When/Then acceptance criteria for each story, including negative cases. These become the QA checks.
4. Propose decisions on anything ambiguous and wait for answers.
5. Propose a MoSCoW scope cut sized to the time budget; the user confirms it.
6. Write `docs/requirements.md` with stories, criteria, scope and out-of-scope. Update the glossary and profile if needed.

## Hand off
➡️ Next step: `/architect`
Suggested prompt: `/architect design the structure, interfaces and vertical slices for docs/requirements.md`
