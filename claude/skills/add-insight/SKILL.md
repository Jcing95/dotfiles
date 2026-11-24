---
name: "add-insight"
description: "Add a lesson learned (a rule, gotcha or workflow correction) to a CLAUDE.md, merged into the right section with minimal added context. Use when the user asks to add, remember or persist an insight or rule in CLAUDE.md, or approves a CLAUDE.md change proposed in a summary."
---

# add-insight

Every line in CLAUDE.md is loaded into every session. Add as little as possible and only what changes behavior.

## 1. Pick the target file

- Generic workflow, tooling or sandbox rule: the user's global `~/.claude/CLAUDE.md`. Resolve symlinks and edit the real file (`readlink -f`).
- Rule tied to one repo (its build, tests, conventions): that repo's `CLAUDE.md`.
- If it is unclear which applies, ask.

## 2. Distill the insight

Rewrite it as an imperative rule of one or two short sentences. Keep only:

- what to do or avoid, phrased concretely (commands, flags, file names),
- a short reason, only if the rule would look arbitrary without it.

Drop the story of how the problem came up, session specifics (PR numbers, branch names, dates), and anything the model already does by default or can derive from the environment. Explanations of tooling mechanics that don't change the action are noise: state the action.

## 3. Place it

Read the whole target file first, then in order of preference:

1. Already covered: change nothing and tell the user.
2. Contradicts an existing rule: show both and ask which wins.
3. Refines an existing rule: extend or reword that bullet instead of adding a new one.
4. Fits an existing section: append a bullet there, matching its style.
5. Nothing fits: add a new `##` section next to the most related one. Do not create a section for a single generic rule if a broader existing section can hold it.

## 4. Apply and report

Edit the file with the Edit tool, keeping the surrounding formatting. If the insight came from the user, apply it directly. If you inferred it yourself, show the proposed text and placement and wait for approval first.

Report the file, the section, and the exact text added or changed. Do not commit.
