# Git Workflow & Standards

## Overview

This document defines the Git workflow and standards that must be followed by all developers and AI agents working on the repository.

The main goals are:

* Keep personal and office Git identities separate.
* Maintain a clean and consistent branch structure.
* Follow Conventional Commits.
* Prevent accidental exposure of secrets.
* Prevent unsafe Git operations.
* Keep `main`/`master` protected from direct development pushes.
* Ensure AI agents stop and ask for approval when an unsafe or ambiguous Git operation is required.

---

## GitHub Project Identity Check

Before starting **any Git or GitHub operation**, the AI agent must determine whether the repository is a:

* **Personal Project**
* **Office Project**

The agent must **not assume** the project type.

### If Project Type Is Unknown

The agent must stop and ask the user:

```text
Before I start Git/GitHub operations, please confirm:

1. Personal Project
2. Office Project
```

No GitHub-related operation should begin until the project identity is confirmed.

### Personal Project

For a personal project, configure the repository with the personal Git identity:

```bash
git config --local user.name "Your Personal Name"
git config --local user.email "your.personal@email.com"
```

Verify:

```bash
git config --local user.name
git config --local user.email
```

### Office Project

For an office project, configure the repository with the office Git identity:

```bash
git config --local user.name "Your Office Name"
git config --local user.email "your.office@company.com"
```

Verify:

```bash
git config --local user.name
git config --local user.email
```

### Mandatory Agent Rule

The agent must follow this order:

```text
Identify Project
      ↓
Personal or Office?
      ↓
Set/Verify Local Git Identity
      ↓
Check Repository Status
      ↓
Perform Git/GitHub Operation
```

The agent must never:

* Assume an unknown repository is personal.
* Assume an unknown repository is an office project.
* Use the global Git identity without checking the project identity.
* Push to GitHub before verifying the project identity.
* Mix personal and office Git identities.
* Change Git identity silently.

If the project type is already explicitly known from the current project configuration or an established project rule, the agent may proceed without asking again, but it must still verify the local Git identity before Git operations.

---

## Branch Naming Convention

All developers and AI agents must follow the standardized branch naming convention.

| Branch Type | Pattern                  | Purpose                                    | Example                    |
| ----------- | ------------------------ | ------------------------------------------ | -------------------------- |
| Feature     | `feature/<feature-name>` | New functionality or features              | `feature/budget-module`    |
| Bugfix      | `bugfix/<issue-name>`    | Standard bug fixes                         | `bugfix/address-display`   |
| Hotfix      | `hotfix/<issue-name>`    | Urgent production fixes                    | `hotfix/login-error`       |
| Refactor    | `refactor/<module-name>` | Code improvements without behavior changes | `refactor/project-service` |
| Docs        | `docs/<topic>`           | Documentation changes                      | `docs/readme`              |
| Test        | `test/<module-name>`     | Adding or updating tests                   | `test/budget-tests`        |
| Release     | `release/<version>`      | Release preparation                        | `release/v1.2.0`           |

### Branch Naming Rules

* Use lowercase names.
* Use hyphens instead of spaces.
* Keep branch names descriptive.
* Do not use personal names unless required.
* Do not use vague names such as:

  * `test`
  * `changes`
  * `new`
  * `temp`
  * `final`
* AI agents must follow the same branch naming convention as human developers.

---

## Commit Message Convention

All commits must follow the Conventional Commits format:

```text
<type>: <concise description>
```

The description should clearly explain what the commit does.

### Supported Commit Types

| Type       | Purpose                                         | Example                                      |
| ---------- | ----------------------------------------------- | -------------------------------------------- |
| `feat`     | Addition of a new feature                       | `feat: create purchase requisition workflow` |
| `fix`      | Bug fix                                         | `fix: correct budget validation`             |
| `refactor` | Code improvement without changing behavior      | `refactor: simplify task service`            |
| `docs`     | Documentation changes                           | `docs: add installation guide`               |
| `test`     | Adding or correcting tests                      | `test: add budget tests`                     |
| `style`    | Formatting-only changes                         | `style: format code`                         |
| `chore`    | Maintenance, dependencies, build/config updates | `chore: update frappe to v15.97.0`           |
| `perf`     | Performance improvements                        | `perf: improve report performance`           |

### Commit Examples

Good:

```text
feat: add budget approval workflow
fix: correct purchase order validation
refactor: simplify project service
docs: update installation guide
test: add purchase requisition tests
style: format purchase order module
chore: update frappe dependency
perf: optimize general ledger query
```

Avoid:

```text
update
changes
fixed
final changes
work done
testing
```

---

## AI Agent Git Safety Rules

AI agents working in this repository must treat Git operations as controlled operations.

The agent must:

1. Inspect the current repository state before making commits.
2. Avoid destructive Git commands unless explicitly authorized.
3. Never silently resolve merge conflicts.
4. Never expose or commit credentials.
5. Never push directly to `main` or `master`.
6. Stop and ask the user when an operation requires human intervention.

---

## Pre-Commit Inspection

Before creating a commit, the AI agent must run:

```bash
git status
```

The agent must inspect:

* Modified files.
* Deleted files.
* New/untracked files.
* Unexpected changes.
* Files that should not be part of the commit.

The agent must not blindly commit all changes using:

```bash
git add .
```

without first inspecting the repository state.

Where appropriate, specific files should be staged:

```bash
git add path/to/file.py
git add path/to/file.js
```

Then verify:

```bash
git status
git diff --cached
```

### Pre-commit Hooks (Linting)

This project uses the [pre-commit](https://pre-commit.com) framework, configured in `.pre-commit-config.yaml`. It runs `ruff` (Python lint + format) plus common whitespace/YAML/JSON checks automatically on `git commit`.

The AI agent must:

* Assume pre-commit hooks are active once `.pre-commit-config.yaml` exists in the repository.
* Let `git commit` run the hooks normally, and fix whatever they flag (lint errors, formatting, trailing whitespace, etc.) rather than working around them.
* Never run `git commit --no-verify` (or otherwise bypass hooks) unless the user explicitly authorizes it for that specific commit.
* If a hook modifies files (e.g. `ruff-format` reformatting code), re-stage the changed files and re-attempt the commit — do not assume the first attempt succeeded.
* If pre-commit itself is not installed yet, tell the user rather than silently skipping the checks:
  ```bash
  pip install pre-commit
  pre-commit install
  ```

---

## Sensitive Files & `.gitignore`

Sensitive files must never be committed.

Examples include:

```text
.env
.env.*
*.pem
*.key
*.p12
*.crt
*.secret
secrets.json
credentials.json
database dumps
local database files
API tokens
private SSH keys
```

The repository must contain an appropriate `.gitignore`.

Before committing, the AI agent must verify that sensitive files are excluded.

Example:

```gitignore
# Environment files
.env
.env.*

# Secrets
*.pem
*.key
*.p12
*.secret
secrets.json
credentials.json

# Database dumps
*.sql
*.sql.gz

# Python
__pycache__/
*.pyc

# Node
node_modules/

# Local files
*.log
.DS_Store
```

The `.gitignore` must be adapted to the actual project requirements.

---

## Mandatory "Stop & Ask" Rules

The AI agent must immediately stop execution and ask the user for instructions when any of the following situations occurs.

### Merge Conflicts

If a `pull`, `merge`, or `rebase` produces conflicts:

1. Stop immediately.
2. Display the affected files.
3. Do not resolve the conflicts automatically.
4. Ask the user how the conflict should be resolved.

Example:

```text
Merge conflict detected.

Affected files:
- path/to/file1.py
- path/to/file2.js

I have stopped without resolving the conflicts.
Please specify how you want the conflicts resolved.
```

The agent must not automatically choose one side using:

```bash
git checkout --ours
git checkout --theirs
```

or similar commands.

---

## Destructive Git Commands

The following commands must never be executed without explicit user authorization:

```bash
git push --force
git push --force-with-lease
git reset --hard
git clean -df
git branch -D
git branch -DA
```

These commands can permanently discard work or rewrite repository history.

If such an operation appears necessary, the AI agent must stop and ask for explicit approval.

Example:

```text
This operation requires a destructive Git command:

git reset --hard

This may permanently discard uncommitted changes.

I have stopped. Please explicitly confirm if you want this command executed.
```

---

## Authentication & Token Errors

If Git encounters authentication problems, the AI agent must stop.

Examples:

```text
Permission denied
Authentication failed
Invalid username or password
Invalid token
Repository access denied
SSH authentication failure
Credential prompt
```

The agent must not:

* Guess credentials.
* Modify authentication settings without approval.
* Replace tokens automatically.
* Switch accounts silently.
* Store credentials in project files.

The error must be reported to the user.

Example:

```text
Git authentication failed.

Error:
<git error message>

I have stopped execution. Please verify the configured Git account,
PAT, SSH key, or repository permissions.
```

---

## Branch Switching With Uncommitted Changes

Before switching branches, check:

```bash
git status
```

If uncommitted changes exist, the AI agent must not switch branches automatically.

The user must decide whether to:

### Commit

```bash
git add <files>
git commit -m "..."
```

### Stash

```bash
git stash
```

### Discard

Only after explicit user authorization:

```bash
git reset --hard
```

The agent must ask the user which option should be used.

---

## Main/Master Branch Protection

The AI agent must never push directly to:

```text
main
master
```

Development work must be performed on a dedicated branch.

For example:

```bash
git checkout -b feature/budget-module
```

Then:

```bash
git push -u origin feature/budget-module
```

After pushing the branch, the changes should be submitted through a Pull Request (PR).

Expected workflow:

```text
main/master
     |
     +---- feature/budget-module
     |
     +---- bugfix/address-display
     |
     +---- hotfix/login-error
```

---

## Standard Development Workflow

The recommended workflow is:

### Step 1: Check Repository

```bash
git status
git branch
```

### Step 2: Verify Git Identity

```bash
git config --local user.name
git config --local user.email
```

### Step 3: Create a Dedicated Branch

Example:

```bash
git checkout -b feature/budget-module
```

### Step 4: Make Changes

Implement and test the required changes.

### Step 5: Inspect Changes

```bash
git status
git diff
```

### Step 6: Verify Sensitive Files

Check that credentials, tokens, secrets, dumps, and private keys are not being committed.

### Step 7: Stage Changes

Prefer specific files:

```bash
git add path/to/file.py
git add path/to/file.js
```

### Step 8: Inspect Staged Changes

```bash
git diff --cached
```

### Step 9: Commit

Use a Conventional Commit:

```bash
git commit -m "feat: add budget approval workflow"
```

### Step 10: Push Dedicated Branch

```bash
git push -u origin feature/budget-module
```

### Step 11: Create Pull Request

Create a PR from the dedicated branch into the appropriate primary/development branch.

---

## AI Agent Quick Rules

Before Git operations:

```text
CHECK → VERIFY → ACT → INSPECT → COMMIT → PUSH
```

The AI agent must follow these rules:

* Always check `git status` before committing.
* Verify the local Git identity.
* Never commit secrets.
* Follow the branch naming convention.
* Follow Conventional Commits.
* Never push directly to `main` or `master`.
* Never resolve merge conflicts automatically.
* Never execute destructive Git commands without explicit approval.
* Stop on authentication/token errors.
* Stop before switching branches with uncommitted changes.
* Ask the user when Git state is ambiguous.

---

## Final Git Safety Principle

When there is uncertainty, the AI agent must prefer:

```text
STOP → EXPLAIN → ASK
```

instead of:

```text
GUESS → EXECUTE → RISK DATA LOSS
```

Repository history, uncommitted work, credentials, and user changes must always be treated as protected resources.
