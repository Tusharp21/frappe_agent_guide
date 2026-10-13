# 04 Safety and enforcement

## What the template adds

* **Acceptance criteria** in every MEDIUM and HIGH proposal, so "done" has a definition.
* **A permission policy.** Every command has an *action level*: **automatic** (read, search, edit app code, lint, run tests on a dev site, `git add`/`commit` on a branch), **ask first** (install a dependency, `bench migrate`/`build`/`update`/`restore`/`execute`/`console`/`set-config`, delete files, `curl`/`wget`, `git push` of a branch, `sudo`), or **prohibited** (anything on production, destructive SQL, `bench drop-site`, secrets, firewall/DNS, force-push, deleting branches, push to `main`/`master`). Approval for one action does not extend to the next. Automatic mode (see [03](./03-daily-use.md)) skips only the wait for your decision, never this policy.
* **Production is read-only for the agent.** It never runs anything against a production site or host, not even harmless-looking read commands. It writes a deployment plan (`templates/DEPLOYMENT_PLAN.md`: changes, migrations, backup, validation, rollback, approvals) and you run it. If it needs information from production, it asks you to run a command and paste the output.
* **Secrets stay out of the agent's context** (`.env`, `site_config.json`, `common_site_config.json`, keys). `site_config.json` holds database passwords.
* **An audit trail** in each task record, plus an optional command log ([05](./05-history-and-audit.md)).

Production is identified by `environments.production` in `config.json` plus any `--site` or SSH target containing `prod`, `production` or `live` as a word ([02](./02-configuration.md)). Set it first.

## Enforcement (opt-in)

Rules in `AGENTS.md` are advisory. These layers enforce them; install them with the `--with-*` options ([01](./01-install-update-uninstall.md)):

| Layer | Covers | Blocks / asks |
| ----- | ------ | ------------- |
| Git `pre-push` hook (`--with-git-hooks`) | **Every agent** and humans | Push to `main`/`master`, remote branch deletion, force-push. A human can bypass with `git push --no-verify` |
| Claude Code hooks (`--with-claude-hooks`) | Claude Code | Everything below, plus a ruff lint check on edited Python and the `frappe-*` skills |
| Cursor hooks (`--with-cursor-hooks`) | Cursor | Everything below; `.cursorignore` also hides secrets from file reads |
| Copilot hooks (`--with-copilot-hooks`) | Copilot (VS Code agent mode, CLI, coding agent) | Everything below |

`--with-all-hooks` installs all of them. The hook layers run one shared `hooks/guard.sh`, driven by `policy.json` and `config.json`:

* **Blocked:** push to `main`/`master`, force-push, `--no-verify`, `reset --hard`, `clean`, `branch -D`, `--ours`/`--theirs`; any command targeting a production site or host; reading or editing protected files; destructive SQL, `bench drop-site`, firewall/DNS changes.
* **Asks first:** dependency installs, `bench migrate`/`restore`/`execute`/..., deletes, `curl`/`wget`, `git commit`, `git push`, `sudo`.
* **Process gates** (`process_gates` in `policy.json`, on by default; see [02](./02-configuration.md)): app code under `apps/` can be edited only while the active task is `LOCKED` or `IN_PROGRESS`, and only inside the card's `Allowed paths` when set. With no active task the agent's tool asks you (so a LOW change costs one click). A task cannot wait for your approval while its card says `Tests: NOT RUN`.
* **Phase scope is fixed once approved:** a task's `Allowed paths` cannot be edited after the task leaves `DRAFT`; widening it needs a new decision. Tasks started from a plan get their paths from the locked plan.
* **The agent cannot lock itself:** it may not edit a record's `State:` line, `tasks/.active`, or the files that define its rules (`.frappe-agent/` except `tasks/`, `project_knowledge/` and `audit/`; `AGENTS.md`; the hook settings). You change those yourself.

These gates are enforced by the Claude Code and Copilot hooks, which see edit tools. Cursor's hooks cover shell commands and file reads only, and Codex has no hooks, so there the process gates do not apply and `AGENTS.md` is advisory.

An existing `.claude/settings.json`, `.cursor/hooks.json` or `.github/hooks/frappe-agent.json` is never overwritten: the installer tells you to merge by hand.

## Limits to know about

* Hooks are a safety net, not a security boundary. A shell one-liner such as `bash -c "..."` can evade pattern matching.
* The strongest protection for production is to **keep production credentials out of the agent's environment**: no production SSH keys, no production `site_config.json`, no VPN into production on the machine where the agent runs.
* `.cursorignore` does not stop terminal commands; the Cursor hook does. GitHub's Copilot content exclusion is a repository/organization setting and does not apply to agent mode, so the Copilot hook is the control there.
* The Cursor and Copilot hook formats are newer than Claude Code's and were verified against their documentation, not in a live session. After installing, ask the agent to `cat .env` and confirm it is refused.
* Task states and the solution lock are process friction, not a guarantee ([03](./03-daily-use.md)). The hooks cannot tell whether the quote in `--note` really came from you, and a shell trick the patterns do not recognise can still write a file. Read the summary before you approve.
* There is one active task per bench (`tasks/.active`). Two agent sessions on the same bench at once overwrite each other's pointer.
* Without `python3` the hook blocks every call rather than letting everything through. If the hook input cannot be parsed, the call is allowed.
