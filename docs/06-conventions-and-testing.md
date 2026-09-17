# Part 6 — Conventions, Testing & Migration Safety (Sections 51-55)

_Part of [FRAPPE_DEVELOPMENT.md](../FRAPPE_DEVELOPMENT.md) — the Frappe Development Knowledge Base index._

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

