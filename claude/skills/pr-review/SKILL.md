---
name: "pr-review"
description: "Review code changes from a local diff or PR context. Produce findings to be reviewed by a human and acted on by an agent. Findings base on inspected code and CLI-confirmed evidence"
---

# pr-review

Review the provided diff or PR context. Base every finding on inspected code, file paths, line numbers or explicit user provided context. If a concern depends on runtime behavior, browser behavior, CI status, coverage reports, or deployment state that you did not verify, report it as a risk or testing gap rather than a confirmed defect.

Do a indepth review of the diff and, if it is a PR stack keep the rest of the stack in mind. Check the full PR stack on github, as it is possible that stuff is added on a stacked PR. Always compare the diff to the actual PR base instead of master/main if there is one.

Let the user reiterate on the findings and decide which of them are actually relevant before posting any comments on the PR.

Do not mind positioning of a change in a big PR stack, it is more work to restructure the PR than it causes harm - if there are no security related gaps.

## additional review rules

- **Scope & Size:** The PR should do ONE logical thing. It should ideally be < 500 lines of code and < 50 files. Moves and logic changes must NOT happen in the same PR. The smaller the PR the better.
- **Testing:** Helper functions need unit tests, services/comms need integration tests, complex UI needs UI-tests. Bug fixes MUST include a test reproducing the bug.
- **Naming:** PRs and Commits must follow Conventional Commits (e.g., `feat(scope): Subject`).
- **Rollbacks:** Must contain ONLY code that does the rollback and link to the original commit.

## output format

1. List findings first, ordered by severity, with file/line references when available.
2. Separate confirmed defects from unverified risks or testing gaps.
3. Note any evidence you did not have.
