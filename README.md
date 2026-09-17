# FRAPPE-AI-DEV-TEMPLATE

## Overview
This repository serves as a structured system for integrating an AI Agent into Frappe Framework development. It acts as the "Brain" and "Rulebook" for the AI, ensuring that all generated code is secure, standard-compliant, and strictly follows the approved architecture.

## Why this exists?
AI agents often generate generic code, miss framework-specific nuances, or overwrite existing patterns. This template forces the AI to:
1. Understand Frappe standard practices.
2. Analyze before writing code.
3. Seek human approval before implementation.
4. Self-review its work.

## Directory Structure
* `AGENTS.md`: The core rulebook and instructions for the AI.
* `FRAPPE_DEVELOPMENT.md`: Frappe-specific coding standards and best practices.
* `workflow/`: The step-by-step process the AI must follow.
  * `REQUIREMENT_ANALYSIS.md`: Pre-coding inspection and planning.
  * `IMPLEMENTATION.md`: Approved coding guidelines.
  * `REVIEW.md`: Post-coding quality and security checks.
* `templates/`: Markdown templates for documenting tasks.
  * `TASK_TEMPLATE.md`: Standard format for breaking down complex tasks.

## How to use this in a new project
1. Copy this entire folder structure into the root of your Frappe custom app or project workspace.
2. When starting a session with an AI (like Cursor, GitHub Copilot, or ChatGPT), prompt the AI to: *"Read the FRAPPE-AI-DEV-TEMPLATE/README.md and AGENTS.md first."*
3. For business-specific logic, create a separate `project_knowledge/` folder. Do not clutter these global files with business context.

## Basic Workflow
1. **User:** Describes the task.
2. **AI:** Reads guidelines -> Analyzes system -> Presents a plan using `REQUIREMENT_ANALYSIS.md`.
3. **User:** Approves or requests changes to the plan.
4. **AI:** Implements code based on `IMPLEMENTATION.md`.
5. **AI:** Reviews code based on `REVIEW.md` and provides the final output.