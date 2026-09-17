# Part 9 — Debugging & Operations

_Part of [FRAPPE_DEVELOPMENT.md](../FRAPPE_DEVELOPMENT.md) — the Frappe Development Knowledge Base index._

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

## Security Rules

Before shipping, re-confirm the security rules from earlier chapters: security-sensitive functionality is implemented server-side, not trusted to hidden UI fields, disabled buttons, or client-side validation/permissions ("Whitelisted Methods" and "Permissions" in `docs/04-security-and-backend.md`); and secrets — passwords, tokens, API keys, integration credentials, sensitive business data — stay protected end-to-end ("Passwords and Secrets" in `docs/04-security-and-backend.md`).

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

---

## Deployment Checklist

Before deployment:

```text
[ ] Code committed
[ ] Git diff reviewed
[ ] No secrets committed
[ ] Customizations exported
[ ] Fixtures updated if required
[ ] Patches added if required
[ ] Hooks verified
[ ] Tests passed
[ ] Migration requirements identified
[ ] Build requirements identified
[ ] Settings/configuration documented
[ ] Error handling verified
```

After deployment:

```text
[ ] Migrate
[ ] Clear cache if required
[ ] Build assets if required
[ ] Verify application
[ ] Verify relevant Doctype
[ ] Verify scheduled jobs
[ ] Check Error Log
```

---

