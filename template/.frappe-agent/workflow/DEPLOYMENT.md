# Deployment Workflow

The agent never deploys, and is read-only on production (see [`PERMISSIONS_AND_PRODUCTION.md`](./PERMISSIONS_AND_PRODUCTION.md)). This workflow is how the agent prepares a deployment and records the outcome; **a human runs every step**.

```text
PRE-CHECK -> PLAN (agent) -> BACKUP -> DEPLOY -> VERIFY -> ROLLBACK IF NEEDED   (last four: human)
```

1. **Pre-check (agent).** Confirm the task is COMPLETED (approved) and its record has acceptance criteria met, tests with real output, and a rollback plan. List the commits, the patches that will run on `bench migrate`, the dependency changes and the config changes.
2. **Plan (agent).** Fill [`../templates/DEPLOYMENT_PLAN.md`](../templates/DEPLOYMENT_PLAN.md) and hand it to the user.
3. **Path.** The expected path is development, then a test/staging site, then human QA, then production with human approval. Do not skip the test/staging step for HIGH tasks. A rollback plan is mandatory for anything that reaches production.
4. **Backup, deploy, verify (human).** The user takes the backup, runs the steps, and runs the validation checks.
5. **Rollback (human).** If a check fails or the trigger condition in the plan is met, the human follows the rollback steps.
6. **Record (agent).** When the human reports the result, update the task record's `Deployment` field with the date, the environment and the outcome (success, rolled back, issues). Do not mark it deployed on your own assumption.
