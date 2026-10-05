#!/usr/bin/env bash
#
# Claude Code PreToolUse hook. Enforces .frappe-agent/policy.json, config.json and the rules
# in workflow/GIT_WORKFLOW.md and workflow/PERMISSIONS_AND_PRODUCTION.md:
#   * blocks forbidden git commands (push to main/master, force-push,
#     --no-verify, reset --hard, clean, branch -D, --ours/--theirs)
#   * blocks any command that targets a production site or host
#   * blocks reading/editing protected files (.env, site_config.json, keys)
#   * blocks commands matching config "blocked_commands" (destructive SQL, ...)
#   * asks the user first for commands matching config "ask_commands"
# Exit code 2 blocks the call and shows the message to the agent.
#
# Also understands the Cursor (beforeShellExecution/beforeReadFile) and Copilot
# (preToolUse) hook payloads. Installed only with `install.sh --with-*-hooks`. Fails open: if the input
# or the config cannot be parsed, the call is allowed. This is a safety net,
# not a security boundary (e.g. `bash -c "..."` can evade it).

command -v python3 >/dev/null 2>&1 || exit 0

# The script comes from the heredoc, so hand the hook's JSON input and the
# config path over via the environment instead of stdin.
HOOK_INPUT="$(cat)" \
FA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)" \
python3 - <<'PY'
import fnmatch, json, os, re, shlex, subprocess, sys

try:
    data = json.loads(os.environ.get("HOOK_INPUT", ""))
except Exception:
    sys.exit(0)

# policy.json holds the patterns; config.json holds the workflow settings and
# may also override any key (older installs kept the patterns in config.json).
cfg = {}
for name in ("policy.json", "config.json"):
    try:
        cfg.update(json.load(open(os.path.join(os.environ["FA_DIR"], name))))
    except Exception:
        pass

# Normalize the payloads of Claude Code / VS Code, Cursor and Copilot hooks.
dialect = "claude"
tool = data.get("tool_name") or ""
ti = data.get("tool_input") or {}
if not tool:
    if "toolName" in data:  # Copilot preToolUse
        dialect = "copilot"
        name = str(data.get("toolName") or "").lower()
        args = data.get("toolArgs") or {}
        if isinstance(args, str):
            try:
                args = json.loads(args)
            except Exception:
                args = {"command": args}
        if not isinstance(args, dict):
            args = {}
        path = args.get("path") or args.get("file_path") or args.get("filePath") or ""
        if name in ("bash", "shell", "powershell", "terminal", "run_in_terminal"):
            tool, ti = "Bash", {"command": args.get("command") or args.get("cmd") or ""}
        elif name in ("view", "read", "read_file", "readfile"):
            tool, ti = "Read", {"file_path": path}
        elif name in ("edit", "create", "write", "str_replace_editor", "apply_patch"):
            tool, ti = "Edit", {"file_path": path}
    elif "command" in data:  # Cursor beforeShellExecution
        dialect, tool, ti = "cursor", "Bash", {"command": data.get("command") or ""}
    elif "file_path" in data or "path" in data:  # Cursor beforeReadFile
        dialect, tool, ti = "cursor", "Read", {"file_path": data.get("file_path") or data.get("path") or ""}
cwd = data.get("cwd") or os.getcwd()

DOC = "See .frappe-agent/workflow/GIT_WORKFLOW.md and .frappe-agent/workflow/PERMISSIONS_AND_PRODUCTION.md."


def decision(kind, reason):
    """Print the allow/ask/deny decision in the calling agent's dialect."""
    msg = "frappe-agent policy: " + reason
    if dialect == "cursor":
        out = {"permission": kind, "user_message": msg, "agent_message": msg}
    elif dialect == "copilot":
        out = {"permissionDecision": kind, "permissionDecisionReason": msg}
    else:
        out = {"hookSpecificOutput": {"hookEventName": "PreToolUse",
                                      "permissionDecision": kind,
                                      "permissionDecisionReason": msg}}
    print(json.dumps(out))


def block(reason):
    if dialect != "claude":
        decision("deny", reason)
    sys.stderr.write(
        "Blocked by .frappe-agent guard: %s\n%s Stop and tell the user; do not retry or "
        "work around it.\n" % (reason, DOC)
    )
    sys.exit(2)


def ask(reason):
    decision("ask", "(ask-first action) " + reason)
    sys.exit(0)


# --- protected files --------------------------------------------------------
protected = cfg.get("protected_files") or []
TEMPLATE_SUFFIXES = (".example", ".sample", ".template", ".dist")


def is_protected(path):
    name = os.path.basename(str(path).strip().strip("'\""))
    if not name or name.endswith(TEMPLATE_SUFFIXES):
        return False
    return any(fnmatch.fnmatch(name, pat) for pat in protected)


FILE_TOOLS = ("Read", "Edit", "Write", "MultiEdit", "NotebookEdit")
if tool in FILE_TOOLS:
    p = ti.get("file_path") or ti.get("notebook_path") or ""
    if is_protected(p):
        block("'%s' is a protected file (secrets/credentials); it must not enter the agent's context" % p)
    sys.exit(0)
if tool in ("Grep", "Glob"):
    for key in ("path", "glob", "pattern"):
        v = ti.get(key) or ""
        if tool == "Glob" and key == "pattern" and is_protected(v):
            block("searching for protected files (%s)" % v)
        if key in ("path", "glob") and is_protected(v):
            block("'%s' is a protected file" % v)
    sys.exit(0)
if tool != "Bash":
    sys.exit(0)

cmd = ti.get("command") or ""

# --- production --------------------------------------------------------------
prod = (cfg.get("environments") or {}).get("production") or {}
prod_ids = [s.lower() for s in (prod.get("sites") or []) + (prod.get("hosts") or []) if s]
words = [re.escape(w) for w in (prod.get("name_words") or []) if w]
word_re = re.compile(r"(^|[._\-/@])(%s)([._\-:/]|$)" % "|".join(words), re.I) if words else None
REMOTE = {"ssh", "scp", "sftp", "rsync", "kubectl", "docker", "mosh"}


def tokens(part):
    try:
        return shlex.split(part)
    except ValueError:
        return part.split()


def check_production(part, toks):
    low = part.lower()
    for ident in prod_ids:
        if ident in low:
            block("'%s' is configured as production; the agent must be read-only there and "
                  "may only write a deployment plan" % ident)
    sites = re.findall(r"--site[=\s]+(\S+)", part)
    cmdname = os.path.basename(toks[0]) if toks else ""
    candidates = [s.strip("'\"") for s in sites]
    if cmdname in REMOTE:
        candidates += [t for t in toks[1:] if not t.startswith("-")]
    if word_re:
        for c in candidates:
            if word_re.search(c):
                block("'%s' looks like a production target; the agent must be read-only in "
                      "production. Write a deployment plan instead (templates/DEPLOYMENT_PLAN.md)" % c)


# --- git ---------------------------------------------------------------------
def check_git(part):
    if re.search(r"(^|\s)--no-verify(\s|$)", part):
        block("--no-verify bypasses the project's pre-commit hooks")
    if re.search(r"\bcommit\b", part) and re.search(r"\s-[a-zA-Z]*n[a-zA-Z]*(\s|$)", part):
        block("'git commit -n' bypasses the project's pre-commit hooks")
    if re.search(r"\bpush\b", part):
        if re.search(r"\s(--force(-with-lease)?(=\S+)?|-f)(\s|$)", part) or re.search(r"\s\+\S", part):
            block("force-push rewrites remote history")
        if re.search(r"(^|[\s:/])(main|master)(\s|$)", part):
            block("direct push to main/master; use a dedicated branch and a Pull Request")
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


# --- blocked patterns on the whole command (catches SQL inside quotes) -------
for pat in cfg.get("blocked_commands") or []:
    try:
        m = re.search(pat, cmd, re.I)
    except re.error:
        continue
    if m:
        block("'%s' is a prohibited action; it requires a human to run it" % m.group(0).strip())

SAFE_FOR_PROTECTED = {"ls", "test", "[", "stat"}
for part in re.split(r"&&|\|\||[;|\n]", cmd):
    part = part.strip()
    if not part:
        continue
    toks = tokens(part)
    check_production(part, toks)
    if re.match(r"(?:\S+=\S+\s+)*git\b", part):
        check_git(part)
    first = os.path.basename(toks[0]) if toks else ""
    if first not in SAFE_FOR_PROTECTED:
        for t in toks[1:]:
            if is_protected(t):
                block("'%s' is a protected file (secrets/credentials); it must not enter the agent's context" % t)

for pat in cfg.get("ask_commands") or []:
    try:
        m = re.search(pat, cmd, re.I)
    except re.error:
        continue
    if m:
        ask("'%s' needs your approval" % m.group(0).strip())

sys.exit(0)
PY
