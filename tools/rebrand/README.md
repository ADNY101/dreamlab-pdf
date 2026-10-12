# Keeping up with upstream

This fork tracks an actively developed upstream project (see `[upstream]` in `rebrand.toml`). New
upstream releases come in through a script, so bug fixes and features keep flowing in without
redoing the rebrand by hand.

## How the repository is laid out

| Branch | What it holds |
|---|---|
| `upstream-rebranded` | One commit per synced upstream snapshot: upstream's tree passed through `rebrand.py`, `cargo fmt` and a `Cargo.lock` refresh. `.upstream-commit` records the upstream commit. **Never edit this branch by hand.** |
| `main` | `upstream-rebranded` plus our own changes: the icon, README, NOTICE, feedback links, translations of our labels, the Windows installer, disabled workflows. |

Because our changes are ordinary commits on `main`, git carries them forward on every sync.

## Syncing

```sh
git checkout main
tools/rebrand/sync-upstream.sh            # latest upstream
tools/rebrand/sync-upstream.sh v0.9.0     # or a specific upstream tag/commit
cargo build && cargo test                  # then push
```

The script fetches upstream, rebrands it onto `upstream-rebranded`, merges that into `main`, and
finishes with `rebrand.py --check`, which lists any upstream name that survived. New upstream code
can mention the old name in a new way; add a rule to `rebrand.toml` and re-run.

**When the merge stops on conflicts**, upstream changed lines we also changed. Typical spots:

- `README.md`, `NOTICE`, `LICENSE-MIT`: keep ours, then copy in any upstream facts worth keeping.
- The links module and title bar: keep our feedback links; take upstream's other changes.
- Translation catalogs (`crates/ui-egui/src/i18n/*.tsv`): take upstream's new lines and keep ours
  (the "Send feedback" / "Feedback" entries); never re-add Discord or ArtCraft entries.
- `.github/workflows/*`: we disabled the release workflows (moved to `.github/workflows-disabled/`);
  if upstream changed one, leave it disabled (`git rm` the re-added copy).

Then `git add` the files and `git commit` to finish the merge.

## Regenerated files

Some binary files contain the product name and can't be edited as text. When upstream changes one,
the merge conflicts on it; regenerate it on `main` instead of choosing a side.

(The commands for this repository's binaries are listed below; skip the section if it says none.)

None at the moment: DreamLab PDF's product name only appears in text files. The app icon
files in `assets/app-icon/` are ours; if upstream changes its icon, keep ours.

## Changing the rules

`rebrand.toml` holds every mechanical change: name rules, URL and company rules, protected upstream
references (issue links, shared test corpora), our installer GUIDs, and file deletions (the
upstream brand marks, which forks must not ship). Rules run top to bottom. After editing it, the
next sync applies it to the whole upstream tree.

Anything that isn't mechanical (new artwork, new wording, new features) belongs on `main` as a
normal commit, not in the rules.
