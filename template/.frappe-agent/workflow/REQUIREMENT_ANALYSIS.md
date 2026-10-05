# Requirement Analysis Workflow

Before writing any code, the AI must perform a detailed analysis of the user's request.

## Start of Every Task: Confirm Understanding and Mode

Read [`../config.json`](../config.json) first. Then, before any analysis beyond reading, tell the user in a few lines what you understood the task to be, the tier you chose (below) and why, and ask:

> Is this what you want? Should I (A) present a plan and wait for your approval, or (B) run it automatically?

* Use the interactive question tool if your environment has one; otherwise ask in plain text and wait.
* If `approval_mode` is `always_plan`, do not offer (B); go straight to the plan.
* Offer (B) only if the tier is in `auto_mode_allowed_tiers`. **Major** tasks always need an approved plan.
* If the user picks (B), skip the approval wait but still follow every policy in [`PERMISSIONS_AND_PRODUCTION.md`](./PERMISSIONS_AND_PRODUCTION.md) (Medium actions still need approval, High actions are never run), still run verification, and still create the audit record.
* If the requirement is ambiguous, ask clarifying questions instead of choosing an option.

## 0. Classify the Task Tier

Pick a tier first; it sets how much analysis and paperwork the task needs. State the tier and the reason. If unsure, pick the higher tier.

| Tier | What it covers | Plan format |
| ---- | -------------- | ----------- |
| **Trivial** | Single-file change with no logic, permission, schema, or data impact: label/text, translation, comment, typo, styling. | One line: what changes, in which file. Skip sections 3-4 below. |
| **Standard** | Everything else: new field, validation, client/server script, report, small API, bug fix. | The structured proposal in section 5. |
| **Major** | New DocType, schema change, data migration or patch, role/permission changes, integrations or public APIs, scheduled/background jobs, `hooks.py` overrides, or changes spanning more than one app. | Fill `../templates/TASK_TEMPLATE.md`, and add a **rollback plan** and a **migration impact** note (what runs on `bench migrate`, what is irreversible). |

Every tier requires explicit user approval before any code is written, either by approving the plan (A) or by choosing auto mode (B) at the start.

## 1. Understand the Request
* What is the exact business requirement?
* Who is the target user/role?

## 2. System Inspection
* **DocTypes:** Identify all standard and custom DocTypes involved.
* **Files:** Identify which controllers, JS files, or HTML templates are relevant.
* **Discovery:** Run `../scripts/inspect_app.sh <app>` for the app's branch, modules, hooks, DocTypes, fixtures, and patches, and read `../project_knowledge/APP_MAP.md`.
* **Existing Patterns:** Search the codebase to see how similar problems were solved previously. Do not invent a new pattern if a standard one exists.

## 3. Data Flow & Business Rules
* Map out how data will enter, move through, and exit the system.
* Note all validation rules, status changes, and constraints.

## 4. Pre-Checks
* **Security Check:** What permissions/roles are required? Are there any data leak risks?
* **Performance Check:** Will this feature involve large datasets? Do we need background jobs?

## 5. Proposed Solution
Create a structured proposal:
* Summary of approach.
* **Acceptance criteria** (Standard and Major): a numbered, testable definition of done that the user can edit before approving.
* List of files expected to change or be created.
* Potential risks or impacts on existing features.

**STOP HERE. Present the plan to the user and request APPROVAL before proceeding to implementation.**
