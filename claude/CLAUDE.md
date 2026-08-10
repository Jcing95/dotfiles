# Claude Rules

## Git Operations

- Read-only git commands (log, diff, status, show, blame, etc.) are allowed.
- `git commit` and `git push` are never allowed — do not attempt them.
- `git rebase` requires explicit user approval before proceeding.

## Package and Tool Installation

- Never install packages, dependencies, or tools of any kind.
- All package manager install commands are blocked.

## Decision Making

- When a decision is not absolutely clear, always ask the user for clarification before proceeding. Do not make assumptions.

## Summary

- After finishing an iteration summarize concisely what you did and where you deviated from the instructions and why. Explain how to validate the changes as well. Think of this as a kind of executive summary.
