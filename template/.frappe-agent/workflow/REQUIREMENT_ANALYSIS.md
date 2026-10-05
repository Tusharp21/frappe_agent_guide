# Requirement Analysis Workflow

Before writing any code, the AI must perform a detailed analysis of the user's request.

## 0. Classify the Task Tier

Pick a tier first; it sets how much analysis and paperwork the task needs. State the tier and the reason. If unsure, pick the higher tier.

| Tier | What it covers | Plan format |
| ---- | -------------- | ----------- |
| **Trivial** | Single-file change with no logic, permission, schema, or data impact: label/text, translation, comment, typo, styling. | One line: what changes, in which file. Skip sections 3-4 below. |
| **Standard** | Everything else: new field, validation, client/server script, report, small API, bug fix. | The structured proposal in section 5. |
| **Major** | New DocType, schema change, data migration or patch, role/permission changes, integrations or public APIs, scheduled/background jobs, `hooks.py` overrides, or changes spanning more than one app. | Fill `../templates/TASK_TEMPLATE.md`, and add a **rollback plan** and a **migration impact** note (what runs on `bench migrate`, what is irreversible). |

Every tier still requires explicit user approval before any code is written.

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
* List of files expected to change or be created.
* Potential risks or impacts on existing features.

**STOP HERE. Present the plan to the user and request APPROVAL before proceeding to implementation.**
