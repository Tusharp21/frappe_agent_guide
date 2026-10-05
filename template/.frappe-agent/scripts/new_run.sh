#!/usr/bin/env bash
#
# Create the next audit record (RUN-YYYY-NNN.md) from templates/RUN_REPORT.md.
# Records are local: .frappe-agent/audit/ is git-ignored and kept on update.
#
# Usage:
#   .frappe-agent/scripts/new_run.sh "<task title>" [trivial|standard|major]
# Prints the path of the new file; the agent then fills in the rest.

set -euo pipefail

FA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE="$FA_DIR/templates/RUN_REPORT.md"
AUDIT_DIR="$FA_DIR/audit"
TASK="${1:?usage: new_run.sh \"<task title>\" [trivial|standard|major]}"
TIER="${2:-standard}"

[ -f "$TEMPLATE" ] || { echo "Missing $TEMPLATE" >&2; exit 1; }
mkdir -p "$AUDIT_DIR"

year="$(date +%Y)"
last="$(find "$AUDIT_DIR" -maxdepth 1 -name "RUN-${year}-*.md" 2>/dev/null \
  | sed -E "s/.*RUN-${year}-([0-9]+)\.md/\1/" | sort -n | tail -1)"
next=$(( 10#${last:-0} + 1 ))
run_id="$(printf 'RUN-%s-%03d' "$year" "$next")"
out="$AUDIT_DIR/$run_id.md"

developer="$(git config user.name 2>/dev/null || true)"
branch="$(git symbolic-ref --short HEAD 2>/dev/null || true)"

# Escape for sed replacement: backslash, ampersand and the delimiter.
esc() { printf '%s' "$1" | sed -e 's/[\\&|]/\\&/g'; }

sed -e "s|{{RUN_ID}}|$(esc "$run_id")|g" \
    -e "s|{{DATE}}|$(date '+%Y-%m-%d %H:%M')|g" \
    -e "s|{{DEVELOPER}}|$(esc "${developer:-unknown}")|g" \
    -e "s|{{TASK}}|$(esc "$TASK")|g" \
    -e "s|{{TIER}}|$(esc "$TIER")|g" \
    -e "s|{{BRANCH}}|$(esc "${branch:-}")|g" \
    "$TEMPLATE" > "$out"

echo "$out"
