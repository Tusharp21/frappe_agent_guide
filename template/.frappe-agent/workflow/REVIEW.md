# Test, Review and Report

Steps 7 to 9 of the [`TASK.md`](./TASK.md) workflow. After implementation, test and review the work against this checklist before reporting it as done.

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

Run these for real and report the actual results. Run them from the bench root; use the site and app names from the task. If a command cannot be run (no site available, missing permissions), say so rather than skipping silently. If the test decision was NO, record the reason and still run the linter. **HIGH tasks may not skip tests.**

| Risk | Run |
| ---- | --- |
| LOW | The app's linter on the changed file (see the pre-commit item above). |
| MEDIUM | Linter, plus the tests for the touched DocType/module: `bench --site <site> run-tests --app <app> --module <dotted.module.path>` (or `--doctype "<DocType>"`). |
| HIGH | Everything for MEDIUM, plus: run `bench --site <site> migrate` on a **test site or backup copy only** (never production) when a patch, fixture, or schema change is involved, and confirm the patch is listed in `patches.txt` and fixtures are exported. |

For MEDIUM and HIGH, review the final `git diff` with a separate read-only reviewer (for example a subagent) rather than relying only on this self-review.

## 7. Final Report and Record

Evidence matters more than the word "done". Never write that tests passed unless you ran them and have the output.

* Add the `testing`, `summary` and `audit` sections (HIGH also `rollback`) with `../scripts/task_section.sh <id> <name>` and fill them in: what was done, files changed (`git diff --stat`), **actual** test output (or "NOT RUN" and why), review findings, problems, limitations, risk, branch, commit ID, each acceptance criterion marked met / not met / not verified, and the rollback plan for HIGH tasks.
* LOW tasks without a record: give the user a short report: what changed, files changed, commands run, test results, risks, branch and commit.
* Do not mark the work done while any acceptance criterion is unverified without saying so.
* If the change must reach production, write a deployment plan (see `DEPLOYMENT.md`) and hand it to the user. Do not deploy.
* Update the card, `project_knowledge/` and any lessons (step 11 of `TASK.md`).
