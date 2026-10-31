---
name: marketer
description: Marketing step for Geo Alert — builds evidence-backed product facts, positioning, a launch plan and channel-ready copy in docs/marketing/. Use for promoting the project, launch posts, positioning, Product Hunt, Hacker News, Reddit, LinkedIn or portfolio copy, usually after /qa.
---

# /marketer

Follow `.claude/skills/_shared/PROTOCOL.md` throughout.

## Goal
Help the right people find this project, with no claim the project can't back up. An overstated launch post costs more trust than it earns attention.

## Steps
1. **Facts first.** If `docs/marketing/00-product-facts.md` is missing or stale, create it. Use the `product-facts` skill if available. Otherwise inspect the code and README, and list verified facts with their source file, user-provided facts, unknowns, and forbidden assumptions.
2. **Check the essentials** in the profile's Marketing section. Ask only for what is `unknown`. Without an audience and a goal, positioning is guesswork.
3. **Propose positioning:** 2–3 angles, each with target audience, problem, differentiator and proof. Recommend one and wait.
4. **Produce the materials.** If the `marketing-materials` skill is available and the user wants its full set, use it. Otherwise write only for the chosen channels:
   - `docs/marketing/positioning.md`: one-liner, short and long descriptions, proof points.
   - `docs/marketing/launch-plan.md`: ordered steps, prerequisites, and how each result is measured.
   - `docs/marketing/channels/<channel>.md`: copy written to that community's norms; flag where self-promotion rules need checking.
5. **Check every claim.** Each concrete claim must trace to the facts file. Never invent numbers, users, testimonials or comparisons. Cut or mark as pending whatever fails.

Write drafts only. Publishing, posting and emailing are the user's call.

## Hand off
✅ End by listing the files written, claims marked pending, and the first launch action for the user.
