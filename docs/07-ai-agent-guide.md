# Part 7 — AI Agent Guide: Git, Review & Workflow (Sections 56-61)

_Part of [FRAPPE_DEVELOPMENT.md](../FRAPPE_DEVELOPMENT.md) — the Frappe Development Knowledge Base index._

---

# 56. Git Rules

Git workflow, branch naming, commit conventions, and safety rules (including which files must never be committed) are defined in [`GIT_WORKFLOW.md`](../GIT_WORKFLOW.md). That document is the single source of truth for all Git operations — follow it instead of duplicating its rules here.

---

# 57. Code Review Checklist

The self-review checklist an AI agent must run after implementation is defined in [`workflow/REVIEW.md`](../workflow/REVIEW.md). That document is the single source of truth for post-implementation review — follow it instead of duplicating its checklist here.

---

# 58. AI Coding Agent Workflow

The overall process — understanding the requirement, inspecting the system, and stopping for approval before coding — is defined in [`workflow/REQUIREMENT_ANALYSIS.md`](../workflow/REQUIREMENT_ANALYSIS.md). The steps below are the Frappe-specific technical checklist to apply *within* that process, not a replacement for it.

## Step 1 — Understand the Requirement

Identify:

```text
What is being changed?
Which Doctype?
Which module?
Frontend or backend?
New functionality or modification?
Does data migration exist?
Does configuration exist?
```

---

## Step 2 — Search Existing Code

Before creating anything, search for:

```text
Doctype name
field name
function name
API name
existing hooks
existing scripts
existing Settings
existing customizations
```

---

## Step 3 — Identify the Correct Extension Point

Choose the smallest appropriate extension point.

Decision:

```text
UI behavior?
    → Client Script

Small document event?
    → Server Script

Complex/reusable business logic?
    → Python

Application-wide event?
    → hooks.py

Existing data migration?
    → Patch

Deployable configuration record?
    → Fixture

Administrator-controlled behavior?
    → Settings

Field/metadata customization?
    → Custom Field + Export
```

---

# 59. AI Agent File Placement Rules

The AI agent should follow these conventions.

### Standard Doctype custom code

```text
custom_script/
└── <doctype_name>/
    ├── <doctype_name>.js
    └── <doctype_name>.py
```

### New custom Doctype

```text
<module>/
└── doctype/
    └── <doctype_name>/
        ├── <doctype_name>.json
        ├── <doctype_name>.py
        ├── <doctype_name>.js
        └── test_<doctype_name>.py
```

### Exported customization

```text
<module>/
└── custom/
```

### Patches

```text
patches/
└── <version>/
```

### Static frontend assets

```text
public/
```

### Website

```text
www/
```

### Reusable templates

```text
templates/
```

---

# 60. AI Agent Rules — Do Not

The AI agent must NOT:

- Directly modify ERPNext source code without explicit instruction.
- Create duplicate Client Scripts for the same Doctype unnecessarily.
- Create multiple unrelated implementations of the same event.
- Hardcode passwords.
- Hardcode API keys.
- Put secrets in JavaScript.
- Hide server-side errors.
- Use `print()` as production error logging.
- Create unnecessary patches.
- Use patches for normal business logic.
- Create fixtures for transactional data.
- Put complex business logic inside Jinja templates.
- Trust client-side validation for critical business rules.
- Create a new utility without searching for an existing one.
- Modify generated files without understanding their source.
- Delete existing logic without checking its consumers.
- Refactor unrelated code while implementing a focused feature.

---

# 61. AI Agent Rules — Must

The AI agent MUST:

1. Inspect existing implementation first.
2. Follow the Doctype-centric structure.
3. Reuse existing functions when possible.
4. Keep one primary Client Script per Doctype.
5. Keep Server Scripts organized by Doctype/event.
6. Use custom fields instead of directly modifying standard metadata.
7. Export customizations.
8. Use `custom_script/` for standard Doctype custom code.
9. Use Settings for configurable functionality.
10. Keep credentials server-side.
11. Log important errors through Frappe Error Log.
12. Add server-side validation for important business rules.
13. Check permissions for sensitive operations.
14. Use patches for existing-data migration.
15. Use fixtures for required deployable records.
16. Review the Git diff before completion.
17. Run relevant tests.
18. Avoid unrelated modifications.

---

