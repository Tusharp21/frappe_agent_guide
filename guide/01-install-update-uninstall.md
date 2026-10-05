# 01 Install, update, uninstall

## Install

1. `cd` into your bench root.
2. Run:

   ```bash
   curl -fsSL https://raw.githubusercontent.com/Tusharp21/frappe_agent_guide/master/install.sh | bash
   ```

3. Open `.frappe-agent/config.json` and set your production sites and hosts (see [02 Configuration](./02-configuration.md)).
4. Start your agent from the bench root and tell it: *"Read AGENTS.md first."*

Prefer not to pipe a script into `bash`? Clone this repository and copy `template/AGENTS.md` and `template/.frappe-agent/` into your project by hand.

### Options

Pass them after `bash -s --`, for example `curl -fsSL .../install.sh | bash -s -- --update`.

| Option | Effect |
| ------ | ------ |
| `--update` | Refresh `.frappe-agent/` and the `AGENTS.md` block; your `config.json`, `policy.json`, `project_knowledge/`, `tasks/` and `audit/` are preserved |
| `--force` | Like `--update`, but also resets `config.json`, `policy.json` and `project_knowledge/` (`tasks/` and `audit/` are never touched) |
| `--with-claude` | Create `CLAUDE.md` containing `@AGENTS.md` |
| `--with-copilot` | Create `.github/copilot-instructions.md` pointing to `AGENTS.md` |
| `--with-git-hooks` | `pre-push` hook in every `apps/<app>` repo; protects against **any** agent |
| `--with-claude-hooks` | `.claude/settings.json` hooks and `.claude/skills/` |
| `--with-cursor-hooks` | `.cursor/hooks.json` and a `.cursorignore` block |
| `--with-copilot-hooks` | `.github/hooks/frappe-agent.json` |
| `--with-all-hooks` | All four hook options. None are on by default, so the default install stays at two items |
| `--dir <path>` | Install somewhere other than the current directory |
| `--branch <name>` / `--version <tag>` | Install from a branch or release tag |
| `--dry-run` | Show what would change; write nothing |
| `--yes` | Skip the "this is not a bench" prompt |
| `--help` | List all options |

What the hook options do is explained in [04 Safety and enforcement](./04-safety-and-enforcement.md).

## How each agent picks it up

| Agent | Mechanism |
| ----- | --------- |
| Codex, Cursor, GitHub Copilot (agent mode) | Read `AGENTS.md` natively |
| Claude Code | Falls back to `AGENTS.md` when no `CLAUDE.md` exists (recent versions). If you already have a `CLAUDE.md`, the installer appends an `@AGENTS.md` import block so the rules still load. Use `--with-claude` for older versions |
| Copilot chat | Use `--with-copilot` |

## Linting (pre-commit)

This template does not ship a pre-commit config. Each Frappe app has its own `.pre-commit-config.yaml`; enable it once per app:

```bash
pip install pre-commit
cd apps/<app_name> && pre-commit install
```

The agent follows the app's config and never bypasses it with `--no-verify`.

## Git and the bench

The bench root is usually not a Git repository; each app under `apps/` is. The agent runs Git operations inside the app being changed and never pushes to `main`/`master`.

## Update

Re-run the installer with `--update`. Template files are replaced; your settings, project knowledge, task records and audit log are kept. `--update` does not add new keys to your existing `config.json`; check [02 Configuration](./02-configuration.md) after a major update.

Older versions copied files (`FRAPPE_DEVELOPMENT.md`, `docs/`, `workflow/`, ...) into the project root. The installer detects these and lists them; once you have checked they hold no local changes, delete them by hand.

## Uninstall

From the folder you installed into:

```bash
curl -fsSL https://raw.githubusercontent.com/Tusharp21/frappe_agent_guide/master/uninstall.sh | bash
```

It lists what it will remove and asks for confirmation (`--yes` to skip). It removes `.frappe-agent/` and only the marked block in `AGENTS.md` / `CLAUDE.md` / `.github/copilot-instructions.md` / `.cursorignore`; a file is deleted only if nothing else was in it. Hook files are removed only if you have not edited them. `--keep-knowledge` keeps `config.json`, `policy.json`, `project_knowledge/`, `tasks/` and `audit/`. Without it, your task history and audit log are deleted too, so keep them if you want the history.
