# {{RUN_ID}}: {{TASK}}

> Audit record and final report in one. Created by `scripts/new_run.sh`; stored locally in `.frappe-agent/audit/` (not in git). Fill every field. Never write that something passed unless you actually ran it and are pasting its output.

| Field | Value |
| ----- | ----- |
| Run ID | {{RUN_ID}} |
| Date / time | {{DATE}} |
| Developer | {{DEVELOPER}} |
| Agent | |
| App / project | |
| Task | {{TASK}} |
| Tier | {{TIER}} |
| Approval mode | ask_each_task: plan approved / auto |
| Branch | {{BRANCH}} |
| Risk | Low / Medium / High |
| Reviewer | |
| Approval | Pending / Approved (by, when) |
| Commit | |
| Deployment | Not deployed. Steps handed to the human (see deployment plan, if any) |

## Requirement
<!-- The user's request, in their words. -->

## Acceptance criteria
<!-- Copied from the approved plan. Mark each Met / Not met / Not verified. -->
1.

## What changed
<!-- Short summary of the implementation. -->

## Files changed
<!-- Output of `git diff --stat` -->
```text
```

## Commands executed
<!-- Meaningful commands only (tests, lint, migrate on a test site, git). -->
```text
```

## Tests and checks: actual output
<!-- Paste real output. If something was not run, say "NOT RUN" and why. -->
```text
```

## Review findings
<!-- Severity / file / problem / fix, from the separate review pass. "No issues found" is a valid result. -->

## Remaining risks and limitations

## Rollback plan
<!-- Required for Major tier. -->

## Follow-ups and lessons
<!-- Anything to add to project_knowledge/ (APP_MAP.md or DECISIONS.md). -->
