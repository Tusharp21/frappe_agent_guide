---
name: frappe-task
description: Run a Frappe/ERPNext development task through the project's task workflow (understand, check existing work, clarify, propose, lock, execute, test, review, approve). Use at the start of every Frappe change request: feature, bug fix, DocType, API, patch, report.
---

Follow `.frappe-agent/workflow/TASK.md` exactly.

1. Read `.frappe-agent/config.json`. Classify the risk: LOW, MEDIUM or HIGH (if unsure, higher).
2. In your first message give your understanding and ask whether to propose a solution and wait for the user's decision, or run automatically (never automatic for HIGH).
3. For MEDIUM and HIGH create the record with `.frappe-agent/scripts/new_task.sh "<title>" <risk>` and move states with `.frappe-agent/scripts/task_state.sh`.
4. Check existing work first: `search_history.sh`, `inspect_app.sh`, `project_knowledge/APP_MAP.md`.
5. Clarify, propose, and wait for the user's decision. Lock only with a note quoting the user. Never change a locked solution silently.
6. Execute, test with real commands, review, then ask for approval before COMPLETED (MEDIUM/HIGH).

For a bug use `workflow/BUG.md`; to review an existing diff use `workflow/CODE_REVIEW.md`; for production, only write a plan with `workflow/DEPLOYMENT.md` and let the human deploy.
