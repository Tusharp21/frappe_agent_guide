# Contributing to the Frappe AI Dev Template

Thanks for wanting to improve this template. This repository is documentation and tooling for AI coding agents (and human developers) working on Frappe/ERPNext projects — contributions should make those instructions clearer, more correct, or more complete, without turning the knowledge base into a duplicate-riddled mess.

## Before you start

For anything beyond a typo fix, open an issue first describing the problem or gap. This avoids duplicate work and lets us agree on where a change belongs before you write it.

## Ground rules for this repository

* **Single source of truth.** Each rule should live in exactly one place. If a concept already has a home (e.g. the Git rules live in `GIT_WORKFLOW.md`, the extension-point decision tree lives in `docs/05-business-logic-and-jobs.md`), link to it instead of restating it elsewhere.
* **Keep `docs/` parts focused.** `FRAPPE_DEVELOPMENT.md` is a table-of-contents index into 10 files under `docs/`. If you're adding a new topic, put it in the most relevant existing part, or propose a new part rather than growing one file indefinitely.
* **Reference sections by heading, not by number.** `docs/`, `GIT_WORKFLOW.md`, and `AGENTS.md` deliberately have no numbered sections — numbers are fragile (renumbering cascades whenever content is merged or reordered) and add nothing for an AI agent, which reads by heading/content, not by index. Cross-reference a section with its heading text and a link (e.g. `["Business Logic Placement"](./05-business-logic-and-jobs.md)`), never `Section 46`. Keep heading hierarchy correct too: one `#` (H1) per file for its title, `##` for major sections, `###` for subsections.
* **Concise over exhaustive.** This is read by an AI agent as working context on every task — prefer short, decisive rules and one clear example over long prose or multiple redundant examples.
* **`install.sh` / `uninstall.sh` stay in sync.** If you add, rename, or remove a top-level file or folder that should be installed into a target project (currently `AGENTS.md`, `FRAPPE_DEVELOPMENT.md`, `GIT_WORKFLOW.md`, `LICENSE`, `docs/`, `workflow/`, `templates/`, `.pre-commit-config.yaml`), update the `ITEMS` array in both scripts.

## Making changes

1. Follow the branch naming and commit message conventions in [`GIT_WORKFLOW.md`](./GIT_WORKFLOW.md) (e.g. `docs/<topic>` branch, `docs: clarify patch naming rule` commit).
2. If you change `install.sh` or `uninstall.sh`, test them locally against a scratch directory before opening a PR — both scripts support `--dir <path>` for exactly this:
   ```bash
   mkdir -p /tmp/template-test && bash install.sh --dir /tmp/template-test
   bash uninstall.sh --dir /tmp/template-test --yes
   ```
3. If you change any Markdown file, check that internal links still resolve (relative paths, not absolute) and that code fences are balanced.
4. Keep documentation changes and tooling changes (`install.sh`, `uninstall.sh`, `.pre-commit-config.yaml`) in separate commits where practical, so history stays easy to review.

## Opening a pull request

Use the PR template (it's filled in automatically). At minimum, describe:

* What changed and why.
* Which file(s) are now the single source of truth for the topic, if you moved or de-duplicated content.
* How you verified it (links checked, scripts tested, etc.).

## Reporting problems instead of fixing them

If you spot a contradiction, a broken link, or duplicated content but don't have time to fix it, open an issue describing exactly what's wrong and where (file + section heading) — that's still a valuable contribution.
