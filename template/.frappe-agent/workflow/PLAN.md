# Plan Workflow

For large work: split it into phases, get the whole plan approved and locked once, then run each phase as one task, stopping after every phase. This is how a team scopes a project (discovery, scope sign-off, then build in increments); the single-task process is [`TASK.md`](./TASK.md).

```text
UNDERSTAND -> CHECK EXISTING -> CLARIFY -> WRITE PLAN -> USER DECISION -> LOCK PLAN
  per phase:  START PHASE (task) -> EXECUTE -> TEST -> REVIEW -> USER VERIFIES (UAT) -> PHASE DONE -> STOP
                                                                          user says continue -> next phase
FINISH: all phases done -> final summary -> USER APPROVAL -> COMPLETE PLAN -> UPDATE HISTORY
```

## When to make a plan

Make one when the request is any of: two or more separate features or behaviours; more than one DocType or app; any HIGH-risk part (migration, permissions); or the user asks for a plan. Anything smaller is one task.

## Steps

1. **Understand and check existing work.** As in `TASK.md` steps 2 and 3, recorded in the plan: `../scripts/search_history.sh`, `../scripts/inspect_app.sh`, `../project_knowledge/APP_MAP.md`; ask short questions for ambiguous business points.
2. **Create.** `../scripts/new_plan.sh "<title>"`. Fill goal, scope (in and **out**) and open questions.
3. **Write the phases** in the plan's phase table, following these rules:
   * One feature or one layer per phase; each must be testable on its own.
   * Order by dependency. A schema or migration change is its own HIGH phase.
   * Usually 3 to 6 phases; the last covers tests, the user's acceptance run and the deployment plan.
   * Every phase has a risk, **allowed paths** (the files it may edit) and **acceptance criteria** written so the user can check them (these are the UAT scenarios).
4. **Propose.** Show the user the plan with a recommendation and the risks; the user may edit it.
5. **Decide and lock.** `../scripts/plan_state.sh <plan> LOCKED --note "<what the user said>"`. Never lock on your own. The lock stores a hash of the scope and phases.
6. **Run a phase.** `../scripts/plan_next.sh <plan>` creates the phase's task with its risk, allowed paths and acceptance criteria. A LOW or MEDIUM phase starts already LOCKED (the plan lock approved it), so go straight to execute; a HIGH phase starts DRAFT and needs its own proposal (rollback plan, migration impact) and lock. Then follow `TASK.md` steps 6 to 10 for that task: execute inside the allowed paths, test with real output, review, and give the user the summary together with the phase's acceptance criteria to verify. The task reaches COMPLETED only on the user's approval.
7. **Stop.** When the phase's task is COMPLETED, report what was done and what the next phase is, and wait. Start the next phase only on the user's go-ahead: `../scripts/plan_next.sh <plan> --note "<their words>"`. The script refuses otherwise.
8. **Change requests.** If scope or phases must change, stop: `../scripts/plan_state.sh <plan> DRAFT --note "CR: <what and why>"`, edit, get a new decision, lock again. Finished phases stay done. Never edit a locked plan: `plan_next.sh` detects it and refuses.
9. **Finish.** When every phase is done, give the final summary and the acceptance results, and on the user's approval `../scripts/plan_state.sh <plan> COMPLETED --note "<their words>"`. Write one deployment plan for the whole change ([`DEPLOYMENT.md`](./DEPLOYMENT.md)); add lasting facts to `../project_knowledge/APP_MAP.md` and decisions to `DECISIONS.md`.

## Resuming

The plan record is the source of truth, so a new session needs no memory of the old one. Read the plan's card and phase table, then `../scripts/plan_next.sh <plan>`: it resumes the phase in progress (making its task the active one) or reports that the next phase waits for the user.

## Rules

1. The plan, not the conversation, defines the work: no phase, file or behaviour outside the locked plan.
2. One phase at a time, in order; never start a phase before the previous one is COMPLETED and the user said continue.
3. Every phase is a task with its own record, tests and approval; the plan only sequences them.
4. Do not edit a record's `State:` or `Lock hash:` by hand; the scripts do it and record the user's words.
