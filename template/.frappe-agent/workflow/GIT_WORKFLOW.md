# Git Workflow & Standards

Rules for all developers and AI agents. Examples, message templates, a full `.gitignore` and the step-by-step command sequence are in [`GIT_REFERENCE.md`](./GIT_REFERENCE.md); read it only when you need an example.

Goals: separate personal and office Git identities, a clean branch structure, Conventional Commits, no exposed secrets, no unsafe Git operations, `main`/`master` protected, and the agent stops and asks when an operation is unsafe or ambiguous.

## Where Git Operations Run (Bench Layout)

This template is usually installed in the **bench root** (the folder containing `apps/` and `sites/`). The bench root is normally **not** a Git repository; each app under `apps/<app_name>/` is its own repository.

* Run every Git operation (`status`, `checkout -b`, `add`, `commit`, `push`) **inside the app repository** being changed, e.g. `cd apps/<app_name>`.
* Do not run `git init` in the bench root, and do not commit `.frappe-agent/` or `AGENTS.md` into an app repository unless the user asks for it.
* If a task touches more than one app, treat each app as a separate repository with its own branch and Pull Request.

## GitHub Project Identity Check

Before **any Git or GitHub operation**, the agent must know whether the repository is a **Personal Project** or an **Office Project**, and must not assume.

* If the type is explicitly known from the project configuration or an established project rule (for example recorded under the app in [`project_knowledge/APP_MAP.md`](../project_knowledge/APP_MAP.md)), proceed without asking again.
* If unknown, stop and ask: *"Before I start Git/GitHub operations, please confirm: 1. Personal Project, 2. Office Project."* Once answered, record it in `APP_MAP.md` so it is known next time.
* Before Git operations, always verify the local identity (`git config --local user.name` and `user.email`) matches the project type. Set it with `git config --local` if needed (commands in the reference).

The agent must never: assume an unknown repository is personal or office; use the global Git identity without checking; push before verifying the identity; mix personal and office identities; change the identity silently.

## Branch Naming Convention

Agents follow the same convention as developers. Lowercase, hyphens instead of spaces, descriptive; no personal names, and no vague names (`test`, `changes`, `new`, `temp`, `final`).

| Type | Pattern | Example |
| ---- | ------- | ------- |
| Feature | `feature/<feature-name>` | `feature/budget-module` |
| Bugfix | `bugfix/<issue-name>` | `bugfix/address-display` |
| Hotfix | `hotfix/<issue-name>` | `hotfix/login-error` |
| Refactor | `refactor/<module-name>` | `refactor/project-service` |
| Docs | `docs/<topic>` | `docs/readme` |
| Test | `test/<module-name>` | `test/budget-tests` |
| Release | `release/<version>` | `release/v1.2.0` |

## Commit Message Convention

Conventional Commits: `<type>: <concise description that says what the commit does>`.

Types: `feat` (new feature), `fix` (bug fix), `refactor` (no behavior change), `docs`, `test`, `style` (formatting only), `chore` (maintenance, dependencies, config), `perf`. Never use messages like `update`, `changes`, `fixed`, `final changes`, `work done`, `testing`.

## AI Agent Git Safety Rules

The agent treats Git operations as controlled operations and must:

1. Inspect the repository state before committing.
2. Avoid destructive Git commands unless explicitly authorized.
3. Never silently resolve merge conflicts.
4. Never expose or commit credentials.
5. Never push directly to `main` or `master`.
6. Stop and ask the user when an operation requires human intervention.

## Pre-Commit Inspection

Before a commit, run `git status` and inspect modified, deleted and untracked files, unexpected changes, and anything that should not be in the commit. Do not blindly `git add .`; stage specific files, then verify with `git status` and `git diff --cached`.

### Pre-commit Hooks (Linting)

Each Frappe app normally ships its own `.pre-commit-config.yaml` (created by `bench new-app`). That file, inside the app repository, is the source of truth for linting. This template does not install a config of its own.

The AI agent must:

* Check for `.pre-commit-config.yaml` in the app repository being changed, and follow it.
* Let `git commit` run the hooks normally, and fix whatever they flag (lint errors, formatting, trailing whitespace, etc.) rather than working around them.
* Never run `git commit --no-verify` (or otherwise bypass hooks) unless the user explicitly authorizes it for that specific commit.
* If a hook modifies files (e.g. `ruff-format` reformatting code), re-stage the changed files and re-attempt the commit; do not assume the first attempt succeeded.
* If the app has a config but pre-commit is not installed yet, tell the user rather than silently skipping the checks (`pip install pre-commit`, then `cd apps/<app_name> && pre-commit install`).
* If the app has no `.pre-commit-config.yaml`, run `ruff check` and `ruff format --check` on the changed Python files if `ruff` is available, and tell the user that the app has no hooks configured.

## Sensitive Files & `.gitignore`

Never commit secrets: `.env` and `.env.*`, `*.pem`, `*.key`, `*.p12`, `*.crt`, `*.secret`, `secrets.json`, `credentials.json`, database dumps and local database files, API tokens, private SSH keys. The repository must have an appropriate `.gitignore`, adapted to the project (a sample is in the reference). Before committing, verify sensitive files are excluded.

## Mandatory "Stop & Ask" Rules

Stop immediately and ask the user in these situations.

* **Merge conflicts** (from `pull`, `merge`, `rebase`): stop, list the affected files, do not resolve automatically, ask how to resolve. Never pick a side with `git checkout --ours` / `--theirs` or similar.
* **Destructive commands**: never run without explicit authorization: `git push --force`, `git push --force-with-lease`, `git reset --hard`, `git clean -df`, `git branch -D`, `git branch -DA`. They can permanently discard work or rewrite history. If one seems necessary, stop, name the command and what it may destroy, and ask for explicit confirmation.
* **Authentication or token errors** (`Permission denied`, `Authentication failed`, invalid token, repository access denied, SSH failure, credential prompt): stop and report the error. Never guess credentials, change authentication settings, replace tokens, switch accounts silently, or store credentials in project files.
* **Branch switching with uncommitted changes**: check `git status` first. If there are uncommitted changes, do not switch; ask the user whether to commit, stash, or (only with explicit authorization) discard.

## Main/Master Branch Protection

Never push directly to `main` or `master`. Work on a dedicated branch (`git checkout -b feature/budget-module`), push it (`git push -u origin <branch>`), and submit a Pull Request into the appropriate primary/development branch.

## Standard Development Workflow

1. Check the repository (`git status`, `git branch`).
2. Verify the Git identity (`git config --local user.name` / `user.email`).
3. Create a dedicated branch.
4. Make and test the changes.
5. Inspect them (`git status`, `git diff`) and check that no secrets, tokens, dumps or keys are included.
6. Stage specific files; inspect the staged diff (`git diff --cached`).
7. Commit with a Conventional Commit message.
8. Push the dedicated branch, then create the Pull Request.

Quick rule: `CHECK -> VERIFY -> ACT -> INSPECT -> COMMIT -> PUSH`.

## Final Git Safety Principle

When uncertain: **STOP -> EXPLAIN -> ASK**, never GUESS -> EXECUTE -> RISK DATA LOSS. Repository history, uncommitted work, credentials, and user changes are protected resources.
