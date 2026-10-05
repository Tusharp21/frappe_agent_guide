# Understanding and Proposal Checklist

Steps 2 to 4 of the [`TASK.md`](./TASK.md) workflow: understand the request, inspect the system, and propose a solution. Do not write code in this phase. Risk levels, the plan-or-auto question, and the output formats are defined in `TASK.md`.

## 1. Understand the Request
* What is the exact business requirement and the expected result?
* Who is the target user/role?
* What is unclear? Anything that is a business decision is a question for the user, not a guess.

## 2. Check Existing Work
* Run `../scripts/search_history.sh <keywords>` and read what comes back.
* **DocTypes:** identify all standard and custom DocTypes involved.
* **Files:** identify which controllers, JS files, or HTML templates are relevant.
* **Discovery:** run `../scripts/inspect_app.sh <app>` for the app's branch, modules, hooks, DocTypes, fixtures and patches, and read `../project_knowledge/APP_MAP.md`.
* **Existing patterns:** search the codebase for how similar problems were solved. Do not invent a new pattern if a standard one exists; prefer standard Frappe/ERPNext behavior over new code.
* Decide: reuse, extend, or build new.

## 3. Data Flow and Business Rules
* Map how data will enter, move through, and exit the system.
* Note all validation rules, status changes, and constraints.

## 4. Pre-Checks
* **Security:** what permissions/roles are required? Any data-leak risk? Does it touch secrets or production? (See `PERMISSIONS_AND_PRODUCTION.md`.)
* **Performance:** will this involve large datasets? Do we need background jobs?
* **Migration:** does it change the schema or existing data? If yes, the task is HIGH.

## 5. Propose
Fill the Solution proposal section of the task record, with acceptance criteria for MEDIUM and HIGH, and a rollback plan and migration-impact note for HIGH.

**STOP HERE.** Present the proposal and wait for the user's decision. Do not continue until the solution is locked (or the user chose automatic mode where it is allowed).
