# Deployment Plan: [Task / Release]

> The agent writes this document. **The agent does not deploy or run anything on production**; a human performs every step. Production is read-only for the agent.

## Summary
[What is being released and why]

## Changes
* Apps / commits / PRs:

## Database changes
* Patches that run on `bench migrate`:
* Schema (DocType) changes:
* Irreversible steps:

## Dependencies and configuration
* New/changed Python or Node dependencies:
* Site or common config changes:

## Risk level
Low / Medium / High, and why.

## Before you start (human)
1. Take a full backup (database and files) and note where it is stored.
2. Confirm the change was validated on the test/staging site and QA signed off.
3. Confirm the maintenance window and who is on call.
4. Code readiness:
   * [ ] Code committed, Git diff reviewed, no secrets committed
   * [ ] Customizations exported; fixtures updated and patches added if required
   * [ ] Hooks verified; tests passed; error handling verified
   * [ ] Migration and build requirements identified; settings/configuration documented

## Deployment steps (human runs these)
1.
2.

## Validation after deployment
* [ ] Migrate run; cache cleared and assets built if required
* [ ] Application and the relevant DocType verified; scheduled jobs verified
* [ ] Error Log checked
* [ ] Specific checks that prove the change works:
* [ ] Existing critical flows still work:
* [ ] Error log / background jobs look healthy:

## Rollback steps
1. Condition that triggers a rollback:
2. Steps to restore (code and database):
3. Who decides, and how long rollback takes:

## Approvals required
* [ ] Tech lead / owner:
* [ ] QA:
