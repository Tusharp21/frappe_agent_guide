#!/usr/bin/env bash
#
# Install the frappe-agent pre-push hook into app repositories. Because it
# runs inside Git, it protects against every AI agent (Claude Code, Cursor,
# Copilot, Codex), not just the ones with hook support. It blocks pushes to
# main/master, branch deletion on the remote, and force pushes.
#
# Usage (from anywhere inside a bench):
#   .frappe-agent/scripts/install_git_hooks.sh            # all apps under apps/
#   .frappe-agent/scripts/install_git_hooks.sh app1 app2  # specific apps
#   .frappe-agent/scripts/install_git_hooks.sh --remove [apps...]
#
# An existing pre-push hook that this template did not install is never
# overwritten. Humans can still bypass with `git push --no-verify`.

set -uo pipefail

FA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$FA_DIR/hooks/git/pre-push"
MARK="# frappe-agent pre-push"
REMOVE=0
[ "${1:-}" = "--remove" ] && { REMOVE=1; shift; }

BENCH="$(dirname "$FA_DIR")"
if [ ! -d "$BENCH/apps" ]; then
  echo "No apps/ folder next to .frappe-agent/ (expected at $BENCH/apps)." >&2
  exit 1
fi

if [ $# -gt 0 ]; then
  apps=("$@")
else
  apps=()
  for d in "$BENCH"/apps/*/; do apps+=("$(basename "$d")"); done
fi

for app in "${apps[@]}"; do
  repo="$BENCH/apps/$app"
  if ! git -C "$repo" rev-parse --git-dir >/dev/null 2>&1; then
    echo "  - $app: not a git repository, skipped"
    continue
  fi
  hooks_dir="$(git -C "$repo" rev-parse --git-path hooks)"
  case "$hooks_dir" in /*) ;; *) hooks_dir="$repo/$hooks_dir" ;; esac
  dest="$hooks_dir/pre-push"
  if [ "$REMOVE" -eq 1 ]; then
    if [ -f "$dest" ] && grep -qF "$MARK" "$dest"; then
      rm -f "$dest"; echo "  - $app: removed pre-push hook"
    else
      echo "  = $app: no frappe-agent hook to remove"
    fi
    continue
  fi
  if [ -e "$dest" ] && ! grep -qF "$MARK" "$dest"; then
    echo "  ! $app: a different pre-push hook exists, left untouched"
    continue
  fi
  mkdir -p "$hooks_dir"
  cp "$SRC" "$dest" && chmod +x "$dest"
  echo "  + $app: pre-push hook installed"
done
