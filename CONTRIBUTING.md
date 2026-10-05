# Contributing to the Frappe AI Dev Template

Thanks for wanting to improve this template. This repository is documentation and tooling for AI coding agents (and the developers who run them) on Frappe/ERPNext projects — contributions should make those instructions clearer, more correct, or more complete, without turning the knowledge base into a duplicate-riddled mess.

## Before you start

For anything beyond a typo fix, open an issue first describing the problem or gap. This avoids duplicate work and lets us agree on where a change belongs before you write it.

## Ground rules for this repository

* **Two kinds of docs, two places.** Files the AI agent uses live under `template/.frappe-agent/` and are installed into a user's bench. Documentation for *people* (install, configuration, how a task runs) lives in `guide/` and is **not** installed. Do not put human-facing guides inside `template/`; the agent would carry them around.
* **Single source of truth.** Each rule should live in exactly one place. If a concept already has a home (e.g. the Git rules live in `template/.frappe-agent/workflow/GIT_WORKFLOW.md`, the extension-point decision tree lives in `template/.frappe-agent/knowledge/05-business-logic-and-jobs.md`), link to it instead of restating it elsewhere.
* **Everything installable lives in `template/`.** It contains `AGENTS.md` and the `.frappe-agent/` folder, and the installer copies exactly those two items into a user's bench. Do not add other files to a user's project root.
* **Keep `knowledge/` parts focused.** `knowledge/INDEX.md` is the routing table agents use to pick what to read. If you add a topic, put it in the most relevant existing part (or propose a new part) and add a row to `INDEX.md`.
* **Keep `template/AGENTS.md` short.** It is loaded on every task. Hard rules and the process flow only; detail belongs in `.frappe-agent/`.
* **Hooks must fail open and match the docs.** `hooks/guard.sh` mirrors `workflow/GIT_WORKFLOW.md`, `workflow/PERMISSIONS_AND_PRODUCTION.md` and `config.json`; change them together. `policy.json` is the single source for patterns, so do not hard-code new ones in the hook. Test hooks with sample JSON input (see how `guard.sh` reads `tool_input.command`) before opening a PR.
* **User data survives updates.** `config.json`, `policy.json`, `project_knowledge/`, `tasks/` and `audit/` are never overwritten by `--update`; if you add another user-owned file, add it to `is_user_data` in `install.sh` and to the keep list in `uninstall.sh`.
* **Reference sections by heading, not by number.** Files under `template/` deliberately have no numbered sections — numbers are fragile (renumbering cascades whenever content is merged or reordered) and add nothing for an AI agent, which reads by heading/content, not by index. Cross-reference a section with its heading text and a link (e.g. `["Business Logic Placement"](./05-business-logic-and-jobs.md)`), never `Section 46`. Keep heading hierarchy correct too: one `#` (H1) per file for its title, `##` for major sections, `###` for subsections.
* **Concise over exhaustive.** Agent-facing files are read as working context on every task — prefer short, decisive rules and one clear example over long prose or multiple redundant examples.
* **`install.sh` / `uninstall.sh` stay in sync.** Both rely on the `<!-- frappe-agent:start -->` / `<!-- frappe-agent:end -->` markers in `template/AGENTS.md`. If you add, rename, or remove anything the installer copies, or change the markers, update both scripts.

## Making changes

1. Follow the branch naming and commit message conventions in [`template/.frappe-agent/workflow/GIT_WORKFLOW.md`](./template/.frappe-agent/workflow/GIT_WORKFLOW.md) (e.g. `docs/<topic>` branch, `docs: clarify patch naming rule` commit).
2. If you change `install.sh` or `uninstall.sh`, test them locally against a scratch directory before opening a PR — both scripts support `--dir <path>` for exactly this:
   ```bash
   mkdir -p /tmp/template-test/apps /tmp/template-test/sites
   bash install.sh --source . --dir /tmp/template-test
   bash uninstall.sh --dir /tmp/template-test --yes
   ```
3. If you change any Markdown file, check that internal links still resolve (relative paths, not absolute) and that code fences are balanced.
4. Keep documentation changes and tooling changes (`install.sh`, `uninstall.sh`) in separate commits where practical, so history stays easy to review.

## Opening a pull request

Use the PR template (it's filled in automatically). At minimum, describe:

* What changed and why.
* Which file(s) are now the single source of truth for the topic, if you moved or de-duplicated content.
* How you verified it (links checked, scripts tested, etc.).

## Reporting problems instead of fixing them

If you spot a contradiction, a broken link, or duplicated content but don't have time to fix it, open an issue describing exactly what's wrong and where (file + section heading) — that's still a valuable contribution.
