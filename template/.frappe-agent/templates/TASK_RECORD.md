# {{TASK_ID}}: {{TASK}}

> One living file per task: history and audit in one. Created by `scripts/new_task.sh`, state changed with `scripts/task_state.sh`. Stored locally (see `history.path` in `config.json`), not in git. Fill each section as the task reaches it. Keep the card short: `scripts/search_history.sh` shows only the card to future tasks. Never write that something passed unless you ran it and are pasting its output.

<!-- CARD:START -->
- **Task ID:** {{TASK_ID}}
- **Title:** {{TASK}}
- **State:** DRAFT
- **Risk:** {{RISK}}
- **Opened:** {{DATE}}
- **Developer:** {{DEVELOPER}}
- **App:**
- **Branch:** {{BRANCH}}
- **Related:** <!-- module / DocTypes -->
- **Decision:** <!-- the user's decision, one line -->
- **Locked solution:** <!-- one line -->
- **Files:** <!-- changed files, comma separated -->
- **Tests:** NOT RUN <!-- PASS / FAIL / PARTIAL / NOT RUN -->
- **Approval:** Pending <!-- who, when, what they said -->
- **Commit:**
- **Deployment:** Not deployed <!-- human deploys; date and result once reported -->
<!-- CARD:END -->

## State log

| When | State | Note |
| ---- | ----- | ---- |
<!-- STATE-LOG-END -->

## Requirement
* Requirement:
* Expected result:
* Priority:
* Related module:
* Dependencies:
* Notes:

## Understanding and existing-work check
* Understanding:
* Existing implementation:
* Related previous work (from `scripts/search_history.sh`):
* Dependencies:
* Risks:
* Missing information:

## Clarification
<!-- One entry per question. -->
* Question:
* Why it matters:
* Options:
* Answer (the user's words):

## Solution proposal
* Proposed solution (numbered steps):
* Files likely affected:
* Existing functionality reused:
* Potential impact:
* Risks:
* Alternative:
* Recommendation:
* Acceptance criteria (MEDIUM and HIGH; the user may edit):
  1.

## Decision and lock
* Selected solution:
* User decision (their words):
* Test required: YES / NO (if NO, the reason; NO is not allowed for HIGH)
* Additional instruction:
* Status: LOCKED
<!-- If the locked solution must change materially, set the state back to WAITING_FOR_DECISION and record the new decision here as a dated entry. Never edit the locked solution silently. -->

## Execution log
<!-- Short notes on what was done; deviations from the locked solution (there should be none without a new decision). -->

## Testing report
* Tests executed:
* Result:
* Manual verification:
* Known issues:
* Conclusion: PASS / FAIL / PARTIAL
* Acceptance criteria: met / not met / not verified, one line each

## Review
<!-- Separate read-only review of the diff. Severity / file / problem / why it matters / fix. "No issues found" is a valid result. -->

## Final summary
* What was done:
* Files changed (`git diff --stat`):
* Problems found:
* Known limitations:
* Risk: LOW / MEDIUM / HIGH
* Status: READY FOR APPROVAL

## Audit evidence
* Agent:
* Commands executed (meaningful ones: tests, lint, migrate on a test site, git):
* Actual output (paste real output; "NOT RUN" and why if not run):

```text
```

* Human approval (who, when, their words):
* Commit:
* Deployment (human-run; result reported by the human):

## Rollback plan
<!-- Required for HIGH. -->

## Lessons and knowledge updates
<!-- Facts for project_knowledge/APP_MAP.md, decisions for DECISIONS.md, repeated mistakes that should become a rule or test. -->
