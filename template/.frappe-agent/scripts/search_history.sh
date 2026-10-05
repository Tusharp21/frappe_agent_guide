#!/usr/bin/env bash
#
# Search past work before starting a task, cheaply: prints only the short card
# of matching task records, plus matching lines from DECISIONS.md and
# APP_MAP.md, plus matching commit subjects from each app's git history.
# Nothing is modified.
#
# Usage:
#   .frappe-agent/scripts/search_history.sh [-n MAX_TASKS] <keyword> [keyword...]
# Open a task file in full only if its card looks relevant.

set -uo pipefail

FA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=_lib.sh
. "$FA_DIR/scripts/_lib.sh"

MAX=5
if [ "${1:-}" = "-n" ]; then MAX="${2:?-n needs a number}"; shift 2; fi
[ $# -ge 1 ] || { echo "usage: search_history.sh [-n MAX_TASKS] <keyword> [keyword...]" >&2; exit 1; }
KEYS=("$@")

HIST="$(history_dir)"
BENCH="$(dirname "$FA_DIR")"
found=0

echo "== Past tasks (best matches first; open the file for full detail)"
if [ -d "$HIST" ] || [ -d "$FA_DIR/audit" ]; then
  # score = number of distinct keywords found in the file
  scored=()
  while IFS= read -r f; do
    score=0
    for k in "${KEYS[@]}"; do grep -qiF -- "$k" "$f" && score=$((score + 1)); done
    [ "$score" -gt 0 ] && scored+=("$score|$f")
  done < <(find "$HIST" "$FA_DIR/audit" -maxdepth 1 \( -name 'TASK-*.md' -o -name 'RUN-*.md' \) 2>/dev/null | sort -u)
  if [ "${#scored[@]}" -gt 0 ]; then
    while IFS='|' read -r score f; do
      echo
      echo "--- $f  (matched $score/${#KEYS[@]} keywords)"
      card="$(print_card "$f")"
      if [ -n "$card" ]; then printf '%s\n' "$card"; else head -15 "$f"; fi
      found=1
    done < <(printf '%s\n' "${scored[@]}" | sort -t'|' -k1,1nr | head -n "$MAX")
  fi
fi
[ "$found" -eq 0 ] && echo "  none"

echo
echo "== Decisions and app map"
hits=0
for f in "$FA_DIR/project_knowledge/DECISIONS.md" "$FA_DIR/project_knowledge/APP_MAP.md"; do
  [ -f "$f" ] || continue
  seen=""
  for k in "${KEYS[@]}"; do
    while IFS= read -r line; do
      case "$seen" in *"|$line|"*) continue ;; esac
      seen="$seen|$line|"
      echo "  $(basename "$f"): $line"; hits=1
    done < <(grep -iF -- "$k" "$f" | head -5)
  done
done
[ "$hits" -eq 0 ] && echo "  none"

echo
echo "== Git history (commit subjects matching any keyword)"
ghits=0
if [ -d "$BENCH/apps" ]; then
  greps=(); for k in "${KEYS[@]}"; do greps+=(--grep="$k"); done
  for d in "$BENCH"/apps/*/; do
    git -C "$d" rev-parse --git-dir >/dev/null 2>&1 || continue
    out="$(git -C "$d" log -i --oneline -n 5 "${greps[@]}" 2>/dev/null)"
    if [ -n "$out" ]; then
      echo "  $(basename "$d"):"; printf '%s\n' "$out" | sed 's/^/    /'; ghits=1
    fi
  done
fi
[ "$ghits" -eq 0 ] && echo "  none"

echo
echo "No match is a valid result: it means the work looks new. Decide: reuse, extend, or new implementation."
exit 0
