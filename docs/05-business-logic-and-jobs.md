# Part 5 — Business Logic, Jobs & Reports (Sections 46-50)

_Part of [FRAPPE_DEVELOPMENT.md](../FRAPPE_DEVELOPMENT.md) — the Frappe Development Knowledge Base index._

---

# 46. Business Logic Placement

Use the following general decision framework.

### UI-only behavior

Use:

```text
Client Script / JS
```

Examples:

- Show/hide fields
- Buttons
- Dialogs
- UI filters

### Small event automation

Use:

```text
Server Script
```

Examples:

- Small field update
- Simple event logic
- Small validation

### Complex/reusable business logic

Use:

```text
Python application code
```

Examples:

- Complex calculations
- Reusable services
- External integrations
- Large validation workflows

### Application-wide behavior

Use:

```text
Hooks
```

Examples:

- Document events
- Scheduled jobs
- Overrides
- App-wide events

### Existing-data migration

Use:

```text
Patch
```

### Deployable configuration records

Use:

```text
Fixture
```

### Administrator-controlled configuration

Use:

```text
Settings
```

---

# 47. Scheduled Jobs

Scheduled/background processing should be configured through appropriate Frappe mechanisms.

Example concept:

```python
scheduler_events = {
    "hourly": [
        "my_app.jobs.process_pending_records"
    ]
}
```

Do not perform expensive operations synchronously during a normal document save if they can safely run asynchronously.

For long-running operations, consider background jobs.

---

# 48. Background Jobs

Example:

```python
frappe.enqueue(
    "my_app.jobs.process_document",
    queue="long",
    document_name=doc.name
)
```

Use background jobs for operations such as:

- Large data processing
- External API processing
- Long-running reports
- Bulk operations
- Non-blocking integrations

Ensure that jobs are safe to retry where possible.

---

# 49. Reports

Reports should follow the same module/domain organization.

Examples:

```text
my_module/
└── report/
    └── sales_summary/
        ├── sales_summary.json
        ├── sales_summary.py
        └── sales_summary.js
```

Keep report queries efficient.

Do not duplicate business calculations unnecessarily between:

- reports
- forms
- server scripts
- Python utilities

Where appropriate, centralize reusable business calculations.

---

# 50. Print Formats

Print formats should be treated as presentation logic.

Do not place large amounts of business logic inside Jinja templates.

Preferred:

```text
Python
    ↓
Prepare/validate data
    ↓
Print Format
    ↓
Presentation
```

The print format should primarily render the information.

---

