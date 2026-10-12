#!/usr/bin/env python3
"""Refresh ATTRIBUTION.toml after a rebrand: drop [[asset]] entries whose file was deleted (the
upstream brand marks) and recompute every [[asset]] sha256 (renamed text changes file contents).

    python3 tools/rebrand/attribution_hashes.py [ATTRIBUTION.toml]
"""
import hashlib
import os
import re
import sys

path = sys.argv[1] if len(sys.argv) > 1 else "ATTRIBUTION.toml"
root = os.path.dirname(os.path.abspath(path))
text = open(path, encoding="utf-8").read()
blocks = re.split(r"(?=^\[\[(?:asset|bundled|fetched|build_input)\]\])", text, flags=re.M)
out, dropped, rehashed = [], 0, 0
for block in blocks:
    m = re.search(r'^path = "([^"]+)"', block, re.M)
    if block.startswith("[[asset]]") and m:
        file = os.path.join(root, m.group(1))
        if not os.path.exists(file):
            dropped += 1
            continue
        digest = hashlib.sha256(open(file, "rb").read()).hexdigest()
        new = re.sub(r'^sha256 = "[0-9a-f]*"', f'sha256 = "{digest}"', block, flags=re.M)
        rehashed += new != block
        block = new
    out.append(block)
open(path, "w", encoding="utf-8").write("".join(out))
print(f"attribution: {dropped} entries for deleted files dropped, {rehashed} hashes refreshed")
