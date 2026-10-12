# DreamLab PDF app icon

<img src="dreamlab-pdf-small.svg" alt="DreamLab PDF app icon: a page with a crescent moon and a sparkle on an indigo-to-violet tile" width="128">

**Motif:** a document page with a folded corner, a crescent moon (the "dream") and two text lines, with a
sparkle beside it.

**Palette:** indigo `#312e81` → violet `#7c3aed` tile gradient, paper `#f8f7ff`, accents `#6d28d9`,
`#a5b4fc`, `#c4b5fd` and `#fde68a`.

**Tile:** `viewBox="0 0 512 512"`, a rounded square with `rx=112` that clips everything. Windows and Linux
icons use the full-bleed tile. macOS icons put it on Apple's grid (an 824 px body centred on a transparent
1024 px canvas).

**Provenance:** original placeholder artwork for DreamLab PDF, hand-written SVG.
Licence: [LICENSE.txt](LICENSE.txt) (`MIT OR Apache-2.0`, like the repo).

## Files

| File | What it is |
|---|---|
| `dreamlab-pdf.svg` | the master vector; every PNG, `.ico` and `.icns` is rendered from it |
| `dreamlab-pdf-small.svg` | a copy of the master for places such as this README |
| `dreamlab-pdf-1024.png` | 1024 px on Apple's grid; also the runtime Dock icon on macOS |
| `dreamlab-pdf.icns` | macOS icon (16–1024 px) |
| `dreamlab-pdf.ico` | Windows icon (16–256 px), embedded in `dreamlab-pdf.exe` by `apps/dreamlab-pdf/build.rs` |
| `dreamlab-pdf-document.svg` | Windows PDF file icon master: a Lucide document outline, green badge and outlined PDF lettering; no font dependency |
| `dreamlab-pdf-document.ico` | Windows PDF file icon (16–256 px), embedded as resource 2 in `dreamlab-pdf.exe` |
| `hicolor/<n>x<n>/apps/com.dreamlab.pdf.png` | Linux hicolor theme, 16–512 px; the 256 px one is the runtime icon on Windows and Linux |
| `hicolor/scalable/apps/com.dreamlab.pdf.svg` | Linux scalable icon (copy of the master) |

Where it shows: `apps/dreamlab-pdf/src/main.rs` sets the window icon (Dock, taskbar, Alt-Tab, launcher) and the
Wayland app id `com.dreamlab.pdf`; `packaging/linux/com.dreamlab.pdf.desktop` names the
hicolor icon.

Windows PDF files use resource 2 (`"dreamlab-pdf.exe",-2`) when DreamLab PDF is chosen as the default
reader; the app keeps resource 1. The document outline is adapted from Lucide `file-text`
1.49.0 (ISC); its badge and outlined lettering are original (`MIT OR Apache-2.0`), covered by
[LICENSE-document.txt](LICENSE-document.txt). Both icons are embedded, requiring no runtime
sidecar. This provides a file type icon; first-page thumbnails still need a thumbnail provider.

## Regenerate

```sh
packaging/icons.sh        # needs resvg and python3; iconutil (macOS) for the .icns
cargo xtask assets        # then update the sha256 values in ATTRIBUTION.toml and run with --write
```
