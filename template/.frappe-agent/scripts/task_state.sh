#!/usr/bin/env bash
#
# Move a task record to a new state and log it. Six states keep it simple.
#
# Usage:
#   .frappe-agent/scripts/task_state.sh <TASK-ID|path> <STATE> [--note "text"] [--force]
#
# States:
#   DRAFT                 open: understanding, questions, proposal; the solution is not locked yet
#   LOCKED                the user approved a final solution
#   IN_PROGRESS           executing, testing and reviewing
#   WAITING_FOR_APPROVAL  summary given; waiting for the user's final approval
#   COMPLETED             approved and done
#   BLOCKED               stopped by a dependency or problem; say what is needed in --note.
#                         Unblock back to the state it was in, or to DRAFT.
#
# A --note is required for LOCKED and for COMPLETED (from WAITING_FOR_APPROVAL):
# quote what the user actually said. The agent must never lock or complete a
# task on its own. LOW-risk tasks may skip LOCKED and approval. If a locked
# solution must change materially, move back to DRAFT. --force allows any
# other move and is logged as forced.

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

case " DRAFT LOCKED IN_PROGRESS WAITING_FOR_APPROVAL COMPLETED BLOCKED " in
  *" $NEW "*) ;;
  *) echo "Unknown state: $NEW (use DRAFT, LOCKED, IN_PROGRESS, WAITING_FOR_APPROVAL, COMPLETED or BLOCKED)" >&2; exit 1 ;;
esac

if [ -f "$REF" ]; then FILE="$REF"; else FILE="$(history_dir)/$REF.md"; fi
[ -f "$FILE" ] || { echo "Task record not found: $REF" >&2; exit 1; }

CUR="$(card_field "$FILE" State)"
RISK="$(card_field "$FILE" Risk)"

# Records made by the earlier 12-state version map onto the six states.
case "$CUR" in
  UNDERSTANDING|CLARIFICATION|SOLUTION_PROPOSED|WAITING_FOR_DECISION) CUR_N=DRAFT ;;
  TESTING|REVIEW) CUR_N=IN_PROGRESS ;;
  *) CUR_N="$CUR" ;;
esac

# The state a task was in before it was BLOCKED (from the state log), so that
# unblocking cannot skip a step (for example resume without a lock).
prior_state() {
  awk -F'|' '/^\| [0-9]{4}-/ {
    gsub(/ \(FORCED\)/, "", $3); gsub(/^ +| +$/, "", $3)
    if ($3 != "BLOCKED") last = $3
  } END { print last }' "$FILE"
}

allowed() {  # allowed <from> <to>
  local from="$1" to="$2" prior
  [ "$to" = "BLOCKED" ] && [ "$from" != "COMPLETED" ] && return 0
  if [ "$from" = "BLOCKED" ]; then
    [ "$to" = "DRAFT" ] && return 0
    prior="$(prior_state)"
    case "$prior" in
      UNDERSTANDING|CLARIFICATION|SOLUTION_PROPOSED|WAITING_FOR_DECISION) prior=DRAFT ;;
      TESTING|REVIEW) prior=IN_PROGRESS ;;
    esac
    [ "$to" = "$prior" ] && return 0
    return 1
  fi
  case "$from>$to" in
    DRAFT\>LOCKED|LOCKED\>IN_PROGRESS|\
    IN_PROGRESS\>WAITING_FOR_APPROVAL|IN_PROGRESS\>DRAFT|\
    WAITING_FOR_APPROVAL\>COMPLETED|WAITING_FOR_APPROVAL\>IN_PROGRESS|WAITING_FOR_APPROVAL\>DRAFT) return 0 ;;
  esac
  if [ "$RISK" = "LOW" ]; then
    case "$from>$to" in DRAFT\>IN_PROGRESS|IN_PROGRESS\>COMPLETED|DRAFT\>COMPLETED) return 0 ;; esac
  fi
  return 1
}

[ "$CUR" = "$NEW" ] && { echo "Task is already in $NEW." >&2; exit 1; }

FORCED=""
if ! allowed "$CUR_N" "$NEW"; then
  if [ "$FORCE" -ne 1 ]; then
    echo "Invalid move for a $RISK task: $CUR -> $NEW. Order: DRAFT -> LOCKED -> IN_PROGRESS -> WAITING_FOR_APPROVAL -> COMPLETED. Use --force and explain in --note if you really need this." >&2
    exit 1
  fi
  FORCED=" (FORCED)"
fi

if [ -z "$FORCED" ]; then
  if [ "$NEW" = "LOCKED" ] && [ -z "$NOTE" ]; then
    echo "Moving to LOCKED needs --note quoting the user's decision." >&2; exit 1
  fi
  if [ "$NEW" = "COMPLETED" ] && [ "$CUR_N" = "WAITING_FOR_APPROVAL" ] && [ -z "$NOTE" ]; then
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
