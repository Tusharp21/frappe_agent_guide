#!/usr/bin/env bash
#
# List the headings of a knowledge-base doc with their line ranges, so you can
# read only the section you need instead of the whole file (use the Read tool
# with offset/limit, or `sed -n 'START,ENDp'`). Computed on the fly, so it never
# goes stale. Read-only.
#
# Usage:
#   .frappe-agent/scripts/doc_sections.sh <doc>   # e.g. 02, 02-doctype-development, or a path
#   .frappe-agent/scripts/doc_sections.sh         # list the docs with sizes

set -euo pipefail

FA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOCS="$FA_DIR/docs"

if [ $# -eq 0 ]; then
  for f in "$DOCS"/[0-9]*.md; do
    printf '  %5d lines  %s\n' "$(wc -l < "$f")" "$(basename "$f")"
  done
  exit 0
fi

arg="$1"
if [ -f "$arg" ]; then file="$arg"
else
  file="$(find "$DOCS" -maxdepth 1 -name "${arg}*.md" | sort | head -1)"
fi
[ -n "${file:-}" ] && [ -f "$file" ] || { echo "No such doc: $arg" >&2; exit 1; }

echo "$(basename "$file") ($(wc -l < "$file") lines). Read a range, not the whole file."
awk '
  /^```/ { fence = !fence }
  !fence && /^#{2,3} / { n++; start[n] = NR; title[n] = $0 }
  END {
    for (i = 1; i <= n; i++) {
      end = (i < n) ? start[i + 1] - 1 : NR
      printf "  %4d-%-4d %s\n", start[i], end, title[i]
    }
  }
' "$file"
