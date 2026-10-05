# Permissions, Production and Secrets

Every action the agent can perform has a policy: allowed automatically, needs approval, or prohibited. The thresholds below are the defaults; the patterns that hooks enforce are in [`../config.json`](../config.json) (see [`../CONFIGURATION.md`](../CONFIGURATION.md)).

## Risk policy

| Risk | Examples | Policy |
| ---- | -------- | ------ |
| **Low** | Read files, search, edit app code, format/lint, run tests on a dev site, `git status/diff/log`, create a branch, `git add`/`git commit` on a dedicated branch | Automatic |
| **Medium** | Install a dependency (`pip`, `npm`, `bench get-app`), `bench migrate`/`build`/`update`/`restore`/`execute`/`console`/`set-config`, delete files, network access (`curl`, `wget`), `git push` of a dedicated branch, `sudo`, restarting services | Ask the user first, every time |
| **High** | Anything on production; destructive SQL (`DROP`, `TRUNCATE`, `DELETE` without `WHERE`); `bench drop-site`/`reinstall`/`uninstall-app`; credentials or secrets; firewall/DNS; force-push; deleting branches; push to `main`/`master` | **Prohibited for the agent.** A human runs it. Stop and tell the user |

Approval for one action does not extend to the next. Choosing "auto" mode at the start of a task (see [`REQUIREMENT_ANALYSIS.md`](./REQUIREMENT_ANALYSIS.md)) skips plan approval only; it never skips these policies.

## Production: the agent is read-only

The agent never executes anything against production. Not even harmless-looking read commands: no `bench --site <prod> ...`, no SSH/SCP/rsync/`docker exec` to a production host, no database client against production, no production credentials in its environment.

What the agent does instead:

1. Write a deployment plan with [`../templates/DEPLOYMENT_PLAN.md`](../templates/DEPLOYMENT_PLAN.md): changes, migrations, dependencies, config changes, risk, backup requirement, validation steps, rollback steps, post-deployment checks, and the human approvals required.
2. Hand the plan to the user. The user runs every step.
3. If the plan needs information from production, ask the user to run a command and paste the output (after removing secrets).

How production is identified: the sites and hosts in `environments.production` in `config.json`, plus any `--site` or SSH target that contains `prod`, `production` or `live` as a word. If it is unclear whether a target is production, treat it as production and ask.

Expected path for a change: development, then a test/staging site, then human QA, then production with human approval. A rollback plan is mandatory for anything that reaches production.

## Secrets

* Never read, print, copy or edit `.env`, `site_config.json`, `common_site_config.json`, private keys or certificates (the `protected_files` list in `config.json`). `site_config.json` contains database passwords.
* Never ask the user to paste a secret into the conversation. If a task needs a credential, tell the user which setting to configure and let them do it.
* Never write secrets into code, commands, logs, plans or reports. Reference them by name (for example "the `api_secret` field in the Settings DocType").
* Template files such as `.env.example` are fine to read.

## Destructive operations on a dev site

Dropping or truncating data, even on a dev site, is High risk: stop and ask. Prefer a backup (`bench --site <site> backup`, which needs approval) before any migration or data change you are asked to run.
