<p align="center">
  <img src="assets/app-icon/dreamlab-pdf-small.svg" alt="DreamLab PDF" width="112">
</p>

<h1 align="center">DreamLab PDF</h1>

<p align="center">
  <b>A fast, private, open-source PDF workbench written in pure Rust.</b><br>
  Read, organize, combine, split, comment on, fill in, sign and secure PDFs.<br>
  macOS · Windows · Linux · FreeBSD · the web
</p>

<p align="center">
  <img alt="License: MIT OR Apache-2.0" src="https://img.shields.io/badge/license-MIT%20OR%20Apache--2.0-6d28d9">
  <img alt="Written in Rust" src="https://img.shields.io/badge/written%20in-Rust-4338ca">
  <img alt="No account, no telemetry" src="https://img.shields.io/badge/no%20account-no%20telemetry-6d28d9">
</p>

> [!NOTE]
> DreamLab PDF is based on [PdfCraft](https://github.com/storytold/pdfcraft) by the ArtCraft team
> (MIT OR Apache-2.0). It is an independent fork and is not made, sponsored or endorsed by them.

---

## Highlights

- **Faithful rendering.** World scripts, vertical Japanese, colour emoji, gradients, soft masks,
  transparency and optional content render the way the author intended. Deep zoom renders in tiles,
  so text stays sharp.
- **Fearless saving.** Saves are incremental (the original bytes stay intact) and atomic (written to a
  temporary copy, then swapped in). Undo runs deep and survives saving; autosave and crash recovery
  protect unsaved work.
- **Yours.** No account, no telemetry, no cloud. Documents never leave your machine.

## What it does

| Area | Features |
|---|---|
| **Read** | Continuous, single-page, two-up and full-screen layouts; distraction-free Read mode; light and dark themes |
| **Find** | Search as you type, step through matches, select text in correct reading order (columns, RTL, CJK) |
| **Navigate** | Bookmarks (searchable), thumbnails, the document's own page labels (i, ii, 1, 2…) |
| **Organize** | Page grid: rotate, delete, insert blank or from file, reorder, crop, number pages; full undo |
| **Combine & split** | Merge any number of PDFs (one bookmark per file); extract selected pages; split every *n* pages or before chosen pages. Links, form fields, layers and attachments survive |
| **Protect** | Full standard security handler, 40-bit RC4 through AES-256; user/owner passwords; permissions honoured; edits to encrypted files stay encrypted |
| **Comments & forms** | Threaded comments, highlights, shapes, ink, stamps; fill and author forms with sandboxed JavaScript |
| **Pro tools** | Redaction and sanitizing, digital signatures, printing, Accessibility Checker, OCR (Latin), compare, optimize |
| **Everywhere** | ⌘K / Ctrl-K command palette for every tool; 17 interface languages |

### From the command line

```sh
dreamlab-pdf-cli info    form.pdf                                   # structure as JSON
dreamlab-pdf-cli text    paper.pdf --page 3                         # reading-order text
dreamlab-pdf-cli edit    in.pdf --rotate 1,2:90 --delete 5 --title "Q3" --out out.pdf
dreamlab-pdf-cli combine report.pdf appendix.pdf --out combined.pdf
dreamlab-pdf-cli extract report.pdf --pages 1,3,5 --out highlights.pdf
dreamlab-pdf-cli split   report.pdf --every 10 --out-dir parts/
```

---

## Built for agents, too

Every engine feature is reachable without the GUI, through one table of JSON-Schema-described tools: open, inspect, render pages to PNG, extract and find text, rotate, delete, move and insert pages, edit bookmarks and page labels, add, reply to, restyle and delete comments (highlight a phrase just by naming it), list and fill in form fields, protect with passwords, set metadata, undo and redo, save, combine, extract and split. Three front doors share it:

- **`dreamlab-pdf-cli run`**, for one-off calls and JSON scripts:

  ```sh
  dreamlab-pdf-cli tools                                        # every tool and its JSON Schema
  dreamlab-pdf-cli run text_find doc=1 query=invoice            # key=value; values parse as JSON
  dreamlab-pdf-cli run --script review.json                     # e.g. comment_add {"type": "highlight", "find": "total due"}
  dreamlab-pdf-cli run --script steps.json --root ./work        # several steps in one session
  ```

  With `--root`, every file the script's steps read or write stays in that directory, including the PNG a step saves with `"out"` (the script itself is read from wherever you name it).

- **An MCP server**, for AI agents such as Claude. **It is opt-in:** DreamLab PDF never starts it on its own, and it opens no network port. It runs only while an agent launches `dreamlab-pdf-cli mcp`, talks over stdin/stdout, and stops when the agent disconnects. To enable it, add it to your agent's MCP configuration:

  ```json
  { "mcpServers": { "dreamlab-pdf": { "command": "dreamlab-pdf-cli", "args": ["mcp", "--root", "/path/to/your/pdfs"] } } }
  ```

  `--compact` shrinks the tool list the agent has to read: `tools/list` returns about ten core tools plus `tool_search` and `tool_call`, which find and run every other tool, so the list costs far fewer tokens. Every tool still works.

  `--root` confines every file the agent can read or write to one directory. Builds that should not include the server at all can use `cargo build -p dreamlab-pdf-cli --no-default-features`.

- **The Rust API** (`dreamlab_pdf_automation::Automation::call`), for embedding.

Edits stay in memory, undoable, until `doc_save`. Saving to the same file appends an incremental update, so the original bytes are preserved, and the write is atomic. Unsaved changes are never discarded silently.

### Driving the app itself

Start the desktop app with `dreamlab-pdf --control ~/.dreamlab-pdf-control.json` and an agent can see and operate the real interface: the widget tree with labels and positions (from the accessibility tree), clicks, typing, keys, commands, view options and screenshots. This is also off by default. It listens only on loopback, and every connection must present the random token written to that file, which only you can read.

Keep the control file in a folder only you can write, not a shared one such as `/tmp`: another user could create the file there first and receive your commands. `dreamlab-pdf-cli ui` refuses a control file that is a symbolic link, and on macOS, Linux and FreeBSD one that another user owns or can read or write. The app doesn't start if it can't write the file.

```sh
dreamlab-pdf-cli ui --control ~/.dreamlab-pdf-control.json inspect query=rotate      # find widgets
dreamlab-pdf-cli ui --control ~/.dreamlab-pdf-control.json click label="Organize pages"
dreamlab-pdf-cli ui --control ~/.dreamlab-pdf-control.json key key=K modifiers='["command"]'
dreamlab-pdf-cli ui --control ~/.dreamlab-pdf-control.json command id=comment.square   # pick a tool, then draw:
dreamlab-pdf-cli ui --control ~/.dreamlab-pdf-control.json drag from='[400,300]' to='[600,420]'
dreamlab-pdf-cli ui --control ~/.dreamlab-pdf-control.json screenshot --out window.png
dreamlab-pdf-cli ui --control ~/.dreamlab-pdf-control.json resize width=1200 height=800
dreamlab-pdf-cli ui --control ~/.dreamlab-pdf-control.json focus label="Read"
dreamlab-pdf-cli ui --control ~/.dreamlab-pdf-control.json inspect focused=true
dreamlab-pdf-cli ui --control ~/.dreamlab-pdf-control.json quit
```

`ui.dock` arranges the `tools` and `inspector` panels; `canvas` is the protected document view.
Each per-panel request requires a `panel` ID and an `operation`: `open`, `close`,
`activate`, `float` with `rect: [x, y, width, height]`, or `move` with `target` and
`zone: center|left|right|top|bottom`. For example,
`{"operation":"float","panel":"tools","rect":[100,100,320,440]}` floats Tools.
`ui.dock.reset` restores the default
arrangement. The control channel accepts these methods directly; `ui.command` also accepts
`{"id":"ui.dock","params":{...}}`. Saved preferences retain groups, active tabs, visibility
and floating geometry. Invalid requests return an error without changing the document or layout.


`resize` requests a native inner-window size in logical points (each dimension must be between 320 and 8192); the window manager may constrain it. `state` reports the observed `window.width`, `window.height` and `window.pixels_per_point`. `focus` accepts exactly one widget `id` or unique enabled, focusable `label`; subsequent `key` requests traverse or activate the actual widgets. `inspect` includes focusability and accepts a `focused` filter. `quit` takes no parameters: clean documents exit normally, while unsaved edits or typing open the existing Save/Don't save/Cancel prompt and return `quitting: false, needs_confirmation: true`. It never silently discards work. Window resizing and application quit are native-only.

---

## How it's built

DreamLab PDF is a Cargo workspace of focused crates, layered so the core never depends on the UI:

| Crate | What it does |
|---|---|
| `dreamlab-pdf-filters` | Every PDF stream filter (Flate, LZW, ASCII85, RunLength, predictors), encode and decode, property-tested |
| `dreamlab-pdf-crypt` | The standard security handler: RC4, AES-128/256, revisions 2–6, permissions |
| `dreamlab-pdf-cos` | The PDF object layer: tolerant parsing, repair, copy-on-write edits, incremental and full writing |
| `dreamlab-pdf-organize` | Page operations, combine / extract / split, bookmarks, page labels, document information |
| `dreamlab-pdf-fonts` | Font metrics and encodings for generated appearances |
| `dreamlab-pdf-annot` | Comments: builders and appearance streams for notes, text markup, shapes, ink and text boxes; replies, status, edits |
| `dreamlab-pdf-forms` | Interactive forms: the field model, filling with regenerated appearances, Clear form |
| `dreamlab-pdf-render` | Rendering, inspection and text extraction with reading order |
| `dreamlab-pdf-engine` | The façade every frontend uses: sessions, edits, undo, saving, the tool catalogue |
| `dreamlab-pdf-automation` | Agent control: the headless tool table, `dreamlab-pdf-cli run`, and the opt-in MCP server |
| `dreamlab-pdf-ui-egui` | The desktop and web interface |

**Quality gates.** Every change passes the same automated checks:
- formatting, and Clippy with warnings as errors;
- 200+ unit, property and UI tests;
- crate-layering rules and a WebAssembly build check;
- an asset-licence audit.

On top of those, two corpus sweeps run over real-world files:
- **Opening and rendering:** of the 983 pdf.js test files, 963 open and render cleanly, with 0 crashes.
- **Open, edit and save round trips:** 958 succeed.

The output is verified with independent tools: hayro, qpdf and poppler.

DreamLab PDF is a clean-room implementation. Its behaviour comes from the ISO 32000 specification and black-box observation, never from anyone else's code. Every icon, font and image is openly licensed and listed in [ATTRIBUTION.md](ATTRIBUTION.md).

## Get started

You need a recent stable Rust toolchain (1.95 or newer for the desktop app).

```sh
git clone https://github.com/mad10188/dreamlab-pdf
cd dreamlab-pdf
cargo run --release -p dreamlab-pdf -- some.pdf        # desktop app
cargo run --release -p dreamlab-pdf-cli -- --help      # command-line tool and MCP server
cargo test --workspace                                 # the test suite
```

On Linux the desktop app needs the usual windowing development packages (for example on Debian/Ubuntu:
`libxkbcommon-dev libwayland-dev libx11-dev libgtk-3-dev`).

The interface language is chosen in **Menu → Edit → Preferences…** (Command-comma on macOS,
Ctrl-comma elsewhere). See [docs/localization.md](docs/localization.md).

Japanese UI and edited-PDF text use the optional [craft-fonts](https://github.com/storytold/craft-fonts)
build input:

```sh
git clone https://github.com/storytold/craft-fonts ../craft-fonts
CRAFT_FONTS_DIR=../craft-fonts cargo run --release -p dreamlab-pdf -- some.pdf
```

### Windows installer (setup.exe)

`packaging/windows/build-setup.sh` cross-compiles the app for Windows x64 from Linux (MinGW-w64) and
packages it with NSIS as `dist/release/dreamlab-pdf-<ver>-windows-x64-setup.exe`: per-machine install,
Start Menu and optional desktop shortcut, PDF handler registration, "Create PDF" on images, optional
OCR model download and optional CLI on PATH, with a clean uninstaller. Silent install:
`setup.exe /S [/NODESKTOP] [/NOOCR] [/CLIPATH] [/D=C:\Path]`; silent removal: `uninstall.exe /S`.

Packaging scripts for every platform (MSI, DMG, AppImage, Flatpak, `.deb`, `.rpm`, FreeBSD, web) are in
[`packaging/`](packaging/). Logs, environment variables and other development notes are in
[docs/development.md](docs/development.md).

### Panels and docking

Tools and Inspector panels can be dragged into tab groups, split beside the PDF, or floated within the app window. Read and full-screen modes keep their existing focused document view. Drag a panel header to a target edge or another header. Its context menu offers Float panel, Move to group, and Close panel. Existing panel toggles reopen panels at their saved location; Reset Panel Layout restores the app layout. Floating panels remain inside the current app window.

Advanced `ui.dock` operations use the same validated transaction as pointer gestures:
`moveFloating` updates `rect`, `resizeSplit` accepts a boolean child `path` and
`size` (`{"Ratio":0.5}`, `{"FixedFirst":280}`, or `{"FixedSecond":280}`),
`setStackOpen` takes `open`, and `resizeStack` takes a point `height` or null.
A center `move` can include `before` (panel ID or null to append) for tab order.
The equivalent `{"action": ...}` form accepts a serialized shared docking action;
this is also the form emitted by the renderer. Protected-canvas and app-specific panel
rules apply equally to both forms.

## Status

DreamLab PDF is **alpha**, tracking the PdfCraft codebase as of October 2026. Viewing, organizing,
commenting, form filling, passwords, redaction and agent control work well; editing existing text,
non-Latin OCR, Office import/export and Windows printing are thin. Details are in
[ROADMAP.md](ROADMAP.md), [docs/gaps.md](docs/gaps.md) and [docs/target-app-parity.md](docs/target-app-parity.md).

Bugs and ideas: [open an issue](https://github.com/mad10188/dreamlab-pdf/issues).

## License and credits

DreamLab PDF is dual-licensed under [MIT](LICENSE-MIT) or [Apache-2.0](LICENSE-APACHE), at your option.
Copyright (c) 2026 Marc Joseph and the DreamLab PDF contributors.

DreamLab PDF is a modified version of [PdfCraft](https://github.com/storytold/pdfcraft),
Copyright (c) 2026 ArtCraft Team and the PdfCraft contributors, used under the same licenses. Required
notices are in [NOTICE](NOTICE).

Bundled fonts, icons, images and other assets keep their own open licenses; each one is listed with its
author, source and license in [ATTRIBUTION.md](ATTRIBUTION.md).

<sub>Adobe and Acrobat are trademarks or registered trademarks of Adobe Inc. in the United States and/or
other countries. DreamLab PDF is an independent, open-source project and is not affiliated with,
sponsored by or endorsed by Adobe Inc.; these names are used only to describe compatible workflows.</sub>
