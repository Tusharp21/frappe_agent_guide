# Part 10 — Final Principles

_Part of [FRAPPE_DEVELOPMENT.md](../FRAPPE_DEVELOPMENT.md) — the Frappe Development Knowledge Base index._

---

## Minimal Change Principle

When implementing a requirement:

> Make the smallest correct change that follows the existing architecture.

Avoid:

```text
Small requirement
    ↓
Large refactor
    ↓
Unrelated file changes
```

Prefer:

```text
Requirement
    ↓
Existing extension point
    ↓
Minimal implementation
    ↓
Test
```

Refactoring should be done separately when possible.

---

## Upgrade-Friendly Development

ERPNext/Frappe upgrades should be considered when designing customizations.

Prefer mechanisms that minimize conflicts with framework/application updates.

Preferred:

```text
Custom App
├── Hooks
├── Custom Fields
├── Property Setters
├── Client Scripts
├── Server Scripts
├── Custom Scripts
├── Overrides
├── Fixtures
└── Patches
```

Avoid:

```text
Direct modification of ERPNext source
```

because direct modifications increase upgrade and merge complexity.

---

## Final AI Agent Checklist

Before completing any Frappe development task, run back through ["AI Agent Rules — Do Not" and "AI Agent Rules — Must"](./07-ai-agent-guide.md) as a final self-check, alongside the process checklist in `workflow/REVIEW.md`.

---

## Project Development Golden Rule

The most important rule for this project is:

> **Before creating new Frappe code, first understand where the existing functionality belongs and extend the existing architecture instead of creating a parallel implementation.**

The project should remain:

```text
Doctype-centric
        +
Configuration-driven
        +
Server-validated
        +
Upgrade-friendly
        +
Version-controlled
        +
Easy to debug
```