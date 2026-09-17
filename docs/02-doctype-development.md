# Part 2 — Doctype & Script Development

_Part of [FRAPPE_DEVELOPMENT.md](../FRAPPE_DEVELOPMENT.md) — the Frappe Development Knowledge Base index._

---

## Document Events

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

## Server Script Convention

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

### Server Script Decision Rule

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

## Client Script Convention

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

### Client Script Responsibilities

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

## Frontend Development Structure

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

## Standard Doctype Customization

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

## `custom_script/`

`custom_script/` is the project's preferred location for additional code related to standard DocTypes, organized by Doctype — see the example structure in "Standard Doctype Customization" above.

---

### Python File Responsibilities

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

### JavaScript File Responsibilities

The JS file can contain:

- Form events
- Buttons
- Filters
- Client-side validation
- UI behavior
- Dialogs
- Field handling

---

## Custom Fields

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

## Customization Export

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

### Customization Rule

When a field is required on an existing/standard Doctype, always go through the Custom Field → Export → `custom/` workflow described in "Custom Fields" and "Customization Export" above. Never edit the standard DocType's JSON directly.

This makes the customization:

- Version-controlled
- Reproducible
- Deployable
- Easier to review
- Safer during ERPNext upgrades

---

## DocTypes

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

## Doctype Python

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

## Doctype JavaScript

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

## Child Tables

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

