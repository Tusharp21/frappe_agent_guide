---
name: frappe-analyze
description: Analyze a Frappe/ERPNext task before any code is written and present a plan for approval. Use at the start of every Frappe change request (new feature, bug fix, DocType, API, patch, report).
---

Follow `.frappe-agent/workflow/REQUIREMENT_ANALYSIS.md` exactly.

1. Run `.frappe-agent/scripts/inspect_app.sh` to list apps, then `.frappe-agent/scripts/inspect_app.sh <app>` for the app the task belongs to.
2. Read `.frappe-agent/project_knowledge/APP_MAP.md` and the part of `.frappe-agent/docs/` that `docs/INDEX.md` routes this task to.
3. Classify the task tier (Trivial, Standard, Major) as defined in the workflow file, and say which tier you chose and why.
4. Present the plan in the format for that tier, then **stop and wait for explicit approval**. Write no code before approval.
