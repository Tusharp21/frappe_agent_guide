# Part 10 — Final Principles & Version History (Sections 78-82)

_Part of [FRAPPE_DEVELOPMENT.md](../FRAPPE_DEVELOPMENT.md) — the Frappe Development Knowledge Base index._

---

# 78. Minimal Change Principle

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

# 79. Upgrade-Friendly Development

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

# 80. Final AI Agent Checklist

Before completing any Frappe development task, the AI agent should mentally verify:

```text
[ ] Did I understand the requirement?
[ ] Did I identify the correct Doctype?
[ ] Did I identify the correct module?
[ ] Did I search existing code?
[ ] Did I search existing hooks?
[ ] Did I search existing Client Scripts?
[ ] Did I search existing Server Scripts?
[ ] Did I check existing utilities?
[ ] Did I avoid duplicate implementation?
[ ] Did I follow Doctype-centric organization?
[ ] Did I keep one Client Script per Doctype?
[ ] Did I organize Server Scripts by Doctype/event?
[ ] Did I use custom_script/ for standard Doctype code?
[ ] Did I create fields through customization mechanisms?
[ ] Did I export customizations?
[ ] Did I use Settings for configurable values?
[ ] Did I protect credentials?
[ ] Did I add server-side validation?
[ ] Did I handle errors properly?
[ ] Did I use Error Log where appropriate?
[ ] Did I use a patch for required data migration?
[ ] Did I use fixtures for deployable configuration records?
[ ] Did I avoid modifying standard Frappe/ERPNext source?
[ ] Did I run relevant tests?
[ ] Did I inspect git diff?
[ ] Did I avoid unrelated changes?
```

---

# 81. Project Development Golden Rule

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

---

# 82. Version History

## Version 1.0

Initial development knowledge base covering:

- Bench
- Bench commands
- Site configuration
- Hooks
- Document events
- Fixtures
- Patches
- Modules
- DocTypes
- `public/`
- `templates/`
- `www/`
- YAML
- TOML
- JSON
- Client Scripts
- Server Scripts
- Custom Scripts
- Custom Fields
- Exported Customizations
- Settings
- Feature Flags
- Secrets
- Logging
- Error Handling
- API integrations
- Permissions
- Database access
- Testing
- Migration
- Deployment
- AI coding-agent rules
- Project-specific development conventions

## Version 1.1

- Split the single `FRAPPE_DEVELOPMENT.md` file into 10 parts under `docs/`, with `FRAPPE_DEVELOPMENT.md` kept as the table-of-contents index. Content unchanged, only reorganized for maintainability.
- Removed duplicated Git rules and code review checklist from the knowledge base; both now point to `GIT_WORKFLOW.md` and `workflow/REVIEW.md` as the single source of truth.
- Added a root `.gitignore` and `LICENSE` (MIT) to the repository.

---

# END OF FRAPPE DEVELOPMENT KNOWLEDGE BASE