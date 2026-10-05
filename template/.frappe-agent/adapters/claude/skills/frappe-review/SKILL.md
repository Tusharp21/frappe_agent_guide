---
name: frappe-review
description: Test, review and report finished Frappe/ERPNext changes against the project checklist. Use after implementation, before asking for approval or reporting a task as done.
---

Follow `.frappe-agent/workflow/REVIEW.md`.

* Run the verification commands listed there for the task's risk level and report the real output. Do not claim a check passed if you did not run it.
* For MEDIUM and HIGH, review the diff with a separate read-only subagent so the code is not graded only by the agent that wrote it.
* Fill the summary and audit evidence in the task record, mark each acceptance criterion met / not met / not verified, and add lasting facts to `.frappe-agent/project_knowledge/`.
