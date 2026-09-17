#!/usr/bin/env bash
#
# Installer for the Frappe AI Dev Template.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/Tusharp21/frappe_agent_guide/master/install.sh | bash
#
# Options (pass after `bash -s --` when piping, or directly when run as a file):
#   -d, --dir <path>   Install into <path> instead of the current directory.
#   -f, --force         Overwrite files/folders that already exist at the destination.
#   -b, --branch <name> Install from a specific branch/tag (default: master).
#   -h, --help          Show this help text.
#
# The script downloads a tarball of the repository and copies only the
# template files (AGENTS.md, FRAPPE_DEVELOPMENT.md, docs/, GIT_WORKFLOW.md,
# workflow/, templates/, LICENSE) into the target directory. It never
# touches unrelated files in your project, and by default it will not
# overwrite anything that already exists at the destination.

set -euo pipefail

REPO_OWNER="Tusharp21"
REPO_NAME="frappe_agent_guide"
BRANCH="master"
TARGET_DIR="$(pwd)"
FORCE=0

print_help() {
  sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'
}

while [ $# -gt 0 ]; do
  case "$1" in
    -d|--dir)
      TARGET_DIR="$2"
      shift 2
      ;;
    -f|--force)
      FORCE=1
      shift
      ;;
    -b|--branch)
      BRANCH="$2"
      shift 2
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

command -v curl >/dev/null 2>&1 || { echo "Error: curl is required but not installed." >&2; exit 1; }
command -v tar  >/dev/null 2>&1 || { echo "Error: tar is required but not installed." >&2; exit 1; }

mkdir -p "$TARGET_DIR"
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

TARBALL_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}/archive/refs/heads/${BRANCH}.tar.gz"

echo "Frappe AI Dev Template installer"
echo "  Source:      ${REPO_OWNER}/${REPO_NAME}@${BRANCH}"
echo "  Destination: ${TARGET_DIR}"
echo

echo "Downloading template..."
if ! curl -fsSL "$TARBALL_URL" -o "$TMP_DIR/template.tar.gz"; then
  echo "Error: failed to download ${TARBALL_URL}" >&2
  exit 1
fi

tar -xzf "$TMP_DIR/template.tar.gz" -C "$TMP_DIR"
SRC_DIR="$(find "$TMP_DIR" -maxdepth 1 -type d -name "${REPO_NAME}-*" | head -n1)"
if [ -z "$SRC_DIR" ]; then
  echo "Error: could not locate extracted template contents." >&2
  exit 1
fi

ITEMS=(
  "AGENTS.md"
  "FRAPPE_DEVELOPMENT.md"
  "GIT_WORKFLOW.md"
  "LICENSE"
  "README.md"
  "docs"
  "workflow"
  "templates"
)

copied=()
skipped=()

for item in "${ITEMS[@]}"; do
  src="$SRC_DIR/$item"
  dest="$TARGET_DIR/$item"

  [ -e "$src" ] || continue

  if [ -e "$dest" ] && [ "$FORCE" -ne 1 ]; then
    skipped+=("$item")
    continue
  fi

  rm -rf "$dest"
  cp -R "$src" "$dest"
  copied+=("$item")
done

echo
if [ "${#copied[@]}" -gt 0 ]; then
  echo "Installed:"
  printf '  + %s\n' "${copied[@]}"
fi

if [ "${#skipped[@]}" -gt 0 ]; then
  echo
  echo "Skipped (already exist at destination, not overwritten):"
  printf '  - %s\n' "${skipped[@]}"
  echo
  echo "Re-run with --force to overwrite these files, or remove/rename them first."
fi

echo
echo "Done. Next step: point your AI agent at this project and ask it to read"
echo "AGENTS.md (and README.md) before starting work."
