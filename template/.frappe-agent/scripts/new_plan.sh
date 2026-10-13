#!/usr/bin/env bash
#
# Create a new plan record (PLAN-YYYY-NNN.md, state DRAFT) from
# templates/PLAN_RECORD.md, in the same folder as the task records. A plan is
# a large piece of work (2+ features, more than one DocType or app, or any
# HIGH change) split into phases; each phase later runs as one task.
#
# Usage:
#   .frappe-agent/scripts/new_plan.sh "<plan title>"
# Prints the path of the new file.

set -euo pipefail

FA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=_lib.sh
. "$FA_DIR/scripts/_lib.sh"

TITLE="${1:?usage: new_plan.sh \"<plan title>\"}"

TEMPLATE="$FA_DIR/templates/PLAN_RECORD.md"
[ -f "$TEMPLATE" ] || { echo "Missing $TEMPLATE" >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "python3 is required." >&2; exit 1; }

HIST="$(history_dir)"
mkdir -p "$HIST"

year="$(date +%Y)"
last="$(find "$HIST" -maxdepth 1 -name "PLAN-${year}-*.md" 2>/dev/null \
  | sed -E "s/.*PLAN-${year}-([0-9]+)\.md/\1/" | sort -n | tail -1)"
next=$(( 10#${last:-0} + 1 ))
id="$(printf 'PLAN-%s-%03d' "$year" "$next")"
out="$HIST/$id.md"

developer="$(git config user.name 2>/dev/null || true)"
branch="$(git symbolic-ref --short HEAD 2>/dev/null || true)"
now="$(date '+%Y-%m-%d %H:%M')"

esc() { printf '%s' "$1" | sed -e 's/[\\&|]/\\&/g'; }

sed -e "s|{{PLAN_ID}}|$id|g" \
    -e "s|{{DATE}}|$now|g" \
    -e "s|{{DEVELOPER}}|$(esc "${developer:-unknown}")|g" \
    -e "s|{{TITLE}}|$(esc "$TITLE")|g" \
    -e "s|{{BRANCH}}|$(esc "${branch:-}")|g" \
    "$TEMPLATE" \
  | awk -v row="| $now | DRAFT | plan created |" '
      /<!-- STATE-LOG-END -->/ { print row }
      { print }
    ' > "$out"

echo "$out"
