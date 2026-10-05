---
name: frappe-review
description: Review finished Frappe/ERPNext changes against the project checklist and run the verification commands. Use after implementation, before reporting a task as done.
---

Follow `.frappe-agent/workflow/REVIEW.md`.

* Run the verification commands listed there for the task's tier and report the real output. Do not claim a check passed if you did not run it.
* For Standard and Major tasks, prefer reviewing the diff with a separate read-only subagent so the code is not graded only by the agent that wrote it.
* After a passing review, add any lasting facts to `.frappe-agent/project_knowledge/APP_MAP.md` and any decision to `DECISIONS.md`.
