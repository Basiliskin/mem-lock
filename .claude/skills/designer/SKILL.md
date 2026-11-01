---
name: designer
description: UI/UX designer step for LeaveCheck — builds 2 clickable, self-contained HTML prototypes with mocked state, lets the user pick or mix, then writes docs/design.md. Use after /architect, or when the UI needs rethinking.
---

# /designer

Follow `.claude/skills/_shared/PROTOCOL.md` throughout.

## Goal
Let the user feel the UX before code exists, then lock it into `docs/design.md`.

## Steps
1. Read `docs/requirements.md`, `docs/architecture.md`, and the profile.
2. Build 2 throwaway prototypes, `prototypes/variant-a.html` and `prototypes/variant-b.html`. Each is one self-contained file with inline CSS and JS, using mocked data shaped like the real contracts, and clickable through the main user journey and its error states. Make the layouts really different, not recolours.
3. Each variant must meet this checklist: current state is unmistakable; disabled actions say why; results and errors are clearly announced, including to screen readers; keyboard operable; AA contrast; works at 360px wide.
4. Tell the user how to open them and recommend one. They may pick, mix, or describe their own; iterate until they confirm.
5. Write `docs/design.md`: chosen layout with an ASCII sketch, component tree, design tokens, interaction rules and accessibility notes.

Prototypes hold mock logic only and are never imported by production code.

## Hand off
➡️ Next step: `/developer`
Suggested prompt: `/developer S0`
