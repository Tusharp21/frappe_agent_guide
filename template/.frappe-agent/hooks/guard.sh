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
#   * process gates (policy.json "process_gates"): app code under apps/ may be
#     edited only while the active task (tasks/.active) is LOCKED or
#     IN_PROGRESS, and only inside the card's "Allowed paths" when set
# Exit code 2 blocks the call and shows the message to the agent.
#
# Also understands the Cursor (beforeShellExecution/beforeReadFile) and Copilot
# (preToolUse) hook payloads. Installed only with `install.sh --with-*-hooks`.
# Without python3 every call is blocked (fail closed), since the policy cannot
# be evaluated. If the hook input or the config cannot be parsed, the call is
# allowed. This is a safety net, not a security boundary (e.g. `bash -c "..."`
# can evade it, and the process gates only see the editor tools).

if ! command -v python3 >/dev/null 2>&1; then
  echo "Blocked by .frappe-agent guard: python3 is not available, so the policy cannot be checked. Install python3 or remove the hook." >&2
  exit 2
fi

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


# --- process gates -----------------------------------------------------------
GATES = {"enabled": True, "no_active_task": "ask", "draft_edit": "block", "out_of_scope": "ask",
         "harness_files": "block"}
GATES.update(cfg.get("process_gates") or {})
WRITE_TOOLS = ("Edit", "Write", "MultiEdit", "NotebookEdit")


def card_value(text, name):
    on = False
    for line in text.splitlines():
        if "<!-- CARD:START -->" in line:
            on = True
            continue
        if "<!-- CARD:END -->" in line:
            break
        if on and line.startswith("- **%s:**" % name):
            val = line.split(":**", 1)[1]
            return re.sub(r"<!--.*?-->", "", val).strip()
    return ""


def history_dir():
    fa = os.environ["FA_DIR"]
    p = (cfg.get("history") or {}).get("path") or "tasks"
    p = os.path.expanduser(p)
    return os.path.normpath(p if os.path.isabs(p) else os.path.join(fa, p))


def in_scope(rel, allowed):
    for entry in [a.strip() for a in allowed.split(",") if a.strip()]:
        entry = entry.lstrip("./")
        if fnmatch.fnmatch(rel, entry):
            return True
        if entry.endswith("/") and rel.startswith(entry):
            return True
        if rel == entry.rstrip("/"):
            return True
    return False


def under(path, base):
    a = os.path.realpath(path if os.path.isabs(path) else os.path.join(cwd, path))
    b = os.path.realpath(base)
    return a == b or a.startswith(b + os.sep)


STATE_MSG = ("task state changes only through .frappe-agent/scripts/task_state.sh (it records "
             "the user's words); do not edit the record's State line or tasks/.active directly")


def check_record_integrity(path, ti):
    """The agent must not lock or complete its own task by editing the record."""
    if not GATES.get("enabled", True):
        return
    hist = history_dir()
    if not under(path, hist):
        return
    name = os.path.basename(path)
    if name == ".active":
        block("tasks/.active is maintained by new_task.sh and task_state.sh; " + STATE_MSG)
    if not name.endswith(".md"):
        return
    texts = [ti.get("old_string") or "", ti.get("new_string") or ""]
    for e in ti.get("edits") or []:
        if isinstance(e, dict):
            texts += [e.get("old_string") or "", e.get("new_string") or ""]
    if any("**State:**" in t for t in texts):
        block("this edit touches the State line of a task record; " + STATE_MSG)
    SCOPE_MSG = ("the task's Allowed paths are part of what the user approved; once the task is past "
                 "DRAFT a change needs a new decision: task_state.sh <id> DRAFT, then lock again")
    target = path if os.path.isabs(path) else os.path.join(cwd, path)
    try:
        existing = open(target).read()
    except Exception:
        existing = ""
    if existing and card_value(existing, "State") not in ("", "DRAFT"):
        if any("**Allowed paths:**" in t for t in texts):
            block("this edit touches the Allowed paths of a task that is no longer DRAFT; " + SCOPE_MSG)
        if "content" in ti and card_value(ti["content"], "Allowed paths") != card_value(existing, "Allowed paths"):
            block("this write changes the Allowed paths of a task that is no longer DRAFT; " + SCOPE_MSG)
    if "content" in ti:
        target = path if os.path.isabs(path) else os.path.join(cwd, path)
        try:
            old = card_value(open(target).read(), "State")
        except Exception:
            old = ""
            if card_value(ti["content"], "State") not in ("", "DRAFT"):
                block("a new task record must start as DRAFT; " + STATE_MSG)
        if card_value(ti["content"], "State") != old and old:
            block("this write changes the State of a task record; " + STATE_MSG)


# Files that define the agent's own rules. The agent may not edit them (a human
# does), or it could switch the gates off. tasks/ and project_knowledge/ are
# the agent's working area and stay open. "harness_paths" in policy.json
# replaces the default list; paths are relative to the bench root.
def harness_paths():
    fa = os.path.basename(os.path.realpath(os.environ["FA_DIR"]))
    default = [fa + "/", "AGENTS.md", ".claude/settings.json", ".claude/settings.local.json",
               ".cursor/hooks.json", ".github/hooks/"]
    return cfg.get("harness_paths") or default


def harness_open():
    fa = os.path.basename(os.path.realpath(os.environ["FA_DIR"]))
    return [fa + "/project_knowledge/", fa + "/audit/"]


def is_harness(path):
    root = os.path.dirname(os.path.realpath(os.environ["FA_DIR"]))
    target = path if os.path.isabs(path) else os.path.join(cwd, path)
    rel = os.path.relpath(os.path.realpath(target), root)
    if rel.startswith(".."):
        return False
    if under(path, history_dir()):
        return False
    if any(rel.startswith(o) for o in harness_open()):
        return False
    return any(rel == h.rstrip("/") or (h.endswith("/") and rel.startswith(h)) or rel == h
               for h in harness_paths())


HARNESS_MSG = ("this file defines the agent's own rules and is changed by a human, not the agent. "
               "Tell the user what you need changed")

VERBS = {"sed", "tee", "mv", "cp", "rm", "truncate", "install", "dd", "ln", "awk", "gawk"}
INTERPRETERS = ("python", "perl", "ruby", "node")
FA_SCRIPTS = {"new_task.sh", "task_state.sh", "search_history.sh", "doc_sections.sh",
              "inspect_app.sh", "install_git_hooks.sh"}


def check_record_bash(part, toks):
    """Best effort: shell writes into the task records or tasks/.active."""
    if not GATES.get("enabled", True) or not toks:
        return
    hist = history_dir()
    runner = os.path.basename(toks[0])
    if runner in ("bash", "sh") and len(toks) > 1:
        runner = os.path.basename(toks[1])
    if runner in FA_SCRIPTS:
        return
    clean = lambda t: t.strip("'\"")
    targets = []
    for i, t in enumerate(toks):
        if t in (">", ">>") and i + 1 < len(toks):
            targets.append(clean(toks[i + 1]))
        elif t.startswith(">") and not t.startswith(">&") and len(t) > 1:
            targets.append(clean(t.lstrip(">")))
    first = os.path.basename(toks[0])
    if first in VERBS:
        targets += [clean(t) for t in toks[1:] if not t.startswith("-")]
    if any(t and under(t, hist) for t in targets):
        block("shell command writes into the task records; " + STATE_MSG)
    if GATES.get("harness_files", "block") != "allow":
        if any(t and is_harness(t) for t in targets):
            apply(GATES.get("harness_files", "block"), "shell command writes to a harness file; " + HARNESS_MSG)
    if first.startswith(INTERPRETERS):
        frag = "/" + os.path.basename(hist) + "/"
        if frag in part or ".active" in part:
            block("script touches the task records; " + STATE_MSG)
        if GATES.get("harness_files", "block") != "allow":
            fa = os.path.basename(os.path.realpath(os.environ["FA_DIR"]))
            names = [h for h in harness_paths() if h != fa + "/"] + [fa + "/policy.json", fa + "/config.json", fa + "/hooks", fa + "/scripts", fa + "/workflow"]
            if any(n.rstrip("/") in part for n in names):
                apply(GATES.get("harness_files", "block"), "script touches a harness file; " + HARNESS_MSG)


def apply(action, reason):
    if action == "block":
        block(reason)
    elif action == "ask":
        ask(reason)


def check_process_gate(path):
    if not GATES.get("enabled", True):
        return
    if (cfg.get("history") or {}).get("enabled") is False:
        return
    fa = os.path.realpath(os.environ["FA_DIR"])
    root = os.path.dirname(fa)
    target = path if os.path.isabs(path) else os.path.join(cwd, path)
    rel = os.path.relpath(os.path.realpath(target), root)
    if rel.startswith(".."):
        return
    gated = cfg.get("gated_paths") or ["apps"]
    if not any(rel == g or rel.startswith(g.rstrip("/") + "/") for g in gated):
        return

    hist = history_dir()
    try:
        task_id = open(os.path.join(hist, ".active")).read().strip()
        record = open(os.path.join(hist, task_id + ".md")).read()
    except Exception:
        apply(GATES.get("no_active_task", "ask"),
              "no active task: editing app code needs a task. Create one with "
              ".frappe-agent/scripts/new_task.sh, or ask the user if this is a LOW change")
        return

    state = card_value(record, "State")
    risk = card_value(record, "Risk")
    if state not in ("LOCKED", "IN_PROGRESS") and not (risk == "LOW" and state == "DRAFT"):
        apply(GATES.get("draft_edit", "block"),
              "%s is %s, so its solution is not locked. Get the user's decision, then run "
              "task_state.sh %s LOCKED --note \"<their words>\" before editing app code"
              % (task_id, state or "in an unknown state", task_id))
        return

    allowed = card_value(record, "Allowed paths")
    if allowed and not in_scope(rel, allowed):
        apply(GATES.get("out_of_scope", "ask"),
              "%s is outside the Allowed paths of %s (%s). A scope change needs a new user "
              "decision: move the task back to DRAFT, or ask the user to approve this file"
              % (rel, task_id, allowed))

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
    if tool in WRITE_TOOLS and p:
        check_record_integrity(p, ti)
        if GATES.get("enabled", True) and is_harness(p):
            apply(GATES.get("harness_files", "block"), "'%s': %s" % (p, HARNESS_MSG))
        check_process_gate(p)
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
    check_record_bash(part, toks)
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
