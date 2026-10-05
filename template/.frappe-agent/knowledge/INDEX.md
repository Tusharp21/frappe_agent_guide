# Docs Routing Index

Do **not** read every file in `knowledge/`. Pick the row that matches the task, then run `../scripts/doc_sections.sh <name>` (for example `doctype`) to list that doc's headings with line ranges and read only the section you need. Follow its links when it points elsewhere.

| If the task involves... | Read |
| ----------------------- | ---- |
| Bench, `bench` commands, site config, `hooks.py`, deciding where code goes | [`architecture-and-bench.md`](./architecture-and-bench.md) |
| DocTypes, fields, child tables, Client/Server Scripts, document events, custom fields | [`doctype-and-scripts.md`](./doctype-and-scripts.md) |
| App/module structure, `public/`, `www/`, fixtures, patches, `patches.txt` | [`app-structure-fixtures-patches.md`](./app-structure-fixtures-patches.md) |
| APIs, whitelisted methods, permissions, secrets, settings, logging, queries, performance | [`security-and-backend.md`](./security-and-backend.md) |
| Business logic placement, scheduled/background jobs, reports, print formats | [`business-logic-and-jobs.md`](./business-logic-and-jobs.md) |
| Naming, file names, tests, validation, migration safety | [`conventions-and-testing.md`](./conventions-and-testing.md) |
| Agent do's and don'ts, file placement rules | [`agent-rules-and-file-placement.md`](./agent-rules-and-file-placement.md) |
| Worked examples (field, client behavior, validation, toggle, API, data migration) | [`examples-and-patterns.md`](./examples-and-patterns.md) |
| Debugging, change management (the deployment checklist is in `templates/DEPLOYMENT_PLAN.md`) | [`debugging-and-operations.md`](./debugging-and-operations.md) |
| Minimal-change and upgrade-friendly principles; the project golden rule | [`principles.md`](./principles.md) |

## Always read, regardless of task

* [`../workflow/TASK.md`](../workflow/TASK.md): the task workflow (states, formats, risk levels). Use `BUG.md` for bugs, `CODE_REVIEW.md` to review a diff, `DEPLOYMENT.md` for production.
* [`../workflow/REQUIREMENT_ANALYSIS.md`](../workflow/REQUIREMENT_ANALYSIS.md) before proposing a solution.
* [`../workflow/GIT_WORKFLOW.md`](../workflow/GIT_WORKFLOW.md) before any Git operation.
* [`../workflow/PERMISSIONS_AND_PRODUCTION.md`](../workflow/PERMISSIONS_AND_PRODUCTION.md) before running any command that installs, migrates, deletes, pushes, or touches an environment.
* [`../config.json`](../config.json) for approval mode, risk levels, history and production settings.
* [`../project_knowledge/APP_MAP.md`](../project_knowledge/APP_MAP.md) to see what is already known about this bench, and `../scripts/search_history.sh <keywords>` for past tasks.
