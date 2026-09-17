# Part 9 — Debugging & Operations (Sections 70-77)

_Part of [FRAPPE_DEVELOPMENT.md](../FRAPPE_DEVELOPMENT.md) — the Frappe Development Knowledge Base index._

---

# 70. Debugging Workflow

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

# 71. Frontend Debugging

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

# 72. Backend Debugging

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

# 73. Database Transaction Awareness

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

# 74. Security Rules

Security-sensitive functionality must always be implemented server-side.

Never trust:

```text
Hidden UI fields
Disabled buttons
Client-side validation
Client-provided permissions
```

Validate important operations on the server.

Protect:

- Passwords
- Tokens
- API keys
- Integration credentials
- Sensitive business data

---

# 75. Documentation Rule

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

# 76. Change Management

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

# 77. Deployment Checklist

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

