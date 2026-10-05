#!/usr/bin/env bash
#
# Read-only discovery for a Frappe bench. Prints what an agent needs to know
# before planning a change. Changes nothing.
#
# Usage (from anywhere inside a bench):
#   .frappe-agent/scripts/inspect_app.sh            # list apps and sites
#   .frappe-agent/scripts/inspect_app.sh <app_name> # inspect one app
#   .frappe-agent/scripts/inspect_app.sh <app_name> --filter <word>  # only DocTypes/modules matching <word>
#   .frappe-agent/scripts/inspect_app.sh <app_name> --all            # no output caps
#
# Long lists are capped so large apps do not flood the agent's context; the
# output says how to see the rest.

set -uo pipefail

# Find the bench root: the nearest parent that has both apps/ and sites/.
dir="$(pwd)"
while [ "$dir" != "/" ] && { [ ! -d "$dir/apps" ] || [ ! -d "$dir/sites" ]; }; do
  dir="$(dirname "$dir")"
done
if [ "$dir" = "/" ]; then
  echo "Not inside a bench (no folder with apps/ and sites/ found above $(pwd))." >&2
  exit 1
fi
BENCH="$dir"

echo "== Bench: $BENCH"

if [ $# -eq 0 ]; then
  echo
  echo "== Apps (apps/)"
  for a in "$BENCH"/apps/*/; do
    [ -d "$a" ] || continue
    name="$(basename "$a")"
    if git -C "$a" rev-parse --git-dir >/dev/null 2>&1; then
      branch="$(git -C "$a" symbolic-ref --short HEAD 2>/dev/null || echo detached)"
    else
      branch="not a git repo"
    fi
    echo "  - $name  [branch: $branch]"
  done
  echo
  echo "== Sites (sites/)"
  for s in "$BENCH"/sites/*/; do
    [ -f "$s/site_config.json" ] && echo "  - $(basename "$s")"
  done
  [ -f "$BENCH/sites/apps.txt" ] && { echo; echo "== sites/apps.txt"; sed 's/^/  /' "$BENCH/sites/apps.txt"; }
  echo
  echo "Next: re-run with an app name to inspect it."
  exit 0
fi

APP="$1"; shift
FILTER=""; ALL=0
while [ $# -gt 0 ]; do
  case "$1" in
    --filter) FILTER="${2:?--filter needs a word}"; shift 2 ;;
    --all) ALL=1; shift ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done
CAP=40
APP_DIR="$BENCH/apps/$APP"
PKG="$APP_DIR/$APP"
[ -d "$APP_DIR" ] || { echo "No such app: apps/$APP" >&2; exit 1; }

echo "== App: $APP  ($APP_DIR)"

echo
echo "== Git (this is the repository to branch and commit in)"
if git -C "$APP_DIR" rev-parse --git-dir >/dev/null 2>&1; then
  echo "  branch: $(git -C "$APP_DIR" symbolic-ref --short HEAD 2>/dev/null || echo detached)"
  echo "  remote: $(git -C "$APP_DIR" remote get-url origin 2>/dev/null || echo none)"
  changes="$(git -C "$APP_DIR" status --short | wc -l | tr -d ' ')"
  echo "  uncommitted changes: $changes"
  git -C "$APP_DIR" status --short | head -10 | sed 's/^/    /'
else
  echo "  not a git repository"
fi

echo
echo "== Linting"
if [ -f "$APP_DIR/.pre-commit-config.yaml" ]; then
  echo "  .pre-commit-config.yaml: present"
  if [ -f "$APP_DIR/.git/hooks/pre-commit" ]; then echo "  hook installed: yes"; else echo "  hook installed: NO (user can run: cd apps/$APP && pre-commit install)"; fi
else
  echo "  .pre-commit-config.yaml: absent (use ruff check / ruff format --check if available)"
fi

echo
echo "== Modules (modules.txt)"
if [ -f "$PKG/modules.txt" ]; then
  total="$(grep -c . "$PKG/modules.txt")"
  if [ "$ALL" -eq 1 ] || [ "$total" -le "$CAP" ]; then sed 's/^/  - /' "$PKG/modules.txt"
  else head -n "$CAP" "$PKG/modules.txt" | sed 's/^/  - /'; echo "  ... $((total - CAP)) more (use --all)"; fi
else echo "  none found"; fi

echo
echo "== hooks.py (top-level settings that are set)"
if [ -f "$PKG/hooks.py" ]; then
  hooks_lines="$(grep -nE '^[a-z_]+ *=' "$PKG/hooks.py" | grep -vE '^[0-9]+:(app_name|app_title|app_publisher|app_description|app_email|app_license|app_icon|app_color) ' | cut -c1-110)"
  htotal="$(printf '%s\n' "$hooks_lines" | grep -c . || true)"
  if [ "$htotal" -eq 0 ]; then echo "  none set"
  elif [ "$ALL" -eq 1 ] || [ "$htotal" -le "$CAP" ]; then printf '%s\n' "$hooks_lines" | sed 's/^/  /'
  else printf '%s\n' "$hooks_lines" | head -n "$CAP" | sed 's/^/  /'; echo "  ... $((htotal - CAP)) more (use --all)"; fi
else
  echo "  none found"
fi

echo
echo "== DocTypes (module / name / flags)"
dt_lines=""
while IFS= read -r f; do
  base="$(basename "$f" .json)"
  [ "$(basename "$(dirname "$f")")" = "$base" ] || continue
  module="$(basename "$(dirname "$(dirname "$(dirname "$f")")")")"
  flags=""
  grep -qE '"istable": *1' "$f" && flags="$flags child-table"
  grep -qE '"issingle": *1' "$f" && flags="$flags single"
  grep -qE '"is_submittable": *1' "$f" && flags="$flags submittable"
  grep -qE '"custom": *1' "$f" && flags="$flags custom"
  dt_lines="$dt_lines$module / $base${flags:+  [${flags# }]}"$'\n'
done < <(find "$PKG" -path '*/doctype/*/*.json' -not -path '*/node_modules/*' 2>/dev/null | sort)
dt_lines="${dt_lines%$'\n'}"
if [ -n "$FILTER" ]; then
  dt_lines="$(printf '%s\n' "$dt_lines" | grep -iF -- "$FILTER" || true)"
  echo "  (filtered by: $FILTER)"
fi
dtotal="$(printf '%s' "$dt_lines" | grep -c . || true)"
if [ "$dtotal" -eq 0 ]; then
  echo "  none found"
elif [ "$ALL" -eq 1 ] || [ "$dtotal" -le "$CAP" ]; then
  printf '%s\n' "$dt_lines" | sed 's/^/  - /'
else
  echo "  $dtotal DocTypes. Per module:"
  printf '%s\n' "$dt_lines" | awk -F' / ' '{c[$1]++} END {for (m in c) printf "    %s: %d\n", m, c[m]}' | sort
  echo "  First $((CAP / 2)):"
  printf '%s\n' "$dt_lines" | head -n "$((CAP / 2))" | sed 's/^/    - /'
  echo "  ... use --filter <word> to narrow, or --all to list everything."
fi

echo
echo "== Fixtures"
if [ -d "$PKG/fixtures" ]; then ls "$PKG/fixtures" | sed 's/^/  - /'; else echo "  no fixtures/ folder"; fi

echo
echo "== Patches (patches.txt, last 5 entries)"
if [ -f "$PKG/patches.txt" ]; then
  grep -vE '^\s*(#|$|\[)' "$PKG/patches.txt" | tail -5 | sed 's/^/  /'
else
  echo "  none found"
fi

echo
echo "== Tests"
tests="$(find "$PKG" -name 'test_*.py' -not -path '*/node_modules/*' 2>/dev/null | wc -l | tr -d ' ')"
echo "  test files: $tests"

echo
echo "== Docs"
for f in README.md CHANGELOG.md; do [ -f "$APP_DIR/$f" ] && echo "  $f"; done
true
