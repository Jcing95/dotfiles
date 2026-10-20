---
name: "work-status"
description: "Executive status report over the user's open GitHub PRs, PRs where review is requested from them personally, and their open ClickUp tasks, with next steps prioritized by the Eisenhower matrix. Strictly read-only. Use when the user asks for their status, work overview, what to do next, or a morning/daily report on PRs and tasks."
---

# work-status

Strictly read-only: never comment, review, rerun, request reviewers or change ClickUp tasks. Gather all data in parallel in one turn, no subagents. Use `$TMPDIR` for temporary files. Render ClickUp tasks as `[name](url)` and PRs as `[repo#n](url)`.

## 1. Gather (in parallel)

GitHub login: `gh api user --jq .login`. Write the query to `$TMPDIR/ws.graphql`:

```graphql
query($q:String!){search(query:$q,type:ISSUE,first:100){issueCount nodes{... on PullRequest{
  number title url isDraft createdAt updatedAt headRefName baseRefName body mergeable reviewDecision additions deletions
  repository{nameWithOwner defaultBranchRef{name}} author{login}
  reviewRequests(first:20){nodes{requestedReviewer{__typename ... on User{login} ... on Bot{login} ... on Team{name}}}}
  reviews(last:50){nodes{author{login} state submittedAt}}
  reviewThreads(first:100){nodes{isResolved comments(first:1){nodes{author{login}}}}}
  commits(last:1){nodes{commit{statusCheckRollup{state contexts(first:100){nodes{__typename
    ... on CheckRun{name conclusion status} ... on StatusContext{context state}}}}}}}
}}}}
```

Run it twice:

```bash
gh api graphql -F q="is:open is:pr author:<login> archived:false" -F query=@$TMPDIR/ws.graphql > $TMPDIR/ws-own.json
gh api graphql -F q="is:open is:pr user-review-requested:<login> archived:false" -F query=@$TMPDIR/ws.graphql > $TMPDIR/ws-review.json
```

`user-review-requested` matches personal requests only; do not use `review-requested`, which includes team requests.

ClickUp: `clickup_resolve_assignees(["me"])`, then `clickup_filter_tasks(assignees=[<id>])`, paging until `has_more` is false.

## 2. Own PR states

Compute all flags that apply, in this order:

| Flag | Rule |
|---|---|
| Merge conflict | `mergeable == CONFLICTING` |
| CI red | rollup `FAILURE`/`ERROR`; name the failing checks |
| Review to address | `reviewDecision == CHANGES_REQUESTED`, or unresolved threads whose first comment is by a human other than the user |
| Copilot comments open | unresolved threads whose first comment is by `copilot-pull-request-reviewer*` |
| CI pending | rollup `PENDING`/`EXPECTED` |
| Draft | `isDraft` |
| No Copilot review requested | no Copilot bot in `reviewRequests` and no Copilot review |
| No human review requested | no `User` in `reviewRequests` and no review by a non-bot other than the user |
| Awaiting review | a human is requested or has commented, no approval yet |
| Ready to merge | `reviewDecision` is `APPROVED` (or null with a human approval), CI green, not conflicting, not draft |

Team requests are usually auto-added by CODEOWNERS and do not count as a human review request; list them in the table only. `mergeable == UNKNOWN` is not yet computed by GitHub, so do not flag it. Stacked PR (base differs from `defaultBranchRef`): note `stacked on <base>`, and "Ready to merge" becomes "approved, waiting on base".

## 3. Review requests

For each: author, size (`+additions/-deletions`), age (`createdAt`, or the user's last review if any), whether the user already reviewed (re-request), CI state, draft.

## 4. ClickUp tasks

- `backlog`: not planned, low priority by default.
- `merged`: flag "close task".
- Cross-link: a PR belongs to a task when its title, body or branch contains `CU-<id>` or the task id. A task `in review` inherits the PR flags. Flag mismatches: `in progress` with an open non-draft PR (move to `in review`), `in review` without an open PR.

## 5. Eisenhower mapping

- **Q1 Do now** (urgent, important): own non-draft PRs with merge conflict, CI red or review to address; ready-to-merge PRs; review requests waiting more than 1 business day; non-backlog tasks overdue, due within 1 day, or priority `urgent`.
- **Q2 Schedule** (important, not urgent): `in progress` / `in review` tasks with priority high, normal or none; review requests younger than 1 business day; Copilot comments to address; drafts with activity in the last 30 days.
- **Q3 Quick admin** (urgent, low value, under 2 minutes each): request Copilot review, request a human reviewer, rerun CI failures that look flaky (infra, timeouts), close `merged` tasks, fix ClickUp/PR status mismatches.
- **Q4 Later / drop**: backlog tasks (move to Q2 with a note if urgent or overdue), low-priority tasks idle more than 30 days, drafts idle more than 30 days (suggest closing).

Within a quadrant sort by ClickUp priority (or PR severity order from step 2), then by age, oldest first. Group several actions on one PR into one line.

## 6. Report

Terminal markdown, concise:

1. One headline line: counts of own PRs, review requests and open tasks, plus the biggest blocker.
2. `## Q1 Do now` to `## Q4 Later`: numbered actions, verb first, linked item, short reason, e.g. `Fix CI on [codesphere-monorepo#123](url): lint, unit-tests`. Omit empty quadrants.
3. Tables:
   - Own PRs: `PR | Flags | CI | Reviews | Age`
   - Review requests: `PR | Author | Size | Waiting`
   - ClickUp tasks: `Task | Status | Priority | Linked PR`
