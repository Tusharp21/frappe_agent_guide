#!/usr/bin/env bash
#
# Tests for the plan layer: new_plan.sh, plan_state.sh, plan_next.sh and how
# they hand phases to the task system and the guard. Runs against a throwaway
# copy of the template in a temp bench.
#
# Usage: tests/plan_test.sh

set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BENCH="$(mktemp -d)"
trap 'rm -rf "$BENCH"' EXIT

cp -R "$REPO/template/.frappe-agent" "$BENCH/.frappe-agent"
mkdir -p "$BENCH/apps/myapp/myapp"
echo "x = 1" > "$BENCH/apps/myapp/myapp/a.py"
echo "y = 1" > "$BENCH/apps/myapp/myapp/b.py"

FA="$BENCH/.frappe-agent"
S="$FA/scripts"
GUARD="$FA/hooks/guard.sh"
TASKS="$FA/tasks"
YEAR="$(date +%Y)"
PASS=0; FAIL=0

check() {  # check <name> <expected> <actual>
  if [ "$2" = "$3" ]; then PASS=$((PASS + 1)); printf '  ok    %s\n' "$1"
  else FAIL=$((FAIL + 1)); printf '  FAIL  %s (expected %s, got %s)\n' "$1" "$2" "$3"; fi
}

rc() { "$@" >/dev/null 2>&1; echo $?; }   # run, print exit code
field() { sed -n "s/^- \*\*$2:\*\* *//p" "$1" | head -1 | sed 's/ *<!--.*-->//'; }

verdict() {  # verdict <tool> <abs path>
  local out code payload
  payload="$(python3 -c 'import json,sys; print(json.dumps({"tool_name": sys.argv[1], "tool_input": {"file_path": sys.argv[2]}, "cwd": sys.argv[3]}))' "$1" "$2" "$BENCH")"
  out="$(printf '%s' "$payload" | bash "$GUARD" 2>/dev/null)"; code=$?
  if [ "$code" -eq 2 ]; then echo BLOCK
  elif printf '%s' "$out" | grep -q '"permissionDecision": "ask"'; then echo ASK
  else echo ALLOW; fi
}

# set_phases <plan file> <row>...   replaces the phase table rows
set_phases() {
  local file="$1"; shift
  python3 - "$file" "$@" <<'PY'
import sys
path, rows = sys.argv[1], sys.argv[2:]
text = open(path).read()
head, rest = text.split("<!-- PHASES:START -->\n", 1)
_, tail = rest.split("<!-- PHASES:END -->", 1)
table = ["| # | Phase | Risk | Allowed paths | Acceptance criteria | Status | Task |",
         "| - | ----- | ---- | ------------- | ------------------- | ------ | ---- |"] + list(rows)
open(path, "w").write(head + "<!-- PHASES:START -->\n" + "\n".join(table) + "\n<!-- PHASES:END -->" + tail)
PY
}

echo "Creating a plan"
PLAN="$(bash "$S/new_plan.sh" "Discount approval" 2>/dev/null)"
PID="$(basename "$PLAN" .md)"
check "new_plan.sh creates PLAN-YYYY-NNN.md" "PLAN-$YEAR-001" "$PID"
check "new plan starts as DRAFT" DRAFT "$(field "$PLAN" State)"
check "plan lives next to the task records" "$TASKS" "$(dirname "$PLAN")"

echo "Locking"
check "cannot lock without --note" 1 "$(rc bash "$S/plan_state.sh" "$PID" LOCKED)"
check "cannot lock a plan with no phases" 1 "$(rc bash "$S/plan_state.sh" "$PID" LOCKED --note "user: ok")"
set_phases "$PLAN" \
  "| 1 | Discount fields | MEDIUM | apps/myapp/myapp/a.py | Fields visible and saved | PENDING | |" \
  "| 2 | Approval workflow | HIGH | apps/myapp/myapp/ | Manager approves above 10 percent | PENDING | |" \
  "| 3 | Tests and report | LOW | apps/myapp/myapp/b.py | Tests pass | PENDING | |"
check "plan_next.sh refuses a DRAFT plan" 1 "$(rc bash "$S/plan_next.sh" "$PID")"
check "lock with a note succeeds" 0 "$(rc bash "$S/plan_state.sh" "$PID" LOCKED --note "user: approved the plan")"
check "plan is LOCKED" LOCKED "$(field "$PLAN" State)"
check "risk is the highest phase risk" HIGH "$(field "$PLAN" Risk)"
check "lock hash is recorded" "yes" "$([ -n "$(field "$PLAN" "Lock hash")" ] && echo yes || echo no)"
check "decision is recorded" "user: approved the plan" "$(field "$PLAN" Decision)"

echo "Phase 1 (MEDIUM): starts already locked by the plan"
out="$(bash "$S/plan_next.sh" "$PID" 2>&1)"; code=$?
check "plan_next.sh starts phase 1" 0 "$code"
T1="TASK-$YEAR-001"
check "a task was created" "yes" "$([ -f "$TASKS/$T1.md" ] && echo yes || echo no)"
check "MEDIUM phase task is LOCKED by the plan" LOCKED "$(field "$TASKS/$T1.md" State)"
check "task carries the phase's allowed paths" "apps/myapp/myapp/a.py" "$(field "$TASKS/$T1.md" "Allowed paths")"
check "task is the active one" "$T1" "$(cat "$TASKS/.active")"
check "plan moved to IN_PROGRESS" IN_PROGRESS "$(field "$PLAN" State)"
check "task names its plan and phase" "yes" "$(grep -q "$PID" "$TASKS/$T1.md" && grep -qi "phase 1" "$TASKS/$T1.md" && echo yes || echo no)"
check "guard allows the phase's file" ALLOW "$(verdict Edit "$BENCH/apps/myapp/myapp/a.py")"
check "guard asks for a file outside the phase" ASK "$(verdict Edit "$BENCH/apps/myapp/myapp/b.py")"
check "plan_next.sh again resumes the same phase" 0 "$(rc bash "$S/plan_next.sh" "$PID")"
check "still only one task" 1 "$(ls "$TASKS"/TASK-*.md | wc -l | tr -d ' ')"

echo "Scope and state cannot be edited by the agent"
payload="$(python3 -c 'import json,sys; print(json.dumps({"tool_name":"Edit","tool_input":{"file_path":sys.argv[1],"old_string":"- **Allowed paths:** apps/myapp/myapp/a.py","new_string":"- **Allowed paths:** apps/"},"cwd":sys.argv[2]}))' "$TASKS/$T1.md" "$BENCH")"
printf '%s' "$payload" | bash "$GUARD" >/dev/null 2>&1
check "widening Allowed paths on a locked task is blocked" 2 "$?"
payload="$(python3 -c 'import json,sys; print(json.dumps({"tool_name":"Edit","tool_input":{"file_path":sys.argv[1],"old_string":"- **State:** LOCKED","new_string":"- **State:** COMPLETED"},"cwd":sys.argv[2]}))' "$PLAN" "$BENCH")"
printf '%s' "$payload" | bash "$GUARD" >/dev/null 2>&1
check "editing a plan's State line is blocked" 2 "$?"

echo "One phase at a time"
check "phase 2 will not start while phase 1 is open" 1 "$(rc bash "$S/plan_next.sh" "$PID" --note "user: continue")"
set_card() { sed -i "s|^- \*\*$2:\*\*.*|- **$2:** $3|" "$1"; }
bash "$S/task_state.sh" "$T1" IN_PROGRESS >/dev/null 2>&1
set_card "$TASKS/$T1.md" Tests PASS
bash "$S/task_state.sh" "$T1" WAITING_FOR_APPROVAL >/dev/null 2>&1
bash "$S/task_state.sh" "$T1" COMPLETED --note "user: phase 1 approved" >/dev/null 2>&1
check "phase 2 needs the user's continue note" 1 "$(rc bash "$S/plan_next.sh" "$PID")"

echo "Phase 2 (HIGH): needs its own proposal and lock"
check "phase 2 starts with a note" 0 "$(rc bash "$S/plan_next.sh" "$PID" --note "user: continue")"
T2="TASK-$YEAR-002"
check "HIGH phase task stays DRAFT" DRAFT "$(field "$TASKS/$T2.md" State)"
check "guard blocks editing for the DRAFT HIGH phase" BLOCK "$(verdict Edit "$BENCH/apps/myapp/myapp/a.py")"
check "phase 1 shows as done in the plan" "1/3 done" "$(field "$PLAN" Phases)"

echo "Tampering and change requests"
python3 - "$PLAN" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read().replace("Manager approves above 10 percent", "Anyone approves")
open(p, "w").write(s)
PY
check "plan_next.sh refuses a plan edited after the lock" 1 "$(rc bash "$S/plan_next.sh" "$PID" --note "user: continue")"
python3 - "$PLAN" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read().replace("Anyone approves", "Manager approves above 10 percent")
open(p, "w").write(s)
PY
check "restoring the text makes the plan valid again" 0 "$(rc bash "$S/plan_next.sh" "$PID")"
check "back to DRAFT needs a note" 1 "$(rc bash "$S/plan_state.sh" "$PID" DRAFT)"
check "back to DRAFT with a change-request note" 0 "$(rc bash "$S/plan_state.sh" "$PID" DRAFT --note "CR: add an SMS alert phase")"
check "plan is DRAFT again" DRAFT "$(field "$PLAN" State)"
check "lock hash cleared" "" "$(field "$PLAN" "Lock hash")"
check "change request is logged" "yes" "$(grep -q "CR: add an SMS alert phase" "$PLAN" && echo yes || echo no)"
check "relock with a new note" 0 "$(rc bash "$S/plan_state.sh" "$PID" LOCKED --note "user: approved the revised plan")"

echo "Finishing the plan"
check "cannot complete with open phases" 1 "$(rc bash "$S/plan_state.sh" "$PID" COMPLETED --note "user: done")"
set_card "$TASKS/$T2.md" Tests PASS
bash "$S/task_state.sh" "$T2" LOCKED --note "user: proposal ok" >/dev/null 2>&1
bash "$S/task_state.sh" "$T2" IN_PROGRESS >/dev/null 2>&1
bash "$S/task_state.sh" "$T2" WAITING_FOR_APPROVAL >/dev/null 2>&1
bash "$S/task_state.sh" "$T2" COMPLETED --note "user: ok" >/dev/null 2>&1
bash "$S/plan_next.sh" "$PID" --note "user: continue" >/dev/null 2>&1
T3="TASK-$YEAR-003"
check "LOW phase starts locked" LOCKED "$(field "$TASKS/$T3.md" State)"
bash "$S/task_state.sh" "$T3" IN_PROGRESS >/dev/null 2>&1
bash "$S/task_state.sh" "$T3" COMPLETED >/dev/null 2>&1
check "complete needs the user's words" 1 "$(rc bash "$S/plan_state.sh" "$PID" COMPLETED)"
check "plan completes when every phase is done" 0 "$(rc bash "$S/plan_state.sh" "$PID" COMPLETED --note "user: delivered, approved")"
check "plan is COMPLETED" COMPLETED "$(field "$PLAN" State)"
check "all phases done" "3/3 done" "$(field "$PLAN" Phases)"

echo
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
