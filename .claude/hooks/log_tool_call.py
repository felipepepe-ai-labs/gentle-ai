#!/usr/bin/env python3
"""PostToolUse hook: append a curated line per tool call to docs/agent-logs/.

Collapses immediate repeats of the same tool + summary into a single
line with a "(xN)" counter instead of one line per call, to keep the
log readable.
"""
import json
import os
import re
import sys
import datetime

d = json.load(sys.stdin)
tool = d.get("tool_name", "unknown")
root = d.get("cwd") or os.getcwd()
ti = d.get("tool_input", {}) or {}
summary = ti.get("command") or ti.get("file_path") or ti.get("pattern") or ti.get("prompt") or ""
summary = str(summary).replace("\n", " ").strip()[:160]

now = datetime.datetime.now()
outdir = os.path.join(root, "docs", "agent-logs")
os.makedirs(outdir, exist_ok=True)
path = os.path.join(outdir, now.strftime("%Y-%m-%d") + ".md")

new_line = "- %s | tool=%s | %s" % (now.strftime("%H:%M:%S"), tool, summary)

collapse_re = re.compile(r"^- \d\d:\d\d:\d\d \| tool=(.*?) \| (.*?)( \(x(\d+)\))?$")

lines = []
if os.path.exists(path):
    with open(path, "r") as f:
        lines = f.read().splitlines()

if lines:
    m = collapse_re.match(lines[-1])
    if m and m.group(1) == tool and m.group(2) == summary:
        count = int(m.group(4)) + 1 if m.group(4) else 2
        lines[-1] = "- %s | tool=%s | %s (x%d)" % (now.strftime("%H:%M:%S"), tool, summary, count)
        with open(path, "w") as f:
            f.write("\n".join(lines) + "\n")
        sys.exit(0)

with open(path, "a") as f:
    f.write(new_line + "\n")
