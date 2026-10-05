# Implementation Workflow

The checklist for step 6 of the [`TASK.md`](./TASK.md) workflow. Begin only after the solution is **LOCKED** (or the user chose automatic mode where it is allowed).

## 1. Verify the Scope
* Re-read the locked solution and the acceptance criteria in the task record.
* Make no changes outside the agreed scope and files: no unrelated refactors, no new dependencies without approval.
* If the solution must change materially, stop and follow `TASK.md` step 5.

## 2. Code Implementation
* **Backend:** Write Python logic, updating controllers or hooks. Ensure clear separation of concerns.
* **Frontend:** Write JS for client scripts or Vue/JS components if required.
* **Database:** Apply schema changes via doctype JSON modifications, custom fields, or fixtures.
* Follow the project rules and the relevant part of `../knowledge/` (see `../knowledge/INDEX.md`).

## 3. Error Handling and Edge Cases
* Handle all exceptions gracefully using standard Frappe error handling (`frappe.throw`, `frappe.msgprint`).
* Account for edge cases (empty fields, null references, invalid state transitions).

## 4. In-flight Checks
* **Security:** are `@frappe.whitelist()` methods properly protected?
* **Performance:** are queries optimized? No N+1 query problems?
* **Formatting:** does the code align with standard PEP8 (Python) and Frappe JS formatting?
* **Permissions policy:** ask first for the actions that need it; never run prohibited ones (see `PERMISSIONS_AND_PRODUCTION.md`).

## 5. Output Delivery
Present the code cleanly to the user, specifying exactly which file each block belongs to. Note any deviation or surprise in the task record's execution log. Then test (see `REVIEW.md`).
