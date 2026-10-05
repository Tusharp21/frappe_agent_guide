# Contributor Notes for AI Agents

This repository is the **source** of the Frappe AI Dev Template, not a Frappe project. What gets installed into a user's bench lives in `template/`:

* `template/AGENTS.md` — entry file (installed as `AGENTS.md`)
* `template/.frappe-agent/` — rules, docs, workflow, templates, project knowledge (installed as `.frappe-agent/`)

Read `CONTRIBUTING.md` before changing anything. In short:

* Edit content under `template/`; edit `install.sh` / `uninstall.sh` only for installer behavior.
* One source of truth per rule; link instead of duplicating.
* Test installer changes with `--source . --dir <scratch dir>` before opening a PR.
* Follow `template/.frappe-agent/GIT_WORKFLOW.md` for branches and commits; never push to `master`.
