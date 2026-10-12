//! Windows only: embed the app icon and version info (VERSIONINFO) into `dreamlab-pdf.exe`, so it
//! shows in Explorer, the taskbar, the Start menu and Alt-Tab. A separate PDF document icon
//! uses resource ID 2; the installer references it as `dreamlab-pdf.exe,-2`.
//!
//! On every other target this does nothing. A missing resource compiler is a warning, so a
//! cross-compile from macOS or Linux still links, unless `DREAMLAB_PDF_REQUIRE_WINRES=1` turns it
//! into an error (for release builds).

#[path = "src/windows_manifest.rs"]
mod windows_manifest;

fn main() {
    println!("cargo:rerun-if-changed=build.rs");
    println!("cargo:rerun-if-changed=../../assets/app-icon/dreamlab-pdf.ico");
    println!("cargo:rerun-if-changed=../../assets/app-icon/dreamlab-pdf-document.ico");
    println!("cargo:rerun-if-changed=src/windows_manifest.rs");
    println!("cargo:rerun-if-env-changed=DREAMLAB_PDF_REQUIRE_WINRES");
    if std::env::var("CARGO_CFG_TARGET_OS").as_deref() != Ok("windows") {
        return;
    }
    let mut res = winresource::WindowsResource::new();
    res.set_icon("../../assets/app-icon/dreamlab-pdf.ico")
        .set_icon_with_id("../../assets/app-icon/dreamlab-pdf-document.ico", "2")
        .set_manifest(windows_manifest::WINDOWS_MANIFEST)
        .set("ProductName", "DreamLab PDF")
        .set("FileDescription", "DreamLab PDF workbench")
        .set("LegalCopyright", "Copyright (c) the DreamLab PDF contributors. MIT OR Apache-2.0.")
        .set("OriginalFilename", "dreamlab-pdf.exe")
        .set("InternalName", "dreamlab-pdf");
    if let Err(e) = res.compile() {
        if std::env::var_os("DREAMLAB_PDF_REQUIRE_WINRES").is_some() {
            println!("cargo::error=embedding Windows resources failed: {e}");
            return;
        }
        println!("cargo:warning=dreamlab-pdf.exe built without icon/version resources: {e}");
    }
}
