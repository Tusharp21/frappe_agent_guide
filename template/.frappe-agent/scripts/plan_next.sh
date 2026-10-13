#!/usr/bin/env bash
#
# Start (or resume) the next phase of a locked plan as a task.
#
# Usage:
#   .frappe-agent/scripts/plan_next.sh <PLAN-ID|path> [--note "the user's words"]
#
# What it does:
#   * refuses a plan that is not LOCKED or IN_PROGRESS, or whose scope or
#     phases changed after the lock (hash mismatch)
#   * marks phases DONE whose task is COMPLETED
#   * if a phase is already in progress, makes its task active and stops
#   * otherwise creates a task for the first phase that is not done, with the
#     phase's risk, allowed paths and acceptance criteria. A LOW or MEDIUM
#     phase starts LOCKED (the plan lock approved it); a HIGH phase starts
#     DRAFT and needs its own proposal and lock
#
# Every phase after the first needs --note quoting the user's go-ahead, so the
# agent stops after each phase until the user says continue.

set -euo pipefail

FA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=_lib.sh
. "$FA_DIR/scripts/_lib.sh"
PLANPY="$FA_DIR/scripts/_plan.py"
S="$FA_DIR/scripts"

[ $# -ge 1 ] || { echo "usage: plan_next.sh <PLAN-ID|path> [--note \"the user's words\"]" >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "python3 is required." >&2; exit 1; }
REF="$1"; shift
NOTE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --note) NOTE="${2:?--note needs text}"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

if [ -f "$REF" ]; then FILE="$REF"; else FILE="$(history_dir)/$REF.md"; fi
[ -f "$FILE" ] || { echo "Plan record not found: $REF" >&2; exit 1; }
ID="$(basename "$FILE" .md)"
case "$ID" in PLAN-*) ;; *) echo "$ID is not a plan record." >&2; exit 1 ;; esac
fail() { echo "$*" >&2; exit 1; }

STATE="$(card_field "$FILE" State)"
case "$STATE" in
  LOCKED|IN_PROGRESS) ;;
  *) fail "$ID is $STATE. Phases start only from a LOCKED or IN_PROGRESS plan (get the user's approval, then plan_state.sh $ID LOCKED --note ...)." ;;
esac

[ "$(python3 "$PLANPY" hash "$FILE")" = "$(card_field "$FILE" "Lock hash")" ] \
  || fail "The scope or phases of $ID changed after the lock. Do not edit a locked plan: restore it, or reopen it with plan_state.sh $ID DRAFT --note \"CR: ...\" and get a new decision."

read -r DONE TOTAL < <(python3 "$PLANPY" sync "$FILE" "$(history_dir)")
PHASE="$(python3 "$PLANPY" next "$FILE")"
if [ "$PHASE" = "{}" ]; then
  echo "All $TOTAL phases of $ID are done. Give the user the final summary and acceptance results, then: plan_state.sh $ID COMPLETED --note \"<their approval>\""
  exit 0
fi

field() { printf '%s' "$PHASE" | python3 -c 'import json,sys; print(json.load(sys.stdin)[sys.argv[1]])' "$1"; }
N="$(field n)"; TITLE="$(field phase)"; RISK="$(field risk | tr '[:lower:]' '[:upper:]')"
ALLOWED="$(field allowed)"; ACCEPT="$(field acceptance)"; STATUS="$(field status)"; TASK="$(field task)"

if [ "$STATUS" = "IN_PROGRESS" ] && [ -n "$TASK" ]; then
  [ -z "$NOTE" ] || fail "Phase $N is not finished: $TASK is not COMPLETED. The next phase starts only after the user approves this one."
  bash "$S/task_state.sh" "$TASK" --activate >/dev/null
  echo "Phase $N of $TOTAL is in progress: $TASK is the active task. Finish and complete it before the next phase."
  exit 0
fi

if [ "$DONE" -ge 1 ] && [ -z "$NOTE" ]; then
  fail "Phase $((DONE + 1)) of $TOTAL: stop here and give the user the result of the previous phase. Start the next one only on their go-ahead: plan_next.sh $ID --note \"<their words>\"."
fi

TASKFILE="$(bash "$S/new_task.sh" "$(python3 "$PLANPY" field "$FILE" Title): phase $N, $TITLE" "$RISK")"
TID="$(basename "$TASKFILE" .md)"
DECISION="$(card_field "$FILE" Decision)"

if [ "$RISK" = "HIGH" ]; then
  python3 "$PLANPY" taskfill "$TASKFILE" "$ID" "$N" "$TITLE" "$ACCEPT" "$ALLOWED" ""
  NEXT="DRAFT. HIGH phases need their own proposal (rollback plan, migration impact) and the user's lock: task_state.sh $TID LOCKED --note \"<their words>\"."
else
  python3 "$PLANPY" taskfill "$TASKFILE" "$ID" "$N" "$TITLE" "$ACCEPT" "$ALLOWED" "per $ID phase $N: $ACCEPT"
  if bash "$S/task_state.sh" "$TID" LOCKED --note "locked by $ID phase $N; plan decision: $DECISION" >/dev/null 2>&1; then
    NEXT="LOCKED by the plan. Mark it started with task_state.sh $TID IN_PROGRESS and implement inside its Allowed paths."
  else
    NEXT="DRAFT (the automatic lock failed). Lock it with task_state.sh $TID LOCKED --note \"<the user's words>\" before editing code."
  fi
fi

python3 "$PLANPY" setrow "$FILE" "$N" status=IN_PROGRESS task="$TID"
python3 "$PLANPY" sync "$FILE" "$(history_dir)" >/dev/null
if [ "$STATE" = "LOCKED" ]; then
  python3 "$PLANPY" field "$FILE" State IN_PROGRESS
fi
python3 "$PLANPY" log "$FILE" IN_PROGRESS "phase $N started: $TID${NOTE:+ (user: $NOTE)}"

echo "Phase $N of $TOTAL: $TITLE"
echo "  task:       $TID ($TASKFILE)"
echo "  risk:       $RISK"
echo "  scope:      $ALLOWED"
echo "  acceptance: $ACCEPT"
echo "  state:      $NEXT"
