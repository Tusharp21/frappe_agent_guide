#!/usr/bin/env bash
#
# Uninstaller for the Frappe AI Dev Template.
#
# Usage (run from the folder you installed into):
#   curl -fsSL https://raw.githubusercontent.com/Tusharp21/frappe_agent_guide/master/uninstall.sh | bash
#
# Options (pass after `bash -s --` when piping, or directly when run as a file):
#   -d, --dir <path>   Uninstall from <path> instead of the current directory.
#   -y, --yes          Skip the confirmation prompt (needed for non-interactive shells).
#       --keep-knowledge  Keep .frappe-agent/project_knowledge/ (your notes and decisions).
#   -h, --help         Show this help text.
#
# Removes the .frappe-agent/ folder and the marked "frappe-agent" block from
# AGENTS.md, CLAUDE.md and .github/copilot-instructions.md. A file is deleted
# only if nothing but that block was in it. Anything else you wrote in those
# files is left untouched. Also removes the frappe-* skills in .claude/skills/
# and .claude/settings.json, but only if it is unmodified from the template's.

set -euo pipefail

TARGET_DIR="$(pwd)"
ASSUME_YES=0
KEEP_KNOWLEDGE=0

START_MARK="<!-- frappe-agent:start -->"
END_MARK="<!-- frappe-agent:end -->"

print_help() {
  sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'
}

while [ $# -gt 0 ]; do
  case "$1" in
    -d|--dir)  TARGET_DIR="${2:?--dir needs a path}"; shift 2 ;;
    -y|--yes)  ASSUME_YES=1; shift ;;
    --keep-knowledge) KEEP_KNOWLEDGE=1; shift ;;
    -h|--help) print_help; exit 0 ;;
    *) echo "Unknown option: $1" >&2; print_help; exit 1 ;;
  esac
done

TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

has_block() { [ -f "$1" ] && grep -qF "$START_MARK" "$1"; }

strip_block() {
  awk -v s="$START_MARK" -v e="$END_MARK" '
    index($0, s) { skip = 1 }
    !skip { print }
    index($0, e) { skip = 0 }
  ' "$1"
}

SKILL_NAMES=("frappe-analyze" "frappe-implement" "frappe-review")
CLAUDE_ADAPTER="$TARGET_DIR/.frappe-agent/adapters/claude/settings.json"
claude_settings="$TARGET_DIR/.claude/settings.json"
# settings.json is removed only if it is byte-identical to what we installed.
remove_settings=0
settings_note=0
if [ -f "$claude_settings" ] && grep -qF ".frappe-agent/hooks/guard.sh" "$claude_settings"; then
  if [ -f "$CLAUDE_ADAPTER" ] && cmp -s "$claude_settings" "$CLAUDE_ADAPTER"; then
    remove_settings=1
  else
    settings_note=1
  fi
fi
skills_present=()
for n in "${SKILL_NAMES[@]}"; do
  [ -d "$TARGET_DIR/.claude/skills/$n" ] && skills_present+=("$n")
done

FILES=("AGENTS.md" "CLAUDE.md" ".github/copilot-instructions.md")
block_files=()
for f in "${FILES[@]}"; do
  has_block "$TARGET_DIR/$f" && block_files+=("$f")
done
folder_present=0
[ -d "$TARGET_DIR/.frappe-agent" ] && folder_present=1

if [ "$folder_present" -eq 0 ] && [ "${#block_files[@]}" -eq 0 ] \
   && [ "$remove_settings" -eq 0 ] && [ "$settings_note" -eq 0 ] && [ "${#skills_present[@]}" -eq 0 ]; then
  echo "Nothing to remove — no template files found in: $TARGET_DIR"
  exit 0
fi

echo "Frappe AI Dev Template uninstaller"
echo "  Target: $TARGET_DIR"
echo
echo "The following will be removed:"
if [ "$folder_present" -eq 1 ]; then
  if [ "$KEEP_KNOWLEDGE" -eq 1 ]; then
    echo "  - .frappe-agent/ (except project_knowledge/)"
  else
    echo "  - .frappe-agent/ (including project_knowledge/)"
  fi
fi
for f in "${block_files[@]}"; do
  echo "  - frappe-agent block in $f"
done
[ "$remove_settings" -eq 1 ] && echo "  - .claude/settings.json (unmodified copy of the template's)"
for n in "${skills_present[@]}"; do echo "  - .claude/skills/$n"; done
echo

if [ "$ASSUME_YES" -ne 1 ]; then
  if { : </dev/tty; } 2>/dev/null; then
    read -r -p "Proceed? [y/N] " reply </dev/tty
  else
    echo "No TTY available for confirmation. Re-run with --yes to proceed non-interactively." >&2
    exit 1
  fi
  case "$reply" in
    y|Y|yes|YES) ;;
    *) echo "Aborted. Nothing was deleted."; exit 0 ;;
  esac
fi

for f in "${block_files[@]}"; do
  path="$TARGET_DIR/$f"
  strip_block "$path" > "$TMP_DIR/stripped"
  if [ -z "$(tr -d '[:space:]' < "$TMP_DIR/stripped")" ]; then
    rm -f "$path"
    echo "  - removed $f"
  else
    # Drop trailing blank lines left behind by the removed block.
    awk '{ lines[NR] = $0 } END { n = NR; while (n > 0 && lines[n] ~ /^[[:space:]]*$/) n--; for (i = 1; i <= n; i++) print lines[i] }' \
      "$TMP_DIR/stripped" > "$path"
    echo "  ~ removed block from $f (rest of the file kept)"
  fi
done

if [ "$remove_settings" -eq 1 ]; then
  rm -f "$claude_settings"
  echo "  - removed .claude/settings.json"
fi
if [ "$settings_note" -eq 1 ]; then
  echo "  ! .claude/settings.json was edited after install, so it was left alone."
  echo "    Remove the .frappe-agent/hooks/guard.sh and lint.sh entries from it by hand."
fi
for n in "${skills_present[@]}"; do
  rm -rf "${TARGET_DIR:?}/.claude/skills/$n"
  echo "  - removed .claude/skills/$n"
done
rmdir "$TARGET_DIR/.claude/skills" "$TARGET_DIR/.claude" 2>/dev/null || true

if [ "$folder_present" -eq 1 ]; then
  if [ "$KEEP_KNOWLEDGE" -eq 1 ] && [ -d "$TARGET_DIR/.frappe-agent/project_knowledge" ]; then
    for entry in "$TARGET_DIR/.frappe-agent"/* "$TARGET_DIR/.frappe-agent"/.[!.]*; do
      [ -e "$entry" ] || continue
      [ "$(basename "$entry")" = "project_knowledge" ] && continue
      rm -rf "$entry"
    done
    echo "  - removed .frappe-agent/ contents (kept project_knowledge/)"
  else
    rm -rf "${TARGET_DIR:?}/.frappe-agent"
    echo "  - removed .frappe-agent/"
  fi
fi

echo
echo "Done. The Frappe AI Dev Template has been removed from: $TARGET_DIR"
