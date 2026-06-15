#!/usr/bin/env python3
# Validate that a SKILL.md has a LEADING, CLOSED YAML frontmatter block whose
# `name` equals the expected value and whose `description` is non-empty.
# (Greps over the whole file would pass metadata outside the frontmatter — the
# packaging-review blocker this guards against.) Exit 0 iff valid.
import sys

path, expected = sys.argv[1], sys.argv[2]
try:
    lines = open(path).read().split("\n")
except FileNotFoundError:
    print(f"missing: {path}"); sys.exit(1)

if not lines or lines[0].strip() != "---":
    print(f"no leading frontmatter: {path}"); sys.exit(1)

end = next((i for i in range(1, len(lines)) if lines[i].strip() == "---"), None)
if end is None:
    print(f"unclosed frontmatter: {path}"); sys.exit(1)

fm = lines[1:end]

def field(key):
    for l in fm:
        if l.startswith(key + ":"):
            return l[len(key) + 1:].strip()
    return None

name, desc = field("name"), field("description")
if name != expected:
    print(f"name '{name}' != '{expected}': {path}"); sys.exit(1)
if not desc:
    print(f"empty/missing description: {path}"); sys.exit(1)
sys.exit(0)
