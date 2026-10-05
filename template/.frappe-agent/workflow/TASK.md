# Task Workflow

The master process for MEDIUM and HIGH tasks (LOW tasks use the short path in `AGENTS.md`). The agent is a controlled engineering assistant: the developer owns the requirement and every business or technical decision; the agent understands the system first, proposes, executes only what is locked, proves the result with evidence, and records it. Do the bookkeeping quietly; talk to the user naturally and add no approvals beyond those below.

```text
UNDERSTAND -> CHECK EXISTING -> CLARIFY -> PROPOSE -> USER DECISION -> LOCK
           -> EXECUTE -> TEST -> REVIEW -> SUMMARY + AUDIT -> USER APPROVAL -> COMPLETE -> UPDATE HISTORY
```

Step detail: [`REQUIREMENT_ANALYSIS.md`](./REQUIREMENT_ANALYSIS.md) (understand, propose), [`IMPLEMENTATION.md`](./IMPLEMENTATION.md) (execute), [`REVIEW.md`](./REVIEW.md) (test, review, report). Safety: [`PERMISSIONS_AND_PRODUCTION.md`](./PERMISSIONS_AND_PRODUCTION.md). Other workflows: [`BUG.md`](./BUG.md), [`CODE_REVIEW.md`](./CODE_REVIEW.md), [`DEPLOYMENT.md`](./DEPLOYMENT.md).

## Risk levels

Classify as soon as you understand the task; if unsure, pick the higher level, and say which and why. (This is the *task* risk; each command also has an *action level*, see the permissions file.)

| Risk | Examples | Flow |
| ---- | -------- | ---- |
| **LOW** | Label or text, translation, typo, comment, styling; no logic, permission, schema or data impact | The short path in `AGENTS.md`; completes after the summary, the user may reject it |
| **MEDIUM** | Business logic, validation, client/server script, report, API, DocType logic, a new field or DocType needing no migration of existing data | Full flow below; user decision and approval required |
| **HIGH** | Database migration or patch, schema change touching existing data, permission/role/security changes, anything affecting production, more than one app | MEDIUM flow plus rollback plan, migration-impact note, validation on a test site, a deployment plan for the human, and tests may not be skipped |

## Mode: decide first, or automatic

Read [`../config.json`](../config.json). In your first message, with your understanding, the risk level and what you found in existing work, ask:

> Is this what you want? Should I (A) propose a solution and wait for your decision, or (B) run it automatically?

Use the interactive question tool if you have one, else ask in plain text and wait. If `approval_mode` is `always_plan`, do not offer (B). Offer (B) only for risk levels in `auto_mode_allowed_risk`; **HIGH always needs a proposal, a decision and a lock.** In (B) you still ask about every ambiguous **business** decision, follow the permission policy, test, and record the task; lock the solution yourself with the note "auto mode, chosen by the user at the start".

## States

Set with `../scripts/task_state.sh <id> <STATE> [--note "..."]`, which validates the order and logs it. Six states; the steps below happen *within* them.

| State | Meaning | Steps |
| ----- | ------- | ----- |
| `DRAFT` | Open: understanding, questions, proposal; the solution is not locked | 1 to 4 |
| `LOCKED` | The user approved a final solution (`--note` quotes them) | 5 |
| `IN_PROGRESS` | Executing, testing and reviewing | 6 to 9 |
| `WAITING_FOR_APPROVAL` | Summary given; waiting for the user | 10 |
| `COMPLETED` | Approved and done (`--note` quotes them) | 11 |
| `BLOCKED` | Stopped by a dependency or problem; say what is needed | any |

If a locked solution must change, move back to `DRAFT` and get a new decision.

## Steps

Records are created for the risk levels in `history.record_for`. Fill the matching section of the record as you reach each step, and delete sections that do not apply.

1. **Create.** `../scripts/new_task.sh "<title>" <low|medium|high>`; fill the Requirement block. Do not start coding.
2. **Understand and check existing work.** Never build what already exists. Run `../scripts/search_history.sh <keywords>` and `../scripts/inspect_app.sh <app>`, read `../project_knowledge/APP_MAP.md`, search the code for existing implementations and patterns. Decide: reuse, extend, or new. (Section: Understanding.)
3. **Clarify.** If anything important is ambiguous, do not code and do not guess a business decision: ask short, specific questions, one at a time, each with why it matters and options. Record each answer in the user's words. (Section: Clarification.)
4. **Propose.** Give the solution with acceptance criteria; HIGH adds a rollback plan and migration-impact note. Give a recommendation, not just options. (Section: Solution proposal.)
5. **Decide and lock.** Record the user's decision, then `../scripts/task_state.sh <id> LOCKED --note "<what the user said>"`. Never lock on your own. **A locked solution is never changed silently**: if it must change materially, stop, move back to `DRAFT`, explain, and get a new decision. (Section: Decision and lock.)
6. **Execute.** `IN_PROGRESS`; follow [`IMPLEMENTATION.md`](./IMPLEMENTATION.md). (Section: Execution log.)
7. **Test and verify.** Run the checks in [`REVIEW.md`](./REVIEW.md) section 6 and report real results; "tests should pass" is not evidence. (Section: Testing report.)
8. **Review.** Review the diff and fix findings, as in [`REVIEW.md`](./REVIEW.md). (Section: Review.)
9. **Summary and audit.** Fill the summary and audit evidence as described in [`REVIEW.md`](./REVIEW.md) section 7. (Sections: Final summary, Audit evidence, Rollback plan.)
10. **Approval.** `WAITING_FOR_APPROVAL`; present the summary. Only on the user's approval run `../scripts/task_state.sh <id> COMPLETED --note "<what the user said>"`. Changes requested: back to `IN_PROGRESS` (or `DRAFT` if the solution changes).
11. **Update history.** Update the card at the top of the record (decision, locked solution, files, tests, approval, commit). Add lasting facts to `../project_knowledge/APP_MAP.md` and decisions to `DECISIONS.md`. If a mistake repeated, propose a rule, test or checklist item. (Section: Lessons.)

You never deploy. If the change must reach production, write the plan per [`DEPLOYMENT.md`](./DEPLOYMENT.md) and hand it to the user. COMPLETED means development is approved; update the card's `Deployment` field when the human reports the result.

## Non-negotiable rules

These come with the hard rules in `AGENTS.md` (production read-only, real test results only, stay in scope).

1. Never guess an ambiguous business requirement; ask.
2. Never change a locked solution silently.
3. On every new task, search the relevant history first.
4. Record important work.
5. The human keeps the final responsibility.
