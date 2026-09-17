# Part 6 — Conventions, Testing & Migration Safety

_Part of [FRAPPE_DEVELOPMENT.md](../FRAPPE_DEVELOPMENT.md) — the Frappe Development Knowledge Base index._

---

## Naming Conventions

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

## File Naming

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

## Testing

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

Linting and formatting (ruff, and the pre-commit hooks that run it) are covered in ["Pre-commit Hooks (Linting)"](../GIT_WORKFLOW.md#pre-commit-hooks-linting) in `GIT_WORKFLOW.md` — code must pass those hooks, not just tests.

---

## Validation Strategy

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

## Migration Safety

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

