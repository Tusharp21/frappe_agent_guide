# AI Agent Guidelines (AGENTS.md)

## 1. Purpose
This document defines the rules, behavior, and workflow for the AI Agent assisting with this Frappe project. The AI must strictly follow these instructions to ensure high-quality, secure, and standardized code.

## 2. Getting Started & Process Flow
Whenever a new task or query is assigned, the AI must follow this flow:
1. **Read & Understand:** Read the user request carefully.
2. **Consult Knowledge:** Refer to `FRAPPE_DEVELOPMENT.md` for standard practices.
3. **Analyze:** Follow `workflow/REQUIREMENT_ANALYSIS.md` to analyze the system and existing code.
4. **Plan & Seek Approval:** Present a step-by-step implementation plan. **Wait for explicit approval from the user.**
5. **Implement:** Once approved, follow `workflow/IMPLEMENTATION.md`.
6. **Review:** After coding, verify changes using `workflow/REVIEW.md`.

## 3. Strict Rules of Engagement
* **No Code Without Approval:** Never generate the final code before the user approves the proposed plan and architecture.
* **Inspect Before You Act:** Always inspect existing code, relevant DocTypes, and established patterns in the project before suggesting new implementations.
* **Stay in Scope:** Do not modify files or add features outside the specific scope of the requested task.
* **Do Not Guess:** If requirements are ambiguous, ask clarifying questions instead of making assumptions.

## 4. Coding & Security Rules
* Follow Frappe standard framework guidelines.
* Never hardcode sensitive information (secrets, API keys, passwords).
* Always apply role-based permission checks (`frappe.has_permission`).
* Write clean, modular, and well-commented code.

## 5. Output Format
* Keep responses concise and to the point.
* Use Markdown for formatting.
* Provide exact file paths when proposing code changes.
* Format file changes clearly: `[File Path] -> [Code Block]`

## 6. Git Execution Rules
* Strictly follow conventions in `GIT_WORKFLOW.md`.
* Never push directly to the main/master branch, under any circumstances — always work on a dedicated branch and submit a Pull Request (see `GIT_WORKFLOW.md`).
* Halt operation immediately on git conflicts or authentication issues and prompt the user.