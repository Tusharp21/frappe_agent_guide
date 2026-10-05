# 03 Daily use

## The flow of a task

```text
UNDERSTAND -> CHECK EXISTING -> CLARIFY -> PROPOSE -> YOUR DECISION -> LOCK
           -> EXECUTE -> TEST -> REVIEW -> SUMMARY + AUDIT -> YOUR APPROVAL -> COMPLETE -> UPDATE HISTORY
```

1. **You** describe the task in plain language.
2. **The agent** reads `AGENTS.md`, classifies the risk, searches past work, and in its first message gives its understanding and asks whether to propose a solution and wait for your decision, or run automatically.
3. **You** answer its questions and choose a solution; it locks your decision.
4. **The agent** implements only the locked solution, tests with real commands, reviews the diff and gives a summary.
5. **You** approve (MEDIUM and HIGH). The agent then records the task and updates `project_knowledge/`.
6. **Production:** the agent writes a deployment plan; you deploy and report the result.

## Risk levels

| Risk | Examples | What to expect |
| ---- | -------- | -------------- |
| **LOW** | Label or text, translation, typo, styling | No approval wait; a short summary; you can still reject it |
| **MEDIUM** | Business logic, validation, scripts, reports, APIs, a new field or DocType needing no data migration | Full flow with your decision and your final approval |
| **HIGH** | Migration or patch, permission/security changes, anything affecting production, several apps | MEDIUM flow plus rollback plan, test-site validation, a deployment plan for you, and tests may not be skipped |

If the agent is unsure, it picks the higher level.

## What you will be asked

* **At the start:** whether to *propose and wait for your decision* or *run automatically*. Automatic is never offered for HIGH and never skips the permission rules. Set `approval_mode` to `always_plan` to never be offered it ([02](./02-configuration.md)).
* **Clarifying questions:** ambiguous business points become short questions with options; the agent does not guess.
* **A decision:** it proposes a solution with acceptance criteria and a recommendation; you pick or edit.
* **A final approval** (MEDIUM and HIGH) before the task is COMPLETED.

## The solution lock and task states

Once you decide, the solution is **locked**. The agent cannot change it silently; if it must, it comes back to you. Six states are tracked in the task record by `scripts/task_state.sh`: `DRAFT`, `LOCKED`, `IN_PROGRESS`, `WAITING_FOR_APPROVAL`, `COMPLETED`, `BLOCKED`. The script rejects out-of-order moves and requires the agent to quote your words when locking or completing. This is friction, not a guarantee: an agent can still write a note itself or use `--force`.

## Other workflows

* **Bug:** reproduce, diagnose the root cause, propose and lock a fix, add a regression test.
* **Code review:** the agent reviews a diff read-only and lists findings; you choose what to fix.
* **Deployment:** the agent writes the plan; you run it.

## Discovery and verification

* `scripts/inspect_app.sh [app]` prints an app's branch, modules, `hooks.py` settings, DocTypes, fixtures and patches (read-only; long lists are capped, use `--filter` or `--all`).
* Before reporting work done, the agent must actually run the checks for the risk level (linter, `bench run-tests`, and `bench migrate` on a test site for HIGH changes) and paste the real output. A separate read-only reviewer checks the diff for MEDIUM and HIGH.

## Why it stays cheap to run

The agent reads only what a step needs, not the whole knowledge base:

* `AGENTS.md` (always loaded) has a short LOW-task path, so a typo fix never reads the task workflow.
* `knowledge/INDEX.md` routes to one part, and `scripts/doc_sections.sh <name>` lists its headings with line ranges so only one section is read.
* The Git rules are separate from the Git examples, which are read only when needed.
* The task record has a short card on top, and `scripts/search_history.sh` shows future tasks just the card.
* `config.json` is small; the regex patterns for hooks are in `policy.json`.

## Repeated mistakes

If the agent repeats a mistake, add a rule to `AGENTS.md` or a note to `project_knowledge/DECISIONS.md`; if it keeps happening, add a test or a `blocked_commands`/`ask_commands` pattern ([02](./02-configuration.md)).
