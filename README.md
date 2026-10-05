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
    ├── workflow/      # requirement analysis, implementation, review
    ├── templates/     # task, run report, deployment plan
    ├── config.json    # approval mode, audit, production sites, protected files (yours; kept on update)
    ├── scripts/       # inspect_app.sh, new_run.sh, install_git_hooks.sh
    ├── hooks/         # guard/audit/lint hooks (used with --with-*-hooks)
    ├── audit/         # local audit trail, created on first use (git-ignored; kept on update)
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
   | `--update` | Refresh `.frappe-agent/` and the `AGENTS.md` block; your `config.json`, `project_knowledge/` and `audit/` are preserved |
   | `--force` | Like `--update`, but also resets `config.json` and `project_knowledge/` (the audit trail is never touched) |
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

## Task tiers
The agent classifies each task before planning: **Trivial** (label/text/typo) gets a one-line plan, **Standard** gets the structured plan, and **Major** (new DocType, patch/schema change, permissions, integrations, jobs, multi-app) also needs the task template, a rollback plan and a migration-impact note. Every tier still needs your approval before code is written. See `.frappe-agent/workflow/REQUIREMENT_ANALYSIS.md`.

## Discovery and verification
* `.frappe-agent/scripts/inspect_app.sh [app]` prints an app's branch, modules, `hooks.py` settings, DocTypes, fixtures and patches. It is read-only and the analysis step uses it.
* `.frappe-agent/workflow/REVIEW.md` lists the commands the agent must actually run per tier (linter, `bench run-tests`, and `bench migrate` on a test site for Major changes) and asks for a separate read-only reviewer on the diff.

## Controls this template adds
* **Ask at the start of every task.** The agent says what it understood and asks whether to wait for plan approval or run automatically. Auto is never offered for Major tasks and never skips the permission rules. Configurable (`approval_mode`).
* **Acceptance criteria** in every Standard/Major plan, so "done" has a definition.
* **Permission policy** (Low: automatic, Medium: ask, High: prohibited) in `workflow/PERMISSIONS_AND_PRODUCTION.md`.
* **Production is read-only for the agent.** It writes a deployment plan (`templates/DEPLOYMENT_PLAN.md`); a human runs it. Configure your production sites and hosts in `config.json`.
* **Secrets stay out of the agent's context** (`.env`, `site_config.json`, keys).
* **Audit trail:** a local `RUN-YYYY-NNN.md` per task (requirement, criteria, files, commands, real test output, risks, commit) plus an optional command log. Stored in `.frappe-agent/audit/`, outside git.

Everything is configured in `.frappe-agent/config.json`; see `.frappe-agent/CONFIGURATION.md` for the full guide.

## Enforcement (opt-in)
Rules in `AGENTS.md` are advisory. These layers enforce them:

| Layer | Covers | Blocks / asks |
| ----- | ------ | ------------- |
| Git `pre-push` hook (`--with-git-hooks`) | Every agent and humans | Push to `main`/`master`, remote branch deletion, force-push (humans can use `--no-verify`) |
| Claude Code hooks (`--with-claude-hooks`) | Claude Code | Everything below, plus a ruff lint check on edited Python and the `frappe-*` skills |
| Cursor hooks (`--with-cursor-hooks`) | Cursor | Everything below; `.cursorignore` also hides secrets from file reads |
| Copilot hooks (`--with-copilot-hooks`) | Copilot (VS Code agent mode, CLI, coding agent) | Everything below |

What the hooks decide, from one shared `hooks/guard.sh` driven by `config.json`:
* **Blocked:** push to `main`/`master`, force-push, `--no-verify`, `reset --hard`, `clean`, `branch -D`, `--ours`/`--theirs`; any command targeting a production site or host; reading or editing protected files; destructive SQL, `bench drop-site`, firewall/DNS changes.
* **Asks first:** dependency installs, `bench migrate`/`restore`/`execute`/…, deletes, `curl`/`wget`, `git push`, `sudo`.

Honest limits:
* Hooks are a safety net, not a security boundary: `bash -c "..."` and similar tricks can evade pattern matching.
* The strongest protection for production is to **keep production credentials out of the agent's environment** (no production SSH keys or `site_config.json` on that machine).
* The Cursor and Copilot hook formats are newer and were verified against their documentation, not in a live session. After installing, ask the agent to `cat .env` and confirm it is refused.
* `.cursorignore` does not stop terminal commands (the hook does); Copilot's content exclusion is a GitHub setting that does not apply to agent mode (the hook does).

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
1. **You:** describe the task.
2. **Agent:** reads `AGENTS.md`, routes to the relevant docs via `docs/INDEX.md`, analyzes the bench, and presents a plan.
3. **You:** approve or request changes.
4. **Agent:** implements, then self-reviews with `workflow/REVIEW.md`.
5. **Agent:** records lasting facts and decisions in `project_knowledge/`.

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
