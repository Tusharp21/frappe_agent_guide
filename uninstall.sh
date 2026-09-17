#!/usr/bin/env bash
#
# Uninstaller for the Frappe AI Dev Template.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/Tusharp21/frappe_agent_guide/master/uninstall.sh | bash
#
# Options (pass after `bash -s --` when piping, or directly when run as a file):
#   -d, --dir <path>   Uninstall from <path> instead of the current directory.
#   -y, --yes           Skip the confirmation prompt (needed for non-interactive shells).
#   -h, --help          Show this help text.
#
# This removes only the files/folders that install.sh creates:
# AGENTS.md, FRAPPE_DEVELOPMENT.md, GIT_WORKFLOW.md, LICENSE, docs/,
# workflow/, templates/. It never touches anything else in your project,
# and it will not delete anything unless you confirm (or pass --yes).
# README.md is left in place, since projects often customize it after install.

set -euo pipefail

TARGET_DIR="$(pwd)"
ASSUME_YES=0

print_help() {
  sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'
}

while [ $# -gt 0 ]; do
  case "$1" in
    -d|--dir)
      TARGET_DIR="$2"
      shift 2
      ;;
    -y|--yes)
      ASSUME_YES=1
      shift
      ;;
    -h|--help)
      print_help
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      print_help
      exit 1
      ;;
  esac
done

TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

ITEMS=(
  "AGENTS.md"
  "FRAPPE_DEVELOPMENT.md"
  "GIT_WORKFLOW.md"
  "LICENSE"
  "docs"
  "workflow"
  "templates"
)

present=()
for item in "${ITEMS[@]}"; do
  [ -e "$TARGET_DIR/$item" ] && present+=("$item")
done

if [ "${#present[@]}" -eq 0 ]; then
  echo "Nothing to remove — no template files found in: $TARGET_DIR"
  exit 0
fi

echo "Frappe AI Dev Template uninstaller"
echo "  Target: $TARGET_DIR"
echo
echo "The following will be permanently deleted:"
printf '  - %s\n' "${present[@]}"
echo
echo "Note: README.md is intentionally left in place (projects often customize it)."
echo

if [ "$ASSUME_YES" -ne 1 ]; then
  if [ -r /dev/tty ]; then
    read -r -p "Proceed with deletion? [y/N] " reply </dev/tty
  else
    echo "No TTY available for confirmation. Re-run with --yes to proceed non-interactively." >&2
    exit 1
  fi
  case "$reply" in
    y|Y|yes|YES) ;;
    *) echo "Aborted. Nothing was deleted." ; exit 0 ;;
  esac
fi

for item in "${present[@]}"; do
  rm -rf "${TARGET_DIR:?}/$item"
  echo "  - removed $item"
done

echo
echo "Done. The Frappe AI Dev Template has been removed from: $TARGET_DIR"
