#!/usr/bin/env bash
# Build dist/release/dreamlab-pdf-<version>-windows-x64-setup.exe from Linux (or WSL/macOS with NSIS).
#
# Cross-compiles dreamlab-pdf.exe and dreamlab-pdf-cli.exe for x86_64-pc-windows-gnu with MinGW-w64,
# then packages them with NSIS (packaging/windows/nsis/dreamlab-pdf.nsi).
#
# Needs: Rust (stable), MinGW-w64 (x86_64-w64-mingw32-gcc, -windres), NSIS (makensis), python3.
#   Ubuntu/Debian: sudo apt install mingw-w64 nsis cmake nasm
#   Rust target:   rustup target add x86_64-pc-windows-gnu
# If the Rust target can't be downloaded (offline mirrors), set BUILD_STD=1 with the rust-src
# component (or a matching library/ checkout) in the toolchain's sysroot: std is then built from source.
#
#   packaging/windows/build-setup.sh            # build + package
#   SKIP_BUILD=1 packaging/windows/build-setup.sh
#   WITH_CLI=1 packaging/windows/build-setup.sh    # put the CLI in setup.exe too (larger)
#
# Writes to dist/release/: the setup.exe, a portable zip of the app, and the CLI as its own zip.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
TARGET=x86_64-pc-windows-gnu
VERSION="${DREAMLAB_PDF_VERSION:-$(awk '/^\[workspace.package\]/{p=1;next} /^\[/{p=0} p && /^version/{gsub(/[" ]/,"",$0); split($0,a,"="); print a[2]; exit}' Cargo.toml)}"
DIST="${DIST:-$ROOT/dist/release}"
STAGE="$ROOT/target/setup-stage"
echo "DreamLab PDF $VERSION: Windows x64 setup.exe"

if [ -z "${SKIP_BUILD:-}" ]; then
  export CARGO_TARGET_X86_64_PC_WINDOWS_GNU_LINKER=x86_64-w64-mingw32-gcc
  # Static libgcc/winpthread: the .exe files need no MinGW DLLs beside them.
  export CARGO_TARGET_X86_64_PC_WINDOWS_GNU_RUSTFLAGS="-C target-feature=+crt-static"
  export CC_x86_64_pc_windows_gnu=x86_64-w64-mingw32-gcc CXX_x86_64_pc_windows_gnu=x86_64-w64-mingw32-g++
  export AR_x86_64_pc_windows_gnu=x86_64-w64-mingw32-ar
  export DREAMLAB_PDF_REQUIRE_WINRES=1
  extra=()
  if [ -n "${BUILD_STD:-}" ]; then
    export RUSTC_BOOTSTRAP=1
    extra=(-Zbuild-std=std,panic_unwind)
  fi
  cargo build --release "${extra[@]}" --target "$TARGET" -p dreamlab-pdf -p dreamlab-pdf-cli
fi

BIN="$ROOT/target/$TARGET/release"
rm -rf "$STAGE" && mkdir -p "$STAGE/models" "$DIST"
cp "$BIN/dreamlab-pdf.exe" "$BIN/dreamlab-pdf-cli.exe" "$STAGE/"
x86_64-w64-mingw32-strip "$STAGE/"*.exe || true
cp assets/app-icon/dreamlab-pdf.ico "$STAGE/"
cp packaging/windows/nsis/get-ocr-models.ps1 "$STAGE/"
# Text files with Windows line endings, so Notepad shows them properly.
crlf() { sed 's/\r$//; s/$/\r/' "$1" > "$2"; }
crlf LICENSE-MIT "$STAGE/LICENSE-MIT.txt"
crlf LICENSE-APACHE "$STAGE/LICENSE-APACHE.txt"
crlf NOTICE "$STAGE/NOTICE.txt"
crlf assets/app-icon/LICENSE-document.txt "$STAGE/LICENSE-document.txt"
# Model credits (the same text `cargo xtask models` writes beside the models).
python3 - "$STAGE/models/ATTRIBUTION.txt" <<'PY'
import sys, tomllib
m = tomllib.load(open("ATTRIBUTION.toml", "rb"))
s = "DreamLab PDF's text recognition (Scan & OCR) uses these models, unmodified.\n"
for f in m.get("fetched", []):
    if f.get("kind") == "model":
        s += (f"\n{f['file']}\n  {f['title']}\n  by {f['author']}\n  from {f['source']}\n"
              f"  licence: {f['licence']} ({f['licence_url']}; full text in {f['file']}.LICENCE.txt)\n")
open(sys.argv[1], "w", newline="\r\n").write(s)
PY

OUT="$DIST/dreamlab-pdf-$VERSION-windows-x64-setup.exe"
nsis_cli=()
[ -n "${WITH_CLI:-}" ] && nsis_cli=(-DWITH_CLI)
(cd packaging/windows/nsis && makensis -V2 "${nsis_cli[@]}" -DVERSION="$VERSION" -DSTAGE="$STAGE" -DOUTFILE="$OUT" dreamlab-pdf.nsi)

# Portable app (portable.txt keeps settings beside the exe) and the CLI, each as its own zip.
PORT="$ROOT/target/portable"
APPDIR="$PORT/app/dreamlab-pdf-$VERSION-windows-x64-portable"
CLIDIR="$PORT/cli/dreamlab-pdf-cli-$VERSION-windows-x64"
rm -rf "$PORT" && mkdir -p "$APPDIR/models" "$CLIDIR"
cp "$STAGE/dreamlab-pdf.exe" "$STAGE/"*.txt "$STAGE/get-ocr-models.ps1" "$APPDIR/"
cp "$STAGE/models/ATTRIBUTION.txt" "$APPDIR/models/"
crlf packaging/windows/portable.txt "$APPDIR/portable.txt"
cp "$STAGE/dreamlab-pdf-cli.exe" "$STAGE/"*.txt "$CLIDIR/"
rm -f "$DIST/dreamlab-pdf-$VERSION-windows-x64-portable.zip" "$DIST/dreamlab-pdf-cli-$VERSION-windows-x64.zip"
(cd "$PORT/app" && zip -q -9 -r "$DIST/dreamlab-pdf-$VERSION-windows-x64-portable.zip" .)
(cd "$PORT/cli" && zip -q -9 -r "$DIST/dreamlab-pdf-cli-$VERSION-windows-x64.zip" .)
(cd "$DIST" && sha256sum dreamlab-pdf-*"$VERSION"-windows-x64* | grep -v '\.sha256' > "SHA256SUMS-$VERSION-windows-x64.txt")
ls -la "$DIST"
