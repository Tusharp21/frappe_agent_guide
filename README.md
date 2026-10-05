# FRAPPE-AI-DEV-TEMPLATE

## Overview
A structured rulebook for AI coding agents (Claude Code, Cursor, GitHub Copilot, Codex) working on Frappe/ERPNext projects. It makes the agent understand Frappe standard practices, analyze before writing code, ask for your approval before implementing, and review its own work.

## What gets installed
Exactly two items in your project (normally the **bench root**, the folder that contains `apps/` and `sites/`):

```
your-bench/
├── AGENTS.md          # short entry file: hard rules, process, pointers
└── .frappe-agent/     # everything else
    ├── docs/          # knowledge base + INDEX.md routing table
    ├── workflow/      # TASK.md master workflow + step docs; BUG, CODE_REVIEW, DEPLOYMENT
    ├── templates/     # TASK_RECORD.md (+ sections added step by step), DEPLOYMENT_PLAN.md
    ├── config.json    # workflow settings: approval mode, risk levels, history, production sites (yours; kept on update)
    ├── policy.json    # hook patterns: protected files, blocked/ask-first commands (yours; kept on update)
    ├── scripts/       # new_task.sh, task_state.sh, search_history.sh, inspect_app.sh, install_git_hooks.sh
    ├── hooks/         # guard/audit/lint hooks (used with --with-*-hooks)
    ├── tasks/         # one record per task: history + audit in one file (local, git-ignored, kept on update)
    ├── audit/         # command log (local, git-ignored, kept on update)
    ├── project_knowledge/   # your app map and decisions (kept on update)
    ├── GIT_WORKFLOW.md, FRAPPE_DEVELOPMENT.md, README.md, VERSION
```

Nothing else in your project is touched. If you already have an `AGENTS.md`, the template is added as a clearly marked block (`<!-- frappe-agent:start -->` … `<!-- frappe-agent:end -->`) and your content is left alone.

## Installation

1. `cd` into your bench root.
2. Run:

   ```bash
   curl -fsSL https://raw.githubusercontent.com/Tusharp21/frappe_agent_guide/master/install.sh | bash
   ```

3. Options (pass after `bash -s --`, e.g. `curl -fsSL .../install.sh | bash -s -- --update`):

   | Option | Effect |
   | ------ | ------ |
   | `--update` | Refresh `.frappe-agent/` and the `AGENTS.md` block; your `config.json`, `policy.json`, `project_knowledge/`, `tasks/` and `audit/` are preserved |
   | `--force` | Like `--update`, but also resets `config.json`, `policy.json` and `project_knowledge/` (`tasks/` and `audit/` are never touched) |
   | `--with-claude` | Create `CLAUDE.md` containing `@AGENTS.md` (see below) |
   | `--with-copilot` | Create `.github/copilot-instructions.md` pointing to `AGENTS.md` |
   | `--with-git-hooks` | `pre-push` hook in every `apps/<app>` repo; protects against **any** agent (see [Enforcement](#enforcement-opt-in)) |
   | `--with-claude-hooks` | `.claude/settings.json` hooks and `.claude/skills/` |
   | `--with-cursor-hooks` | `.cursor/hooks.json` and a `.cursorignore` block |
   | `--with-copilot-hooks` | `.github/hooks/frappe-agent.json` |
   | `--with-all-hooks` | All four of the above. None are on by default, so the default install stays at two items |
   | `--dir <path>` | Install somewhere other than the current directory |
   | `--branch <name>` / `--version <tag>` | Install from a branch or release tag |
   | `--dry-run` | Show what would change; write nothing |
   | `--yes` | Skip the "this is not a bench" prompt |
   | `--help` | List all options |

Prefer not to pipe a script into `bash`? Clone this repository and copy `template/AGENTS.md` and `template/.frappe-agent/` into your project by hand.

## How each agent picks it up

| Agent | Mechanism |
| ----- | --------- |
| Codex, Cursor, GitHub Copilot (agent mode) | Read `AGENTS.md` natively |
| Claude Code | Falls back to `AGENTS.md` when no `CLAUDE.md` exists (recent versions). If you already have a `CLAUDE.md`, the installer appends an `@AGENTS.md` import block so the rules still load. Use `--with-claude` for older versions. |
| Copilot chat | Use `--with-copilot` |

Then start the agent from the bench root and tell it: *"Read AGENTS.md first."*

## The task workflow
Every task follows `.frappe-agent/workflow/TASK.md`:

```text
UNDERSTAND -> CHECK EXISTING -> CLARIFY -> PROPOSE -> USER DECISION -> LOCK
           -> EXECUTE -> TEST -> REVIEW -> SUMMARY + AUDIT -> USER APPROVAL -> COMPLETE -> UPDATE HISTORY
```

* **Risk levels:** **LOW** (text/label/typo; no approval wait, summary only), **MEDIUM** (business logic, validation, scripts, reports, APIs; full flow with your approval), **HIGH** (migration/patch, permissions/security, production-impacting; adds rollback plan, test-site validation, deployment plan, tests may not be skipped).
* **Ask at the start of every task.** The agent gives its understanding and asks whether to propose a solution and wait for your decision, or run automatically. Automatic is never offered for HIGH and never skips the permission rules. Configurable (`approval_mode`).
* **Clarify, don't guess.** Ambiguous business points become short questions with options.
* **Solution lock.** Once you decide, the solution is locked; the agent cannot change it silently and must come back to you if it has to.
* **Task states** (`DRAFT` to `COMPLETED`, plus `BLOCKED`) are tracked by `scripts/task_state.sh`, which rejects out-of-order moves and requires the agent to quote your words when locking or completing.
* **History as memory.** Each MEDIUM/HIGH task is one local file with a short card on top; `scripts/search_history.sh <keywords>` shows only the cards of matching past tasks, plus decisions and git history, so the agent checks existing work cheaply before building.
* **Other workflows:** `BUG.md` (reproduce, diagnose, fix, regression test), `CODE_REVIEW.md`, `DEPLOYMENT.md`.

## Discovery and verification
* `.frappe-agent/scripts/inspect_app.sh [app]` prints an app's branch, modules, `hooks.py` settings, DocTypes, fixtures and patches. It is read-only.
* `.frappe-agent/workflow/REVIEW.md` lists the commands the agent must actually run per risk level (linter, `bench run-tests`, and `bench migrate` on a test site for HIGH changes) and asks for a separate read-only reviewer on the diff.

## Controls this template adds
* **Acceptance criteria** in every MEDIUM/HIGH proposal, so "done" has a definition.
* **Permission policy** (action levels: automatic, ask first, prohibited) in `workflow/PERMISSIONS_AND_PRODUCTION.md`.
* **Production is read-only for the agent.** It writes a deployment plan (`templates/DEPLOYMENT_PLAN.md`); a human runs it. Configure your production sites and hosts in `config.json`.
* **Secrets stay out of the agent's context** (`.env`, `site_config.json`, keys).
* **Audit trail:** the task record holds requirement, criteria, locked solution, files, commands, real test output, risks, approval and commit, stored locally in `.frappe-agent/tasks/` (outside git; `history.path` can point to a shared folder), plus an optional command log.

Everything is configured in `.frappe-agent/config.json` (workflow) and `.frappe-agent/policy.json` (hook patterns); see `.frappe-agent/CONFIGURATION.md` for the full guide.

## Enforcement (opt-in)
Rules in `AGENTS.md` are advisory. These layers enforce them:

| Layer | Covers | Blocks / asks |
| ----- | ------ | ------------- |
| Git `pre-push` hook (`--with-git-hooks`) | Every agent and humans | Push to `main`/`master`, remote branch deletion, force-push (humans can use `--no-verify`) |
| Claude Code hooks (`--with-claude-hooks`) | Claude Code | Everything below, plus a ruff lint check on edited Python and the `frappe-*` skills |
| Cursor hooks (`--with-cursor-hooks`) | Cursor | Everything below; `.cursorignore` also hides secrets from file reads |
| Copilot hooks (`--with-copilot-hooks`) | Copilot (VS Code agent mode, CLI, coding agent) | Everything below |

What the hooks decide, from one shared `hooks/guard.sh` driven by `policy.json` and `config.json`:
* **Blocked:** push to `main`/`master`, force-push, `--no-verify`, `reset --hard`, `clean`, `branch -D`, `--ours`/`--theirs`; any command targeting a production site or host; reading or editing protected files; destructive SQL, `bench drop-site`, firewall/DNS changes.
* **Asks first:** dependency installs, `bench migrate`/`restore`/`execute`/…, deletes, `curl`/`wget`, `git push`, `sudo`.

Honest limits:
* Hooks are a safety net, not a security boundary: `bash -c "..."` and similar tricks can evade pattern matching.
* The strongest protection for production is to **keep production credentials out of the agent's environment** (no production SSH keys or `site_config.json` on that machine).
* The Cursor and Copilot hook formats are newer and were verified against their documentation, not in a live session. After installing, ask the agent to `cat .env` and confirm it is refused.
* `.cursorignore` does not stop terminal commands (the hook does); Copilot's content exclusion is a GitHub setting that does not apply to agent mode (the hook does).

## Token efficiency
The agent reads only what a step needs, not the whole knowledge base:
* `AGENTS.md` (always loaded) has a short LOW-task path, so a typo fix never reads the task workflow.
* `docs/INDEX.md` routes to one doc, and `scripts/doc_sections.sh <NN>` lists its headings with line ranges so only one section is read.
* `GIT_WORKFLOW.md` holds the rules; examples and templates are in `GIT_REFERENCE.md`, read only when needed.
* The task record starts as a short card; `scripts/task_section.sh` appends each section's format only when that step is reached, and `scripts/search_history.sh` shows future tasks just the card.
* `config.json` is small (what the agent reads); the regex patterns for hooks are in `policy.json`.
* `scripts/inspect_app.sh` caps long lists (use `--filter` or `--all`).

## Linting (pre-commit)
This template does not ship a pre-commit config. Each Frappe app has its own `.pre-commit-config.yaml`; enable it once per app:

```bash
pip install pre-commit
cd apps/<app_name> && pre-commit install
```

The agent follows the app's config and never bypasses it with `--no-verify`.

## Git and the bench
The bench root is usually not a Git repository; each app under `apps/` is. The agent runs Git operations inside the app being changed and never pushes to `main`/`master`. Details are in `.frappe-agent/GIT_WORKFLOW.md`.

## Basic workflow
1. **You:** describe the task in plain language.
2. **Agent:** reads `AGENTS.md`, classifies the risk, searches past work, and asks whether to propose and wait for your decision or run automatically.
3. **You:** answer its questions and choose a solution; it locks your decision.
4. **Agent:** implements only the locked solution, tests with real commands, reviews the diff, and gives a summary.
5. **You:** approve (MEDIUM/HIGH). The agent then records the task and updates `project_knowledge/`.
6. **Production:** the agent writes a deployment plan; you deploy and report the result.

## Updating from an older install
Older versions copied files (`FRAPPE_DEVELOPMENT.md`, `docs/`, `workflow/`, …) into the project root. The installer detects these and lists them; once you've checked they hold no local changes, delete them by hand.

## Uninstallation
From the folder you installed into:

```bash
curl -fsSL https://raw.githubusercontent.com/Tusharp21/frappe_agent_guide/master/uninstall.sh | bash
```

It lists what it will remove and asks for confirmation (`--yes` to skip, `--keep-knowledge` to keep `project_knowledge/`). It removes `.frappe-agent/` and only the marked block in `AGENTS.md` / `CLAUDE.md` / `.github/copilot-instructions.md`; a file is deleted only if nothing else was in it.

## Repository layout (for contributors)
* `template/` — the installable payload (`AGENTS.md` and `.frappe-agent/`)
* `install.sh`, `uninstall.sh` — installer scripts
* `CONTRIBUTING.md`, `.github/PULL_REQUEST_TEMPLATE.md`, `LICENSE`
* `AGENTS.md` — short notes for AI agents working on this repository itself
