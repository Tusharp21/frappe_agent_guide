# Frappe Development Knowledge Base

**Document:** `FRAPPE_DEVELOPMENT.md`  
**Version:** `1.0`  
**Purpose:** Project-level Frappe/ERPNext development standards and AI coding-agent instructions.

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

# 10. Document Events

Document events allow custom server-side logic to execute during a document lifecycle.

Common events include:

```text
before_insert
after_insert
validate
before_save
on_update
before_submit
on_submit
before_cancel
on_cancel
on_trash
after_delete
```

Exact available events depend on the Frappe document lifecycle.

Use the event that represents the actual business requirement.

For example:

```python
doc_events = {
    "Purchase Order": {
        "validate": "my_app.custom_script.purchase_order.purchase_order.validate"
    }
}
```

---

# 11. Server Script Convention

This project follows a **Doctype + Event** approach for Server Scripts.

Example:

```text
Purchase Order
├── Validate
├── Before Submit
├── After Submit
└── On Cancel
```

Each event should have a clear responsibility.

Avoid creating one large Server Script that contains unrelated logic for multiple events.

---

## 11.1 Server Script Decision Rule

Use Server Script for:

- Small event-specific logic
- Simple validations
- Simple field updates
- Small automation
- Lightweight document event behavior

Move logic into application Python code when it becomes:

- Large
- Reusable
- Complex
- Security-sensitive
- Test-heavy
- Integration-heavy
- Difficult to maintain in a Server Script

---

# 12. Client Script Convention

This project follows a **one Client Script per Doctype** convention.

For each Doctype, client-side functionality should preferably remain in a single JS implementation.

Example:

```text
Sales Order
└── sales_order.js
```

That file can contain:

```javascript
frappe.ui.form.on("Sales Order", {
    refresh(frm) {
        // UI logic
    },

    validate(frm) {
        // client validation
    },

    customer(frm) {
        // customer field event
    },

    before_save(frm) {
        // client-side pre-save logic
    }
});
```

Helper functions may be defined in the same file when they belong specifically to the Doctype.

---

## 12.1 Client Script Responsibilities

Client-side code can handle:

- UI behavior
- Buttons
- Dialogs
- Field visibility
- Field properties
- Query filters
- Client-side validation
- Fetching data for UI purposes
- Form events
- User interaction

Client-side validation must not be considered sufficient for critical business rules.

Important business validations must also be enforced server-side.

---

# 13. Frontend Development Structure

Frontend development should follow this hierarchy:

```text
Application
└── Module
    └── Doctype
        └── Client-side logic
```

The goal is to make it immediately obvious:

> "This code belongs to this Doctype."

Avoid unrelated global JS unless the behavior is genuinely application-wide.

---

# 14. Standard Doctype Customization

Standard ERPNext/Frappe DocTypes must not normally be modified directly.

For example, if additional behavior is required for:

```text
Sales Order
Purchase Order
Sales Invoice
Purchase Receipt
Customer
Supplier
```

the project should implement the behavior through the custom application.

Recommended structure:

```text
my_app/
└── my_app/
    └── custom_script/
        ├── sales_order/
        │   ├── sales_order.js
        │   └── sales_order.py
        │
        ├── purchase_order/
        │   ├── purchase_order.js
        │   └── purchase_order.py
        │
        └── sales_invoice/
            ├── sales_invoice.js
            └── sales_invoice.py
```

---

# 15. `custom_script/`

`custom_script/` is the project's preferred location for additional code related to standard DocTypes.

Example:

```text
custom_script/
└── purchase_order/
    ├── purchase_order.js
    └── purchase_order.py
```

The directory should be organized by Doctype.

---

## 15.1 Python File Responsibilities

The Python file can contain:

- Validation logic
- Document event handlers
- Helper methods
- Business logic
- Integration calls
- Data processing

Example:

```python
def validate(doc, method=None):
    validate_custom_business_rule(doc)
```

---

## 15.2 JavaScript File Responsibilities

The JS file can contain:

- Form events
- Buttons
- Filters
- Client-side validation
- UI behavior
- Dialogs
- Field handling

---

# 16. Custom Fields

Custom fields should be created through Frappe's customization mechanisms rather than by manually modifying standard DocType definitions.

Preferred workflow:

```text
Create field
    ↓
Customize Form / Custom Field
    ↓
Associate with correct module
    ↓
Export customization
    ↓
Review generated JSON
    ↓
Commit to Git
```

---

# 17. Customization Export

Exported customizations should be stored in the relevant application's module.

The project uses a `custom/` directory for exported customization data.

Example:

```text
my_app/
└── my_app/
    └── my_module/
        └── custom/
            ├── custom_field.json
            ├── property_setter.json
            └── ...
```

The exact generated files depend on what has been customized.

---

## 17.1 Customization Rule

When a field is required on an existing/standard Doctype:

**Preferred:**

```text
Custom Field
    ↓
Export
    ↓
custom/
```

**Avoid:**

```text
Directly editing ERPNext standard DocType JSON
```

This makes the customization:

- Version-controlled
- Reproducible
- Deployable
- Easier to review
- Safer during ERPNext upgrades

---

# 18. DocTypes

DocTypes are the core data/model abstraction in Frappe.

A DocType generally defines:

- Fields
- Data types
- Naming
- Permissions
- Child tables
- Workflow-related configuration
- Form behavior
- Database representation
- Metadata

Typical structure:

```text
my_module/
└── doctype/
    └── my_doctype/
        ├── __init__.py
        ├── my_doctype.json
        ├── my_doctype.py
        ├── my_doctype.js
        ├── my_doctype_list.js
        ├── my_doctype_tree.js
        └── test_my_doctype.py
```

Not every Doctype requires every file.

---

# 19. Doctype Python

The main Python controller can contain server-side document behavior.

Example:

```python
import frappe
from frappe.model.document import Document


class MyDoctype(Document):
    def validate(self):
        self.validate_business_rules()

    def validate_business_rules(self):
        pass
```

Use the controller when the behavior is part of the Doctype itself.

Keep reusable logic in appropriate helper/service modules where necessary.

---

# 20. Doctype JavaScript

A Doctype JS file is responsible for client-side behavior specific to that DocType.

Example:

```javascript
frappe.ui.form.on("My Doctype", {
    refresh(frm) {
        // Form UI
    },

    validate(frm) {
        // Client-side validation
    }
});
```

For a project convention, avoid unnecessarily creating multiple JS implementations for the same Doctype.

---

# 21. Child Tables

Child tables should remain logically associated with their parent DocType.

Example:

```text
Sales Order
└── Sales Order Item
```

When adding child-table behavior:

- Identify the parent Doctype.
- Identify the child Doctype.
- Keep parent form behavior in the parent Client Script.
- Keep reusable server-side logic in Python.
- Avoid duplicating calculations across multiple locations.

Critical calculations should be validated server-side.

---

# 22. Modules

A Frappe application can contain multiple modules.

Example:

```text
my_app/
└── my_module/
    ├── doctype/
    ├── report/
    ├── page/
    ├── workspace/
    └── custom/
```

A module should represent a meaningful business/application area.

Examples:

```text
Billing
Project Management
Vendor Management
Manufacturing
Integration
HR
Finance
```

Use modules to keep related functionality grouped together.

---

# 23. `modules.txt`

`modules.txt` identifies modules belonging to an application.

Example:

```text
Billing
Project Management
Vendor Management
```

When creating a new module, ensure that the module is correctly registered.

Do not manually add arbitrary entries without understanding how the application/module was created.

---

# 24. `public/`

The `public/` directory is generally used for static assets.

Example:

```text
public/
├── js/
├── css/
├── images/
└── ...
```

Possible contents:

- JavaScript assets
- CSS
- Images
- Other static files

Use `public/` for assets that need to be served as application resources.

Avoid placing business logic in static assets.

---

# 25. `templates/`

The `templates/` directory contains reusable templates.

Typical structure:

```text
templates/
├── pages/
├── includes/
├── emails/
└── ...
```

Templates may be used for:

- Website pages
- Email templates
- Reusable HTML
- Jinja templates

Keep template logic lightweight.

Complex business logic should remain in Python.

---

# 26. `www/`

The `www/` directory is used for website routes/pages.

Example:

```text
www/
├── my-page/
│   ├── index.html
│   └── my-page.py
│
└── another-page/
    └── index.html
```

The directory structure can define website routes.

Use `www/` for website-facing pages, not normal Desk/Doctype functionality.

---

# 27. Templates vs `www`

Use:

```text
www/
```

when creating website routes/pages.

Use:

```text
templates/
```

for reusable templates/includes.

Do not create website pages in arbitrary locations.

---

# 28. Fixtures

Fixtures are used to export/import records or configuration that should be maintained as part of the application.

Typical examples include:

- Custom Fields
- Property Setters
- Client Scripts
- Server Scripts
- Workspaces
- Custom configuration records
- Other selected DocType records

Example concept:

```text
fixtures/
└── custom_field.json
```

---

## 28.1 Fixture Rule

Use fixtures when a record is:

1. Required by the application.
2. Required across environments.
3. Expected to be deployed through Git/application installation.
4. Not appropriate to create manually in every environment.

Do not fixture arbitrary transactional data.

Avoid committing production-specific transactional records as fixtures.

---

# 29. Patches

Patches are used for controlled database/data migrations.

A patch is appropriate when existing data must be transformed because of a code/schema change.

Example:

```text
my_app/
└── patches/
    ├── __init__.py
    └── v1/
        ├── __init__.py
        └── update_old_data.py
```

Patch example:

```python
import frappe


def execute():
    records = frappe.get_all(
        "My Doctype",
        fields=["name"]
    )

    for record in records:
        # Migration logic
        pass
```

---

# 30. Patch Rules

A patch should be:

- Deterministic
- Safe
- Repeat-aware where appropriate
- Focused
- Documented
- Tested

Do not use patches as a replacement for normal application logic.

Use a patch when the purpose is to migrate existing data or schema-related state.

---

## 30.1 Patch Naming

Patch names should clearly describe the migration.

Good:

```text
update_customer_reference.py
migrate_old_status_values.py
create_missing_records.py
```

Avoid:

```text
fix.py
temp.py
test_patch.py
new.py
```

---

# 31. `patches.txt`

`patches.txt` controls the sequence of patches that are executed.

Example concept:

```text
my_app.patches.v1.update_customer_reference
my_app.patches.v1.migrate_old_status_values
```

Patches should be added in the correct sequence.

Once a patch has been deployed and executed, do not casually edit its historical behavior.

If a new correction is required, prefer creating a new patch.

---

# 32. YAML Files

YAML is commonly used for configuration and automation files.

Example:

```yaml
name: my_app
version: 1.0.0
enabled: true
```

YAML is indentation-sensitive.

Important rules:

- Use consistent indentation.
- Do not mix tabs and spaces.
- Validate YAML syntax.
- Keep keys meaningful.
- Avoid unnecessary duplication.

Before modifying a YAML file, identify whether it is:

- CI/CD configuration
- Deployment configuration
- Application configuration
- Tool configuration
- Generated configuration

---

# 33. TOML Files

TOML is another configuration format commonly encountered in Python projects.

Example:

```toml
[project]
name = "my_app"
version = "1.0.0"
```

Common files may include:

```text
pyproject.toml
```

TOML configuration can define:

- Python project metadata
- Dependencies
- Build configuration
- Tool configuration
- Formatting/linting configuration

Do not modify `pyproject.toml` without checking the tools that consume its configuration.

---

# 34. JSON Files

Frappe uses JSON extensively for metadata/configuration.

Examples:

```text
site_config.json
common_site_config.json
doctype.json
```

When modifying JSON:

- Keep valid JSON syntax.
- Do not add comments.
- Preserve expected Frappe metadata structure.
- Avoid manually modifying generated metadata when an official customization mechanism exists.

---

# 35. Settings Architecture

The project follows a **central Settings pattern**.

Application-level configurable behavior should be managed through a dedicated Settings DocType/Page.

Example:

```text
My Application Settings
│
├── Feature Settings
│   ├── Enable Feature A
│   ├── Enable Feature B
│   └── Enable Automation
│
├── Integration Settings
│   ├── API URL
│   ├── API Key
│   └── API Configuration
│
├── Security/Secret Settings
│   ├── Password
│   └── Secret Configuration
│
└── Other Configuration
```

---

# 36. Feature Flags

If a feature needs to be enabled/disabled by an administrator, use a Settings field.

Example:

```text
Enable Liquidated Damages
Enable OCR
Enable SAP Integration
Enable Automatic Quality Inspection
```

Application code should check the configured value.

Conceptually:

```python
settings = frappe.get_single("My Application Settings")

if settings.enable_feature:
    # Feature logic
    pass
```

Do not hardcode:

```python
ENABLE_FEATURE = True
```

when the business expects the administrator to control the feature.

---

# 37. Passwords and Secrets

Password/API-secret related configuration should be managed through the designated Settings mechanism.

Never hardcode:

```python
API_KEY = "abc123"
PASSWORD = "mypassword"
TOKEN = "secret"
```

Never commit real credentials into Git.

Do not expose secrets in:

- Client-side JS
- API responses
- Logs
- Error messages
- Browser console
- Public files

Secrets must remain server-side.

---

# 38. Logging

Application errors that require persistent investigation should be recorded through Frappe's Error Log mechanisms.

Example:

```python
frappe.log_error(
    title="Custom Integration Error",
    message=frappe.get_traceback()
)
```

Use meaningful titles.

Example:

```text
SAP PO Integration Error
OCR Invoice Processing Error
Purchase Order Validation Error
Payment Gateway Error
```

---

# 39. Logging Rules

Logs should provide useful debugging context.

Include where appropriate:

- Document type
- Document name
- Operation
- External API
- Error message
- Traceback
- Relevant non-sensitive identifiers

Never log:

- Passwords
- API secrets
- Access tokens
- Sensitive credentials
- Unnecessary personal data

Bad:

```python
frappe.log_error(str(password))
```

Good:

```python
frappe.log_error(
    title="SAP Integration Error",
    message=frappe.get_traceback()
)
```

---

# 40. Error Handling

Do not silently ignore exceptions.

Bad:

```python
try:
    process_invoice()
except:
    pass
```

Better:

```python
try:
    process_invoice()
except Exception:
    frappe.log_error(
        title="Invoice Processing Error",
        message=frappe.get_traceback()
    )
    raise
```

Whether the exception should be re-raised depends on the business requirement.

Do not hide failures merely to make the transaction appear successful.

---

# 41. API and Integration Development

External API integrations must remain server-side unless there is a clear reason otherwise.

Preferred flow:

```text
Frontend
   ↓
Whitelisted Python Method
   ↓
Business Logic
   ↓
External API
   ↓
Response Processing
   ↓
Database
```

Avoid:

```text
Browser
   ↓
External API using secret credentials
```

because credentials can be exposed to the client.

---

# 42. Whitelisted Methods

Use whitelisted methods when frontend/client code needs to call server-side functionality.

Example:

```python
@frappe.whitelist()
def get_customer_details(customer):
    ...
```

Client:

```javascript
frappe.call({
    method: "my_app.api.get_customer_details",
    args: {
        customer: frm.doc.customer
    }
});
```

Server-side methods must validate permissions and input.

Never assume that hiding a button on the frontend provides security.

---

# 43. Permissions

Permissions must be enforced server-side.

Client-side behavior such as:

```javascript
frm.set_df_property(...)
```

does not replace server-side permission checks.

For sensitive operations:

- Validate user permissions.
- Validate document permissions.
- Validate business rules.
- Validate ownership/access where required.

---

# 44. Database Access

Prefer Frappe APIs when appropriate.

Examples:

```python
frappe.get_doc(...)
frappe.get_all(...)
frappe.get_list(...)
frappe.db.get_value(...)
frappe.db.exists(...)
```

Use SQL only when necessary.

Example:

```python
frappe.db.sql(...)
```

When using SQL:

- Use parameterized queries.
- Avoid SQL injection.
- Avoid unnecessary queries.
- Avoid loading large datasets unnecessarily.
- Understand transaction behavior.

---

# 45. Performance

Avoid unnecessary database queries.

Bad pattern:

```python
for item in items:
    frappe.db.get_value(...)
```

when the same information can be fetched efficiently in bulk.

Be careful with:

- Loops over large datasets
- API calls inside loops
- Repeated database calls
- Expensive reports
- Large child tables
- Unnecessary document saves

Performance-sensitive code should be measured rather than optimized based only on assumptions.

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

# 51. Naming Conventions

Use clear, descriptive names.

Python:

```text
snake_case
```

JavaScript:

```text
camelCase
```

Classes:

```text
PascalCase
```

Examples:

```python
create_billing_plan()
validate_payment_schedule()
```

```javascript
setCustomerAddress()
calculateBillingValue()
```

---

# 52. File Naming

Prefer names based on the Doctype or responsibility.

Good:

```text
purchase_order.py
purchase_order.js
payment_schedule.py
invoice_processing.py
```

Avoid:

```text
temp.py
test2.py
new.py
final.py
abc.py
```

---

# 53. Testing

New business-critical functionality should have appropriate tests.

Test:

- Valid scenarios
- Invalid scenarios
- Boundary conditions
- Permissions where relevant
- Existing behavior
- Regression cases

Example:

```python
class TestMyDoctype(FrappeTestCase):
    def test_valid_document(self):
        ...

    def test_invalid_document(self):
        ...
```

---

# 54. Validation Strategy

Important business rules should be validated on the server.

Preferred:

```text
Client Validation
        +
Server Validation
```

Do not rely only on:

```text
Client Validation
```

because API calls, imports, background jobs, console operations, and other server-side paths can bypass frontend code.

---

# 55. Migration Safety

When changing existing fields or data:

1. Understand current data.
2. Identify affected records.
3. Decide whether the change is metadata-only or data migration.
4. Use a patch when existing data needs transformation.
5. Test on a non-production environment.
6. Run migration.
7. Verify data.

Never assume that adding a field automatically solves historical data requirements.

---

# 56. Git Rules

Before committing:

```bash
git status
git diff
```

Review:

- Modified files
- Added files
- Deleted files
- Generated files
- Unexpected standard application changes
- Secrets
- Debug code

Do not commit:

```text
.env
passwords
API secrets
access tokens
temporary files
local database dumps
unnecessary logs
```

unless explicitly required by the project's repository strategy.

---

# 57. Code Review Checklist

Before considering a change complete:

### Architecture

- [ ] Correct module
- [ ] Correct Doctype
- [ ] Correct location
- [ ] Existing implementation checked
- [ ] No unnecessary duplication

### Frontend

- [ ] Correct Client Script
- [ ] Existing Doctype JS checked
- [ ] UI logic only where appropriate
- [ ] No secrets in JS

### Backend

- [ ] Server-side validation implemented
- [ ] Permissions considered
- [ ] Error handling implemented
- [ ] Reusable logic extracted where appropriate

### Customization

- [ ] Fields created through customization mechanism
- [ ] Customization exported
- [ ] `custom/` files reviewed

### Configuration

- [ ] Configurable values are not hardcoded
- [ ] Settings used where appropriate
- [ ] Secrets protected

### Database

- [ ] Queries reviewed
- [ ] SQL parameterized
- [ ] Migration requirement checked
- [ ] Patch added if necessary

### Testing

- [ ] Relevant tests executed
- [ ] Existing behavior verified
- [ ] Regression scenario checked

### Git

- [ ] `git diff` reviewed
- [ ] No accidental standard framework changes
- [ ] No secrets
- [ ] No debug code

---

# 58. AI Coding Agent Workflow

AI agents must follow this workflow before modifying the project.

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

# 62. Preferred Implementation Pattern

For a typical business requirement:

```text
                    Requirement
                         │
                         ▼
                Identify Doctype
                         │
                         ▼
               Search Existing Code
                         │
                         ▼
              Check Existing Feature
                         │
                         ▼
              Choose Extension Point
                         │
        ┌────────────────┼────────────────┐
        ▼                ▼                ▼
      Client           Server          Metadata
       UI              Logic          Customization
        │                │                │
        ▼                ▼                ▼
       JS          Python/Script      Custom Field
                                      Property Setter
                                           │
                                           ▼
                                        Export
```

---

# 63. Example — Adding a Field

Requirement:

> Add `custom_delivery_date` to Purchase Order.

Preferred process:

```text
1. Open Purchase Order customization.
2. Create Custom Field.
3. Configure field properties.
4. Assign appropriate module.
5. Export customization.
6. Verify generated custom JSON.
7. Commit the customization.
```

Do not edit:

```text
erpnext/buying/doctype/purchase_order/purchase_order.json
```

directly.

---

# 64. Example — Adding Client Behavior

Requirement:

> When `supplier` changes, update a UI field.

Use the Purchase Order Client Script.

Conceptually:

```javascript
frappe.ui.form.on("Purchase Order", {
    supplier(frm) {
        // Client-side behavior
    }
});
```

Do not create another unrelated Purchase Order Client Script if the project's existing convention already has one.

Extend the existing implementation.

---

# 65. Example — Adding Server Validation

Requirement:

> Purchase Order cannot be submitted when a business condition is invalid.

The validation must exist server-side.

Example:

```python
def validate(doc, method=None):
    if invalid_condition(doc):
        frappe.throw("Purchase Order cannot be submitted.")
```

The UI may also show the error earlier, but server-side validation remains authoritative.

---

# 66. Example — Feature Toggle

Requirement:

> Enable/disable an integration from the administrator UI.

Preferred:

```text
Application Settings
    └── Enable Integration
```

Then:

```python
settings = frappe.get_single("My Application Settings")

if settings.enable_integration:
    run_integration()
```

Avoid hardcoding the flag.

---

# 67. Example — API Integration

Preferred:

```text
Client
  ↓
frappe.call()
  ↓
Whitelisted Python Method
  ↓
Settings
  ↓
External API
  ↓
Validate Response
  ↓
Update Document
  ↓
Error Log on Failure
```

Never expose credentials to the browser.

---

# 68. Example — Data Migration

Requirement:

> Existing records need to receive a new calculated value.

Preferred:

```text
New field
    ↓
Patch
    ↓
Read existing records
    ↓
Calculate value
    ↓
Update records
```

Do not put historical migration logic into normal document validation if it only exists to repair/migrate old data.

---

# 69. Example — Deployable Configuration

Requirement:

> A required Custom Field/Client Script must exist on every environment.

Use:

```text
Fixture
```

or the appropriate exported customization mechanism.

The objective is:

```text
Developer Environment
        ↓
Git
        ↓
Deployment
        ↓
Test Environment
        ↓
Production
```

without manually recreating the configuration.

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

---

# END OF FRAPPE DEVELOPMENT KNOWLEDGE BASE