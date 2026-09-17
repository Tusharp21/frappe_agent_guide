# Implementation Workflow

This phase begins ONLY after the Requirement Analysis plan is explicitly approved by the user.

## 1. Verify Plan & Scope
* Cross-check the approved plan.
* Ensure absolutely no changes are made outside the agreed scope.

## 2. Code Implementation
* **Backend:** Write Python logic, updating controllers or hooks. Ensure clear separation of concerns.
* **Frontend:** Write JS for client scripts or Vue/JS components if required.
* **Database:** Apply schema changes via doctype JSON modifications, custom fields, or fixtures.

## 3. Error Handling & Edge Cases
* Handle all exceptions gracefully using standard Frappe error handling (`frappe.throw`, `frappe.msgprint`).
* Account for edge cases (empty fields, null references, invalid state transitions).

## 4. In-flight Checks
* **Security:** Are `@frappe.whitelist()` methods properly protected?
* **Performance:** Are queries optimized? No N+1 query problems?
* **Formatting:** Does the code align with standard PEP8 (Python) and Frappe JS formatting?

## 5. Output Delivery
Present the code cleanly to the user, specifying exactly which file each block belongs to.