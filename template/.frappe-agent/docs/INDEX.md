# Docs Routing Index

Do **not** read every file in `docs/`. Pick the row that matches the task, read only that part, and follow its links when it points elsewhere. The full table of contents is in [`FRAPPE_DEVELOPMENT.md`](../FRAPPE_DEVELOPMENT.md).

| If the task involves... | Read |
| ----------------------- | ---- |
| Bench, `bench` commands, site config, `hooks.py`, deciding where code goes | [`01-architecture-and-bench.md`](./01-architecture-and-bench.md) |
| DocTypes, fields, child tables, Client/Server Scripts, document events, custom fields | [`02-doctype-development.md`](./02-doctype-development.md) |
| App/module structure, `public/`, `www/`, fixtures, patches, `patches.txt` | [`03-app-structure-and-files.md`](./03-app-structure-and-files.md) |
| APIs, whitelisted methods, permissions, secrets, settings, logging, queries, performance | [`04-security-and-backend.md`](./04-security-and-backend.md) |
| Business logic placement, scheduled/background jobs, reports, print formats | [`05-business-logic-and-jobs.md`](./05-business-logic-and-jobs.md) |
| Naming, file names, tests, validation, migration safety | [`06-conventions-and-testing.md`](./06-conventions-and-testing.md) |
| Agent do's and don'ts, file placement rules | [`07-ai-agent-guide.md`](./07-ai-agent-guide.md) |
| Worked examples (field, client behavior, validation, toggle, API, data migration) | [`08-examples-and-patterns.md`](./08-examples-and-patterns.md) |
| Debugging, deployment checklist, change management | [`09-debugging-and-operations.md`](./09-debugging-and-operations.md) |
| Final self-check before finishing any task | [`10-final-principles.md`](./10-final-principles.md) |

## Always read, regardless of task

* [`../workflow/REQUIREMENT_ANALYSIS.md`](../workflow/REQUIREMENT_ANALYSIS.md) before planning.
* [`../GIT_WORKFLOW.md`](../GIT_WORKFLOW.md) before any Git operation.
* [`../workflow/PERMISSIONS_AND_PRODUCTION.md`](../workflow/PERMISSIONS_AND_PRODUCTION.md) before running any command that installs, migrates, deletes, pushes, or touches an environment.
* [`../config.json`](../config.json) for approval mode, audit, and production settings (guide: [`../CONFIGURATION.md`](../CONFIGURATION.md)).
* [`../project_knowledge/APP_MAP.md`](../project_knowledge/APP_MAP.md) to see what is already known about this bench.
