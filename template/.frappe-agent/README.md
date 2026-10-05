# .frappe-agent

Rulebook and knowledge base for AI coding agents (Claude Code, Cursor, GitHub Copilot, Codex) working on Frappe/ERPNext projects. Everything the agent needs is in this folder; the only other file the installer touches is `AGENTS.md` in the project root.

## Layout

| Path | Purpose |
| ---- | ------- |
| `docs/INDEX.md` | Routing table: which doc to read for which task |
| `docs/01…10-*.md` | Frappe development knowledge base |
| `FRAPPE_DEVELOPMENT.md` | Table of contents for `docs/` |
| `workflow/` | Requirement analysis, implementation, and review steps |
| `GIT_WORKFLOW.md` | Branching, commit, and safety rules |
| `templates/TASK_TEMPLATE.md` | Format for documenting a task |
| `scripts/inspect_app.sh` | Read-only discovery of a bench or app |
| `hooks/`, `adapters/claude/` | Claude Code guard/lint hooks, settings and skills (used only with `--with-claude-hooks`) |
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

Re-run the installer with `--update`. Template files are replaced; `project_knowledge/` is preserved.
