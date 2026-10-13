#!/usr/bin/env bash
#
# Tests for the process gates in template/.frappe-agent/hooks/guard.sh and the
# task scripts that feed them (new_task.sh, task_state.sh). Runs against a
# throwaway copy of the template in a temp bench; touches nothing else.
#
# Usage: tests/guard_test.sh

set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BENCH="$(mktemp -d)"
trap 'rm -rf "$BENCH"' EXIT

cp -R "$REPO/template/.frappe-agent" "$BENCH/.frappe-agent"
mkdir -p "$BENCH/apps/myapp/myapp"
echo "x = 1" > "$BENCH/apps/myapp/myapp/a.py"
echo "y = 1" > "$BENCH/apps/myapp/myapp/b.py"
echo "# bench readme" > "$BENCH/README.md"
echo "# agent rules" > "$BENCH/AGENTS.md"
mkdir -p "$BENCH/.claude"
echo "{}" > "$BENCH/.claude/settings.json"
echo "SECRET=1" > "$BENCH/apps/myapp/.env"

FA="$BENCH/.frappe-agent"
GUARD="$FA/hooks/guard.sh"
TASKS="$FA/tasks"
YEAR="$(date +%Y)"

PASS=0; FAIL=0

# verdict <json-payload> -> BLOCK | ASK | ALLOW
verdict() {
  local out rc
  out="$(printf '%s' "$1" | bash "$GUARD" 2>/dev/null)"; rc=$?
  if [ "$rc" -eq 2 ]; then echo BLOCK
  elif printf '%s' "$out" | grep -q '"permissionDecision": "ask"'; then echo ASK
  elif printf '%s' "$out" | grep -q '"permissionDecision": "deny"'; then echo BLOCK
  else echo ALLOW; fi
}

edit_payload() {  # edit_payload <abs path> [tool]
  printf '{"tool_name":"%s","tool_input":{"file_path":"%s"},"cwd":"%s"}' "${2:-Edit}" "$1" "$BENCH"
}
bash_payload() {
  printf '{"tool_name":"Bash","tool_input":{"command":"%s"},"cwd":"%s"}' "$1" "$BENCH"
}


# json payloads with arbitrary strings, built by python so quoting is safe
jpayload() {  # jpayload <tool> <key=value>...   (tool_input fields; cwd added)
  python3 - "$BENCH" "$@" <<'PY2'
import json, sys
bench, tool, *pairs = sys.argv[1:]
ti = {}
for pair in pairs:
    k, v = pair.split("=", 1)
    ti[k] = v
print(json.dumps({"tool_name": tool, "tool_input": ti, "cwd": bench}))
PY2
}

check() {  # check <name> <expected> <actual>
  if [ "$2" = "$3" ]; then PASS=$((PASS + 1)); printf '  ok    %s\n' "$1"
  else FAIL=$((FAIL + 1)); printf '  FAIL  %s (expected %s, got %s)\n' "$1" "$2" "$3"; fi
}

task_id() { printf 'TASK-%s-%03d' "$YEAR" "$1"; }
set_card() {  # set_card <task id> <field> <value>
  sed -i "s|^- \*\*$2:\*\*.*|- **$2:** $3|" "$TASKS/$1.md"
}
state() { bash "$FA/scripts/task_state.sh" "$@" >/dev/null 2>&1; }

A="$BENCH/apps/myapp/myapp/a.py"
B="$BENCH/apps/myapp/myapp/b.py"

echo "No active task"
check "edit under apps/ asks" ASK "$(verdict "$(edit_payload "$A")")"
check "edit outside apps/ is not gated" ALLOW "$(verdict "$(edit_payload "$BENCH/README.md")")"
check "reading app code is not gated" ALLOW "$(verdict "$(edit_payload "$A" Read)")"

echo "DRAFT task"
bash "$FA/scripts/new_task.sh" "add discount field" medium >/dev/null
T1="$(task_id 1)"
check "new_task.sh sets the active task" "$T1" "$(cat "$TASKS/.active" 2>/dev/null)"
check "edit app code is blocked" BLOCK "$(verdict "$(edit_payload "$A")")"
check "Write app code is blocked" BLOCK "$(verdict "$(edit_payload "$A" Write)")"
check "MultiEdit app code is blocked" BLOCK "$(verdict "$(edit_payload "$A" MultiEdit)")"
check "editing the task record is allowed" ALLOW "$(verdict "$(edit_payload "$TASKS/$T1.md")")"
check "editing project_knowledge is allowed" ALLOW "$(verdict "$(edit_payload "$FA/project_knowledge/DECISIONS.md")")"

echo "LOCKED task"
state "$T1" LOCKED --note "user: yes go ahead"
check "edit is allowed once locked" ALLOW "$(verdict "$(edit_payload "$A")")"
state "$T1" IN_PROGRESS
check "edit is allowed in progress" ALLOW "$(verdict "$(edit_payload "$A")")"

echo "Scope gate"
set_card "$T1" "Allowed paths" "apps/myapp/myapp/a.py"
check "file on the allowed list is allowed" ALLOW "$(verdict "$(edit_payload "$A")")"
check "file off the allowed list asks" ASK "$(verdict "$(edit_payload "$B")")"
set_card "$T1" "Allowed paths" "apps/myapp/myapp/"
check "directory entry allows files under it" ALLOW "$(verdict "$(edit_payload "$B")")"
set_card "$T1" "Allowed paths" "apps/myapp/*.py, apps/other/"
check "glob entry allowed" ALLOW "$(verdict "$(edit_payload "$A")")"
set_card "$T1" "Allowed paths" "apps/other/"
check "path matching no entry asks" ASK "$(verdict "$(edit_payload "$A")")"
set_card "$T1" "Allowed paths" ""

echo "Evidence gate"
out="$(bash "$FA/scripts/task_state.sh" "$T1" WAITING_FOR_APPROVAL 2>&1)"; rc=$?
check "WAITING_FOR_APPROVAL refused with Tests NOT RUN" 1 "$rc"
set_card "$T1" "Tests" "PASS"
bash "$FA/scripts/task_state.sh" "$T1" WAITING_FOR_APPROVAL >/dev/null 2>&1
check "WAITING_FOR_APPROVAL accepted with Tests PASS" WAITING_FOR_APPROVAL \
  "$(sed -n 's/^- \*\*State:\*\* *//p' "$TASKS/$T1.md" | head -1)"
check "edit is blocked while waiting for approval" BLOCK "$(verdict "$(edit_payload "$A")")"

echo "COMPLETED task"
state "$T1" COMPLETED --note "user: approved"
check "completing clears the active task" "none" "$([ -f "$TASKS/.active" ] && echo present || echo none)"
check "edit asks again after completion" ASK "$(verdict "$(edit_payload "$A")")"

echo "HIGH task needs real test evidence"
bash "$FA/scripts/new_task.sh" "migrate old orders" high >/dev/null
T2="$(task_id 2)"
state "$T2" LOCKED --note "user: ok"
state "$T2" IN_PROGRESS
bash "$FA/scripts/task_state.sh" "$T2" WAITING_FOR_APPROVAL --note "no tests possible" >/dev/null 2>&1
check "HIGH refused with Tests NOT RUN even with a note" 1 "$?"

echo "Switching the active task"
T3="$(basename "$(bash "$FA/scripts/new_task.sh" "second task" medium)" .md)"
check "new task becomes active" "$T3" "$(cat "$TASKS/.active")"
bash "$FA/scripts/task_state.sh" "$T2" --activate >/dev/null 2>&1
check "--activate switches back without a state change" "$T2" "$(cat "$TASKS/.active")"
bash "$FA/scripts/task_state.sh" "$(task_id 999)" --activate >/dev/null 2>&1
check "--activate on a missing task fails" 1 "$?"

echo "LOW task"
bash "$FA/scripts/new_task.sh" "fix typo" low >/dev/null
check "LOW task in DRAFT may edit" ALLOW "$(verdict "$(edit_payload "$A")")"

echo "Regression: safety rules"
check "git commit asks" ASK "$(verdict "$(bash_payload "git commit -m x")")"
check "push to master blocked" BLOCK "$(verdict "$(bash_payload "git push origin master")")"
check "--no-verify blocked" BLOCK "$(verdict "$(bash_payload "git commit --no-verify -m x")")"
check "plain git status allowed" ALLOW "$(verdict "$(bash_payload "git status")")"
check "reading .env blocked" BLOCK "$(verdict "$(edit_payload "$BENCH/apps/myapp/.env" Read)")"

echo "Task record integrity (the agent cannot lock itself)"
REC="$(bash "$FA/scripts/new_task.sh" "integrity task" medium)"
T5="$(basename "$REC" .md)"
check "record was created" "yes" "$([ -f "$REC" ] && echo yes || echo no)"
check "Edit changing the State line is blocked" BLOCK "$(verdict "$(jpayload Edit "file_path=$REC" "old_string=- **State:** DRAFT" "new_string=- **State:** LOCKED")")"
check "Edit of other record text is allowed" ALLOW "$(verdict "$(jpayload Edit "file_path=$REC" "old_string=* Requirement:" "new_string=* Requirement: discount")")"
check "Edit of Allowed paths while DRAFT is allowed" ALLOW "$(verdict "$(jpayload Edit "file_path=$REC" "old_string=- **Allowed paths:**" "new_string=- **Allowed paths:** apps/myapp/")")"
FORGED="$(sed 's/^- \*\*State:\*\* .*/- **State:** LOCKED/' "$REC")"
check "Write forging the State is blocked" BLOCK "$(verdict "$(jpayload Write "file_path=$REC" "content=$FORGED")")"
SAME="$(cat "$REC"; echo "* extra note")"
check "Write keeping the State is allowed" ALLOW "$(verdict "$(jpayload Write "file_path=$REC" "content=$SAME")")"
check "Write to .active is blocked" BLOCK "$(verdict "$(jpayload Write "file_path=$TASKS/.active" "content=TASK-2026-001")")"
check "sed -i on a record is blocked" BLOCK "$(verdict "$(bash_payload "sed -i s/DRAFT/LOCKED/ .frappe-agent/tasks/$T5.md")")"
check "redirect into .active is blocked" BLOCK "$(verdict "$(bash_payload "echo TASK-2026-001 > .frappe-agent/tasks/.active")")"
check "python rewriting a record is blocked" BLOCK "$(verdict "$(bash_payload "python3 -c \\\"open('.frappe-agent/tasks/$T5.md','w')\\\"")")"
check "task_state.sh is allowed" ALLOW "$(verdict "$(bash_payload "bash .frappe-agent/scripts/task_state.sh $T5 LOCKED --note x")")"
state "$T5" LOCKED --note "user: ok"
check "Edit of Allowed paths after lock is blocked" BLOCK "$(verdict "$(jpayload Edit "file_path=$REC" "old_string=- **Allowed paths:**" "new_string=- **Allowed paths:** apps/")")"
WIDER="$(sed 's|^- \*\*Allowed paths:\*\*.*|- **Allowed paths:** apps/|' "$REC")"
check "Write changing Allowed paths after lock is blocked" BLOCK "$(verdict "$(jpayload Write "file_path=$REC" "content=$WIDER")")"
check "cat of a record is allowed" ALLOW "$(verdict "$(bash_payload "cat .frappe-agent/tasks/$T5.md")")"
check "reading with 2>&1 is allowed" ALLOW "$(verdict "$(bash_payload "cat .frappe-agent/tasks/$T5.md 2>&1")")"

echo "Harness files (the agent cannot loosen its own rules)"
POL="$FA/policy.json"
check "Edit policy.json is blocked" BLOCK "$(verdict "$(jpayload Edit "file_path=$POL" "old_string=true" "new_string=false")")"
check "Write config.json is blocked" BLOCK "$(verdict "$(jpayload Write "file_path=$FA/config.json" "content={}")")"
check "Write a hook script is blocked" BLOCK "$(verdict "$(jpayload Write "file_path=$FA/hooks/guard.sh" "content=exit 0")")"
check "Edit a workflow doc is blocked" BLOCK "$(verdict "$(jpayload Edit "file_path=$FA/workflow/TASK.md" "old_string=a" "new_string=b")")"
check "Edit AGENTS.md is blocked" BLOCK "$(verdict "$(jpayload Edit "file_path=$BENCH/AGENTS.md" "old_string=a" "new_string=b")")"
check "Edit .claude/settings.json is blocked" BLOCK "$(verdict "$(jpayload Edit "file_path=$BENCH/.claude/settings.json" "old_string=a" "new_string=b")")"
check "Edit project_knowledge is allowed" ALLOW "$(verdict "$(jpayload Edit "file_path=$FA/project_knowledge/APP_MAP.md" "old_string=a" "new_string=b")")"
check "Reading policy.json is allowed" ALLOW "$(verdict "$(jpayload Read "file_path=$POL")")"
check "sed -i on policy.json is blocked" BLOCK "$(verdict "$(bash_payload "sed -i s/true/false/ .frappe-agent/policy.json")")"
check "redirect into config.json is blocked" BLOCK "$(verdict "$(bash_payload "echo {} > .frappe-agent/config.json")")"
check "python editing a hook is blocked" BLOCK "$(verdict "$(bash_payload "python3 -c \\\"open('.frappe-agent/hooks/guard.sh','w')\\\"")")"
check "cat policy.json is allowed" ALLOW "$(verdict "$(bash_payload "cat .frappe-agent/policy.json")")"
check "script name as a late argument is not an exemption" BLOCK "$(verdict "$(bash_payload "sed -i s/a/b/ .frappe-agent/policy.json task_state.sh")")"

echo "Switches and failure mode"
python3 - "$FA/policy.json" <<'PY'
import json, sys
p = json.load(open(sys.argv[1])); p["process_gates"] = {"enabled": False}
json.dump(p, open(sys.argv[1], "w"), indent=2)
PY
bash "$FA/scripts/new_task.sh" "another draft" medium >/dev/null
check "gates off: DRAFT edit allowed" ALLOW "$(verdict "$(edit_payload "$A")")"
python3 - "$FA/policy.json" <<'PY'
import json, sys
p = json.load(open(sys.argv[1])); p["process_gates"] = {"draft_edit": "ask"}
json.dump(p, open(sys.argv[1], "w"), indent=2)
PY
check "draft_edit=ask is honoured" ASK "$(verdict "$(edit_payload "$A")")"
python3 - "$FA/policy.json" <<'PY'
import json, sys
p = json.load(open(sys.argv[1])); p["process_gates"] = {"harness_files": "allow"}
json.dump(p, open(sys.argv[1], "w"), indent=2)
PY
check "harness_files=allow is honoured" ALLOW "$(verdict "$(jpayload Edit "file_path=$POL" "old_string=a" "new_string=b")")"

EMPTY="$(mktemp -d)"
printf '%s' "$(edit_payload "$A")" | env PATH="$EMPTY" /bin/bash "$GUARD" >/dev/null 2>&1
check "no python3: guard fails closed" 2 "$?"
rmdir "$EMPTY"

echo
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
