# Part 1 — Architecture, Philosophy & Bench (Sections 1-9)

_Part of [FRAPPE_DEVELOPMENT.md](../FRAPPE_DEVELOPMENT.md) — the Frappe Development Knowledge Base index._

---

# 1. Purpose

This document defines how Frappe/ERPNext development must be performed in this project.

It is intended to be used by:

- Frappe/ERPNext developers
- Technical leads
- AI coding agents such as Claude Code, Codex, Gemini Code Assist, etc.
- Developers maintaining custom Frappe applications

The goal is to keep the codebase:

- Structured
- Maintainable
- Upgrade-friendly
- Easy to understand
- Easy to deploy
- Easy to debug
- Consistent across developers
- Safe for AI-assisted development

This document is the **project development source of truth**.

When implementing a new feature or modifying existing functionality, the developer/AI agent must first understand and follow the conventions defined here.

---

# 2. Core Development Philosophy

The project follows a **Doctype-centric development approach**.

The primary principle is:

> Organize functionality around the relevant Doctype while keeping configuration, customization, business logic, and framework code properly separated.

The preferred development order is:

1. Use standard Frappe/ERPNext functionality when it already solves the requirement.
2. Use customization mechanisms for metadata changes.
3. Use hooks for application-level behavior.
4. Use Client Scripts for Doctype-specific frontend behavior.
5. Use Server Scripts for small event-specific server logic.
6. Use Python application code for reusable or complex business logic.
7. Use Settings for configurable behavior.
8. Use fixtures for records that must be version-controlled.
9. Use patches for database/data migrations.
10. Avoid modifying standard Frappe/ERPNext source code directly.

---

# 3. Golden Rules

The following rules apply throughout the project.

## 3.1 Do Not Duplicate Existing Functionality

Before creating new code:

- Search the project.
- Check the relevant Doctype.
- Check existing Client Scripts.
- Check existing Server Scripts.
- Check `hooks.py`.
- Check utility/helper functions.
- Check existing custom scripts.
- Check existing overrides.
- Check Settings.
- Check patches and migrations if the requirement is migration-related.

If functionality already exists, extend or reuse it instead of creating a duplicate implementation.

---

## 3.2 Do Not Modify Standard Frappe/ERPNext Code Directly

Do not directly edit files inside standard Frappe or ERPNext applications unless there is an explicit architectural reason.

Avoid changes such as:

```text
frappe/frappe/...
erpnext/erpnext/...
```

Prefer project application code and supported customization mechanisms.

Examples:

- Hooks
- Custom Fields
- Property Setters
- Client Scripts
- Server Scripts
- Custom Scripts
- Document Events
- Overrides
- Custom Python methods
- Fixtures
- Patches

---

## 3.3 Configuration Must Not Be Hardcoded

Values that can change by:

- environment
- company
- customer
- deployment
- administrator
- integration
- feature configuration

should not normally be hardcoded.

Use the appropriate Settings/configuration mechanism.

---

## 3.4 Keep Code Close to Its Doctype

When code belongs to a specific Doctype, it should be easy to locate by searching for that Doctype.

Example:

```text
Sales Order
    -> sales_order.js
    -> sales_order.py
    -> Sales Order Server Scripts
    -> Sales Order customizations
```

---

# 4. Frappe Architecture Overview

A typical Frappe installation consists of:

```text
Bench
│
├── apps/
│   ├── frappe/
│   ├── erpnext/
│   └── custom_app/
│
├── sites/
│   ├── common_site_config.json
│   └── site1.local/
│       ├── site_config.json
│       ├── private/
│       └── public/
│
├── config/
│
├── env/
├── logs/
├── patches.txt
└── Procfile
```

A custom application generally looks like:

```text
apps/
└── my_app/
    └── my_app/
        ├── hooks.py
        ├── modules.txt
        ├── patches.txt
        ├── __init__.py
        │
        ├── my_module/
        │   ├── __init__.py
        │   ├── doctype/
        │   ├── report/
        │   ├── page/
        │   └── custom/
        │
        ├── custom_script/
        │
        ├── public/
        ├── templates/
        └── www/
```

The exact structure may differ depending on the application, but the project should follow a predictable structure.

---

# 5. Bench

## 5.1 What is Bench?

Bench is the command-line environment/tooling used to manage Frappe sites and applications.

It is commonly used for:

- Creating sites
- Installing applications
- Running migrations
- Building assets
- Running development services
- Running console commands
- Running tests
- Managing workers
- Updating applications
- Clearing cache
- Managing the Frappe environment

---

# 6. Important Bench Commands

Commands should generally be executed from the bench directory.

Example:

```bash
cd /path/to/frappe-bench
```

---

## 6.1 Start Development Environment

```bash
bench start
```

Starts the development processes required for local development.

---

## 6.2 List Sites

```bash
bench --site all list-apps
```

For a specific site:

```bash
bench --site site-name list-apps
```

---

## 6.3 List Installed Apps

```bash
bench --site site-name list-apps
```

---

## 6.4 Migrate Site

```bash
bench --site site-name migrate
```

Migration should be performed after changes that require database/schema synchronization.

---

## 6.5 Clear Cache

```bash
bench --site site-name clear-cache
```

Clear website cache:

```bash
bench --site site-name clear-website-cache
```

When debugging stale metadata, permissions, routes, or cached configuration, clearing the appropriate cache may be required.

---

## 6.6 Build Assets

```bash
bench build
```

For development changes involving frontend assets, rebuild when necessary.

---

## 6.7 Restart Services

Depending on the environment:

```bash
bench restart
```

Production environments may use Supervisor/systemd or other process managers depending on deployment architecture.

---

## 6.8 Console

Open a Frappe console:

```bash
bench --site site-name console
```

Example:

```python
import frappe

doc = frappe.get_doc("Sales Order", "SO-00001")
print(doc.customer)
```

Use the console for:

- Debugging
- Data inspection
- Controlled data fixes
- Testing Frappe APIs
- Verifying document behavior

Avoid making uncontrolled production data changes.

---

## 6.9 Run Tests

Example:

```bash
bench --site site-name run-tests
```

For a specific module:

```bash
bench --site site-name run-tests --module my_app.my_module
```

Tests should be run for functionality that has automated test coverage.

---

## 6.10 Update

```bash
bench update
```

`bench update` may update applications and perform related operations depending on bench configuration.

Do not run update blindly on a production environment.

Always understand what will change before updating.

---

# 7. Site Configuration

Frappe uses configuration files at different levels.

Common files include:

```text
sites/common_site_config.json
sites/site-name/site_config.json
```

---

## 7.1 `common_site_config.json`

Contains configuration shared across sites in the bench.

Typical examples may include:

- Redis configuration
- Default site
- Socket configuration
- Background worker configuration
- Bench-level settings

---

## 7.2 `site_config.json`

Site-specific configuration.

Example:

```text
sites/
└── site-name/
    └── site_config.json
```

It may contain environment-specific configuration such as:

- Database configuration
- Site-specific settings
- Encryption-related configuration
- Host configuration
- Integration configuration where appropriate

Do not commit secrets or sensitive values unless the project's deployment/security strategy explicitly requires it.

---

# 8. `config/`

The bench-level `config/` directory generally contains process/deployment configuration.

Example:

```text
config/
├── redis_cache.conf
├── redis_queue.conf
├── redis_socketio.conf
├── supervisor.conf
└── nginx.conf
```

The exact contents depend on the bench/deployment setup.

Do not modify generated configuration blindly.

Understand whether the file is:

- source-controlled
- generated
- environment-specific
- deployment-managed

before making changes.

---

# 9. `hooks.py`

`hooks.py` is one of the most important files in a Frappe application.

It allows an application to integrate with framework/application events.

Typical uses include:

- Document events
- Scheduler events
- Override methods
- Override whitelisted methods
- Website hooks
- Fixtures
- App-level configuration
- Assets
- Boot session customization
- Notifications
- Installation/uninstallation behavior

Example:

```python
doc_events = {
    "Sales Order": {
        "validate": "my_app.custom_script.sales_order.sales_order.validate",
        "on_submit": "my_app.custom_script.sales_order.sales_order.on_submit",
    }
}
```

---

## 9.1 Hooks Rule

Before adding a hook:

1. Search existing `hooks.py`.
2. Check whether the same event is already registered.
3. Check whether another application already implements the behavior.
4. Avoid registering duplicate handlers.
5. Keep hook functions small.
6. Move complex logic into reusable Python functions.

---

