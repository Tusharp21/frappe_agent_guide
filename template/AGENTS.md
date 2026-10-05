<!-- frappe-agent:start -->
# AI Agent Guidelines (Frappe)

All detailed guidance lives in **`.frappe-agent/`**. This file has only the hard rules and the process; open the others when the step needs them.

## Where things are

* **Task workflow (MEDIUM/HIGH):** `.frappe-agent/workflow/TASK.md`. Others: `BUG.md`, `CODE_REVIEW.md`, `DEPLOYMENT.md`.
* Standards: `.frappe-agent/knowledge/INDEX.md` (routing table), then `scripts/doc_sections.sh <NN>` to read just one section.
* Step details: `.frappe-agent/workflow/` (`REQUIREMENT_ANALYSIS.md`, `IMPLEMENTATION.md`, `REVIEW.md`)
* Git rules: `.frappe-agent/workflow/GIT_WORKFLOW.md` (examples only in `workflow/GIT_REFERENCE.md`)
* Permissions, production, secrets: `.frappe-agent/workflow/PERMISSIONS_AND_PRODUCTION.md`
* Settings: `.frappe-agent/config.json` (small; read it each task)
* Scripts: `.frappe-agent/scripts/` (`new_task.sh`, `task_state.sh`, `search_history.sh`, `inspect_app.sh`)
* Project knowledge: `.frappe-agent/project_knowledge/` (`APP_MAP.md`, `DECISIONS.md`)

## LOW tasks (text, label, typo, styling; no logic, permission, schema or data impact)

Do not read `TASK.md`. Read `config.json`, give your understanding and a one-line plan, ask whether to wait for the user's go-ahead or just do it (per `approval_mode`), make the change, run the app's linter, and give a short summary. No task record. If it turns out to be bigger, reclassify as MEDIUM or HIGH.

## Process (MEDIUM / HIGH)

Follow `.frappe-agent/workflow/TASK.md`:

1. **Understand** the request and read `config.json`. Classify the risk (**LOW / MEDIUM / HIGH**; if unsure, higher). In your first message give your understanding and ask whether to **propose a solution and wait for the user's decision, or run automatically** (HIGH always needs a decision).
2. **Check existing work first:** `search_history.sh`, `inspect_app.sh`, `APP_MAP.md`, the code. Reuse or extend before building new.
3. **Clarify** ambiguous business points with short questions. Do not guess.
4. **Propose**, with acceptance criteria, then **wait for the user's decision and lock the solution**. Write no final code before that.
5. **Execute** only the locked solution. Never change it silently; if it must change, stop and get a new decision.
6. **Test and review** with real commands (`REVIEW.md`), then write the summary and audit evidence in the task record.
7. **Get the user's approval** before marking COMPLETED, then update the history and `project_knowledge/`.

## Hard rules

* Inspect existing code, DocTypes, and patterns before proposing anything new. Stay in scope: no unrelated files or features.
* Follow Frappe framework guidelines. Never hardcode secrets, keys, or passwords.
* Apply role-based permission checks (`frappe.has_permission`) on whitelisted methods and data access.
* Respect the app's own linters and pre-commit hooks (`apps/<app>/.pre-commit-config.yaml`). Fix what they flag; never use `--no-verify` without explicit user authorization.
* **Production is read-only for you.** Never run anything against a production site or host (see `config.json`). Write a deployment plan (`workflow/DEPLOYMENT.md`) and let the human run it.
* Never read, print or edit secrets (`.env`, `site_config.json`, keys). Never run prohibited actions (destructive SQL, `bench drop-site`, force-push). Ask first for ask-first ones (installs, migrate, deletes, network, push). See the permissions file.
* Report only real results: never claim tests passed unless you ran them and have the output.
* Git: follow `.frappe-agent/workflow/GIT_WORKFLOW.md`. Git repositories are the apps under `apps/`, not the bench root. Never push to `main`/`master`; work on a dedicated branch and open a Pull Request. Stop and ask on conflicts or authentication problems.

## Keep context small

* Read only what the routing table or the current step points to. Do not read a file you already read in this conversation.
* For long files read a range (`doc_sections.sh`, offset/limit) or grep, not the whole file.
* Do not paste file contents back to the user; reference `file:line`. Keep script output short (use `--filter`).

## Output format

* Be concise; use Markdown.
* Give exact file paths when proposing changes: `[File Path] -> [Code Block]`.
<!-- frappe-agent:end -->
