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
#       --keep-knowledge  Keep your data in .frappe-agent/: config.json,
#                      policy.json, project_knowledge/, tasks/ (task history) and audit/.
#   -h, --help         Show this help text.
#
# Removes the .frappe-agent/ folder and the marked "frappe-agent" block from
# AGENTS.md, CLAUDE.md, .github/copilot-instructions.md and .cursorignore. A
# file is deleted only if nothing but that block was in it. Also removes what
# the --with-* options installed: the frappe-* skills in .claude/skills/, the
# pre-push hooks in apps/*/.git/hooks, and the hook files
# (.claude/settings.json, .cursor/hooks.json, .github/hooks/frappe-agent.json),
# but only if they are unmodified copies of the template's. Anything else you
# wrote is left untouched.
#
# NOTE: without --keep-knowledge, tasks/ (your task history) and audit/ are
# deleted too. A history.path outside .frappe-agent/ is never touched.

set -euo pipefail

TARGET_DIR="$(pwd)"
ASSUME_YES=0
KEEP_KNOWLEDGE=0

print_help() {
  sed -n '2,/^# NOTE:/p' "$0" | sed 's/^# \{0,1\}//'
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

FA="$TARGET_DIR/.frappe-agent"
MD_START="<!-- frappe-agent:start -->"; MD_END="<!-- frappe-agent:end -->"
IG_START="# frappe-agent:start";        IG_END="# frappe-agent:end"

# strip_block <file> <start> <end>: print the file without the marked block.
strip_block() {
  awk -v s="$2" -v e="$3" '
    index($0, s) { skip = 1 }
    !skip { print }
    index($0, e) { skip = 0 }
  ' "$1"
}
has_block() { [ -f "$1" ] && grep -qF "$2" "$1"; }

# --- marked-block files: file|start|end ------------------------------------
BLOCK_SPECS=(
  "AGENTS.md|$MD_START|$MD_END"
  "CLAUDE.md|$MD_START|$MD_END"
  ".github/copilot-instructions.md|$MD_START|$MD_END"
  ".cursorignore|$IG_START|$IG_END"
)
block_specs_present=()
for spec in "${BLOCK_SPECS[@]}"; do
  IFS='|' read -r f s e <<<"$spec"
  has_block "$TARGET_DIR/$f" "$s" && block_specs_present+=("$spec")
done

# --- whole files that must be unmodified copies: dest|adapter source -------
JSON_SPECS=(
  ".claude/settings.json|claude/settings.json"
  ".cursor/hooks.json|cursor/hooks.json"
  ".github/hooks/frappe-agent.json|copilot/frappe-agent.json"
)
json_remove=(); json_note=()
for spec in "${JSON_SPECS[@]}"; do
  IFS='|' read -r dest adapter <<<"$spec"
  path="$TARGET_DIR/$dest"
  if [ -f "$path" ] && grep -qF ".frappe-agent/hooks/" "$path"; then
    if [ -f "$FA/adapters/$adapter" ] && cmp -s "$path" "$FA/adapters/$adapter"; then
      json_remove+=("$dest")
    else
      json_note+=("$dest")
    fi
  fi
done

SKILL_NAMES=("frappe-task" "frappe-review" "frappe-analyze" "frappe-implement")  # last two: older versions
skills_present=()
for n in "${SKILL_NAMES[@]}"; do
  [ -d "$TARGET_DIR/.claude/skills/$n" ] && skills_present+=("$n")
done

git_hook_repos=()
if [ -d "$TARGET_DIR/apps" ]; then
  for d in "$TARGET_DIR"/apps/*/; do
    [ -d "$d" ] || continue
    hp="$(git -C "$d" rev-parse --git-path hooks 2>/dev/null)" || continue
    case "$hp" in /*) ;; *) hp="$d$hp" ;; esac
    if [ -f "$hp/pre-push" ] && grep -qF "# frappe-agent pre-push" "$hp/pre-push"; then
      git_hook_repos+=("$(basename "$d")|$hp/pre-push")
    fi
  done
fi

folder_present=0
[ -d "$FA" ] && folder_present=1

if [ "$folder_present" -eq 0 ] && [ "${#block_specs_present[@]}" -eq 0 ] && [ "${#json_remove[@]}" -eq 0 ] \
   && [ "${#json_note[@]}" -eq 0 ] && [ "${#skills_present[@]}" -eq 0 ] && [ "${#git_hook_repos[@]}" -eq 0 ]; then
  echo "Nothing to remove — no template files found in: $TARGET_DIR"
  exit 0
fi

echo "Frappe AI Dev Template uninstaller"
echo "  Target: $TARGET_DIR"
echo
echo "The following will be removed:"
if [ "$folder_present" -eq 1 ]; then
  if [ "$KEEP_KNOWLEDGE" -eq 1 ]; then
    echo "  - .frappe-agent/ (except config.json, policy.json, project_knowledge/, tasks/ and audit/)"
  else
    echo "  - .frappe-agent/ (including config.json, policy.json, project_knowledge/, the tasks/ history and audit/)"
  fi
fi
for spec in "${block_specs_present[@]}"; do echo "  - frappe-agent block in ${spec%%|*}"; done
for d in "${json_remove[@]}"; do echo "  - $d (unmodified copy of the template's)"; done
for n in "${skills_present[@]}"; do echo "  - .claude/skills/$n"; done
for r in "${git_hook_repos[@]}"; do echo "  - pre-push hook in apps/${r%%|*}"; done
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

for spec in "${block_specs_present[@]}"; do
  IFS='|' read -r f s e <<<"$spec"
  path="$TARGET_DIR/$f"
  strip_block "$path" "$s" "$e" > "$TMP_DIR/stripped"
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

for d in "${json_remove[@]}"; do
  rm -f "$TARGET_DIR/$d"
  echo "  - removed $d"
done
for d in "${json_note[@]}"; do
  echo "  ! $d was edited after install, so it was left alone."
  echo "    Remove the .frappe-agent/hooks/ entries from it by hand."
done
for n in "${skills_present[@]}"; do
  rm -rf "${TARGET_DIR:?}/.claude/skills/$n"
  echo "  - removed .claude/skills/$n"
done
for r in "${git_hook_repos[@]}"; do
  rm -f "${r#*|}"
  echo "  - removed pre-push hook in apps/${r%%|*}"
done
rmdir "$TARGET_DIR/.claude/skills" "$TARGET_DIR/.claude" "$TARGET_DIR/.cursor" \
      "$TARGET_DIR/.github/hooks" "$TARGET_DIR/.github" 2>/dev/null || true

if [ "$folder_present" -eq 1 ]; then
  if [ "$KEEP_KNOWLEDGE" -eq 1 ]; then
    for entry in "$FA"/* "$FA"/.[!.]*; do
      [ -e "$entry" ] || continue
      case "$(basename "$entry")" in project_knowledge|tasks|audit|config.json|policy.json) continue ;; esac
      rm -rf "$entry"
    done
    echo "  - removed .frappe-agent/ contents (kept config.json, policy.json, project_knowledge/, tasks/ and audit/)"
  else
    rm -rf "${TARGET_DIR:?}/.frappe-agent"
    echo "  - removed .frappe-agent/"
  fi
fi

echo
echo "Done. The Frappe AI Dev Template has been removed from: $TARGET_DIR"
