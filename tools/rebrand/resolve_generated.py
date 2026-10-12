#!/usr/bin/env python3
"""Resolve merge conflicts in files whose conflicting lines are computed, not written.

Called by sync-upstream.sh after a merge stops, with the [merge] settings from rebrand.toml:

  hash_files  conflict hunks that differ only in `sha256 = "..."` lines take upstream's side, then
              the hashes are recomputed from the merged files (attribution_hashes.py)
  regenerate  generated files are rebuilt by their command instead of merged

A file is staged (git add) only when no conflict markers remain in it.
"""
import os
import re
import subprocess
import sys
import tomllib

HERE = os.path.dirname(os.path.abspath(__file__))
HUNK = re.compile(r"^<<<<<<< [^\n]*\n(.*?)^=======\n(.*?)^>>>>>>> [^\n]*\n", re.S | re.M)
SHA = re.compile(r'^sha256 = "[0-9a-f]*"$')


def conflicted():
    out = subprocess.run(["git", "diff", "--name-only", "--diff-filter=U"], capture_output=True, text=True, check=True).stdout
    return set(out.split())


def only_hashes_differ(ours, theirs):
    """True when our side adds nothing but hash values: every other line of ours is in theirs.
    (Upstream may add entries around it; our own real edits keep the conflict for a human.)"""
    theirs_lines = set(theirs.splitlines())
    return all(SHA.match(x) or x in theirs_lines for x in ours.splitlines())


def main():
    cfg = tomllib.load(open(sys.argv[1], "rb")).get("merge", {})
    todo = conflicted()
    for f in cfg.get("hash_files", []):
        if f not in todo:
            continue
        text = open(f, encoding="utf-8").read()
        text = HUNK.sub(lambda m: m.group(2) if only_hashes_differ(m.group(1), m.group(2)) else m.group(0), text)
        open(f, "w", encoding="utf-8").write(text)
        if "<<<<<<< " in text:
            print(f"resolve: {f} still has real conflicts")
            continue
        subprocess.run([sys.executable, os.path.join(HERE, "attribution_hashes.py"), f], check=True)
        subprocess.run(["git", "add", f], check=True)
        print(f"resolve: {f} merged and re-hashed")
    for r in cfg.get("regenerate", []):
        f = r["file"]
        if f not in todo:
            continue
        if any(h in conflicted() for h in cfg.get("hash_files", [])):
            print(f"resolve: {f} waits until its sources merge")
            continue
        subprocess.run(["git", "checkout", "--theirs", "--", f], check=True)
        subprocess.run(["bash", "-c", r["command"]], check=True)
        subprocess.run(["git", "add", f], check=True)
        print(f"resolve: {f} regenerated")


if __name__ == "__main__":
    main()
