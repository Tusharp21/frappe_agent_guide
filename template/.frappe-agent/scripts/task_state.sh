#!/usr/bin/env bash
#
# Move a task record to a new state, validating the transition and appending a
# timestamped row to its state log.
#
# Usage:
#   .frappe-agent/scripts/task_state.sh <TASK-ID|path> <STATE> [--note "text"] [--force]
#
# States: DRAFT UNDERSTANDING CLARIFICATION SOLUTION_PROPOSED WAITING_FOR_DECISION
#         LOCKED IN_PROGRESS TESTING REVIEW WAITING_FOR_APPROVAL COMPLETED BLOCKED
#
# A --note is required when moving to LOCKED or to COMPLETED from
# WAITING_FOR_APPROVAL: quote what the user actually said ("Option A",
# "approved"). The agent must never lock or complete a task on its own. LOW-risk
# tasks may skip the decision and approval states. --force allows an
# out-of-order move (it is logged as forced).

set -euo pipefail

FA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=_lib.sh
. "$FA_DIR/scripts/_lib.sh"

[ $# -ge 2 ] || { echo "usage: task_state.sh <TASK-ID|path> <STATE> [--note \"text\"] [--force]" >&2; exit 1; }
REF="$1"; NEW="$(printf '%s' "$2" | tr '[:lower:]' '[:upper:]')"; shift 2
NOTE=""; FORCE=0
while [ $# -gt 0 ]; do
  case "$1" in
    --note)  NOTE="${2:?--note needs text}"; shift 2 ;;
    --force) FORCE=1; shift ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

STATES=" DRAFT UNDERSTANDING CLARIFICATION SOLUTION_PROPOSED WAITING_FOR_DECISION LOCKED IN_PROGRESS TESTING REVIEW WAITING_FOR_APPROVAL COMPLETED BLOCKED "
case "$STATES" in *" $NEW "*) ;; *) echo "Unknown state: $NEW" >&2; exit 1 ;; esac

if [ -f "$REF" ]; then FILE="$REF"; else FILE="$(history_dir)/$REF.md"; fi
[ -f "$FILE" ] || { echo "Task record not found: $REF" >&2; exit 1; }

CUR="$(card_field "$FILE" State)"
RISK="$(card_field "$FILE" Risk)"

allowed() {  # allowed <from> <to> -> 0 if the transition is valid
  local from="$1" to="$2"
  [ "$to" = "BLOCKED" ] && [ "$from" != "COMPLETED" ] && return 0
  case "$from>$to" in
    DRAFT\>UNDERSTANDING|\
    UNDERSTANDING\>CLARIFICATION|UNDERSTANDING\>SOLUTION_PROPOSED|\
    CLARIFICATION\>UNDERSTANDING|CLARIFICATION\>SOLUTION_PROPOSED|\
    SOLUTION_PROPOSED\>WAITING_FOR_DECISION|SOLUTION_PROPOSED\>CLARIFICATION|\
    WAITING_FOR_DECISION\>LOCKED|WAITING_FOR_DECISION\>SOLUTION_PROPOSED|WAITING_FOR_DECISION\>CLARIFICATION|\
    LOCKED\>IN_PROGRESS|\
    IN_PROGRESS\>TESTING|IN_PROGRESS\>WAITING_FOR_DECISION|\
    TESTING\>REVIEW|TESTING\>IN_PROGRESS|\
    REVIEW\>WAITING_FOR_APPROVAL|REVIEW\>IN_PROGRESS|\
    WAITING_FOR_APPROVAL\>COMPLETED|WAITING_FOR_APPROVAL\>IN_PROGRESS|WAITING_FOR_APPROVAL\>WAITING_FOR_DECISION|\
    BLOCKED\>UNDERSTANDING|BLOCKED\>CLARIFICATION|BLOCKED\>SOLUTION_PROPOSED|BLOCKED\>WAITING_FOR_DECISION|BLOCKED\>IN_PROGRESS|BLOCKED\>TESTING|BLOCKED\>REVIEW)
      return 0 ;;
  esac
  if [ "$RISK" = "LOW" ]; then
    case "$from>$to" in
      UNDERSTANDING\>IN_PROGRESS|DRAFT\>IN_PROGRESS|TESTING\>COMPLETED|REVIEW\>COMPLETED|IN_PROGRESS\>COMPLETED) return 0 ;;
    esac
  fi
  return 1
}

FORCED=""
if [ "$CUR" = "$NEW" ]; then
  echo "Task is already in $NEW." >&2; exit 1
fi
if ! allowed "$CUR" "$NEW"; then
  if [ "$FORCE" -ne 1 ]; then
    echo "Invalid transition for a $RISK task: $CUR -> $NEW. Follow workflow/TASK.md, or use --force and say why in --note." >&2
    exit 1
  fi
  FORCED=" (FORCED)"
fi

if [ -z "$FORCED" ]; then
  if [ "$NEW" = "LOCKED" ] && [ -z "$NOTE" ]; then
    echo "Moving to LOCKED needs --note quoting the user's decision." >&2; exit 1
  fi
  if [ "$NEW" = "COMPLETED" ] && [ "$CUR" = "WAITING_FOR_APPROVAL" ] && [ -z "$NOTE" ]; then
    echo "Moving to COMPLETED needs --note quoting the user's approval." >&2; exit 1
  fi
fi

now="$(date '+%Y-%m-%d %H:%M')"
safe_note="$(printf '%s' "${NOTE:-}" | tr '\n|' '  ')"
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

awk -v new="$NEW" -v row="| $now | $NEW$FORCED | $safe_note |" '
  /^- \*\*State:\*\*/ && !done { print "- **State:** " new; done = 1; next }
  /<!-- STATE-LOG-END -->/ { print row }
  { print }
' "$FILE" > "$tmp"
cat "$tmp" > "$FILE"
echo "$(basename "$FILE" .md): $CUR -> $NEW$FORCED"
