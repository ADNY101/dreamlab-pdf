#!/usr/bin/env bash
# Bring the latest upstream release into this fork.
#
#   tools/rebrand/sync-upstream.sh            # upstream's default branch
#   tools/rebrand/sync-upstream.sh v0.8.0     # or any upstream tag, branch or commit
#
# How the fork is laid out (tools/rebrand/README.md):
#   upstream-rebranded  one commit per synced upstream snapshot: upstream's tree passed through
#                       rebrand.py, cargo fmt and a Cargo.lock refresh. Never edit it by hand.
#   main                upstream-rebranded + our own changes (icon, README, links, installer...).
#
# The script refreshes upstream-rebranded from upstream, then merges it into main. Git carries our
# changes forward; a conflict means upstream changed a line we changed too. Run it on a clean main.
set -euo pipefail
ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"
HERE="tools/rebrand"
CFG="$HERE/rebrand.toml"
REF="${1:-}"

[ "$(git rev-parse --abbrev-ref HEAD)" = main ] || { echo "error: run this on main" >&2; exit 1; }
git diff --quiet && git diff --cached --quiet || { echo "error: commit or stash your changes first" >&2; exit 1; }

read -r URL BRANCH < <(python3 - "$CFG" <<'PY'
import sys, tomllib
u = tomllib.load(open(sys.argv[1], "rb"))["upstream"]
print(u["repo"], u.get("branch", "main"))
PY
)
REF="${REF:-$BRANCH}"

echo "==> fetching $URL ($REF)"
git fetch --quiet --no-tags --depth 1 "$URL" "$REF"
SHA="$(git rev-parse FETCH_HEAD)"
SUBJECT="$(git log -1 --format=%s FETCH_HEAD)"
PREV="$(git show upstream-rebranded:.upstream-commit 2>/dev/null || true)"
if [ "$SHA" = "$PREV" ]; then
  echo "upstream-rebranded is already at ${SHA:0:12}; nothing to sync"
  exit 0
fi

WT="$(mktemp -d)"
trap 'git worktree remove --force "$WT" >/dev/null 2>&1 || true; rm -rf "$WT"' EXIT
git worktree add --quiet "$WT" upstream-rebranded
echo "==> rebranding upstream ${SHA:0:12}: $SUBJECT"
(cd "$WT" && git rm -rq --ignore-unmatch . && git clean -fdxq)
git archive FETCH_HEAD | tar -x -C "$WT"
python3 "$HERE/rebrand.py" --config "$CFG" "$WT" | tail -1
echo "$SHA" > "$WT/.upstream-commit"
# Mechanical follow-ups: longer names reflow lines, and Cargo sorts Cargo.lock by package name.
(cd "$WT" && cargo fmt --all && cargo metadata --format-version 1 >/dev/null)
# Per-fork mechanical follow-ups ([post] in rebrand.toml): refreshed hashes, regenerated files.
python3 - "$CFG" <<'PY' | while IFS= read -r cmd; do
import sys, tomllib
for c in tomllib.load(open(sys.argv[1], "rb")).get("post", {}).get("commands", []):
    print(c)
PY
  echo "    post: $cmd"
  (cd "$WT" && REBRAND_DIR="$ROOT/$HERE" CARGO_TARGET_DIR="$ROOT/target" bash -c "$cmd")
done
git -C "$WT" add -A
git -C "$WT" commit --quiet -m "Rebrand upstream ${SHA:0:12}: $SUBJECT" -m "Upstream: $URL@$SHA"
echo "==> merging into main"
if git merge --no-ff --no-edit -m "Merge upstream ${SHA:0:12}: $SUBJECT" upstream-rebranded; then
  echo
  echo "Merged cleanly. Next: cargo build && cargo test, then push."
else
  # Computed files (hashes, generated docs) resolve themselves; finish if nothing else is left.
  python3 "$HERE/resolve_generated.py" "$CFG" || true
  if [ -z "$(git diff --name-only --diff-filter=U)" ]; then
    git commit --no-edit --quiet
    echo
    echo "Merged (computed files resolved automatically). Next: cargo build && cargo test, then push."
    python3 "$HERE/rebrand.py" --config "$CFG" --check . | tail -15 || true
    exit 0
  fi
  echo
  echo "Merge stopped on conflicts: upstream changed lines we changed too."
  echo "  git status                      # the conflicted files"
  echo "  (fix each file; keep our branding, take upstream's other changes)"
  echo "  git add <files> && git commit   # finish the merge"
  echo "Binary files can't merge; regenerate them (tools/rebrand/README.md, 'Regenerated files')."
fi
echo
python3 "$HERE/rebrand.py" --config "$CFG" --check . | tail -15 || true
