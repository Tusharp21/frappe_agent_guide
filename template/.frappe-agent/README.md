# .frappe-agent

Rulebook and knowledge base for AI coding agents (Claude Code, Cursor, GitHub Copilot, Codex) working on Frappe/ERPNext projects. Everything the agent needs is in this folder; the only other file the installer touches is `AGENTS.md` in the project root.

## Layout

| Path | Purpose |
| ---- | ------- |
| `docs/INDEX.md` | Routing table: which doc to read for which task |
| `docs/01…10-*.md` | Frappe development knowledge base |
| `FRAPPE_DEVELOPMENT.md` | Table of contents for `docs/` |
| `workflow/` | `TASK.md` (master workflow), its step documents, and the `BUG`, `CODE_REVIEW` and `DEPLOYMENT` workflows |
| `GIT_WORKFLOW.md` | Branching, commit, and safety rules |
| `templates/` | `TASK_RECORD.md` (history and audit in one file) and `DEPLOYMENT_PLAN.md` |
| `config.json` | Your settings: approval mode, audit, production sites, protected files, blocked/ask commands (see `CONFIGURATION.md`) |
| `CONFIGURATION.md` | How to configure and use all of this in a project |
| `workflow/PERMISSIONS_AND_PRODUCTION.md` | Risk policy, read-only production, secrets |
| `scripts/` | `new_task.sh`, `task_state.sh`, `search_history.sh`, `inspect_app.sh`, `install_git_hooks.sh` |
| `hooks/`, `adapters/` | Enforcement hooks and agent settings (used only with `--with-*-hooks`) |
| `tasks/` | Local task records, one file per task (created on first use; git-ignored; location set by `history.path`) |
| `audit/` | Local command log (created on first use; git-ignored) |
| `project_knowledge/` | Your project's facts and decisions (kept on update) |
| `VERSION` | Installed template version |

## Linting (pre-commit)

This template does not ship a pre-commit config. Each Frappe app already has its own `.pre-commit-config.yaml`. To enable the hooks, run once per app:

```bash
pip install pre-commit
cd apps/<app_name> && pre-commit install
```

The agent follows the app's config and never bypasses it with `--no-verify`.

## Updating

Re-run the installer with `--update`. Template files are replaced; `config.json`, `project_knowledge/`, `tasks/` and `audit/` are preserved.
