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
- [ ] Do the app's pre-commit hooks (`ruff`, etc.) pass? Run `pre-commit run --files <changed files>` from inside the app repository, or `ruff check` / `ruff format --check` if the app has no hooks.


## 6. Verification Commands

Run these for real and report the actual results. Run them from the bench root; use the site and app names from the task. If a command cannot be run (no site available, missing permissions), say so rather than skipping silently.

| Tier | Run |
| ---- | --- |
| Trivial | The app's linter on the changed file (see the pre-commit item above). |
| Standard | Linter, plus the tests for the touched DocType/module: `bench --site <site> run-tests --app <app> --module <dotted.module.path>` (or `--doctype "<DocType>"`). |
| Major | Everything for Standard, plus: run `bench --site <site> migrate` on a **test site or backup copy only** (never production) when a patch, fixture, or schema change is involved, and confirm the patch is listed in `patches.txt` and fixtures are exported. |

For Standard and Major tasks, review the final `git diff` with a separate read-only reviewer (for example a subagent) rather than relying only on this self-review.
