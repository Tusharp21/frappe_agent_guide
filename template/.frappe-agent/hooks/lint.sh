#!/usr/bin/env bash
#
# Claude Code PostToolUse hook (matcher: Edit|Write|MultiEdit). Runs
# `ruff check` on an edited Python file and reports findings back to the
# agent (exit code 2) so it fixes them. Uses the app's own ruff config
# (pyproject.toml / ruff.toml) if there is one. Does nothing if ruff or
# python3 is missing, or the file is not Python.

command -v python3 >/dev/null 2>&1 || exit 0
command -v ruff >/dev/null 2>&1 || exit 0

file="$(python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
    print((d.get("tool_input") or {}).get("file_path") or "")
except Exception:
    pass
')"

case "$file" in
  *.py) ;;
  *) exit 0 ;;
esac
[ -f "$file" ] || exit 0

if ! out="$(ruff check "$file" 2>&1)"; then
  printf 'ruff found issues in %s. Fix them (do not bypass the linter):\n%s\n' "$file" "$out" >&2
  exit 2
fi
exit 0
