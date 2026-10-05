#!/usr/bin/env bash
#
# Claude Code PreToolUse hook (matcher: Bash). Blocks Git commands that
# GIT_WORKFLOW.md forbids without explicit user authorization. Exit code 2
# blocks the command and shows the message to the agent.
#
# Installed only with `install.sh --with-claude-hooks`. Fails open: if the
# input cannot be parsed, the command is allowed.

command -v python3 >/dev/null 2>&1 || exit 0

# The script comes from the heredoc, so hand the hook's JSON input over via
# the environment instead of stdin.
HOOK_INPUT="$(cat)" python3 - <<'PY'
import json, os, re, subprocess, sys

try:
    data = json.loads(os.environ.get("HOOK_INPUT", ""))
except Exception:
    sys.exit(0)

cmd = (data.get("tool_input") or {}).get("command") or ""
cwd = data.get("cwd") or "."

def block(reason):
    sys.stderr.write(
        "Blocked by .frappe-agent guard: %s\n"
        "See .frappe-agent/GIT_WORKFLOW.md. Stop and ask the user for explicit "
        "authorization instead of retrying.\n" % reason
    )
    sys.exit(2)

# Look at each simple command separately (split on ; && || | and newlines).
for part in re.split(r"&&|\|\||[;|\n]", cmd):
    part = part.strip()
    if not re.match(r"(?:\S+=\S+\s+)*git\b", part):
        continue

    if re.search(r"(^|\s)--no-verify(\s|$)", part):
        block("--no-verify bypasses the project's pre-commit hooks")
    if re.search(r"\bcommit\b", part) and re.search(r"\s-[a-zA-Z]*n[a-zA-Z]*(\s|$)", part):
        block("'git commit -n' bypasses the project's pre-commit hooks")
    if re.search(r"\bpush\b", part):
        if re.search(r"\s(--force(-with-lease)?(=\S+)?|-f)(\s|$)", part) or re.search(r"\s\+\S", part):
            block("force-push rewrites remote history")
        if re.search(r"(^|[\s:/])(main|master)(\s|$)", part):
            block("direct push to main/master; use a dedicated branch and a Pull Request")
        # Bare `git push` while a protected branch is checked out.
        args = [a for a in part.split() if not a.startswith("-")]
        if len(args) <= 3:
            try:
                branch = subprocess.run(
                    ["git", "-C", cwd, "rev-parse", "--abbrev-ref", "HEAD"],
                    capture_output=True, text=True, timeout=5).stdout.strip()
            except Exception:
                branch = ""
            if branch in ("main", "master"):
                block("'git push' while on %s; create a dedicated branch first" % branch)
    if re.search(r"\breset\b.*\s--hard\b", part):
        block("'git reset --hard' can permanently discard work")
    if re.search(r"\bclean\b\s+-[a-zA-Z]*[fd]", part):
        block("'git clean' permanently deletes untracked files")
    if re.search(r"\bbranch\b.*\s-(D|DA)(\s|$)", part):
        block("'git branch -D' force-deletes a branch")
    if re.search(r"\bcheckout\b.*--(ours|theirs)\b", part):
        block("do not resolve conflicts automatically with --ours/--theirs")

sys.exit(0)
PY
