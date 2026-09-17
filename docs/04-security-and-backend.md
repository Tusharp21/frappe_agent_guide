# Part 4 — Settings, Security & Backend Practices

_Part of [FRAPPE_DEVELOPMENT.md](../FRAPPE_DEVELOPMENT.md) — the Frappe Development Knowledge Base index._

---

## Settings Architecture

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

## Feature Flags

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

## Passwords and Secrets

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

## Logging

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

## Logging Rules

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

## Error Handling

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

## API and Integration Development

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

## Whitelisted Methods

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

## Permissions

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

## Database Access

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

## Performance

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

