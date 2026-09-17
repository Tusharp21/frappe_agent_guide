# Frappe Development Knowledge Base

**Document:** `FRAPPE_DEVELOPMENT.md`
**Version:** `1.1`
**Purpose:** Project-level Frappe/ERPNext development standards and AI coding-agent instructions.

This document is the **project development source of truth**. It is intended to be used by Frappe/ERPNext developers, technical leads, AI coding agents (Claude Code, Codex, Gemini Code Assist, etc.), and developers maintaining custom Frappe applications.

The full knowledge base is split into focused parts under [`docs/`](./docs/) so each topic stays easy to read, link to, and maintain. Read them in order the first time; afterwards, jump directly to the part you need.

---

## Table of Contents

| Part | File | Covers |
| ---- | ---- | ------ |
| 1 | [`docs/01-architecture-and-bench.md`](./docs/01-architecture-and-bench.md) | Purpose, core philosophy, golden rules, Frappe architecture overview, Bench, bench commands, site configuration, `config/`, `hooks.py` |
| 2 | [`docs/02-doctype-development.md`](./docs/02-doctype-development.md) | Document events, Server Script & Client Script conventions, frontend structure, standard Doctype customization, `custom_script/`, custom fields, customization export, DocTypes, Doctype Python/JS, child tables |
| 3 | [`docs/03-app-structure-and-files.md`](./docs/03-app-structure-and-files.md) | Modules, `modules.txt`, `public/`, `templates/`, `www/`, templates vs `www`, fixtures, patches, patch rules, `patches.txt`, YAML/TOML/JSON files |
| 4 | [`docs/04-security-and-backend.md`](./docs/04-security-and-backend.md) | Settings architecture, feature flags, passwords & secrets, logging, error handling, API & integration development, whitelisted methods, permissions, database access, performance |
| 5 | [`docs/05-business-logic-and-jobs.md`](./docs/05-business-logic-and-jobs.md) | Business logic placement, scheduled jobs, background jobs, reports, print formats |
| 6 | [`docs/06-conventions-and-testing.md`](./docs/06-conventions-and-testing.md) | Naming conventions, file naming, testing, validation strategy, migration safety |
| 7 | [`docs/07-ai-agent-guide.md`](./docs/07-ai-agent-guide.md) | Git rules, code review checklist, AI coding-agent workflow, file placement rules, agent do's and don'ts |
| 8 | [`docs/08-examples-and-patterns.md`](./docs/08-examples-and-patterns.md) | Preferred implementation pattern and worked examples (field, client behavior, server validation, feature toggle, API integration, data migration, deployable configuration) |
| 9 | [`docs/09-debugging-and-operations.md`](./docs/09-debugging-and-operations.md) | Debugging workflow, frontend/backend debugging, database transaction awareness, security rules, documentation rule, change management, deployment checklist |
| 10 | [`docs/10-final-principles.md`](./docs/10-final-principles.md) | Minimal change principle, upgrade-friendly development, final AI agent checklist, project development golden rule, version history |

---

## Related Documents

* [`AGENTS.md`](./AGENTS.md) — the core rulebook and process flow for the AI agent.
* [`GIT_WORKFLOW.md`](./GIT_WORKFLOW.md) — Git branching, commit, and safety rules.
* [`workflow/`](./workflow/) — step-by-step Requirement Analysis, Implementation, and Review process.
* [`templates/`](./templates/) — Markdown templates for documenting tasks.

---

# END OF FRAPPE DEVELOPMENT KNOWLEDGE BASE INDEX
