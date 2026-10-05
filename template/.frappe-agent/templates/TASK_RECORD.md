# {{TASK_ID}}: {{TASK}}

> One living file per task (history and audit). Created by `scripts/new_task.sh`; change state with `scripts/task_state.sh`. Fill each section when you reach that step and delete sections that do not apply. Keep the card short: `scripts/search_history.sh` shows only the card to future tasks. Never write that something passed unless you ran it and are pasting its output.

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
* Reuse / extend / new:

## Clarification
<!-- One entry per question; add more as needed. -->
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
* Acceptance criteria (the user may edit; testable):
  1.
* HIGH only: rollback plan and migration impact (what runs on `bench migrate`, what is irreversible):

## Decision and lock
* Selected solution:
* User decision (their words):
* Test required: YES / NO (reason if NO; NO is not allowed for HIGH)
* Additional instruction:
* Status: LOCKED
<!-- If the locked solution must change materially: set the state back to DRAFT, then add a dated "Revised decision" entry here. Never edit the locked solution silently. -->

## Execution log
<!-- Short notes on what was done. Any deviation from the locked solution needs a new decision first. -->

## Testing report
* Tests executed:
* Result (real output, e.g. 42 passed, 0 failed):
* Manual verification:
* Known issues:
* Conclusion: PASS / FAIL / PARTIAL
* Acceptance criteria: met / not met / not verified, one line each

## Review
<!-- Separate read-only review of the diff (MEDIUM/HIGH). Severity / file / problem / why it matters / fix. "No issues found" is a valid result. -->

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
* Actual output (paste real output; write "NOT RUN" and why if not run):

```text
```

* Human approval (who, when, their words):
* Commit:
* Deployment (human-run; result reported by the human):

## Rollback plan
<!-- Required for HIGH. How to undo the change, including data and migration effects. -->

## Lessons and knowledge updates
<!-- Facts for project_knowledge/APP_MAP.md, decisions for DECISIONS.md, repeated mistakes that should become a rule or test. -->
