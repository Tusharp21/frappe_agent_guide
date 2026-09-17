# FRAPPE-AI-DEV-TEMPLATE

## Overview
This repository serves as a structured system for integrating an AI Agent into Frappe Framework development. It acts as the "Brain" and "Rulebook" for the AI, ensuring that all generated code is secure, standard-compliant, and strictly follows the approved architecture.

## Why This Exists
AI agents often generate generic code, miss framework-specific nuances, or overwrite existing patterns. This template forces the AI to:
1. Understand Frappe standard practices.
2. Analyze before writing code.
3. Seek human approval before implementation.
4. Self-review its work.

## Directory Structure
* `AGENTS.md`: The core rulebook and instructions for the AI.
* `FRAPPE_DEVELOPMENT.md`: Table-of-contents index for the Frappe-specific coding standards and best practices, split into 10 parts under `docs/` for easier maintenance.
* `docs/`: The full development knowledge base, one focused file per topic (architecture, doctype development, app structure, security, business logic, conventions, AI agent guide, examples, debugging, final principles).
* `GIT_WORKFLOW.md`: Git branching, commit, and safety rules the AI must follow.
* `workflow/`: The step-by-step process the AI must follow.
  * `REQUIREMENT_ANALYSIS.md`: Pre-coding inspection and planning.
  * `IMPLEMENTATION.md`: Approved coding guidelines.
  * `REVIEW.md`: Post-coding quality and security checks.
* `templates/`: Markdown templates for documenting tasks.
  * `TASK_TEMPLATE.md`: Standard format for breaking down complex tasks.
* `LICENSE`: MIT license for this template.
* `.pre-commit-config.yaml`: Pre-commit hooks (ruff for Python lint/format, plus common whitespace/YAML/JSON checks) so the AI agent knows this project enforces linting before commit.
* `install.sh` / `uninstall.sh`: One-line install/uninstall scripts (see [Installation](#installation) and [Uninstallation](#uninstallation)). Not copied into your project.
* `CONTRIBUTING.md`: How to propose changes to this template itself.
* `.github/PULL_REQUEST_TEMPLATE.md`: PR checklist used when contributing to this template.

## Installation

1. `cd` into the root of your Frappe custom app or project workspace.
2. Run:

   ```bash
   curl -fsSL https://raw.githubusercontent.com/Tusharp21/frappe_agent_guide/master/install.sh | bash
   ```

3. This downloads the template and copies `AGENTS.md`, `FRAPPE_DEVELOPMENT.md`, `GIT_WORKFLOW.md`, `LICENSE`, `docs/`, `workflow/`, `templates/`, and `.pre-commit-config.yaml` straight into the current directory. It never touches unrelated files in your project.
4. By default it will **not** overwrite files that already exist at the destination:
   * Add `--force` to overwrite them: `curl -fsSL .../install.sh | bash -s -- --force`
   * Add `--dir <path>` to install somewhere other than the current directory: `curl -fsSL .../install.sh | bash -s -- --dir /path/to/project`
   * Add `--branch <name>` to install from a branch/tag other than `master`.
   * Run with `--help` to see all options: `curl -fsSL .../install.sh | bash -s -- --help`

Prefer not to pipe a script from the internet into `bash`? Clone or download this repository and copy `AGENTS.md`, `FRAPPE_DEVELOPMENT.md`, `GIT_WORKFLOW.md`, `LICENSE`, `docs/`, `workflow/`, `templates/`, and `.pre-commit-config.yaml` into your project root by hand.

Once installed, also run `pip install pre-commit && pre-commit install` inside your Frappe app so the hooks (ruff lint/format, plus common whitespace/YAML/JSON checks) actually run on commit.

## Uninstallation

1. `cd` into the project you installed the template into.
2. Run:

   ```bash
   curl -fsSL https://raw.githubusercontent.com/Tusharp21/frappe_agent_guide/master/uninstall.sh | bash
   ```

3. It lists everything it's about to delete (`AGENTS.md`, `FRAPPE_DEVELOPMENT.md`, `GIT_WORKFLOW.md`, `LICENSE`, `docs/`, `workflow/`, `templates/`, `.pre-commit-config.yaml`) and asks for confirmation before removing anything. `README.md` is left in place since projects often customize it after install.
4. For non-interactive shells (CI, scripts), skip the prompt with `--yes`: `curl -fsSL .../uninstall.sh | bash -s -- --yes`
5. Add `--dir <path>` to uninstall from a directory other than the current one.

Or just delete the files/folders by hand — the uninstaller doesn't do anything you couldn't do with `rm -rf`.

## How to use this in a new project
1. Install the template into your project root (see [Installation](#installation) above).
2. When starting a session with an AI (like Claude Code, Cursor, GitHub Copilot, or ChatGPT), prompt the AI to: *"Read README.md and AGENTS.md first."*
3. For business-specific logic, create a separate `project_knowledge/` folder. Do not clutter these global files with business context.

## Basic Workflow
1. **User:** Describes the task.
2. **AI:** Reads guidelines -> Analyzes system -> Presents a plan using `workflow/REQUIREMENT_ANALYSIS.md`.
3. **User:** Approves or requests changes to the plan.
4. **AI:** Implements code based on `workflow/IMPLEMENTATION.md`.
5. **AI:** Reviews code based on `workflow/REVIEW.md` and provides the final output.