# Permissions, Production and Secrets

Every action the agent can perform has a policy: allowed automatically, needs approval, or prohibited. The thresholds below are the defaults; the patterns that hooks enforce are in [`../policy.json`](../policy.json) and the production sites in [`../config.json`](../config.json).

## Action levels

Every command or action has an **action level**. This is separate from a *task's* risk level (LOW/MEDIUM/HIGH in [`TASK.md`](./TASK.md)): a LOW task can still contain an ask-first action, and a HIGH task can be mostly automatic ones.

| Action level | Examples | Policy |
| ------------ | -------- | ------ |
| **Automatic** | Read files, search, edit app code, format/lint, run tests on a dev site, `git status/diff/log`, create a branch, `git add`/`git commit` on a dedicated branch | Automatic |
| **Ask first** | Install a dependency (`pip`, `npm`, `bench get-app`), `bench migrate`/`build`/`update`/`restore`/`execute`/`console`/`set-config`, delete files, network access (`curl`, `wget`), `git push` of a dedicated branch, `sudo`, restarting services | Ask the user first, every time |
| **Prohibited** | Anything on production; destructive SQL (`DROP`, `TRUNCATE`, `DELETE` without `WHERE`); `bench drop-site`/`reinstall`/`uninstall-app`; credentials or secrets; firewall/DNS; force-push; deleting branches; push to `main`/`master` | **Prohibited for the agent.** A human runs it. Stop and tell the user |

Approval for one action does not extend to the next. Choosing automatic mode at the start of a task (see [`TASK.md`](./TASK.md)) skips the wait for the user's decision only; it never skips these policies.

## Production: the agent is read-only

The agent never executes anything against production. Not even harmless-looking read commands: no `bench --site <prod> ...`, no SSH/SCP/rsync/`docker exec` to a production host, no database client against production, no production credentials in its environment.

Instead it writes a deployment plan and hands it to the user, who runs every step (see [`DEPLOYMENT.md`](./DEPLOYMENT.md)). If it needs information from production, it asks the user to run a command and paste the output, with secrets removed.

How production is identified: the sites and hosts in `environments.production` in `config.json`, plus any `--site` or SSH target that contains `prod`, `production` or `live` as a word. If it is unclear whether a target is production, treat it as production and ask.

## Secrets

* Never read, print, copy or edit `.env`, `site_config.json`, `common_site_config.json`, private keys or certificates (the `protected_files` list in `policy.json`). `site_config.json` contains database passwords.
* Never ask the user to paste a secret into the conversation. If a task needs a credential, tell the user which setting to configure and let them do it.
* Never write secrets into code, commands, logs, plans or reports. Reference them by name (for example "the `api_secret` field in the Settings DocType").
* Template files such as `.env.example` are fine to read.

## Destructive operations on a dev site

Dropping or truncating data, even on a dev site, is a prohibited action: stop and ask. Prefer a backup (`bench --site <site> backup`, which needs approval) before any migration or data change you are asked to run.
