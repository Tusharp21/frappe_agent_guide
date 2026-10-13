#!/usr/bin/env bash
#
# Move a plan record to a new state and log it.
#
# Usage:
#   .frappe-agent/scripts/plan_state.sh <PLAN-ID|path> <STATE> [--note "text"]
#
# States:
#   DRAFT        being written, or reopened for a change request
#   LOCKED       the user approved scope and phases; a hash of both is stored
#   IN_PROGRESS  at least one phase has started (plan_next.sh sets this)
#   COMPLETED    every phase is DONE and the user approved the result
#   BLOCKED      stopped; say why in --note
#
# Moves:
#   DRAFT -> LOCKED          --note quotes the user; the phase table must be valid
#   LOCKED|IN_PROGRESS -> DRAFT   --note "CR: why"; clears the lock hash and logs a
#                            change request. Finished phases stay DONE
#   IN_PROGRESS -> COMPLETED --note quotes the user; all phases DONE; plan unchanged
#   any -> BLOCKED, BLOCKED -> DRAFT or the state it was in
# The agent must never lock or complete a plan on its own.

set -euo pipefail

FA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=_lib.sh
. "$FA_DIR/scripts/_lib.sh"
PLANPY="$FA_DIR/scripts/_plan.py"

[ $# -ge 2 ] || { echo "usage: plan_state.sh <PLAN-ID|path> <STATE> [--note \"text\"]" >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "python3 is required." >&2; exit 1; }
REF="$1"; NEW="$(printf '%s' "$2" | tr '[:lower:]' '[:upper:]')"; shift 2
NOTE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --note) NOTE="${2:?--note needs text}"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

case " DRAFT LOCKED IN_PROGRESS COMPLETED BLOCKED " in
  *" $NEW "*) ;;
  *) echo "Unknown state: $NEW (use DRAFT, LOCKED, IN_PROGRESS, COMPLETED or BLOCKED)" >&2; exit 1 ;;
esac

if [ -f "$REF" ]; then FILE="$REF"; else FILE="$(history_dir)/$REF.md"; fi
[ -f "$FILE" ] || { echo "Plan record not found: $REF" >&2; exit 1; }
ID="$(basename "$FILE" .md)"
case "$ID" in PLAN-*) ;; *) echo "$ID is not a plan record (use task_state.sh for tasks)." >&2; exit 1 ;; esac

CUR="$(card_field "$FILE" State)"
[ "$CUR" = "$NEW" ] && { echo "Plan is already $NEW." >&2; exit 1; }

prior_state() {
  awk -F'|' '/^\| [0-9]{4}-/ { gsub(/^ +| +$/, "", $3); if ($3 != "BLOCKED") last = $3 } END { print last }' "$FILE"
}

fail() { echo "$*" >&2; exit 1; }
need_note() { [ -n "$NOTE" ] || fail "Moving to $NEW needs --note $1."; }

case "$CUR>$NEW" in
  DRAFT\>LOCKED)
    need_note "quoting the user's approval of the plan"
    if ! errs="$(python3 "$PLANPY" validate "$FILE" 2>&1)"; then
      printf 'The phase table is not valid:\n%s\n' "$errs" >&2; exit 1
    fi
    python3 "$PLANPY" field "$FILE" Risk "$(python3 "$PLANPY" maxrisk "$FILE")"
    python3 "$PLANPY" field "$FILE" "Lock hash" "$(python3 "$PLANPY" hash "$FILE")"
    python3 "$PLANPY" field "$FILE" Decision "$(printf '%s' "$NOTE" | tr '\n|' '  ')"
    python3 "$PLANPY" sync "$FILE" "$(history_dir)" >/dev/null
    ;;
  LOCKED\>IN_PROGRESS) ;;
  LOCKED\>DRAFT|IN_PROGRESS\>DRAFT)
    need_note "starting with \"CR:\" and saying what must change and why"
    case "$NOTE" in CR:*|cr:*) ;; *) fail "A change request note must start with \"CR:\"." ;; esac
    python3 "$PLANPY" cr "$FILE" "$NOTE"
    python3 "$PLANPY" field "$FILE" "Lock hash" ""
    ;;
  IN_PROGRESS\>COMPLETED)
    need_note "quoting the user's approval of the result"
    [ "$(python3 "$PLANPY" hash "$FILE")" = "$(card_field "$FILE" "Lock hash")" ] \
      || fail "The scope or phases changed after the lock. Reopen with a change request (--note \"CR: ...\")."
    read -r done total < <(python3 "$PLANPY" sync "$FILE" "$(history_dir)")
    [ "$done" = "$total" ] || fail "Only $done of $total phases are DONE (a phase is done when its task is COMPLETED)."
    python3 "$PLANPY" field "$FILE" Approval "$(printf '%s' "$NOTE" | tr '\n|' '  ')"
    ;;
  COMPLETED\>*) fail "A COMPLETED plan is closed. Open a new plan for further work." ;;
  *\>BLOCKED) need_note "saying what is needed" ;;
  BLOCKED\>DRAFT) ;;
  BLOCKED\>*)
    [ "$NEW" = "$(prior_state)" ] || fail "Unblock back to $(prior_state) or to DRAFT."
    ;;
  *) fail "Invalid move: $CUR -> $NEW. Order: DRAFT -> LOCKED -> IN_PROGRESS -> COMPLETED." ;;
esac

python3 "$PLANPY" field "$FILE" State "$NEW"
python3 "$PLANPY" log "$FILE" "$NEW" "$NOTE"
echo "$ID: $CUR -> $NEW"
if [ "$NEW" = "LOCKED" ]; then
  echo "Locked. Start the first phase with: .frappe-agent/scripts/plan_next.sh $ID"
fi
