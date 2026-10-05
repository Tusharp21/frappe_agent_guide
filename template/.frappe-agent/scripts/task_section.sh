#!/usr/bin/env bash
#
# Append one section of the task record format to a task record and print it,
# so the format is read only when you reach that step.
#
# Usage:
#   .frappe-agent/scripts/task_section.sh <TASK-ID|path> <name>
#
# Names: understanding clarification proposal decision execution testing
#        review summary audit rollback lessons
# A section that is already in the record is not added twice (except
# "clarification", which can repeat for each question).

set -euo pipefail

FA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=_lib.sh
. "$FA_DIR/scripts/_lib.sh"

[ $# -eq 2 ] || { echo "usage: task_section.sh <TASK-ID|path> <name>" >&2; exit 1; }
REF="$1"; NAME="$(printf '%s' "$2" | tr '[:upper:]' '[:lower:]')"

if [ -f "$REF" ]; then FILE="$REF"; else FILE="$(history_dir)/$REF.md"; fi
[ -f "$FILE" ] || { echo "Task record not found: $REF" >&2; exit 1; }

SECTIONS="$FA_DIR/templates/TASK_SECTIONS.md"
block="$(awk -v n="$NAME" '
  $0 == "<!-- SECTION:" n " -->" { on = 1; next }
  /^<!-- \/SECTION -->/ { on = 0 }
  on { print }
' "$SECTIONS")"
[ -n "$block" ] || { echo "Unknown section: $NAME (see the list in this script)" >&2; exit 1; }

heading="$(printf '%s\n' "$block" | head -1)"
if [ "$NAME" != "clarification" ] && grep -qxF "$heading" "$FILE"; then
  echo "Section already in the record: $heading" >&2
  exit 0
fi

{ printf '\n'; printf '%s\n' "$block"; } >> "$FILE"
printf '%s\n' "$block"
