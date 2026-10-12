#!/usr/bin/env python3
"""Mechanically rebrand an upstream source tree in place, driven by a TOML rules file.

    python3 tools/rebrand/rebrand.py --config tools/rebrand/rebrand.toml TREE
    python3 tools/rebrand/rebrand.py --config tools/rebrand/rebrand.toml --check TREE

The same rules applied to the same upstream tree always give the same result, so every upstream
release can be rebranded the same way (see sync-upstream.sh). Only *mechanical* changes belong here:
names, identifiers, paths, URLs, IDs. Hand-made changes (the icon, README, links, the feedback
button, translations) are commits on `main` and survive syncs through git merges.

Rules file sections (applied in this order):
  delete       = [paths]           removed before anything else (e.g. the upstream brand marks)
  [[protect]]  pattern, files?     text kept verbatim (upstream history links, shared corpora)
  [[text]]     pattern, replace, files?   regex substitutions, in order, on every text file
  [[path]]     pattern, replace    renames applied to file and directory names (deepest first)
  [check]      leftover = [regex], allow = [regex]   --check: report names that survived

`files` is a list of fnmatch globs on the path relative to TREE (after renames for rules that run
after paths; text rules run before path renames, so globs use upstream names).
Binary files (a NUL byte in the first 8 KiB) are never edited; --check scans them too (ASCII and
UTF-16) because names hide there (ICC profiles, compiled fixtures, .DS_Store).
"""
import argparse
import fnmatch
import os
import re
import shutil
import sys
import tomllib

SKIP_DIRS = {".git", "target", "node_modules"}


def walk_files(root, skip):
    for dp, dns, fns in os.walk(root):
        dns[:] = [d for d in dns if d not in skip]
        for fn in fns:
            p = os.path.join(dp, fn)
            yield p, os.path.relpath(p, root).replace(os.sep, "/")


def matches(rel, globs):
    return not globs or any(fnmatch.fnmatch(rel, g) for g in globs)


def is_binary(data):
    return b"\0" in data[:8192]


def apply_text(root, cfg, skip):
    protect = [(re.compile(p["pattern"], re.M), p.get("files", [])) for p in cfg.get("protect", [])]
    rules = [(re.compile(r["pattern"], re.M), r["replace"], r.get("files", [])) for r in cfg.get("text", [])]
    changed = 0
    for path, rel in walk_files(root, skip):
        if os.path.islink(path):
            continue
        with open(path, "rb") as f:
            data = f.read()
        if is_binary(data):
            continue
        try:
            text = data.decode("utf-8")
        except UnicodeDecodeError:
            continue
        kept = []

        def hold(m):
            kept.append(m.group(0))
            return f"\x00{len(kept) - 1}\x00"

        out = text
        for rx, globs in protect:
            if matches(rel, globs):
                out = rx.sub(hold, out)
        for rx, rep, globs in rules:
            if matches(rel, globs):
                out = rx.sub(rep, out)
        out = re.sub(r"\x00(\d+)\x00", lambda m: kept[int(m.group(1))], out)
        if out != text:
            with open(path, "w", encoding="utf-8", newline="") as f:
                f.write(out)
            changed += 1
    return changed


def apply_paths(root, cfg, skip):
    rules = [(re.compile(r["pattern"]), r["replace"]) for r in cfg.get("path", [])]
    moved = 0
    for dp, dns, fns in os.walk(root, topdown=False):
        if any(part in skip for part in os.path.relpath(dp, root).split(os.sep)):
            continue
        for name in fns + dns:
            new = name
            for rx, rep in rules:
                new = rx.sub(rep, new)
            if new != name:
                os.rename(os.path.join(dp, name), os.path.join(dp, new))
                moved += 1
    return moved


def check(root, cfg, skip):
    chk = cfg.get("check", {})
    leftover = [re.compile(p) for p in chk.get("leftover", [])]
    allow = [re.compile(p) for p in chk.get("allow", [])]
    allow_files = chk.get("allow_files", [])
    problems = []
    for path, rel in walk_files(root, skip):
        if matches(rel, allow_files) and allow_files:
            continue
        for rx in leftover:
            if rx.search(rel):
                problems.append(f"{rel}: path still contains {rx.pattern!r}")
        with open(path, "rb") as f:
            data = f.read()
        if is_binary(data):
            for rx in leftover:
                word = rx.pattern.strip("\\b()?:i")
                for enc in ("ascii", "utf-16-be", "utf-16-le"):
                    try:
                        needle = word.encode(enc)
                    except UnicodeEncodeError:
                        continue
                    if needle and needle.lower() in data.lower():
                        problems.append(f"{rel}: binary file contains {word!r} ({enc}); regenerate it")
                        break
            continue
        text = data.decode("utf-8", "replace")
        for n, line in enumerate(text.splitlines(), 1):
            for rx in leftover:
                for m in rx.finditer(line):
                    if not any(a.search(line) for a in allow):
                        problems.append(f"{rel}:{n}: {line.strip()[:160]}")
                        break
    return problems


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("tree")
    ap.add_argument("--config", required=True)
    ap.add_argument("--check", action="store_true", help="only report leftovers; change nothing")
    a = ap.parse_args()
    with open(a.config, "rb") as f:
        cfg = tomllib.load(f)
    skip = SKIP_DIRS | set(cfg.get("skip_dirs", []))
    root = os.path.abspath(a.tree)
    if not a.check:
        for d in cfg.get("delete", []):
            p = os.path.join(root, d)
            if os.path.isdir(p):
                shutil.rmtree(p)
            elif os.path.exists(p):
                os.remove(p)
        print(f"rebrand: {apply_text(root, cfg, skip)} files edited, {apply_paths(root, cfg, skip)} paths renamed")
    problems = check(root, cfg, skip)
    for p in problems:
        print("leftover:", p)
    print(f"rebrand check: {len(problems)} leftover(s)")
    return 1 if (a.check and problems) else 0


if __name__ == "__main__":
    sys.exit(main())
