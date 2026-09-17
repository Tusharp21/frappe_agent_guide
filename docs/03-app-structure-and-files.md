# Part 3 — App Structure & Config Files

_Part of [FRAPPE_DEVELOPMENT.md](../FRAPPE_DEVELOPMENT.md) — the Frappe Development Knowledge Base index._

---

## Modules

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

## `modules.txt`

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

## `public/`

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

## `templates/`

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

## `www/`

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

## Templates vs `www`

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

## Fixtures

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

### Fixture Rule

Use fixtures when a record is:

1. Required by the application.
2. Required across environments.
3. Expected to be deployed through Git/application installation.
4. Not appropriate to create manually in every environment.

Do not fixture arbitrary transactional data.

Avoid committing production-specific transactional records as fixtures.

---

## Patches

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

## Patch Rules

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

### Patch Naming

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

## `patches.txt`

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

## YAML Files

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

## TOML Files

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

## JSON Files

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

