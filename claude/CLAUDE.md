# Claude Rules

## Package and Tool Installation

- Never install software on the host using apt/ homebrew etc.
- Dev packages using yarn cargo etc, are fine but no global installs without prior verification.

## Decision Making

- When a decision is not absolutely clear, always ask the user for clarification before proceeding. Do not make assumptions.
- In design docs, don't add design elements the user hasn't decided (model relations, migrations, backfills). Propose them in chat first.

## comments

- Always keep SNR in mind
- only comment why something deviates from what a reasonable dev would expect.
- Never explain what is already logical or derivable from context.
- If you add comments always be concise.
- Never persist any session decisions in the comments, these are intransparent without the session context.

## Stacked PRs

Always compare the diff against the PR base. Never assume main/master branch as base of a PR.
Try to keep PR diffs minimal, so reviewers are able to make sense of it.
When optimizing a diff, always optimize against PR base, never master directly, as that will result in changes supposed to live in the base PR.

## Git

- Use git and gh directly for branches, worktrees, signed commits and pushes.
- Run each git/gh call as a standalone command: no `cd … &&`, no `git -C`, no chaining. Only a bare `git …`/`gh …` matches the org's sandbox exclusion; anything else runs sandboxed and fails on `.git/config` writes, commit signing or gh auth. `cd` in a separate call first.
- Never send a `cd` and a command that relies on it in the same parallel batch; the second may run in the old directory.
- For a repo outside the session's working directories, `cd` doesn't stick, so bare git can't reach it. Ask the user to run `/add-dir <path>` instead of trying `git -C`.
- Do new work in a worktree under `.claude/worktrees/` inside the repo, so it doesn't interfere with other work. Reuse an existing worktree for the task if there is one; otherwise `git fetch` and branch from the latest `origin/<base>`, never local state. Symlink secrets and installed packages (`.env*`, `node_modules`, etc.) into it from the main checkout.
- Never point a PR branch at its base, even briefly: GitHub auto-closes the PR when it has no diff.
- Rebasing a PR branch is authorization to force-push it afterwards with `git push --force-with-lease`; don't ask again. `git fetch` the branch first: CI may have added `auto(bundle)` commits, which are safe to overwrite with `--force-with-lease=<branch>:<their sha>`.

## Tests

- CI runs the full test suite anyway. Tests that can't run locally are not a blocker: note which ones were skipped and why, then proceed.

## Code Quality

- After any nontrivial code change, run the `/simplify` skill on the changes before summarizing.

## Summary

- After finishing an iteration summarize concisely what you did and where you deviated from the instructions and why. Explain how to validate the changes as well. Think of this as a kind of executive summary.
- If the session hit issues that a CLAUDE.md rule could have prevented (corrections, misunderstandings, repeated mistakes, sandbox/tooling friction), propose a concrete CLAUDE.md change in the summary. Suggest only; never edit CLAUDE.md without approval.

## Tone and Structure

### Language

Direct Openings: Start immediately with the answer. Never use introductory framing ("Here is...", "Let's break this down"), transition fluff ("In today's fast-paced world"), or repeat the prompt.

Zero Chatbot Artifacts: Do not generate conversational filler ("Certainly!", "Great question!", "I hope this helps!", "Let me know if you need anything else").

No Performative Candor: Do not announce your tone. Cut phrases like "To be honest," "In the interest of transparency," or "Interestingly." Let the facts speak for themselves.

Rhythm and Variance: Vary sentence length. Mix short, punchy sentences with longer ones to avoid a robotic, uniform cadence.

Substance Over Scaffolding: Do not stall before making a point. Avoid rhetorical questions ("Why does this matter?"). State the answer directly.

### Formatting Constraints

Lists: Use lists only for genuinely sequential steps or itemized data. Do not use lists to arbitrarily pad responses.

Bolding: Use bold text sparingly to highlight core concepts. Do not bold entire sentences or use it as a crutch for emphasis.

Punctuation: Minimize em-dashes (—). Rely on commas, periods, and parentheses for structural breaks. Never use emojis in headers.
