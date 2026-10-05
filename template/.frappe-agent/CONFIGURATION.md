# Configuration Guide

Everything configurable lives in [`config.json`](./config.json) in this folder. The agent reads it before each task, and the enforcement hooks read it on every tool call. It is preserved when you update the template (`install.sh --update`). Edit it directly; there is no other settings file.

## First-time setup in a project

1. Install from the bench root (see the repository README).
2. Open `config.json` and set `environments.production` to your real production site names and hosts. This is the most important setting.
3. Decide the approval mode and which risk levels get a task record.
4. Optional: install enforcement (see [Enforcement](#enforcement)).
5. Fill `project_knowledge/APP_MAP.md` once, or let the agent do it on its first task.

## Settings

| Setting | Values | Meaning |
| ------- | ------ | ------- |
| `approval_mode` | `ask_each_task` (default), `always_plan` | `ask_each_task`: in its first message of every task the agent gives its understanding and asks whether to propose a solution and wait for your decision, or run automatically. `always_plan`: always wait for your decision, never offer automatic. |
| `auto_mode_allowed_risk` | list of `low`, `medium`, `high` | Risk levels for which the agent may offer automatic mode. Default is `low` and `medium`. Keep `high` out. |
| `final_approval_required_for` | list of risk levels | Tasks of these levels wait for your approval before they can be COMPLETED. Default is `medium` and `high`; LOW tasks complete after the summary (you can still reject them). |
| `history.enabled` | `true` / `false` | Turn task records on or off. |
| `history.path` | folder path | Where task records live. Default `tasks` (inside `.frappe-agent/`). Relative paths are resolved from `.frappe-agent/`; an absolute path (for example a shared folder or a checkout of a private repo) works too. |
| `history.record_for` | list of risk levels | Tasks of these levels get a `TASK-YYYY-NNN.md` record. Default `medium` and `high`; LOW tasks get a short summary only. |
| `audit.enabled` | `true` / `false` | Turn the command log on or off. |
| `audit.log_commands` | `true` / `false` | Claude Code, Cursor and Copilot hooks append each shell command to `audit/commands.log` (secrets masked). |
| `environments.production.sites` | list of site names | Exact production site names. The agent is read-only there. |
| `environments.production.hosts` | list of hostnames or IPs | Production servers. Any command mentioning them is blocked. |
| `environments.production.name_words` | list of words | A `--site` or SSH target containing one of these as a word (`prod`, `production`, `live`) is treated as production. |
| `protected_files` | list of file-name globs | Files the agent may not read or edit (secrets). `*.example`, `*.sample` and `*.template` variants are allowed. |
| `blocked_commands` | list of regular expressions | Prohibited actions, blocked outright. |
| `ask_commands` | list of regular expressions | Ask-first actions; the agent's tool asks you first. |

Patterns are case-insensitive regular expressions written as JSON strings, so backslashes are doubled (`\\b`). To loosen a rule, remove its entry; to add one, append a pattern.

### Upgrading an older `config.json`

`--update` keeps your `config.json`, so it will not get new keys by itself. If you installed before the task workflow (version 1.3.0), edit it by hand: rename `auto_mode_allowed_tiers` to `auto_mode_allowed_risk` with `trivial/standard/major` becoming `low/medium/high`, delete `audit.tiers`, and add `final_approval_required_for` and the `history` block from the table above. The hooks only read `audit.log_commands`, `environments`, `protected_files`, `blocked_commands` and `ask_commands`, so nothing breaks if you do not. Older `audit/RUN-*.md` records are still found by `search_history.sh`.

## Where things are stored

| What | Where | In git? |
| ---- | ----- | ------- |
| Task records (history and audit in one file per task) | `tasks/TASK-YYYY-NNN.md`, or `history.path` | No (`tasks/` is ignored and kept on update) |
| Command log | `audit/commands.log` | No |
| Project facts and decisions | `project_knowledge/` | Your choice; kept on update |
| Settings | `config.json` | Your choice; kept on update |

The bench root is normally not a Git repository, so all of this stays local to the machine. To share history with your team, point `history.path` at a shared folder or at a checkout of a private repository that your team commits to, and keep it out of the app repositories.

## Using it day to day

* **Start a task** by describing it. The agent classifies the risk (LOW / MEDIUM / HIGH), searches past work, and asks in its first message whether to propose and wait for your decision, or run automatically.
* **Answer its questions.** For anything ambiguous it asks short questions with options instead of guessing.
* **Decide.** For MEDIUM and HIGH it proposes a solution with acceptance criteria; you pick or edit, and it locks your decision. It will not change a locked solution without asking you again.
* **Approve.** After testing and review it gives a summary; for MEDIUM and HIGH the task completes only when you approve.
* **For production** the agent writes a deployment plan. You run it and tell the agent the result so it can record it.
* **Find old work** with `scripts/search_history.sh <keywords>`, which prints just the short card of matching tasks.
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
