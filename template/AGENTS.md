<!-- frappe-agent:start -->
# AI Agent Guidelines (Frappe)

All detailed guidance for this project lives in **`.frappe-agent/`**. This file holds only the hard rules and the process.

## Where things are

* Standards and best practices: `.frappe-agent/docs/INDEX.md` (routing table — read only the part that matches the task)
* Process: `.frappe-agent/workflow/` (`REQUIREMENT_ANALYSIS.md`, `IMPLEMENTATION.md`, `REVIEW.md`)
* Git rules: `.frappe-agent/GIT_WORKFLOW.md`
* Task template: `.frappe-agent/templates/TASK_TEMPLATE.md`
* Discovery: `.frappe-agent/scripts/inspect_app.sh [app]` (read-only)
* Project knowledge: `.frappe-agent/project_knowledge/` (`APP_MAP.md`, `DECISIONS.md`)

## Process flow

1. **Read & understand** the request. If requirements are ambiguous, ask — do not guess.
2. **Consult** `.frappe-agent/docs/INDEX.md` and read the part(s) that apply, plus `project_knowledge/APP_MAP.md`.
3. **Analyze** using `.frappe-agent/workflow/REQUIREMENT_ANALYSIS.md`. Start from the bench root: look at `apps/`, `sites/`, and `bench list-apps` to find which app the task belongs to.
4. **Plan and wait.** Present a step-by-step plan and wait for explicit user approval. Write no final code before approval.
5. **Implement** using `.frappe-agent/workflow/IMPLEMENTATION.md`.
6. **Review** using `.frappe-agent/workflow/REVIEW.md`, then add any lasting facts to `project_knowledge/`.

## Task tiers

Classify every task in step 3 (details in `REQUIREMENT_ANALYSIS.md`): **Trivial** (text/label/typo, no logic) gets a one-line plan; **Standard** gets the structured plan; **Major** (new DocType, schema/patch, permissions, integrations, jobs, multi-app) also needs the task template, a rollback plan, and a migration-impact note. All tiers still require approval. If unsure, use the higher tier.

## Hard rules

* Inspect existing code, DocTypes, and patterns before proposing anything new.
* Stay in scope: do not modify files or add features outside the requested task.
* Follow Frappe framework guidelines. Never hardcode secrets, keys, or passwords.
* Apply role-based permission checks (`frappe.has_permission`) on whitelisted methods and data access.
* Respect the app's own linters and pre-commit hooks (`apps/<app>/.pre-commit-config.yaml`). Fix what they flag; never use `--no-verify` without explicit user authorization.
* Git: follow `.frappe-agent/GIT_WORKFLOW.md`. Git repositories are the apps under `apps/`, not the bench root. Never push to `main`/`master`; work on a dedicated branch and open a Pull Request. Stop and ask on conflicts or authentication problems.

## Output format

* Be concise; use Markdown.
* Give exact file paths when proposing changes: `[File Path] -> [Code Block]`.
<!-- frappe-agent:end -->
