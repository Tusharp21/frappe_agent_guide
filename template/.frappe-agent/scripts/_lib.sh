# Shared helpers for the task scripts. Source this file; do not run it.
# Expects FA_DIR to be set to the .frappe-agent directory.

# Print the directory where task records live (config.json "history.path",
# default "tasks"; relative paths are resolved from .frappe-agent/).
history_dir() {
  python3 - "$FA_DIR" <<'PY'
import json, os, sys
fa = sys.argv[1]
try:
    cfg = json.load(open(os.path.join(fa, "config.json")))
except Exception:
    cfg = {}
p = (cfg.get("history") or {}).get("path") or "tasks"
p = os.path.expanduser(p)
if not os.path.isabs(p):
    p = os.path.join(fa, p)
print(os.path.normpath(p))
PY
}

# Print the lines of the card (between the CARD markers) of a task record.
print_card() {
  awk '
    /<!-- CARD:START -->/ { on = 1; next }
    /<!-- CARD:END -->/   { on = 0 }
    on { print }
  ' "$1" | sed 's/ *<!--.*-->//'
}

# Value of a card field, e.g. card_field file State -> DRAFT
card_field() {
  print_card "$1" | sed -n "s/^- \*\*$2:\*\* *//p" | head -1 | sed 's/ *<!--.*-->//'
}
