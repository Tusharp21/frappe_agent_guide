# Part 9 — Debugging & Operations

_Part of the Frappe knowledge base. Start at [INDEX.md](./INDEX.md)._

---

## Debugging Workflow

When a feature does not work:

```text
1. Reproduce the issue.
2. Identify the Doctype.
3. Check browser console for frontend errors.
4. Check Frappe Error Log.
5. Check server logs.
6. Check relevant Client Script.
7. Check Server Script/event.
8. Check hooks.
9. Check permissions.
10. Check field/customization metadata.
11. Check database values.
12. Reproduce using console/API if necessary.
```

Do not immediately rewrite working code.

First identify where the failure occurs.

---

## Frontend Debugging

Check:

- Browser console
- Network requests
- `frappe.call`
- Form events
- Field names
- Child table names
- Query filters
- Permission errors
- Server response

Typical investigation:

```text
Form Event
    ↓
JS executes?
    ↓
frappe.call?
    ↓
Request sent?
    ↓
Server method executes?
    ↓
Response correct?
    ↓
UI updated?
```

---

## Backend Debugging

Check:

- Python traceback
- Frappe Error Log
- Document event
- Hook registration
- Method path
- Permissions
- Database state
- API response
- Transaction behavior

For debugging exceptions:

```python
frappe.log_error(
    title="Feature Name Error",
    message=frappe.get_traceback()
)
```

---

## Database Transaction Awareness

Frappe document operations generally participate in database transactions.

Developers must understand whether an operation is:

- part of the current transaction
- committed
- rolled back
- asynchronous

Do not introduce unnecessary manual commits.

Avoid:

```python
frappe.db.commit()
```

unless there is a specific, understood reason.

---

## Documentation Rule

New complex functionality should be documented.

Documentation should explain:

```text
Purpose
Architecture
Doctype involved
Settings involved
Hooks
Server logic
Client logic
External integrations
Migration requirements
Known limitations
```

Do not document obvious code line-by-line unless necessary.

Document the **why**, not only the **what**.

---

## Change Management

For every significant feature, identify whether the change includes:

```text
Code
Metadata
Configuration
Database
Fixtures
Patches
Hooks
Permissions
Frontend assets
External integration
```

A feature is not considered complete until all required components are handled.

The deployment checklist and the deployment plan are in [`../templates/DEPLOYMENT_PLAN.md`](../templates/DEPLOYMENT_PLAN.md) (see `../workflow/DEPLOYMENT.md`).
