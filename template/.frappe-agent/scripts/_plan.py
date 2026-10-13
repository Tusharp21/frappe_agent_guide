#!/usr/bin/env python3
"""Helpers for plan records, used by new_plan.sh, plan_state.sh and plan_next.sh.

Not meant to be run by hand. A plan record is a Markdown file with a card
(<!-- CARD:START --> ... <!-- CARD:END -->), a state log, a "## Scope" section
and a phase table between <!-- PHASES:START --> and <!-- PHASES:END -->.

Subcommands (all print to stdout; errors go to stderr, exit 1):
  parse FILE                    phases as JSON
  validate FILE                 check the phase table is well formed
  hash FILE                     sha256 of the scope text + phase definitions
  maxrisk FILE                  highest phase risk (LOW|MEDIUM|HIGH)
  next FILE                     first phase that is not DONE, as JSON ("{}" if none)
  setrow FILE N key=value...    set status= / task= on phase N
  field FILE NAME [VALUE]       read or set a card field
  sync FILE HISTORY_DIR         mark phases DONE when their task is COMPLETED;
                                update the card's "Phases" field; print "done total"
  log FILE STATE NOTE           append a row to the state log
  cr FILE NOTE                  append a row to the change-request table
  taskfill TASKFILE PLAN_ID N TITLE ACCEPTANCE ALLOWED SOLUTION
                                fill a phase's task record from the plan
"""
import hashlib
import json
import re
import sys
from datetime import datetime

RISKS = ("LOW", "MEDIUM", "HIGH")
COLS = ["n", "phase", "risk", "allowed", "acceptance", "status", "task"]


def die(msg):
    sys.stderr.write(msg + "\n")
    sys.exit(1)


def read(path):
    try:
        return open(path).read()
    except OSError as e:
        die("cannot read %s: %s" % (path, e))


def phase_block(text):
    m = re.search(r"<!-- PHASES:START -->\n(.*?)<!-- PHASES:END -->", text, re.S)
    if not m:
        die("no PHASES:START / PHASES:END markers in the plan record")
    return m


def parse(text):
    rows = []
    for line in phase_block(text).group(1).splitlines():
        line = line.strip()
        if not line.startswith("|"):
            continue
        cells = [c.strip() for c in line.strip("|").split("|")]
        if cells and (cells[0] == "#" or set(cells[0]) <= set("-: ")):
            continue
        cells += [""] * (len(COLS) - len(cells))
        row = dict(zip(COLS, cells[: len(COLS)]))
        row["extra"] = len(cells) > len(COLS)
        rows.append(row)
    return rows


def render(rows):
    out = ["| # | Phase | Risk | Allowed paths | Acceptance criteria | Status | Task |",
           "| - | ----- | ---- | ------------- | ------------------- | ------ | ---- |"]
    for r in rows:
        out.append("| " + " | ".join(r[c] for c in COLS) + " |")
    return "\n".join(out) + "\n"


def write_phases(path, text, rows):
    m = phase_block(text)
    new = text[: m.start(1)] + render(rows) + text[m.end(1):]
    open(path, "w").write(new)


def scope_text(text):
    m = re.search(r"\n## Scope\n(.*?)(?=\n## |\Z)", text, re.S)
    return "\n".join(l.strip() for l in (m.group(1) if m else "").splitlines() if l.strip())


def definition_hash(text):
    rows = [[r["n"], r["phase"], r["risk"].upper(), r["allowed"], r["acceptance"]] for r in parse(text)]
    blob = json.dumps({"scope": scope_text(text), "phases": rows}, sort_keys=True)
    return hashlib.sha256(blob.encode()).hexdigest()


def validate(text):
    rows = parse(text)
    errs = []
    if not rows:
        errs.append("the plan has no phases")
    for i, r in enumerate(rows, 1):
        tag = "phase row %d" % i
        if r["extra"]:
            errs.append("%s has more than %d cells (is there a '|' inside a cell?)" % (tag, len(COLS)))
        if r["n"] != str(i):
            errs.append("%s: '#' must be %d, found '%s'" % (tag, i, r["n"]))
        if not r["phase"]:
            errs.append("%s has no title" % tag)
        if r["risk"].upper() not in RISKS:
            errs.append("%s: risk must be LOW, MEDIUM or HIGH" % tag)
        if not r["allowed"]:
            errs.append("%s has no allowed paths" % tag)
        if not r["acceptance"]:
            errs.append("%s has no acceptance criteria" % tag)
        if r["status"] not in ("PENDING", "IN_PROGRESS", "DONE"):
            errs.append("%s: status must be PENDING, IN_PROGRESS or DONE" % tag)
    return errs


def card_get(text, name):
    on = False
    for line in text.splitlines():
        if "<!-- CARD:START -->" in line:
            on = True
        elif "<!-- CARD:END -->" in line:
            break
        elif on and line.startswith("- **%s:**" % name):
            return re.sub(r"<!--.*?-->", "", line.split(":**", 1)[1]).strip()
    return ""


def card_set(path, name, value):
    text = read(path)
    lines = text.split("\n")
    on = done = False
    for i, line in enumerate(lines):
        if "<!-- CARD:START -->" in line:
            on = True
        elif "<!-- CARD:END -->" in line:
            break
        elif on and line.startswith("- **%s:**" % name):
            lines[i] = "- **%s:** %s" % (name, value)
            done = True
            break
    if not done:
        die("card field '%s' not found in %s" % (name, path))
    open(path, "w").write("\n".join(lines))


def now():
    return datetime.now().strftime("%Y-%m-%d %H:%M")


def clean(s):
    return re.sub(r"\s+", " ", s.replace("|", "/")).strip()


def main(argv):
    if len(argv) < 3:
        die(__doc__)
    cmd, path = argv[1], argv[2]
    args = argv[3:]

    if cmd == "parse":
        print(json.dumps(parse(read(path)), indent=2))
    elif cmd == "validate":
        errs = validate(read(path))
        for e in errs:
            sys.stderr.write("  - " + e + "\n")
        sys.exit(1 if errs else 0)
    elif cmd == "hash":
        print(definition_hash(read(path)))
    elif cmd == "maxrisk":
        rows = parse(read(path))
        print(max((r["risk"].upper() for r in rows), key=RISKS.index, default="LOW"))
    elif cmd == "next":
        for r in parse(read(path)):
            if r["status"] != "DONE":
                print(json.dumps(r))
                return
        print("{}")
    elif cmd == "setrow":
        text = read(path)
        rows = parse(text)
        n = args[0]
        hit = [r for r in rows if r["n"] == n]
        if not hit:
            die("no phase %s" % n)
        for kv in args[1:]:
            k, v = kv.split("=", 1)
            if k not in ("status", "task"):
                die("cannot set %s" % k)
            hit[0][k] = v
        write_phases(path, text, rows)
    elif cmd == "field":
        if len(args) >= 2:
            card_set(path, args[0], args[1])
        else:
            print(card_get(read(path), args[0]))
    elif cmd == "sync":
        hist = args[0]
        text = read(path)
        rows = parse(text)
        for r in rows:
            if r["status"] != "DONE" and r["task"]:
                try:
                    state = card_get(open("%s/%s.md" % (hist, r["task"])).read(), "State")
                except OSError:
                    continue
                if state == "COMPLETED":
                    r["status"] = "DONE"
        write_phases(path, text, rows)
        done = sum(1 for r in rows if r["status"] == "DONE")
        card_set(path, "Phases", "%d/%d done" % (done, len(rows)))
        print(done, len(rows))
    elif cmd == "log":
        text = read(path)
        row = "| %s | %s | %s |" % (now(), args[0], clean(args[1]))
        if "<!-- STATE-LOG-END -->" not in text:
            die("no state log in the record")
        open(path, "w").write(text.replace("<!-- STATE-LOG-END -->", row + "\n<!-- STATE-LOG-END -->", 1))
    elif cmd == "cr":
        text = read(path)
        head = "| When | Change | Why | User decision |\n| ---- | ------ | --- | ------------- |\n"
        row = "| %s | %s | | |\n" % (now(), clean(args[0]))
        if head not in text:
            die("no change-request table in the record")
        open(path, "w").write(text.replace(head, head + row, 1))
    elif cmd == "taskfill":
        plan_id, n, title, acceptance, allowed, solution = args
        text = read(path)
        text = text.replace("* Requirement:", "* Requirement: %s, phase %s: %s" % (plan_id, n, clean(title)), 1)
        text = text.replace("* Expected result:", "* Expected result: %s" % clean(acceptance), 1)
        open(path, "w").write(text)
        card_set(path, "Related", "%s phase %s" % (plan_id, n))
        if allowed:
            card_set(path, "Allowed paths", allowed)
        if solution:
            card_set(path, "Locked solution", clean(solution))
    else:
        die("unknown subcommand: " + cmd)


if __name__ == "__main__":
    main(sys.argv)
