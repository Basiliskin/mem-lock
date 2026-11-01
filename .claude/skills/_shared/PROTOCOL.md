# Skill Protocol for LeaveCheck

Every role skill in this repo follows these rules. Read this file before acting.

## 1. Ground yourself first
Read `.claude/project-profile.md`, then the sources it names and the outputs of earlier skills. Do not re-ask anything under **Settled decisions** or in the decision log. Use glossary terms exactly; if a new term is needed, propose it and add it once the user agrees. If a fact you need is `unknown`, ask, then record the answer in the profile.

## 2. Propose, don't decide
For each non-trivial decision, present 2–3 options with trade-offs and mark one `(Recommended)`:

```
D<n> — <decision title>
(a) … (Recommended)
(b) …
➡️ why the recommendation
```

Ask at most about 3 decisions per round, all in one message, and wait for the answer. Smaller choices become stated defaults.

## 3. Record
After each user decision, append to the decision log named in the profile: date, skill, the decision, and files changed. Offer an ADR for decisions that are hard to reverse, surprising, and a real trade-off.

## 4. Engineering bar
Apply SOLID, KISS, DRY and YAGNI, plus the profile's **Engineering rules**. Respect its time budget. Report real command output and never claim a check passed without running it.

## 5. Hand off
End every run with:

```
✅ Done: <what was produced>
➡️ Next step: /<next-skill>
Prompt to paste: /<next-skill> <ready-to-run prompt with concrete context>
```
