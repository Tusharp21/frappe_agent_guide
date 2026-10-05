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

## 7. Final Report and Audit Record

Evidence matters more than the word "done". Never write that tests passed unless you ran them and have the output.

* If the task's tier is listed in `audit.tiers` in [`../config.json`](../config.json), create the record with `../scripts/new_run.sh "<task title>" <tier>` and fill in [`../templates/RUN_REPORT.md`](../templates/RUN_REPORT.md): requirement, acceptance criteria (met / not met / not verified), files changed (`git diff --stat`), commands executed, **actual** test output (or "NOT RUN" and why), review findings, remaining risks, branch, commit ID, and the rollback plan for Major tasks.
* For tiers without a record, give the user a short report: what changed, files changed, commands run, test results, risks, branch and commit.
* Do not mark the work done while any acceptance criterion is unverified without saying so.
* If the change must reach production, write a deployment plan with [`../templates/DEPLOYMENT_PLAN.md`](../templates/DEPLOYMENT_PLAN.md) and hand it to the user. Do not deploy.
