# Guide

Documentation for the people who install and use this template. It is not installed into your project; the AI agent never reads it. The agent's own files are under `template/.frappe-agent/`.

## What do you want to do?

| I want to... | Read |
| ------------ | ---- |
| Install, update or remove the template | [01 Install, update, uninstall](./01-install-update-uninstall.md) |
| Change settings (approval mode, production sites, protected files) | [02 Configuration](./02-configuration.md) |
| Understand how a task runs and what I will be asked | [03 Daily use](./03-daily-use.md) |
| Know what the agent can and cannot do, and turn on enforcement | [04 Safety and enforcement](./04-safety-and-enforcement.md) |
| Find old work, share history, read the audit record | [05 History and audit](./05-history-and-audit.md) |

## What gets installed

Two items in your project (normally the **bench root**, the folder with `apps/` and `sites/`):

```text
your-bench/
├── AGENTS.md              # short entry file: hard rules, process, pointers
└── .frappe-agent/
    ├── workflow/          # how work is done: TASK.md, BUG, CODE_REVIEW, DEPLOYMENT, permissions, Git rules
    ├── knowledge/         # Frappe knowledge base, INDEX.md routes to the right part
    ├── templates/         # task record, deployment plan
    ├── scripts/           # new_task, task_state, search_history, inspect_app, doc_sections, install_git_hooks
    ├── hooks/  adapters/  # enforcement (only used with the --with-*-hooks options)
    ├── project_knowledge/ # your app map and decisions (kept on update)
    ├── tasks/             # one record per task (local, git-ignored, kept on update)
    ├── audit/             # command log (local, git-ignored, kept on update)
    └── config.json  policy.json  VERSION    # your settings (kept on update)
```

Nothing else in your project is touched. If you already have an `AGENTS.md`, the template is added as a clearly marked block and your content is left alone.
