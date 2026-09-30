#!/usr/bin/env python3
"""Find work that can happen twice for one user action.

The double-scan of Jul 2026 was invisible for months: activateProfession opened a
profession window and scanned on its ready callback, and the open fired
TRADE_SKILL_SHOW whose handler scanned as well. Every profession's recipe walk
ran twice, and everything subscribed to RECIPES_SCANNED ran twice with it. It
surfaced only because a chat line started appearing in pairs.

Nothing about it was visible in the event graph - one publisher, one subscriber.
It was two CALLERS of one operation, one direct and one inside a handler for an
event the direct path itself causes. That is the shape this looks for.

    python3 tools/audit_duplicate_work.py addons/Crafty

Output is a report, not a verdict. Being reachable both directly and from a
handler is normal - a refresh is legitimately callable either way. What needs a
human is whether ONE action reaches it twice, and the report gives the call
sites to read.
"""

import collections
import glob
import os
import re
import sys

# Operations worth auditing: they walk data, rebuild UI, or address the player.
# Cheap accessors are not here - doing those twice costs nothing.
OPERATIONS = [
    "scanOpen", "repopulate", "rerender", "refresh", "layout",
    "beginProfessionScan", "arrive", "launchGhost", "observe",
]


def enclosing_handler(lines, index):
    """Whether this line sits inside a SetScript or subscribe callback."""
    for j in range(index, max(-1, index - 60), -1):
        if re.search(r"(SetScript|:subscribe)\(.*function", lines[j]):
            return True
        if re.match(r"^(local )?function ", lines[j]):
            return False
    return False


def audit(root):
    files = sorted(glob.glob(os.path.join(root, "**", "*.lua"), recursive=True))
    source = {f: open(f, encoding="utf-8").read().split("\n") for f in files}

    print("EVENT GRAPH\n")
    pub, sub = collections.defaultdict(list), collections.defaultdict(list)
    for f, lines in source.items():
        for i, line in enumerate(lines, 1):
            m = re.search(r"events:emit\(\s*(?:constants\.EVENT\.)?([A-Z_]+)", line)
            if m:
                pub[m.group(1)].append(f"{f}:{i}")
            m = re.search(r"events:subscribe\(\s*(?:constants\.EVENT\.)?[\"']?([A-Z_]+)",
                          line)
            if m:
                sub[m.group(1)].append(f"{f}:{i}")

    dead = sorted(e for e in pub if e not in sub)
    print(f"  published but never subscribed : {dead or 'none'}")
    multi = {e: p for e, p in pub.items() if len(p) > 1}
    print(f"  more than one publisher        : {sorted(multi) or 'none'}")
    for e, sites in sorted(multi.items()):
        for s in sites:
            print(f"      {e}  {s}")

    print("\nOPERATIONS REACHABLE BOTH DIRECTLY AND FROM A HANDLER")
    print("(not a defect by itself - read the sites and ask whether ONE action")
    print(" reaches the operation twice)\n")
    for op in OPERATIONS:
        direct, handler = [], []
        for f, lines in source.items():
            for i, line in enumerate(lines):
                if not re.search(r"[:.]" + op + r"\s*\(", line):
                    continue
                if "function" in line.split(op)[0][-12:]:
                    continue
                (handler if enclosing_handler(lines, i) else direct).append(
                    f"{f}:{i + 1}")
        if direct and handler:
            print(f"  {op}")
            for s in direct:
                print(f"      direct   {s}")
            for s in handler:
                print(f"      handler  {s}")


if __name__ == "__main__":
    audit(sys.argv[1] if len(sys.argv) > 1 else ".")
