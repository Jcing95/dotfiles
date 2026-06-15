# Claude Rules

## Git Operations
- Read-only git commands (log, diff, status, show, blame, etc.) are allowed.
- `git commit` and `git push` are never allowed — do not attempt them.
- `git rebase` requires explicit user approval before proceeding.

## Package and Tool Installation
- Never install packages, dependencies, or tools of any kind.
- All package manager install commands are blocked.

## Linting
- When a PR is ready, always run the linter and fix any issues before considering the task complete.

## Decision Making
- When a decision is not absolutely clear, always ask the user for clarification before proceeding. Do not make assumptions.
