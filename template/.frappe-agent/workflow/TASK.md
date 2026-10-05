# Task Workflow

The master process for every development task. The agent is a controlled engineering assistant: the developer owns the requirement and every business or technical decision; the agent understands the system first, proposes, executes only what is locked, proves the result with evidence, and records it. The workflow does the bookkeeping in the background; talk to the user naturally and do not add approvals beyond those below.

```text
NEW TASK -> UNDERSTAND -> CHECK EXISTING -> CLARIFY -> PROPOSE -> USER DECISION -> LOCK
         -> EXECUTE -> TEST -> REVIEW -> SUMMARY + AUDIT -> USER APPROVAL -> COMPLETE -> UPDATE HISTORY
```

Detail for the steps lives in [`REQUIREMENT_ANALYSIS.md`](./REQUIREMENT_ANALYSIS.md) (understand, inspect, propose), [`IMPLEMENTATION.md`](./IMPLEMENTATION.md) (execute) and [`REVIEW.md`](./REVIEW.md) (test, review, report). Safety rules are in [`PERMISSIONS_AND_PRODUCTION.md`](./PERMISSIONS_AND_PRODUCTION.md). Other workflows: [`BUG.md`](./BUG.md), [`CODE_REVIEW.md`](./CODE_REVIEW.md), [`DEPLOYMENT.md`](./DEPLOYMENT.md).

## Risk levels

Classify the task as soon as you understand it; it decides how strict the workflow is. If unsure, pick the higher level. Say which level you chose and why. (This is the *task* risk. The *action level* of each command is a separate idea; see the permissions file.)

| Risk | Examples | Flow |
| ---- | -------- | ---- |
| **LOW** | Label or text, translation, typo, comment, styling, a simple local change with no logic, permission, schema or data impact | Understand -> (one-line plan) -> Execute -> basic check -> Summary -> COMPLETED. The user may reject it afterwards. |
| **MEDIUM** | Business logic, validation, client/server script, report, API, DocType logic, a new field or DocType that needs no migration of existing data | Understand -> Check existing -> Clarify -> Propose -> Decision and Lock -> Execute -> Test -> Review -> Approval |
| **HIGH** | Database migration or patch, schema change touching existing data, permission/role/security changes, anything that affects production, changes across more than one app | The full MEDIUM flow plus: a rollback plan, a migration-impact note, validation on a test site, a deployment plan for the human, and **tests may not be skipped** |

## Mode: plan first, or automatic

Read [`../config.json`](../config.json) first. In your first message to the user, together with your understanding, the risk level and what you found in existing work, ask:

> Is this what you want? Should I (A) propose a solution and wait for your decision, or (B) run it automatically?

* Use the interactive question tool if your environment has one; otherwise ask in plain text and wait.
* If `approval_mode` is `always_plan`, do not offer (B).
* Offer (B) only for risk levels listed in `auto_mode_allowed_risk`. **HIGH always needs a proposal, a decision and a lock.**
* In (B) you still ask the user about every ambiguous **business** decision, still follow the permission policy (ask-first actions still need approval, prohibited actions are never run), still test, and still record the task. Lock the solution yourself and note "auto mode, chosen by the user at the start".

## States

Tracked in the task record with `../scripts/task_state.sh`, which validates the transition and logs it.

| State | Meaning |
| ----- | ------- |
| `DRAFT` | Task created; analysis not started |
| `UNDERSTANDING` | Inspecting the requirement and the existing system |
| `CLARIFICATION` | Waiting for answers to important questions |
| `SOLUTION_PROPOSED` | You have given a solution |
| `WAITING_FOR_DECISION` | Waiting for the user's decision |
| `LOCKED` | The user approved a final solution |
| `IN_PROGRESS` | Executing |
| `TESTING` | Testing and verifying |
| `REVIEW` | Reviewing the implementation and the diff |
| `WAITING_FOR_APPROVAL` | Waiting for the user's final approval |
| `COMPLETED` | Approved and done |
| `BLOCKED` | Stopped by a dependency or problem; say what is needed |

Records are created for the risk levels in `history.record_for` (default MEDIUM and HIGH). LOW tasks get a short summary instead.

## Steps

### 1. Create the task
For a risk level that gets a record, run `../scripts/new_task.sh "<title>" <low|medium|high>`. Fill the requirement block: requirement, expected result, priority, related module, dependencies, notes. Do not start coding. Move to `UNDERSTANDING`.

### 2. Understand and check existing work
Never build what already exists. Before proposing anything:
1. Run `../scripts/search_history.sh <keywords>` (past tasks, decisions, app map, git history).
2. Run `../scripts/inspect_app.sh <app>` and read `../project_knowledge/APP_MAP.md`.
3. Search the code for existing implementations and patterns; identify dependencies and risks.
4. Decide: reuse, extend, or build new.

Write it down in the record in this form:
```text
Understanding: ...
Existing implementation: ...
Related previous work: ...
Dependencies: ...
Risks: ...
Missing information: ...
```

### 3. Clarify
If anything important is ambiguous, do not code and do not guess a business decision. Move to `CLARIFICATION` and ask short, specific questions, one at a time:
```text
Question: Should the discount apply before tax or after tax?
Why it matters: It changes the tax calculation.
Options: A. Before tax   B. After tax
```
Record each answer in the user's words.

### 4. Propose a solution
Move to `SOLUTION_PROPOSED`, then `WAITING_FOR_DECISION`:
```text
Proposed solution: 1. ... 2. ... 3. ...
Files likely affected: ...
Existing functionality reused: ...
Potential impact: ...
Risks: ...
Alternative: ...
Recommendation: ...
Acceptance criteria (MEDIUM and HIGH): numbered, testable; the user may edit them.
```
HIGH adds a rollback plan and a migration-impact note (what runs on `bench migrate`, what is irreversible). Give a recommendation, not just a list of options.

### 5. Decision and lock
When the user decides, record it and lock:
```text
Selected solution: ...
User decision: <their words>
Test required: YES / NO (reason if NO; NO is not allowed for HIGH)
Additional instruction: ...
Status: LOCKED
```
Run `../scripts/task_state.sh <id> LOCKED --note "<what the user said>"`. Never lock on your own; the note must quote the user (or "auto mode, chosen by the user at the start").

**A locked solution is never changed silently.** If you find during execution that it must change materially, stop, move to `WAITING_FOR_DECISION`, explain what you found, and get a new decision before continuing.

### 6. Execute
Move to `IN_PROGRESS` and follow [`IMPLEMENTATION.md`](./IMPLEMENTATION.md): stay inside the locked solution and the task scope, no unrelated refactors, no new dependencies without approval, follow project rules and the relevant docs.

### 7. Test and verify
Move to `TESTING`. If the test decision was YES, run the real checks in [`REVIEW.md`](./REVIEW.md). If NO, record the reason and still run basic safety checks (lint) where practical. Report the actual result; "tests should pass" is not evidence.
```text
Tests executed: ...
Result: 42 passed, 0 failed
Manual verification: ...
Known issues: ...
Conclusion: PASS / FAIL / PARTIAL
```

### 8. Review
Move to `REVIEW`. Review the diff for correctness, edge cases, security, performance, regression risk, unnecessary changes, rule violations and missing tests. For MEDIUM and HIGH use a separate read-only reviewer (for example a subagent). Fix what it finds and re-run the checks.

### 9. Summary and audit
Fill the final summary and the audit evidence in the record: what was done, files changed (`git diff --stat`), tests with real output, problems, limitations, risk, branch, commit, and each acceptance criterion marked met / not met / not verified.
```text
TASK SUMMARY
Task: ...   What was done: ...   Files changed: ...   Tests: ...
Problems found: ...   Known limitations: ...   Risk: LOW / MEDIUM / HIGH
Status: READY FOR APPROVAL
```

### 10. Human approval
MEDIUM and HIGH (`final_approval_required_for`): move to `WAITING_FOR_APPROVAL` and present the summary. The user approves, rejects or asks for changes. Only on approval run `../scripts/task_state.sh <id> COMPLETED --note "<what the user said>"`. Changes requested: back to `IN_PROGRESS` (or `WAITING_FOR_DECISION` if the solution changes).
LOW: give the summary and move to `COMPLETED`; the user can still reject it.

### 11. Update history
Update the card at the top of the record (decision, locked solution, files, tests, approval, commit) so future searches find it. Add lasting facts to `../project_knowledge/APP_MAP.md` and decisions to `DECISIONS.md`. If a mistake repeated, propose a rule, test or checklist item instead of just fixing it once.

### Deployment
You never deploy. If the change must reach production, write the plan with [`DEPLOYMENT.md`](./DEPLOYMENT.md) and hand it to the user. Task completion means the development is approved; deployment status lives in the card's `Deployment` field, which you update when the human reports the result.

## Non-negotiable rules

1. Never guess an ambiguous business requirement; ask.
2. Never change a locked solution silently.
3. Never modify production, and never run destructive actions without explicit approval.
4. Never claim tests passed unless you ran them and have the output.
5. Avoid unrelated changes.
6. On every new task, search the relevant history first.
7. Record important work.
8. The human keeps the final responsibility.
