---
name: architect
description: Architect step for Geo Alert — designs structure, domain model, interfaces and an ordered list of vertical slices. Use after /product, or when structure or API decisions need revisiting.
---

# /architect

Follow `.claude/skills/_shared/PROTOCOL.md` throughout.

## Goal
Produce `docs/architecture.md`, shared interface definitions if the stack needs them, and ADRs for hard-to-reverse choices.

## Steps
1. Read `docs/requirements.md` and the profile's stack, rules and settled decisions. Treat those decisions as fixed. Inspect the existing code so the design extends what is there.
2. Propose only the decisions this project really has, in one round. Typical ones: domain model and boundaries, layering, interface contract and error shape, data storage, client state, configuration.
3. Write `docs/architecture.md`: a context diagram (mermaid), folder tree, domain invariants, interface and error tables.
4. End it with **ordered vertical slices**, `S0`, `S1`, …, each deliverable and testable alone and each mapped to acceptance criteria.

## Hand off
➡️ Next step: `/designer`
Suggested prompt: `/designer build 2 clickable HTML prototypes per docs/requirements.md and docs/architecture.md`
