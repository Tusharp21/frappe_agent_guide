# Requirement Analysis Workflow

Before writing any code, the AI must perform a detailed analysis of the user's request.

## 1. Understand the Request
* What is the exact business requirement?
* Who is the target user/role?

## 2. System Inspection
* **DocTypes:** Identify all standard and custom DocTypes involved.
* **Files:** Identify which controllers, JS files, or HTML templates are relevant.
* **Existing Patterns:** Search the codebase to see how similar problems were solved previously. Do not invent a new pattern if a standard one exists.

## 3. Data Flow & Business Rules
* Map out how data will enter, move through, and exit the system.
* Note all validation rules, status changes, and constraints.

## 4. Pre-Checks
* **Security Check:** What permissions/roles are required? Are there any data leak risks?
* **Performance Check:** Will this feature involve large datasets? Do we need background jobs?

## 5. Proposed Solution
Create a structured proposal:
* Summary of approach.
* List of files expected to change or be created.
* Potential risks or impacts on existing features.

**STOP HERE. Present the plan to the user and request APPROVAL before proceeding to implementation.**