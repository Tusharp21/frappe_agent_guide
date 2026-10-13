# PLAN-2026-001: Discount approval on Sales Order

> Sample plan record for a made-up app (`acme_sales`). Copy it into `.frappe-agent/tasks/PLAN-2026-001.md` to try the plan layer without asking the agent to write a plan. Read it to see what a good plan looks like: small phases, a file list for each, and acceptance criteria you can check by hand.

<!-- CARD:START -->
- **Plan ID:** PLAN-2026-001
- **Title:** Discount approval on Sales Order
- **State:** DRAFT
- **Risk:** <!-- highest phase risk, set at lock -->
- **Opened:** 2026-10-13 10:00
- **Developer:** Your Name
- **App:** acme_sales
- **Branch:** feat/discount-approval
- **Goal:** A Sales Order with a discount above the limit cannot be submitted until a Sales Manager approves it.
- **Decision:** <!-- the user's approval of the plan, their words -->
- **Phases:** 0/3 done
- **Lock hash:**
- **Approval:** Pending
<!-- CARD:END -->

## State log

| When | State | Note |
| ---- | ----- | ---- |
| 2026-10-13 10:00 | DRAFT | plan created |
<!-- STATE-LOG-END -->

## Goal and requirement
* Requirement (the user's words): "Sales users give discounts freely. Anything above 10 percent must be approved by a Sales Manager before the order can be submitted."
* Expected result: orders with discount above the limit are blocked at submit until approved; the manager sees what is waiting.
* Who uses it / business reason: Sales Users create orders; Sales Managers approve. Finance wants a record of who approved.
* Dependencies: none outside `acme_sales`.

## Understanding and existing-work check
* Existing implementation: no discount validation in `acme_sales`; ERPNext's own `additional_discount_percentage` is the field to check (found with `inspect_app.sh acme_sales`).
* Reuse / extend / new: extend `Sales Order` with custom fields and a server-side validation; reuse the standard Workflow doctype for the approval, not a new DocType.
* Risks: a Workflow on a core DocType affects every user of Sales Order; permissions change.
* Open questions and the user's answers: Q: limit configurable? A: "one number in Selling Settings is enough".

## Scope
<!-- Part of the lock hash. -->
* In scope: discount limit setting; approval fields and validation on Sales Order; approval workflow with a manager role; tests.
* Out of scope (what this plan will not change): Quotation, Sales Invoice, discount rules per customer group, email notifications, existing orders (no data migration).
* Assumptions: only the Sales Manager role approves; the limit applies to the order-level discount percentage.

## Phases

Order matters: phase N+1 starts only after phase N's task is COMPLETED. Fill one row per phase while the plan is DRAFT. `Risk` is LOW, MEDIUM or HIGH. `Allowed paths` are files or folders relative to the bench root, comma separated (these become the task's scope gate). `Acceptance criteria` must be testable and are what the user verifies at the end of the phase (UAT). Do not use the `|` character inside a cell. Leave `Status` as PENDING and `Task` empty: `plan_next.sh` fills them. A HIGH phase gets its own proposal and lock when it starts; other phases start already locked by the plan.

<!-- PHASES:START -->
| # | Phase | Risk | Allowed paths | Acceptance criteria | Status | Task |
| - | ----- | ---- | ------------- | ------------------- | ------ | ---- |
| 1 | Discount limit setting and approval fields | MEDIUM | apps/acme_sales/acme_sales/fixtures/, apps/acme_sales/acme_sales/hooks.py, apps/acme_sales/acme_sales/setup/ | Selling Settings shows a Discount Approval Limit (default 10). Sales Order has a read-only Discount Approved By field. After bench migrate on the test site both exist | PENDING | |
| 2 | Block submit above the limit and approval workflow | HIGH | apps/acme_sales/acme_sales/overrides/, apps/acme_sales/acme_sales/workflow/, apps/acme_sales/acme_sales/hooks.py | A Sales User cannot submit an order with 15 percent discount. A Sales Manager can approve it and then the order submits. Approval is recorded in Discount Approved By. An order at 5 percent submits without approval | PENDING | |
| 3 | Tests, acceptance run and deployment plan | LOW | apps/acme_sales/acme_sales/tests/, apps/acme_sales/README.md | Automated tests for under, at and over the limit pass on the test site. You have run the 3 acceptance scenarios by hand. A deployment plan exists for the human to run | PENDING | |
<!-- PHASES:END -->

## Decision and lock
* User decision (their words):
* Locked on:
<!-- If the plan must change after the lock: `plan_state.sh <id> DRAFT --note "CR: why"`, edit, get a new decision, lock again. Never edit a locked plan silently; `plan_next.sh` refuses a plan whose scope or phases changed after the lock. -->

## Change requests
| When | Change | Why | User decision |
| ---- | ------ | --- | ------------- |

## Phase log
<!-- One short entry per finished phase: task id, result, what the user verified. -->

## Final summary
* What was delivered (per phase):
* Acceptance (UAT) results the user confirmed:
* Known limitations:
* Deployment plan: <!-- link to the DEPLOYMENT_PLAN the human runs -->

## Lessons and knowledge updates
<!-- Facts for project_knowledge/APP_MAP.md, decisions for DECISIONS.md. -->
