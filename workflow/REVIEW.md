# Code Review & Quality Assurance

After implementation is complete, the AI must self-review the code against this checklist before considering the task done.

## 1. Functional Review
- [ ] Does the code fulfill the original requirement?
- [ ] Were *only* the expected files modified?

## 2. Code Quality & Standards
- [ ] Is the code following Frappe Framework standards (ORM, Hooks, Whitelisted methods)?
- [ ] Is the code clean, readable, and properly commented?
- [ ] Are strings wrapped for translation?

## 3. Security & Permissions
- [ ] Are role permissions validated (`frappe.has_permission`)?
- [ ] Are API endpoints secure?
- [ ] Are secrets/passwords kept out of the codebase?

## 4. Performance & Database
- [ ] Are DB queries optimized?
- [ ] Are loops free of direct DB calls?
- [ ] Have heavy tasks been moved to background jobs?

## 5. Cleanup
- [ ] Are all `print()`, `console.log()`, and temporary debug statements removed?
- [ ] Is error handling robust and user-friendly?
- [ ] (If applicable) Is the Git diff clean and logical?
- [ ] Do the pre-commit hooks (`ruff`, etc.) pass? Run `pre-commit run --all-files` if unsure.