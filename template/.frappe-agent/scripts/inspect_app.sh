#!/usr/bin/env bash
#
# Read-only discovery for a Frappe bench. Prints what an agent needs to know
# before planning a change. Changes nothing.
#
# Usage (from anywhere inside a bench):
#   .frappe-agent/scripts/inspect_app.sh            # list apps and sites
#   .frappe-agent/scripts/inspect_app.sh <app_name> # inspect one app

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

APP="$1"
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
[ -f "$PKG/modules.txt" ] && sed 's/^/  - /' "$PKG/modules.txt" || echo "  none found"

echo
echo "== hooks.py (top-level settings that are set)"
if [ -f "$PKG/hooks.py" ]; then
  grep -nE '^[a-z_]+ *=' "$PKG/hooks.py" | grep -vE '^[0-9]+:(app_name|app_title|app_publisher|app_description|app_email|app_license|app_icon|app_color) ' | sed 's/^/  /' | cut -c1-110
else
  echo "  none found"
fi

echo
echo "== DocTypes (module / name / flags)"
count=0
while IFS= read -r f; do
  base="$(basename "$f" .json)"
  [ "$(basename "$(dirname "$f")")" = "$base" ] || continue
  module="$(basename "$(dirname "$(dirname "$(dirname "$f")")")")"
  flags=""
  grep -qE '"istable": *1' "$f" && flags="$flags child-table"
  grep -qE '"issingle": *1' "$f" && flags="$flags single"
  grep -qE '"is_submittable": *1' "$f" && flags="$flags submittable"
  grep -qE '"custom": *1' "$f" && flags="$flags custom"
  echo "  - $module / $base${flags:+  [${flags# }]}"
  count=$((count + 1))
done < <(find "$PKG" -path '*/doctype/*/*.json' -not -path '*/node_modules/*' 2>/dev/null | sort)
[ "$count" -eq 0 ] && echo "  none found"

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
