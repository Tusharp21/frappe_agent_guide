# 02 Configuration

Settings live in two small files in `.frappe-agent/`, both preserved when you update the template; edit them directly:

* `config.json`: the workflow settings the agent reads at the start of each task (approval mode, risk levels, history, production sites). Kept small on purpose.
* `policy.json`: the command and file patterns the enforcement hooks apply on every tool call (protected files, blocked and ask-first commands, the command log). The agent does not need to read it.

A key in `config.json` overrides the same key in `policy.json`, so installs made before the split keep working.

## First-time setup

1. Install from the bench root ([01](./01-install-update-uninstall.md)).
2. Open `config.json` and set `environments.production` to your real production site names and hosts. This is the most important setting.
3. Decide the approval mode and which risk levels get a task record.
4. Optional: turn on enforcement ([04](./04-safety-and-enforcement.md)).
5. Fill `project_knowledge/APP_MAP.md` once, or let the agent do it on its first task.

## Settings

| Setting | Values | Meaning |
| ------- | ------ | ------- |
| `approval_mode` | `ask_each_task` (default), `always_plan` | `ask_each_task`: in its first message of every task the agent gives its understanding and asks whether to propose a solution and wait for your decision, or run automatically. `always_plan`: always wait for your decision, never offer automatic |
| `auto_mode_allowed_risk` | list of `low`, `medium`, `high` | Risk levels for which the agent may offer automatic mode. Default `low` and `medium`. Keep `high` out |
| `final_approval_required_for` | list of risk levels | Tasks of these levels wait for your approval before they can be COMPLETED. Default `medium` and `high`; LOW tasks complete after the summary (you can still reject them) |
| `history.enabled` | `true` / `false` | Turn task records on or off |
| `history.path` | folder path | Where task records live. Default `tasks` (inside `.frappe-agent/`). Relative paths resolve from `.frappe-agent/`; an absolute path (a shared folder, or a checkout of a private repo) works too |
| `history.record_for` | list of risk levels | Tasks of these levels get a `TASK-YYYY-NNN.md` record. Default `medium` and `high`; LOW tasks get a short summary only |
| `environments.production.sites` | list of site names | Exact production site names. The agent is read-only there |
| `environments.production.hosts` | list of hostnames or IPs | Production servers. Any command mentioning them is blocked |
| `environments.production.name_words` | list of words | A `--site` or SSH target containing one of these as a word (`prod`, `production`, `live`) is treated as production |
| `audit.enabled` (`policy.json`) | `true` / `false` | Turn the command log on or off |
| `audit.log_commands` (`policy.json`) | `true` / `false` | The Claude Code, Cursor and Copilot hooks append each shell command to `audit/commands.log` (secrets masked) |
| `protected_files` (`policy.json`) | list of file-name globs | Files the agent may not read or edit (secrets). `*.example`, `*.sample` and `*.template` variants are allowed |
| `blocked_commands` (`policy.json`) | list of regular expressions | Prohibited actions, blocked outright |
| `ask_commands` (`policy.json`) | list of regular expressions | Ask-first actions; the agent's tool asks you first |

Patterns are case-insensitive regular expressions written as JSON strings, so backslashes are doubled (`\\b`). To loosen a rule, remove its entry; to add one, append a pattern.

## Upgrading an older `config.json`

`--update` keeps your `config.json`, so it will not get new keys by itself. If you installed before the task workflow (version 1.3.0), edit it by hand: rename `auto_mode_allowed_tiers` to `auto_mode_allowed_risk` with `trivial/standard/major` becoming `low/medium/high`, delete `audit.tiers`, and add `final_approval_required_for` and the `history` block from the table above. The hooks only read `audit.log_commands`, `environments`, `protected_files`, `blocked_commands` and `ask_commands`, so nothing breaks if you do not. Older `audit/RUN-*.md` records are still found by `search_history.sh`.

## Where things are stored

| What | Where | In git? |
| ---- | ----- | ------- |
| Task records (history and audit in one file per task) | `tasks/TASK-YYYY-NNN.md`, or `history.path` | No (`tasks/` is ignored and kept on update) |
| Command log | `audit/commands.log` | No |
| Project facts and decisions | `project_knowledge/` | Your choice; kept on update |
| Settings | `config.json`, `policy.json` | Your choice; kept on update |

The bench root is normally not a Git repository, so all of this stays local to the machine. See [05 History and audit](./05-history-and-audit.md) for sharing it with a team.
