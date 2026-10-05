# Task record sections

The source of every section format in a task record. Do not read this file; `scripts/task_section.sh <task> <name>` appends the section you need to the record and prints it. Each block between the markers is copied verbatim. Names: understanding, clarification, proposal, decision, execution, testing, review, summary, audit, rollback, lessons.

<!-- SECTION:understanding -->
## Understanding and existing-work check
* Understanding:
* Existing implementation:
* Related previous work (from `scripts/search_history.sh`):
* Dependencies:
* Risks:
* Missing information:
* Reuse / extend / new:
<!-- /SECTION -->

<!-- SECTION:clarification -->
## Clarification
<!-- One entry per question; add more as needed. -->
* Question:
* Why it matters:
* Options:
* Answer (the user's words):
<!-- /SECTION -->

<!-- SECTION:proposal -->
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
<!-- /SECTION -->

<!-- SECTION:decision -->
## Decision and lock
* Selected solution:
* User decision (their words):
* Test required: YES / NO (reason if NO; NO is not allowed for HIGH)
* Additional instruction:
* Status: LOCKED
<!-- If the locked solution must change materially: set the state to WAITING_FOR_DECISION, then add a dated "Revised decision" entry here. Never edit the locked solution silently. -->
<!-- /SECTION -->

<!-- SECTION:execution -->
## Execution log
<!-- Short notes on what was done. Any deviation from the locked solution needs a new decision first. -->
<!-- /SECTION -->

<!-- SECTION:testing -->
## Testing report
* Tests executed:
* Result (real output, e.g. 42 passed, 0 failed):
* Manual verification:
* Known issues:
* Conclusion: PASS / FAIL / PARTIAL
* Acceptance criteria: met / not met / not verified, one line each
<!-- /SECTION -->

<!-- SECTION:review -->
## Review
<!-- Separate read-only review of the diff (MEDIUM/HIGH). Severity / file / problem / why it matters / fix. "No issues found" is a valid result. -->
<!-- /SECTION -->

<!-- SECTION:summary -->
## Final summary
* What was done:
* Files changed (`git diff --stat`):
* Problems found:
* Known limitations:
* Risk: LOW / MEDIUM / HIGH
* Status: READY FOR APPROVAL
<!-- /SECTION -->

<!-- SECTION:audit -->
## Audit evidence
* Agent:
* Commands executed (meaningful ones: tests, lint, migrate on a test site, git):
* Actual output (paste real output; write "NOT RUN" and why if not run):

```text
```

* Human approval (who, when, their words):
* Commit:
* Deployment (human-run; result reported by the human):
<!-- /SECTION -->

<!-- SECTION:rollback -->
## Rollback plan
<!-- Required for HIGH. How to undo the change, including data and migration effects. -->
<!-- /SECTION -->

<!-- SECTION:lessons -->
## Lessons and knowledge updates
<!-- Facts for project_knowledge/APP_MAP.md, decisions for DECISIONS.md, repeated mistakes that should become a rule or test. -->
<!-- /SECTION -->
