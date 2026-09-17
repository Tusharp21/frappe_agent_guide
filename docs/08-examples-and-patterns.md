# Part 8 — Implementation Patterns & Examples (Sections 62-69)

_Part of [FRAPPE_DEVELOPMENT.md](../FRAPPE_DEVELOPMENT.md) — the Frappe Development Knowledge Base index._

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

