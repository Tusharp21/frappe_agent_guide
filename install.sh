#!/usr/bin/env bash
#
# Installer for the Frappe AI Dev Template.
#
# Usage (run from your bench root, the folder containing apps/ and sites/):
#   curl -fsSL https://raw.githubusercontent.com/Tusharp21/frappe_agent_guide/master/install.sh | bash
#
# Options (pass after `bash -s --` when piping, or directly when run as a file):
#   -d, --dir <path>     Install into <path> instead of the current directory.
#   -u, --update         Replace template files in an existing .frappe-agent/
#                        (project_knowledge/ is preserved).
#   -f, --force          Like --update, but also replaces project_knowledge/.
#   -b, --branch <name>  Install from a branch (default: master).
#       --version <tag>  Install from a release tag instead of a branch.
#       --with-claude    Create CLAUDE.md containing "@AGENTS.md" if it does not exist.
#       --with-copilot   Create .github/copilot-instructions.md pointing to AGENTS.md.
#       --with-claude-hooks  Claude Code only: add .claude/settings.json (hooks that block
#                        unsafe git commands and lint edited Python) and .claude/skills/.
#       --source <path>  Install from a local checkout instead of downloading.
#       --dry-run        Print what would change without writing anything.
#   -y, --yes            Do not prompt (e.g. when the target is not a bench).
#   -h, --help           Show this help text.
#
# Installs exactly two things into the target directory:
#   AGENTS.md        entry file (appended as a marked block if one already exists)
#   .frappe-agent/   rules, docs, workflow, templates, project knowledge
# CLAUDE.md is touched only if it already exists (a marked "@AGENTS.md" block
# is appended) or if --with-claude is given. Nothing else is modified.

set -euo pipefail

REPO_OWNER="Tusharp21"
REPO_NAME="frappe_agent_guide"
REF_KIND="heads"
REF="master"
TARGET_DIR="$(pwd)"
UPDATE=0
FORCE=0
WITH_CLAUDE=0
WITH_COPILOT=0
WITH_HOOKS=0
DRY_RUN=0
ASSUME_YES=0
SOURCE=""

START_MARK="<!-- frappe-agent:start -->"
END_MARK="<!-- frappe-agent:end -->"

print_help() {
  sed -n '2,28p' "$0" | sed 's/^# \{0,1\}//'
}

while [ $# -gt 0 ]; do
  case "$1" in
    -d|--dir)      TARGET_DIR="${2:?--dir needs a path}"; shift 2 ;;
    -u|--update)   UPDATE=1; shift ;;
    -f|--force)    FORCE=1; UPDATE=1; shift ;;
    -b|--branch)   REF_KIND="heads"; REF="${2:?--branch needs a name}"; shift 2 ;;
    --version)     REF_KIND="tags"; REF="${2:?--version needs a tag}"; shift 2 ;;
    --with-claude) WITH_CLAUDE=1; shift ;;
    --with-copilot) WITH_COPILOT=1; shift ;;
    --with-claude-hooks) WITH_HOOKS=1; shift ;;
    --source)      SOURCE="${2:?--source needs a path}"; shift 2 ;;
    --dry-run)     DRY_RUN=1; shift ;;
    -y|--yes)      ASSUME_YES=1; shift ;;
    -h|--help)     print_help; exit 0 ;;
    *) echo "Unknown option: $1" >&2; print_help; exit 1 ;;
  esac
done

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

run() { if [ "$DRY_RUN" -eq 1 ]; then echo "  [dry-run] $*"; else "$@"; fi; }

# --- locate the template payload ------------------------------------------
if [ -n "$SOURCE" ]; then
  SRC_DIR="$(cd "$SOURCE" && pwd)"
  [ -d "$SRC_DIR/template" ] && SRC_DIR="$SRC_DIR/template"
else
  command -v curl >/dev/null 2>&1 || { echo "Error: curl is required but not installed." >&2; exit 1; }
  command -v tar  >/dev/null 2>&1 || { echo "Error: tar is required but not installed." >&2; exit 1; }
  TARBALL_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}/archive/refs/${REF_KIND}/${REF}.tar.gz"
  echo "Downloading ${REPO_OWNER}/${REPO_NAME}@${REF}..."
  curl -fsSL "$TARBALL_URL" -o "$TMP_DIR/template.tar.gz" \
    || { echo "Error: failed to download ${TARBALL_URL}" >&2; exit 1; }
  tar -xzf "$TMP_DIR/template.tar.gz" -C "$TMP_DIR"
  SRC_DIR="$(find "$TMP_DIR" -maxdepth 1 -type d -name "${REPO_NAME}-*" | head -n1)/template"
fi
[ -f "$SRC_DIR/AGENTS.md" ] && [ -d "$SRC_DIR/.frappe-agent" ] \
  || { echo "Error: template contents not found in ${SRC_DIR}." >&2; exit 1; }

mkdir -p "$TARGET_DIR"
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

echo "Frappe AI Dev Template installer"
echo "  Destination: ${TARGET_DIR}"
[ "$DRY_RUN" -eq 1 ] && echo "  Mode:        dry run (nothing will be written)"
echo

# --- bench check ----------------------------------------------------------
if [ ! -d "$TARGET_DIR/apps" ] || [ ! -d "$TARGET_DIR/sites" ]; then
  echo "Warning: ${TARGET_DIR} does not look like a bench root (no apps/ and sites/)."
  if [ "$ASSUME_YES" -ne 1 ]; then
    if { : </dev/tty; } 2>/dev/null; then
      read -r -p "Install here anyway? [y/N] " reply </dev/tty
      case "$reply" in y|Y|yes|YES) ;; *) echo "Aborted."; exit 0 ;; esac
    else
      echo "No TTY for confirmation. Re-run with --yes, or use --dir <bench root>." >&2
      exit 1
    fi
  fi
fi

# --- helpers --------------------------------------------------------------
has_block() { [ -f "$1" ] && grep -qF "$START_MARK" "$1"; }

# Print file contents with the marked block removed.
strip_block() {
  awk -v s="$START_MARK" -v e="$END_MARK" '
    index($0, s) { skip = 1 }
    !skip { print }
    index($0, e) { skip = 0 }
  ' "$1"
}

# upsert_block <dest> <block-file> <replace-existing 0|1> <label>
upsert_block() {
  local dest="$1" block="$2" replace="$3" label="$4"
  if [ ! -f "$dest" ]; then
    echo "  + created $label"
    [ -d "$(dirname "$dest")" ] || run mkdir -p "$(dirname "$dest")"
    [ "$DRY_RUN" -eq 1 ] || cp "$block" "$dest"
  elif has_block "$dest"; then
    if [ "$replace" -eq 1 ]; then
      echo "  ~ updated block in $label"
      if [ "$DRY_RUN" -eq 0 ]; then
        awk -v s="$START_MARK" -v e="$END_MARK" -v blk="$block" '
          index($0, s) { while ((getline line < blk) > 0) print line; skip = 1 }
          !skip { print }
          index($0, e) { skip = 0 }
        ' "$dest" > "$TMP_DIR/upsert.out" && cat "$TMP_DIR/upsert.out" > "$dest"
      fi
    else
      echo "  = $label already has the block (use --update to refresh it)"
    fi
  else
    echo "  + appended block to existing $label"
    if [ "$DRY_RUN" -eq 0 ]; then
      { [ -s "$dest" ] && printf '\n'; cat "$block"; } >> "$dest"
    fi
  fi
}

# --- .frappe-agent/ -------------------------------------------------------
DEST="$TARGET_DIR/.frappe-agent"
echo "Installing:"
if [ -e "$DEST" ] && [ "$UPDATE" -ne 1 ]; then
  echo "  = .frappe-agent/ already exists (use --update to refresh it, --force to also reset project_knowledge/)"
  REFRESH_AGENTS=0
else
  REFRESH_AGENTS=1
  if [ -e "$DEST" ]; then
    echo "  ~ updating .frappe-agent/"
    if [ "$FORCE" -eq 1 ]; then
      run rm -rf "$DEST"
    else
      for entry in "$DEST"/* "$DEST"/.[!.]*; do
        [ -e "$entry" ] || continue
        [ "$(basename "$entry")" = "project_knowledge" ] && continue
        run rm -rf "$entry"
      done
    fi
  else
    echo "  + .frappe-agent/"
  fi
  run mkdir -p "$DEST"
  if [ "$DRY_RUN" -eq 0 ]; then
    for entry in "$SRC_DIR/.frappe-agent"/* "$SRC_DIR/.frappe-agent"/.[!.]*; do
      [ -e "$entry" ] || continue
      name="$(basename "$entry")"
      # Keep the user's project knowledge on --update.
      if [ "$name" = "project_knowledge" ] && [ -d "$DEST/project_knowledge" ]; then
        continue
      fi
      cp -R "$entry" "$DEST/$name"
    done
  fi
fi

# --- AGENTS.md ------------------------------------------------------------
upsert_block "$TARGET_DIR/AGENTS.md" "$SRC_DIR/AGENTS.md" "$REFRESH_AGENTS" "AGENTS.md"

# --- CLAUDE.md ------------------------------------------------------------
printf '%s\n@AGENTS.md\n%s\n' "$START_MARK" "$END_MARK" > "$TMP_DIR/claude-block"
if [ -f "$TARGET_DIR/CLAUDE.md" ] || [ "$WITH_CLAUDE" -eq 1 ]; then
  upsert_block "$TARGET_DIR/CLAUDE.md" "$TMP_DIR/claude-block" "$REFRESH_AGENTS" "CLAUDE.md"
fi

# --- Copilot --------------------------------------------------------------
if [ "$WITH_COPILOT" -eq 1 ]; then
  printf '%s\nFollow the rules in AGENTS.md at the repository root; all detailed guidance is in .frappe-agent/.\n%s\n' \
    "$START_MARK" "$END_MARK" > "$TMP_DIR/copilot-block"
  upsert_block "$TARGET_DIR/.github/copilot-instructions.md" "$TMP_DIR/copilot-block" "$REFRESH_AGENTS" ".github/copilot-instructions.md"
fi

# --- Claude Code hooks and skills (opt-in) --------------------------------
if [ "$WITH_HOOKS" -eq 1 ]; then
  ADAPTER="$SRC_DIR/.frappe-agent/adapters/claude"
  SETTINGS="$TARGET_DIR/.claude/settings.json"
  if [ ! -f "$SETTINGS" ]; then
    echo "  + created .claude/settings.json (guard and lint hooks)"
    [ -d "$TARGET_DIR/.claude" ] || run mkdir -p "$TARGET_DIR/.claude"
    [ "$DRY_RUN" -eq 1 ] || cp "$ADAPTER/settings.json" "$SETTINGS"
  elif grep -qF ".frappe-agent/hooks/guard.sh" "$SETTINGS"; then
    echo "  = .claude/settings.json already has the hooks"
  else
    echo "  ! .claude/settings.json already exists and was NOT changed."
    echo "    Merge the \"hooks\" entries from .frappe-agent/adapters/claude/settings.json into it by hand."
  fi
  for skill in "$ADAPTER"/skills/*/; do
    name="$(basename "$skill")"
    dest_skill="$TARGET_DIR/.claude/skills/$name"
    if [ -e "$dest_skill" ] && [ "$UPDATE" -ne 1 ]; then
      echo "  = .claude/skills/$name already exists (use --update to refresh)"
    else
      echo "  + .claude/skills/$name"
      run mkdir -p "$TARGET_DIR/.claude/skills"
      run rm -rf "$dest_skill"
      [ "$DRY_RUN" -eq 1 ] || cp -R "$skill" "$dest_skill"
    fi
  done
fi

# --- legacy layout notice -------------------------------------------------
legacy=()
for item in FRAPPE_DEVELOPMENT.md GIT_WORKFLOW.md workflow templates; do
  [ -e "$TARGET_DIR/$item" ] && legacy+=("$item")
done
if [ -e "$TARGET_DIR/docs/01-architecture-and-bench.md" ]; then legacy+=("docs"); fi
if [ "${#legacy[@]}" -gt 0 ]; then
  echo
  echo "Note: an older root-level install was detected. These are now unused and can be"
  echo "deleted by hand once you have checked they hold no local changes:"
  printf '  - %s\n' "${legacy[@]}"
  echo "  (and .pre-commit-config.yaml, if it came from the old template)"
fi

echo
echo "Done. Next steps:"
echo "  - Start your AI agent from ${TARGET_DIR} and ask it to read AGENTS.md."
[ "$WITH_HOOKS" -eq 1 ] && echo "  - Claude Code: hooks and skills are in .claude/. Restart Claude Code (or run /hooks) to load them."
echo "  - Linting: pre-commit is per app. Run: cd apps/<app_name> && pre-commit install"
