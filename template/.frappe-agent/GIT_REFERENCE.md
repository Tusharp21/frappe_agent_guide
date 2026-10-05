# Git Reference (examples and templates)

Companion to [`GIT_WORKFLOW.md`](./GIT_WORKFLOW.md). The rules live there; read this file only when you need an exact command, a message template or an example.

## Git identity

```bash
# Personal project
git config --local user.name "Your Personal Name"
git config --local user.email "your.personal@email.com"
# Office project
git config --local user.name "Your Office Name"
git config --local user.email "your.office@company.com"
# Verify (either type)
git config --local user.name
git config --local user.email
```

Order of operations: Identify project -> Personal or Office? -> Set/verify local Git identity -> Check repository status -> Perform the Git/GitHub operation.

## Commit message examples

Types: `feat: create purchase requisition workflow`, `fix: correct budget validation`, `refactor: simplify task service`, `docs: add installation guide`, `test: add budget tests`, `style: format code`, `chore: update frappe to v15.97.0`, `perf: improve report performance`.

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

Avoid: `update`, `changes`, `fixed`, `final changes`, `work done`, `testing`.

## Staging

```bash
git add path/to/file.py
git add path/to/file.js
git status
git diff --cached
```

## Sample `.gitignore`

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

Adapt it to the actual project.

## Stop-and-ask message templates

Merge conflict:

```text
Merge conflict detected.

Affected files:
- path/to/file1.py
- path/to/file2.js

I have stopped without resolving the conflicts.
Please specify how you want the conflicts resolved.
```

Destructive command:

```text
This operation requires a destructive Git command:

git reset --hard

This may permanently discard uncommitted changes.

I have stopped. Please explicitly confirm if you want this command executed.
```

Authentication failure:

```text
Git authentication failed.

Error:
<git error message>

I have stopped execution. Please verify the configured Git account,
PAT, SSH key, or repository permissions.
```

## Switching branches with uncommitted changes

The user decides: commit (`git add <files>`, `git commit -m "..."`), stash (`git stash`), or, only after explicit authorization, discard (`git reset --hard`).

## Branch and Pull Request flow

```text
main/master
     |
     +---- feature/budget-module
     |
     +---- bugfix/address-display
     |
     +---- hotfix/login-error
```

```bash
git status
git branch
git config --local user.name
git config --local user.email
git checkout -b feature/budget-module
# make changes, test
git status
git diff
git add path/to/file.py
git diff --cached
git commit -m "feat: add budget approval workflow"
git push -u origin feature/budget-module
# then create a Pull Request from the dedicated branch
```
