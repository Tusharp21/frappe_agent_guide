#!/usr/bin/env bash
#
# Installer for the Frappe AI Dev Template.
#
# Usage (run from your bench root, the folder containing apps/ and sites/):
#   curl -fsSL https://raw.githubusercontent.com/Tusharp21/frappe_agent_guide/master/install.sh | bash
#
# Options (pass after `bash -s --` when piping, or directly when run as a file):
#   -d, --dir <path>     Install into <path> instead of the current directory.
#   -u, --update         Replace template files in an existing .frappe-agent/.
#                        Your config.json, project_knowledge/, tasks/ and audit/ are kept.
#   -f, --force          Like --update, but also resets config.json and
#                        project_knowledge/ (tasks/ and audit/ are never touched).
#   -b, --branch <name>  Install from a branch (default: master).
#       --version <tag>  Install from a release tag instead of a branch.
#       --with-claude    Create CLAUDE.md containing "@AGENTS.md" if it does not exist.
#       --with-copilot   Create .github/copilot-instructions.md pointing to AGENTS.md.
#   Enforcement (all optional; see .frappe-agent/CONFIGURATION.md):
#       --with-git-hooks      pre-push hook in every apps/<app> repo (works for any agent)
#       --with-claude-hooks   .claude/settings.json hooks and .claude/skills/
#       --with-cursor-hooks   .cursor/hooks.json and a .cursorignore block
#       --with-copilot-hooks  .github/hooks/frappe-agent.json
#       --with-all-hooks      all four of the above
#       --source <path>  Install from a local checkout instead of downloading.
#       --dry-run        Print what would change without writing anything.
#   -y, --yes            Do not prompt (e.g. when the target is not a bench).
#   -h, --help           Show this help text.
#
# By default installs exactly two things into the target directory:
#   AGENTS.md        entry file (appended as a marked block if one already exists)
#   .frappe-agent/   rules, docs, workflow, templates, scripts, config
# CLAUDE.md is touched only if it already exists (a marked "@AGENTS.md" block
# is appended) or if --with-claude is given. Files for the --with-* options are
# created only when you ask for them, and existing settings files are never
# overwritten.

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
HOOKS_CLAUDE=0
HOOKS_CURSOR=0
HOOKS_COPILOT=0
HOOKS_GIT=0
DRY_RUN=0
ASSUME_YES=0
SOURCE=""

START_MARK="<!-- frappe-agent:start -->"
END_MARK="<!-- frappe-agent:end -->"

print_help() {
  sed -n '2,/^# overwritten\./p' "$0" | sed 's/^# \{0,1\}//'
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
    --with-git-hooks)     HOOKS_GIT=1; shift ;;
    --with-claude-hooks)  HOOKS_CLAUDE=1; shift ;;
    --with-cursor-hooks)  HOOKS_CURSOR=1; shift ;;
    --with-copilot-hooks) HOOKS_COPILOT=1; shift ;;
    --with-all-hooks)     HOOKS_GIT=1; HOOKS_CLAUDE=1; HOOKS_CURSOR=1; HOOKS_COPILOT=1; shift ;;
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

# upsert_block <dest> <block-file> <replace-existing 0|1> <label>
# Uses the current START_MARK/END_MARK (the .cursorignore block overrides them).
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

# install_json <source> <dest> <label>: create a settings/hooks file; never
# overwrite one that already exists (JSON cannot hold our markers).
install_json() {
  local src="$1" dest="$2" label="$3"
  if [ ! -f "$dest" ]; then
    echo "  + created $label"
    [ -d "$(dirname "$dest")" ] || run mkdir -p "$(dirname "$dest")"
    [ "$DRY_RUN" -eq 1 ] || cp "$src" "$dest"
  elif grep -qF ".frappe-agent/hooks/" "$dest"; then
    echo "  = $label already has the frappe-agent hooks"
  else
    echo "  ! $label already exists and was NOT changed."
    echo "    Merge the entries from .frappe-agent/adapters/${src#*/adapters/} into it by hand."
  fi
}

# Items inside .frappe-agent/ that hold the user's data.
is_user_data() {
  case "$1" in
    audit|tasks) return 0 ;;
    project_knowledge|config.json) [ "$FORCE" -ne 1 ] && return 0 || return 1 ;;
    *) return 1 ;;
  esac
}

# --- .frappe-agent/ -------------------------------------------------------
DEST="$TARGET_DIR/.frappe-agent"
ADAPTERS="$SRC_DIR/.frappe-agent/adapters"
echo "Installing:"
if [ -e "$DEST" ] && [ "$UPDATE" -ne 1 ]; then
  echo "  = .frappe-agent/ already exists (use --update to refresh it; --force also resets config.json and project_knowledge/)"
  REFRESH=0
else
  REFRESH=1
  if [ -e "$DEST" ]; then
    echo "  ~ updating .frappe-agent/ (keeping your config.json, project_knowledge/, tasks/ and audit/)"
    [ "$FORCE" -eq 1 ] && echo "    --force: config.json and project_knowledge/ will be reset"
    for entry in "$DEST"/* "$DEST"/.[!.]*; do
      [ -e "$entry" ] || continue
      is_user_data "$(basename "$entry")" && continue
      run rm -rf "$entry"
    done
  else
    echo "  + .frappe-agent/"
  fi
  run mkdir -p "$DEST"
  if [ "$DRY_RUN" -eq 0 ]; then
    for entry in "$SRC_DIR/.frappe-agent"/* "$SRC_DIR/.frappe-agent"/.[!.]*; do
      [ -e "$entry" ] || continue
      name="$(basename "$entry")"
      # Never overwrite the user's data that already exists.
      if [ -e "$DEST/$name" ] && is_user_data "$name"; then continue; fi
      cp -R "$entry" "$DEST/$name"
    done
    find "$DEST" \( -name ".ruff_cache" -o -name "__pycache__" \) -prune -exec rm -rf {} + 2>/dev/null || true
  fi
fi

# --- AGENTS.md ------------------------------------------------------------
upsert_block "$TARGET_DIR/AGENTS.md" "$SRC_DIR/AGENTS.md" "$REFRESH" "AGENTS.md"

# --- CLAUDE.md ------------------------------------------------------------
printf '%s\n@AGENTS.md\n%s\n' "$START_MARK" "$END_MARK" > "$TMP_DIR/claude-block"
if [ -f "$TARGET_DIR/CLAUDE.md" ] || [ "$WITH_CLAUDE" -eq 1 ]; then
  upsert_block "$TARGET_DIR/CLAUDE.md" "$TMP_DIR/claude-block" "$REFRESH" "CLAUDE.md"
fi

# --- Copilot instructions -------------------------------------------------
if [ "$WITH_COPILOT" -eq 1 ]; then
  printf '%s\nFollow the rules in AGENTS.md at the repository root; all detailed guidance is in .frappe-agent/.\n%s\n' \
    "$START_MARK" "$END_MARK" > "$TMP_DIR/copilot-block"
  upsert_block "$TARGET_DIR/.github/copilot-instructions.md" "$TMP_DIR/copilot-block" "$REFRESH" ".github/copilot-instructions.md"
fi

# --- Enforcement (opt-in) -------------------------------------------------
if [ "$HOOKS_CLAUDE" -eq 1 ]; then
  install_json "$ADAPTERS/claude/settings.json" "$TARGET_DIR/.claude/settings.json" ".claude/settings.json (guard, lint and audit hooks)"
  # Skills that older versions installed and this version no longer ships.
  if [ "$UPDATE" -eq 1 ]; then
    for old in frappe-analyze frappe-implement; do
      if [ -d "$TARGET_DIR/.claude/skills/$old" ]; then
        echo "  - removed outdated .claude/skills/$old"
        run rm -rf "$TARGET_DIR/.claude/skills/$old"
      fi
    done
  fi
  for skill in "$ADAPTERS"/claude/skills/*/; do
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

if [ "$HOOKS_CURSOR" -eq 1 ]; then
  install_json "$ADAPTERS/cursor/hooks.json" "$TARGET_DIR/.cursor/hooks.json" ".cursor/hooks.json (guard and audit hooks)"
  ( START_MARK="# frappe-agent:start"; END_MARK="# frappe-agent:end"
    upsert_block "$TARGET_DIR/.cursorignore" "$ADAPTERS/cursor/cursorignore" "$REFRESH" ".cursorignore" )
fi

if [ "$HOOKS_COPILOT" -eq 1 ]; then
  install_json "$ADAPTERS/copilot/frappe-agent.json" "$TARGET_DIR/.github/hooks/frappe-agent.json" ".github/hooks/frappe-agent.json (guard and audit hooks)"
fi

if [ "$HOOKS_GIT" -eq 1 ]; then
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "  [dry-run] would install the pre-push hook into each git repo under apps/"
  elif [ -d "$TARGET_DIR/apps" ]; then
    echo "  git pre-push hooks (apps/*):"
    bash "$DEST/scripts/install_git_hooks.sh" || true
  else
    echo "  ! no apps/ folder here; run .frappe-agent/scripts/install_git_hooks.sh from your bench later"
  fi
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
echo "  - Edit .frappe-agent/config.json: set environments.production to your real"
echo "    production site names and hosts (guide: .frappe-agent/CONFIGURATION.md)."
echo "  - Start your AI agent from ${TARGET_DIR} and ask it to read AGENTS.md."
if [ "$HOOKS_CLAUDE$HOOKS_CURSOR$HOOKS_COPILOT" != "000" ]; then
  echo "  - Restart your agent so it loads the hooks, then try a blocked command"
  echo "    (e.g. ask it to 'cat .env') to confirm enforcement works."
fi
echo "  - Linting: pre-commit is per app. Run: cd apps/<app_name> && pre-commit install"
