---
name: frappe-implement
description: Implement an already-approved Frappe/ERPNext plan. Use only after the user has explicitly approved the plan.
---

Follow `.frappe-agent/workflow/IMPLEMENTATION.md`.

* Confirm the plan was approved in this conversation. If not, stop and use the `frappe-analyze` skill first.
* Stay strictly within the approved scope and file list. If something outside it needs to change, stop and ask.
* Git operations run inside `apps/<app>/` on a dedicated branch, per `.frappe-agent/GIT_WORKFLOW.md`.
* When done, use the `frappe-review` skill before reporting the task as complete.
