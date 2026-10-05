#!/usr/bin/env bash
#
# Create a new task record (TASK-YYYY-NNN.md, state DRAFT) from
# templates/TASK_RECORD.md. Records are local and kept on update; where they
# live is set by "history.path" in config.json (default: .frappe-agent/tasks/).
#
# Usage:
#   .frappe-agent/scripts/new_task.sh "<task title>" [low|medium|high]
# Prints the path of the new file.

set -euo pipefail

FA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=_lib.sh
. "$FA_DIR/scripts/_lib.sh"

TASK="${1:?usage: new_task.sh \"<task title>\" [low|medium|high]}"
RISK="$(printf '%s' "${2:-medium}" | tr '[:lower:]' '[:upper:]')"
case "$RISK" in LOW|MEDIUM|HIGH) ;; *) echo "Risk must be low, medium or high." >&2; exit 1 ;; esac

TEMPLATE="$FA_DIR/templates/TASK_RECORD.md"
[ -f "$TEMPLATE" ] || { echo "Missing $TEMPLATE" >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "python3 is required." >&2; exit 1; }

HIST="$(history_dir)"
mkdir -p "$HIST"

year="$(date +%Y)"
last="$(find "$HIST" -maxdepth 1 -name "TASK-${year}-*.md" 2>/dev/null \
  | sed -E "s/.*TASK-${year}-([0-9]+)\.md/\1/" | sort -n | tail -1)"
next=$(( 10#${last:-0} + 1 ))
id="$(printf 'TASK-%s-%03d' "$year" "$next")"
out="$HIST/$id.md"

developer="$(git config user.name 2>/dev/null || true)"
branch="$(git symbolic-ref --short HEAD 2>/dev/null || true)"
now="$(date '+%Y-%m-%d %H:%M')"

# Escape for sed replacement: backslash, ampersand and the delimiter.
esc() { printf '%s' "$1" | sed -e 's/[\\&|]/\\&/g'; }

sed -e "s|{{TASK_ID}}|$id|g" \
    -e "s|{{DATE}}|$now|g" \
    -e "s|{{DEVELOPER}}|$(esc "${developer:-unknown}")|g" \
    -e "s|{{TASK}}|$(esc "$TASK")|g" \
    -e "s|{{RISK}}|$RISK|g" \
    -e "s|{{BRANCH}}|$(esc "${branch:-}")|g" \
    "$TEMPLATE" \
  | awk -v row="| $now | DRAFT | task created |" '
      /<!-- STATE-LOG-END -->/ { print row }
      { print }
    ' > "$out"

echo "$out"
