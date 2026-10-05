# Knowledge Routing Index

Do **not** read every file in `knowledge/`. Pick the row that matches the task, then run `../scripts/doc_sections.sh <name>` (for example `doctype`) to list that file's headings with line ranges and read only the section you need. Follow its links when it points elsewhere.

| If the task involves... | Read |
| ----------------------- | ---- |
| The golden rules (reuse, smallest change, no core edits, no hardcoding), Bench, `bench` commands, site config, `hooks.py`, deciding where code goes | [`architecture-and-bench.md`](./architecture-and-bench.md) |
| DocTypes, fields, child tables, Client/Server Scripts, document events, custom fields | [`doctype-and-scripts.md`](./doctype-and-scripts.md) |
| Where each file goes, modules, `public/`, `www/`, fixtures, patches, `patches.txt` | [`app-structure-fixtures-patches.md`](./app-structure-fixtures-patches.md) |
| APIs, whitelisted methods, permissions, secrets, settings, logging, queries, performance | [`security-and-backend.md`](./security-and-backend.md) |
| Business logic placement, scheduled/background jobs, reports, print formats | [`business-logic-and-jobs.md`](./business-logic-and-jobs.md) |
| Naming, file names, tests, validation, migration safety, documentation, change management | [`conventions-and-testing.md`](./conventions-and-testing.md) |
| Worked examples (field, client behavior, validation, toggle, API, data migration) | [`examples-and-patterns.md`](./examples-and-patterns.md) |
| Debugging (frontend, backend, database transactions) | [`debugging.md`](./debugging.md) |

The process, Git rules, permissions and settings are routed from `AGENTS.md`, not from here.
