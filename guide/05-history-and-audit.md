# 05 History and audit

## One file per task

Each MEDIUM and HIGH task gets one record, `tasks/TASK-YYYY-NNN.md`, created by `scripts/new_task.sh` and filled as the task progresses. It is both the history (what was asked, decided, done) and the audit (what ran, real test output, who approved, which commit). LOW tasks get a short summary only; change this with `history.record_for` ([02](./02-configuration.md)).

A record starts with a short **card** (task ID, title, state, risk, decision, locked solution, files, tests, approval, commit, deployment), then a state log with timestamps, then the sections for each step. The card is what future tasks read.

## Finding old work

Before building anything, the agent runs `scripts/search_history.sh <keywords>`. It prints only the cards of matching past tasks (best matches first), matching lines from `DECISIONS.md` and `APP_MAP.md`, and matching commit subjects from each app's git history. You can run it yourself. No match is a valid result: it means the work looks new.

## Where records live

By default in `.frappe-agent/tasks/`, outside git (the bench root is normally not a repository), and kept on update and on `--keep-knowledge` uninstall. To share history with a team, set `history.path` to a shared folder or to a checkout of a private repository your team commits to, and keep it out of the app repositories. An older `audit/RUN-*.md` record is still found by the search.

## Command log

With a hook layer installed, each shell command the agent runs is appended to `audit/commands.log` (timestamp, folder, exit status, command; obvious secrets masked). Turn it off with `audit.log_commands` in `policy.json`.

## Project knowledge

* `project_knowledge/APP_MAP.md`: facts about each app (purpose, modules, key DocTypes, settings, integrations, Git project type). The agent reads it before analysis and updates it when it learns something lasting.
* `project_knowledge/DECISIONS.md`: a short log of decisions on approved tasks, so later tasks do not re-litigate them.

Both are kept on update.
