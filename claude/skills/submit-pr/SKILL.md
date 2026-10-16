---
name: "submit-pr"
description: "Review the branch locally with a reviewer subagent, push it and open a draft PR with a concise templated description and ClickUp link, self-assign, request a Copilot review, address valid review comments, mark the PR ready, and get CI green (fix PR-related failures, rerun unrelated ones, max 3 attempts). Use when the user asks to submit, open, or create a PR for the current work."
---

# submit-pr

Run the steps in order. Never force-push, never merge, never touch other PRs of a stack. Keep every fix minimal and scoped to this PR. Use `$TMPDIR` for temporary files.

## Judging review comments

Applies to both the local review (step 1) and the Copilot review (step 9). For each comment, read the referenced code and decide whether it is valid: a real bug, a real risk, or a clear improvement within the PR's scope. Style nitpicks contradicting repo conventions, speculative concerns, and out-of-scope suggestions are invalid. Apply all valid fixes and make one commit per review round (Conventional Commits message).

## 1. Local review

Determine the base first. `gh auth status` must succeed. Never assume main/master as base. `git fetch origin` so remote refs are current.

- If a PR for this branch already exists (`gh pr view --json number,baseRefName,isDraft`), use its base.
- Otherwise check for a stack: among open PRs (`gh pr list --state open --limit 100 --json headRefName`), pick the head branch that is an ancestor of `HEAD` (`git merge-base --is-ancestor origin/<ref> HEAD`) with the fewest commits in `git rev-list --count origin/<ref>..HEAD`. Fall back to the default branch (`gh repo view --json defaultBranchRef --jq .defaultBranchRef.name`).

All diffs below are `git diff origin/<base>...HEAD`. Stop and report if the current branch is the default branch.

Launch a reviewer subagent (Agent tool, `general-purpose`). Give it the base, the diff command and the ClickUp context if known, and instruct it to:

- review the diff in depth, following the rules of the `pr-review` skill (but not posting anything and not waiting for user input),
- not modify any files,
- return a list of findings, each with file, line, severity and a concrete description.

Judge its findings as described above, fix the valid ones and commit. Keep the rejected findings with a one-line reason for the summary.

## 2. Push

```bash
git push -u origin HEAD
```

Stop and report if the push is rejected. Do not force-push or rebase to make it work.

If a PR for this branch already existed in step 1, skip to step 8 (request Copilot only if it was never requested on this PR).

## 3. ClickUp ticket

Use the ClickUp ticket id already known from the current task or conversation and reference it as `CU-<id>`. If none is known, omit the link. Do not ask and do not search for one.

## 4. Title

Conventional Commits: `type(scope): subject`, derived from the diff against the base.

## 5. Body

Find the PR template: `.github/pull_request_template.md`, `.github/PULL_REQUEST_TEMPLATE.md`, `.github/PULL_REQUEST_TEMPLATE/*.md`, `docs/pull_request_template.md`, `pull_request_template.md` (case-insensitive).

- Fill it concisely: what the PR does and why. No file-by-file changelog.
- Remove sections that don't apply instead of leaving placeholders or HTML comments. Only tick checkboxes that are actually true.
- Put `CU-<id>` where the template asks for a ticket/issue reference, otherwise on the first line.
- No template: a short `## What` / `## Why` body.
- Append the PR attribution line from the session instructions, if any.

Write the body to a file in `$TMPDIR`.

## 6. Create the draft PR

```bash
gh pr create --draft --base <base> --title "<title>" --body-file "$TMPDIR/pr-body.md" --assignee @me
```

## 7. Request Copilot

```bash
gh pr edit <n> --add-reviewer @copilot
```

## 8. Wait for the Copilot review

Run in the background (Bash `run_in_background`) and wait for the completion notification instead of polling manually:

```bash
for i in $(seq 1 40); do
  c=$(gh api "repos/{owner}/{repo}/pulls/<n>/reviews" --jq '[.[] | select(.user.login == "copilot-pull-request-reviewer[bot]")] | length')
  [ "$c" -gt 0 ] && exit 0
  sleep 30
done
exit 1
```

On timeout (20 min), note it for the summary and continue with step 10.

## 9. Address Copilot comments

Fetch unresolved threads:

```bash
gh api graphql -F owner='{owner}' -F repo='{repo}' -F n=<n> -f query='
query($owner:String!,$repo:String!,$n:Int!){repository(owner:$owner,name:$repo){pullRequest(number:$n){
  reviewThreads(first:100){nodes{id isResolved path line
    comments(first:20){nodes{databaseId author{login} body}}}}}}}'
```

Consider threads where `isResolved` is false and the first comment's author starts with `copilot-pull-request-reviewer`. Judge them as described above, then:

- Commit the fixes and `git push`.
- Reply on every considered thread:
  ```bash
  gh api "repos/{owner}/{repo}/pulls/<n>/comments/<databaseId>/replies" -f body="..."
  ```
  Valid: `Fixed in <short-sha>.` Invalid: one sentence why it is not addressed.
- Resolve only fixed threads; leave rejected ones open for a human:
  ```bash
  gh api graphql -f id=<thread-id> -f query='mutation($id:ID!){resolveReviewThread(input:{threadId:$id}){thread{isResolved}}}'
  ```

Handle one Copilot round only. Do not re-request its review.

## 10. Mark ready

```bash
gh pr ready <n>
```

## 11. CI (max 3 attempts)

Wait for the **complete** CI before acting. Checks may take a moment to register after a push; if `gh pr checks` reports none, wait and retry. Run in the background:

```bash
gh pr checks <n> --watch --interval 30
```

Do not use `--fail-fast`. When it finishes and anything failed, gather all failures of the current head commit together:

```bash
gh run list --branch <branch> --commit "$(git rev-parse HEAD)" --json databaseId,name,conclusion
gh run view <run-id> --log-failed
```

Classify each failure:

- **Related to the PR** (the failing test, lint, type or build error touches code or behavior this PR changes): fix it.
- **Unrelated** (flaky test, infra/network, failure also present on the base branch): rerun with `gh run rerun <run-id> --failed`.

One attempt = one batch handling all failures of a finished CI run: commit and push all fixes together; rerun unrelated failures only if nothing was pushed (a push retriggers CI anyway). Then wait for the full CI again. Stop after 3 attempts and report what is still failing.

## 12. Summary

Report concisely:

- PR URL, base branch, ClickUp link (or that none was known)
- Local review: fixed findings (with sha) and rejected ones (with reason)
- Copilot comments: fixed (with sha) and rejected (with reason), or that the review timed out
- CI: final state, what was fixed vs. rerun, attempts used
