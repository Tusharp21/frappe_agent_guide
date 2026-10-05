#!/usr/bin/env bash
#
# Claude Code PostToolUse hook (matcher: Bash). Appends each executed command
# to .frappe-agent/audit/commands.log (local, git-ignored) when
# config.json has audit.log_commands = true. Obvious secrets in the command
# line are masked. Never blocks anything.

command -v python3 >/dev/null 2>&1 || exit 0

HOOK_INPUT="$(cat)" \
FA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)" \
python3 - <<'PY'
import datetime, json, os, re, sys

try:
    data = json.loads(os.environ.get("HOOK_INPUT", ""))
    base = os.environ["FA_DIR"]
    cfg = json.load(open(os.path.join(base, "config.json")))
except Exception:
    sys.exit(0)

audit = cfg.get("audit") or {}
if not (audit.get("enabled") and audit.get("log_commands")):
    sys.exit(0)

cmd = (data.get("tool_input") or {}).get("command") or data.get("command") or ""
if not cmd and isinstance(data.get("toolArgs"), dict):  # Copilot postToolUse
    cmd = data["toolArgs"].get("command") or ""
if not cmd:
    sys.exit(0)
cmd = re.sub(r"(?i)((?:pass(?:word|wd)?|token|secret|api[_-]?key)(?:=|\s+))\S+", r"\1***", cmd)
cmd = " ".join(cmd.split())

resp = data.get("tool_response")
status = ""
if isinstance(resp, dict):
    for k in ("exit_code", "exitCode", "returncode"):
        if k in resp:
            status = str(resp[k])
            break

try:
    os.makedirs(os.path.join(base, "audit"), exist_ok=True)
    with open(os.path.join(base, "audit", "commands.log"), "a") as fh:
        fh.write("%s\t%s\t%s\t%s\n" % (
            datetime.datetime.now().isoformat(timespec="seconds"),
            data.get("cwd") or os.getcwd(),
            status or "-",
            cmd[:500]))
except Exception:
    pass
sys.exit(0)
PY
