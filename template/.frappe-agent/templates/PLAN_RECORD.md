# {{PLAN_ID}}: {{TITLE}}

> One living file per plan: a large piece of work split into phases, each phase run as one task. Created by `scripts/new_plan.sh`; change state with `scripts/plan_state.sh`; start phases with `scripts/plan_next.sh`. Do not edit the `State:` or `Lock hash:` lines by hand. Keep the card short. Never write that something passed unless you ran it and are pasting its output.

<!-- CARD:START -->
- **Plan ID:** {{PLAN_ID}}
- **Title:** {{TITLE}}
- **State:** DRAFT
- **Risk:** <!-- highest phase risk, set at lock -->
- **Opened:** {{DATE}}
- **Developer:** {{DEVELOPER}}
- **App:**
- **Branch:** {{BRANCH}}
- **Goal:** <!-- one line -->
- **Decision:** <!-- the user's approval of the plan, their words -->
- **Phases:** 0/0 done
- **Lock hash:**
- **Approval:** Pending <!-- who, when, what they said -->
<!-- CARD:END -->

## State log

| When | State | Note |
| ---- | ----- | ---- |
<!-- STATE-LOG-END -->

## Goal and requirement
* Requirement (the user's words):
* Expected result:
* Who uses it / business reason:
* Dependencies:

## Understanding and existing-work check
* Existing implementation (from `scripts/search_history.sh`, `scripts/inspect_app.sh`, `APP_MAP.md`):
* Reuse / extend / new:
* Risks:
* Open questions and the user's answers:

## Scope
<!-- Part of the lock hash. -->
* In scope:
* Out of scope (what this plan will not change):
* Assumptions:

## Phases

Order matters: phase N+1 starts only after phase N's task is COMPLETED. Fill one row per phase while the plan is DRAFT. `Risk` is LOW, MEDIUM or HIGH. `Allowed paths` are files or folders relative to the bench root, comma separated (these become the task's scope gate). `Acceptance criteria` must be testable and are what the user verifies at the end of the phase (UAT). Do not use the `|` character inside a cell. Leave `Status` as PENDING and `Task` empty: `plan_next.sh` fills them. A HIGH phase gets its own proposal and lock when it starts; other phases start already locked by the plan.

<!-- PHASES:START -->
| # | Phase | Risk | Allowed paths | Acceptance criteria | Status | Task |
| - | ----- | ---- | ------------- | ------------------- | ------ | ---- |
<!-- PHASES:END -->

## Decision and lock
* User decision (their words):
* Locked on:
<!-- If the plan must change after the lock: `plan_state.sh <id> DRAFT --note "CR: why"`, edit, get a new decision, lock again. Never edit a locked plan silently; `plan_next.sh` refuses a plan whose scope or phases changed after the lock. -->

## Change requests
| When | Change | Why | User decision |
| ---- | ------ | --- | ------------- |

## Phase log
<!-- One short entry per finished phase: task id, result, what the user verified. -->

## Final summary
* What was delivered (per phase):
* Acceptance (UAT) results the user confirmed:
* Known limitations:
* Deployment plan: <!-- link to the DEPLOYMENT_PLAN the human runs -->

## Lessons and knowledge updates
<!-- Facts for project_knowledge/APP_MAP.md, decisions for DECISIONS.md. -->
