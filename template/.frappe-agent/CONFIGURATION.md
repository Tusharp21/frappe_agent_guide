# Configuration Guide

Everything configurable lives in [`config.json`](./config.json) in this folder. The agent reads it before each task, and the enforcement hooks read it on every tool call. It is preserved when you update the template (`install.sh --update`). Edit it directly; there is no other settings file.

## First-time setup in a project

1. Install from the bench root (see the repository README).
2. Open `config.json` and set `environments.production` to your real production site names and hosts. This is the most important setting.
3. Decide the approval mode and which task tiers get an audit record.
4. Optional: install enforcement (see [Enforcement](#enforcement)).
5. Fill `project_knowledge/APP_MAP.md` once, or let the agent do it on its first task.

## Settings

| Setting | Values | Meaning |
| ------- | ------ | ------- |
| `approval_mode` | `ask_each_task` (default), `always_plan` | `ask_each_task`: at the start of every task the agent shows what it understood and asks whether to wait for plan approval or run automatically. `always_plan`: always wait for plan approval, never offer auto. |
| `auto_mode_allowed_tiers` | list of `trivial`, `standard`, `major` | Tiers for which the agent may offer auto mode. Default is `trivial` and `standard`. Keep `major` out. |
| `audit.enabled` | `true` / `false` | Turn the audit trail on or off. |
| `audit.tiers` | list of tiers | Tasks of these tiers get a `RUN-YYYY-NNN.md` record. Default is `standard` and `major`. |
| `audit.log_commands` | `true` / `false` | Claude Code, Cursor and Copilot hooks append each shell command to `audit/commands.log` (secrets masked). |
| `environments.production.sites` | list of site names | Exact production site names. The agent is read-only there. |
| `environments.production.hosts` | list of hostnames or IPs | Production servers. Any command mentioning them is blocked. |
| `environments.production.name_words` | list of words | A `--site` or SSH target containing one of these as a word (`prod`, `production`, `live`) is treated as production. |
| `protected_files` | list of file-name globs | Files the agent may not read or edit (secrets). `*.example`, `*.sample` and `*.template` variants are allowed. |
| `blocked_commands` | list of regular expressions | High-risk commands, blocked outright. |
| `ask_commands` | list of regular expressions | Medium-risk commands; the agent's tool asks you first. |

Patterns are case-insensitive regular expressions written as JSON strings, so backslashes are doubled (`\\b`). To loosen a rule, remove its entry; to add one, append a pattern.

## Where things are stored

| What | Where | In git? |
| ---- | ----- | ------- |
| Audit records | `audit/RUN-YYYY-NNN.md` | No (`audit/` is ignored and kept on update) |
| Command log | `audit/commands.log` | No |
| Project facts and decisions | `project_knowledge/` | Your choice; kept on update |
| Settings | `config.json` | Your choice; kept on update |

The bench root is normally not a Git repository, so all of this stays local to the machine.

## Using it day to day

* **Start a task** by describing it. The agent classifies it, reads `config.json`, and asks whether to wait for plan approval or run automatically.
* **Review the plan.** For Standard and Major tasks the plan includes acceptance criteria; edit them before approving.
* **After the work**, the agent creates an audit record with `scripts/new_run.sh` and fills in the files changed, the commands it ran, the real test output, risks and the commit.
* **For production**, the agent gives you a deployment plan. You run it.
* **Repeated mistake?** Add a rule to `AGENTS.md` or `project_knowledge/DECISIONS.md`; if it keeps happening, add a test or a `blocked_commands`/`ask_commands` pattern.

## Enforcement

Rules in `AGENTS.md` are advisory. These layers enforce them; all are opt-in at install time:

| Layer | Covers | How |
| ----- | ------ | --- |
| Git `pre-push` hook | **Every agent** and humans | `scripts/install_git_hooks.sh` (or `install.sh --with-git-hooks`) installs it in each `apps/<app>` repository. Blocks pushes to `main`/`master`, remote branch deletion and force pushes. A human can bypass with `git push --no-verify`. |
| Claude Code hooks | Claude Code | `install.sh --with-claude-hooks` |
| Cursor hooks and `.cursorignore` | Cursor | `install.sh --with-cursor-hooks` |
| Copilot hooks | GitHub Copilot (VS Code agent mode, CLI, coding agent) | `install.sh --with-copilot-hooks` |

The hook layers all run the same `hooks/guard.sh`, so `config.json` is the single source of truth. Run `install.sh --with-all-hooks` to install them all.

### Limits to know about

* Hooks are a safety net, not a security boundary. A shell one-liner such as `bash -c "..."` can evade pattern matching.
* The strongest protection for production is to **keep production credentials out of the agent's environment**: no production SSH keys, no production `site_config.json`, no VPN into production on the machine where the agent runs.
* `.cursorignore` does not stop terminal commands; the Cursor hook does. GitHub's Copilot content exclusion is a repository/organization setting and does not apply to agent mode, so the Copilot hook is the control there.
* The Cursor and Copilot hook formats are newer than Claude Code's. After installing, run one blocked command (for example ask the agent to `cat .env`) and confirm it is refused.
