# Code Review Workflow

For reviewing an existing diff, branch or Pull Request when the user asks for a review (not the self-check at the end of a task; that is `REVIEW.md`). Read-only: do not modify files.

```text
SCOPE -> DIFF -> REVIEW -> FINDINGS -> (user decides) -> fixes as a normal task
```

1. **Scope.** Confirm what is being reviewed (`git diff <base>...<branch>` or the PR) and the task or requirement it should satisfy. Read the related task record if there is one.
2. **Diff.** Read the whole diff, not just the summary. Note files changed that the requirement does not explain.
3. **Review for:** functional bugs, edge cases, security issues (permission checks, exposed methods, secrets), performance problems (queries in loops, N+1), architecture or project-rule violations, regression risk, missing tests, unnecessary changes, and upgrade impact of customizations.
4. **Findings.** For each finding give: severity (High / Medium / Low), file and line, the problem, why it matters, and the recommended fix. If you find no issue, say so explicitly.
5. **Next.** Do not apply fixes yourself. The user chooses which findings to fix; the fixes then follow the normal [`TASK.md`](./TASK.md) workflow.
