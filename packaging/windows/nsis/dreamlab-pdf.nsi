; DreamLab PDF setup.exe (NSIS 3). Built by packaging/windows/build-setup.sh:
;   makensis -DVERSION=0.6.0 -DSTAGE=<dir with the files> -DOUTFILE=<setup.exe> dreamlab-pdf.nsi
;
; Mirrors dreamlab-pdf.wxs (the MSI): per-machine install into Program Files, Start Menu shortcut,
; optional desktop shortcut, App Paths entry, DreamLab PDF registered as a PDF handler (offered in
; "Open with" and Settings > Default apps, never forced as the default), and the "Create PDF with
; DreamLab PDF..." image context menu. Adds: optional OCR model download, optional CLI on PATH.
;
; -DWITH_CLI also installs dreamlab-pdf-cli.exe (and offers it on PATH). Without it the CLI ships
; as its own zip, which keeps setup.exe small.
;
; Silent install:  setup.exe /S [/NODESKTOP] [/NOOCR] [/CLIPATH] [/D=C:\Path\To\Install]
; Silent removal:  "C:\Program Files\DreamLab PDF\uninstall.exe" /S

Target amd64-unicode   ; native 64-bit installer (the app is x64-only)
ManifestDPIAware true
SetCompressor /SOLID lzma

!include "MUI2.nsh"
!include "x64.nsh"
!include "FileFunc.nsh"
!include "LogicLib.nsh"
!include "WinMessages.nsh"

!ifndef VERSION
  !error "pass -DVERSION=x.y.z"
!endif
!ifndef STAGE
  !error "pass -DSTAGE=<staging dir>"
!endif
!ifndef OUTFILE
  !define OUTFILE "dreamlab-pdf-${VERSION}-windows-x64-setup.exe"
!endif

!define APPNAME     "DreamLab PDF"
!define PUBLISHER   "DreamLab"
!define EXE         "dreamlab-pdf.exe"
!define PROGID      "DreamLabPDF.Document"
!define VERB        "DreamLabPDF.CreatePdf"
!define UNINSTKEY   "Software\Microsoft\Windows\CurrentVersion\Uninstall\DreamLab PDF"
!define APPKEY      "Software\DreamLab PDF"
!define URL         "https://github.com/mad10188/dreamlab-pdf"

Name "${APPNAME}"
OutFile "${OUTFILE}"
InstallDir "$PROGRAMFILES64\${APPNAME}"
InstallDirRegKey HKLM "${APPKEY}" "InstallDir"
RequestExecutionLevel admin
BrandingText "${APPNAME} ${VERSION}"

VIProductVersion "${VERSION}.0"
VIAddVersionKey "ProductName" "${APPNAME}"
VIAddVersionKey "CompanyName" "${PUBLISHER}"
VIAddVersionKey "FileDescription" "${APPNAME} Setup"
VIAddVersionKey "FileVersion" "${VERSION}"
VIAddVersionKey "ProductVersion" "${VERSION}"
VIAddVersionKey "LegalCopyright" "Copyright (c) 2026 Marc Joseph and the DreamLab PDF contributors. MIT OR Apache-2.0."

; ---- Look ------------------------------------------------------------------------------------
!define MUI_ICON   "${STAGE}\dreamlab-pdf.ico"
!define MUI_UNICON "${STAGE}\dreamlab-pdf.ico"
!define MUI_WELCOMEFINISHPAGE_BITMAP   "wizard.bmp"
!define MUI_UNWELCOMEFINISHPAGE_BITMAP "wizard.bmp"
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_RIGHT
!define MUI_HEADERIMAGE_BITMAP   "header.bmp"
!define MUI_HEADERIMAGE_UNBITMAP "header.bmp"
!define MUI_ABORTWARNING
!define MUI_COMPONENTSPAGE_SMALLDESC

!define MUI_WELCOMEPAGE_TEXT "This will install ${APPNAME} ${VERSION}, a fast, private, open-source PDF workbench.$\r$\n$\r$\nRead, organize, combine, split, comment on, fill in, sign and protect PDFs. Your documents never leave your computer.$\r$\n$\r$\nClick Next to continue."
!define MUI_LICENSEPAGE_TEXT_TOP "${APPNAME} is free, open-source software."
!define MUI_LICENSEPAGE_TEXT_BOTTOM "You may use it under the MIT License or the Apache License 2.0, at your option. No agreement is required to install it."
!define MUI_LICENSEPAGE_BUTTON "&Next >"

!define MUI_FINISHPAGE_RUN
!define MUI_FINISHPAGE_RUN_TEXT "Launch ${APPNAME}"
!define MUI_FINISHPAGE_RUN_FUNCTION LaunchUnelevated
!define MUI_FINISHPAGE_LINK "${APPNAME} on GitHub"
!define MUI_FINISHPAGE_LINK_LOCATION "${URL}"

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "${STAGE}\LICENSE-MIT.txt"
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "English"

; ---- Sections --------------------------------------------------------------------------------
Section "${APPNAME} (required)" SecMain
  SectionIn RO
  SetShellVarContext all
  SetOutPath "$INSTDIR"
  File "${STAGE}\${EXE}"
  !ifdef WITH_CLI
    File "${STAGE}\dreamlab-pdf-cli.exe"
  !endif
  File "${STAGE}\get-ocr-models.ps1"
  File "${STAGE}\LICENSE-MIT.txt"
  File "${STAGE}\LICENSE-APACHE.txt"
  File "${STAGE}\NOTICE.txt"
  File "${STAGE}\LICENSE-document.txt"
  SetOutPath "$INSTDIR\models"
  File "${STAGE}\models\ATTRIBUTION.txt"
  SetOutPath "$INSTDIR"

  ; Start Menu: a plain link to the program (Windows can use it as a file handler).
  CreateShortcut "$SMPROGRAMS\${APPNAME}.lnk" "$INSTDIR\${EXE}" "" "$INSTDIR\${EXE}" 0 SW_SHOWNORMAL "" "${APPNAME} workbench"

  ; App Paths: "dreamlab-pdf" in Win+R and Start search.
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\App Paths\${EXE}" "" "$INSTDIR\${EXE}"

  ; PDF handler registration (Default Programs). .pdf's own default is left alone.
  WriteRegStr HKLM "Software\Classes\${PROGID}" "" "PDF Document"
  WriteRegStr HKLM "Software\Classes\${PROGID}\DefaultIcon" "" '"$INSTDIR\${EXE}",-2'
  WriteRegStr HKLM "Software\Classes\${PROGID}\shell\open\command" "" '"$INSTDIR\${EXE}" "%1"'
  WriteRegStr HKLM "Software\Classes\.pdf\OpenWithProgids" "${PROGID}" ""
  WriteRegStr HKLM "Software\Classes\Applications\${EXE}" "FriendlyAppName" "${APPNAME}"
  WriteRegStr HKLM "Software\Classes\Applications\${EXE}\DefaultIcon" "" '"$INSTDIR\${EXE}",-2'
  WriteRegStr HKLM "Software\Classes\Applications\${EXE}\SupportedTypes" ".pdf" ""
  WriteRegStr HKLM "Software\Classes\Applications\${EXE}\shell\open\command" "" '"$INSTDIR\${EXE}" "%1"'
  WriteRegStr HKLM "${APPKEY}\Capabilities" "ApplicationName" "${APPNAME}"
  WriteRegStr HKLM "${APPKEY}\Capabilities" "ApplicationDescription" "Open-source PDF workbench"
  WriteRegStr HKLM "${APPKEY}\Capabilities" "ApplicationIcon" "$INSTDIR\${EXE},0"
  WriteRegStr HKLM "${APPKEY}\Capabilities\FileAssociations" ".pdf" "${PROGID}"
  WriteRegStr HKLM "Software\RegisteredApplications" "${APPNAME}" "${APPKEY}\Capabilities"

  ; Image context menu: "Create PDF with DreamLab PDF..." without changing image defaults.
  !macro ImageVerb ext
    WriteRegStr HKLM "Software\Classes\SystemFileAssociations\${ext}\shell\${VERB}" "" "Create PDF with ${APPNAME}..."
    WriteRegStr HKLM "Software\Classes\SystemFileAssociations\${ext}\shell\${VERB}" "MultiSelectModel" "Single"
    WriteRegStr HKLM "Software\Classes\SystemFileAssociations\${ext}\shell\${VERB}\command" "" '"$INSTDIR\${EXE}" --create-images "%1"'
  !macroend
  !insertmacro ImageVerb ".png"
  !insertmacro ImageVerb ".jpg"
  !insertmacro ImageVerb ".jpeg"
  !insertmacro ImageVerb ".tif"
  !insertmacro ImageVerb ".tiff"
  !insertmacro ImageVerb ".gif"
  !insertmacro ImageVerb ".bmp"
  !insertmacro ImageVerb ".jp2"
  !insertmacro ImageVerb ".j2k"
  !insertmacro ImageVerb ".jpx"

  ; Uninstaller and the Add/Remove Programs entry.
  WriteRegStr HKLM "${APPKEY}" "InstallDir" "$INSTDIR"
  WriteRegStr HKLM "${APPKEY}" "Version" "${VERSION}"
  WriteUninstaller "$INSTDIR\uninstall.exe"
  WriteRegStr HKLM "${UNINSTKEY}" "DisplayName" "${APPNAME}"
  WriteRegStr HKLM "${UNINSTKEY}" "DisplayVersion" "${VERSION}"
  WriteRegStr HKLM "${UNINSTKEY}" "Publisher" "${PUBLISHER}"
  WriteRegStr HKLM "${UNINSTKEY}" "DisplayIcon" "$INSTDIR\${EXE},0"
  WriteRegStr HKLM "${UNINSTKEY}" "InstallLocation" "$INSTDIR"
  WriteRegStr HKLM "${UNINSTKEY}" "URLInfoAbout" "${URL}"
  WriteRegStr HKLM "${UNINSTKEY}" "HelpLink" "${URL}/issues"
  WriteRegStr HKLM "${UNINSTKEY}" "UninstallString" '"$INSTDIR\uninstall.exe"'
  WriteRegStr HKLM "${UNINSTKEY}" "QuietUninstallString" '"$INSTDIR\uninstall.exe" /S'
  WriteRegDWORD HKLM "${UNINSTKEY}" "NoModify" 1
  WriteRegDWORD HKLM "${UNINSTKEY}" "NoRepair" 1
  ${GetSize} "$INSTDIR" "/S=0K" $0 $1 $2
  IntFmt $0 "0x%08X" $0
  WriteRegDWORD HKLM "${UNINSTKEY}" "EstimatedSize" "$0"

  ; Tell Explorer about the new file associations.
  System::Call 'shell32::SHChangeNotify(i 0x08000000, i 0, p 0, p 0)'
SectionEnd

Section "Desktop shortcut" SecDesktop
  SetShellVarContext all
  CreateShortcut "$DESKTOP\${APPNAME}.lnk" "$INSTDIR\${EXE}" "" "$INSTDIR\${EXE}" 0 SW_SHOWNORMAL "" "${APPNAME} workbench"
  WriteRegDWORD HKLM "${APPKEY}\Shortcuts" "Desktop" 1
SectionEnd

Section "OCR models (download, about 12 MB)" SecOcr
  DetailPrint "Downloading the OCR models for Scan & OCR..."
  nsExec::ExecToLog 'powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "$INSTDIR\get-ocr-models.ps1"'
  Pop $0
  ${If} $0 != 0
    DetailPrint "OCR models could not be downloaded (exit code $0)."
    MessageBox MB_ICONINFORMATION|MB_OK "The OCR models could not be downloaded right now. Everything else is installed.$\r$\n$\r$\nTo add them later, run this from an administrator PowerShell:$\r$\n$\r$\npowershell -ExecutionPolicy Bypass -File $\"$INSTDIR\get-ocr-models.ps1$\"" /SD IDOK
  ${EndIf}
SectionEnd

!ifdef WITH_CLI
Section /o "Add dreamlab-pdf-cli to PATH" SecPath
  ; System PATH, appended once. PowerShell does the string work and keeps REG_EXPAND_SZ.
  nsExec::ExecToLog `powershell.exe -NoProfile -NonInteractive -Command "$$k='HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment'; $$p=(Get-Item $$k).GetValue('Path','',[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames); $$d='$INSTDIR'; if (($$p -split ';') -notcontains $$d) { Set-ItemProperty $$k -Name Path -Type ExpandString -Value (($$p.TrimEnd(';')) + ';' + $$d) }"`
  Pop $0
  WriteRegDWORD HKLM "${APPKEY}" "OnPath" 1
  SendMessage ${HWND_BROADCAST} ${WM_SETTINGCHANGE} 0 "STR:Environment" /TIMEOUT=5000
SectionEnd
!endif

LangString DESC_Main    ${LANG_ENGLISH} "The DreamLab PDF app, Start Menu shortcut, and registration as a PDF handler (you choose the default in Settings)."
LangString DESC_Desktop ${LANG_ENGLISH} "A DreamLab PDF shortcut on the desktop for all users."
LangString DESC_Ocr     ${LANG_ENGLISH} "Downloads the text-recognition models used by Scan & OCR (CC-BY-SA-4.0, verified by SHA-256). Needs an internet connection."
!ifdef WITH_CLI
LangString DESC_Path    ${LANG_ENGLISH} "Lets you run dreamlab-pdf-cli from any terminal (adds the install folder to the system PATH)."
!endif
!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
  !insertmacro MUI_DESCRIPTION_TEXT ${SecMain}    $(DESC_Main)
  !insertmacro MUI_DESCRIPTION_TEXT ${SecDesktop} $(DESC_Desktop)
  !insertmacro MUI_DESCRIPTION_TEXT ${SecOcr}     $(DESC_Ocr)
  !ifdef WITH_CLI
    !insertmacro MUI_DESCRIPTION_TEXT ${SecPath}    $(DESC_Path)
  !endif
!insertmacro MUI_FUNCTION_DESCRIPTION_END

; ---- Functions -------------------------------------------------------------------------------
Function .onInit
  ${IfNot} ${RunningX64}
    MessageBox MB_ICONSTOP|MB_OK "${APPNAME} requires 64-bit Windows." /SD IDOK
    Abort
  ${EndIf}
  SetRegView 64
  ; A previous install's folder wins over the default (upgrades in place).
  ReadRegStr $0 HKLM "${APPKEY}" "InstallDir"
  ${If} $0 != ""
    StrCpy $INSTDIR $0
  ${EndIf}
  ; Command-line switches for unattended installs.
  ${GetParameters} $R0
  ClearErrors
  ${GetOptions} $R0 "/NODESKTOP" $R1
  ${IfNot} ${Errors}
    !insertmacro UnselectSection ${SecDesktop}
  ${EndIf}
  ClearErrors
  ${GetOptions} $R0 "/NOOCR" $R1
  ${IfNot} ${Errors}
    !insertmacro UnselectSection ${SecOcr}
  ${EndIf}
  !ifdef WITH_CLI
    ClearErrors
    ${GetOptions} $R0 "/CLIPATH" $R1
    ${IfNot} ${Errors}
      !insertmacro SelectSection ${SecPath}
    ${EndIf}
  !endif
FunctionEnd

; The installer runs elevated; launching through Explorer starts the app as the signed-in user,
; so drag-and-drop from Explorer and per-user settings work as normal.
Function LaunchUnelevated
  Exec '"$WINDIR\explorer.exe" "$INSTDIR\${EXE}"'
FunctionEnd

Function un.onInit
  SetRegView 64
FunctionEnd

; ---- Uninstall -------------------------------------------------------------------------------
Section "Uninstall"
  SetShellVarContext all

  ; Remove the install folder from PATH if we added it.
  ReadRegDWORD $0 HKLM "${APPKEY}" "OnPath"
  ${If} $0 == 1
    nsExec::ExecToLog `powershell.exe -NoProfile -NonInteractive -Command "$$k='HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment'; $$p=(Get-Item $$k).GetValue('Path','',[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames); $$d='$INSTDIR'; Set-ItemProperty $$k -Name Path -Type ExpandString -Value ((($$p -split ';') | Where-Object { $$_ -and $$_ -ne $$d }) -join ';')"`
    Pop $0
    SendMessage ${HWND_BROADCAST} ${WM_SETTINGCHANGE} 0 "STR:Environment" /TIMEOUT=5000
  ${EndIf}

  Delete "$SMPROGRAMS\${APPNAME}.lnk"
  Delete "$DESKTOP\${APPNAME}.lnk"

  Delete "$INSTDIR\${EXE}"
  Delete "$INSTDIR\dreamlab-pdf-cli.exe"
  Delete "$INSTDIR\get-ocr-models.ps1"
  Delete "$INSTDIR\LICENSE-MIT.txt"
  Delete "$INSTDIR\LICENSE-APACHE.txt"
  Delete "$INSTDIR\NOTICE.txt"
  Delete "$INSTDIR\LICENSE-document.txt"
  RMDir /r "$INSTDIR\models"
  Delete "$INSTDIR\uninstall.exe"
  RMDir "$INSTDIR"

  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\App Paths\${EXE}"
  DeleteRegKey HKLM "Software\Classes\${PROGID}"
  DeleteRegValue HKLM "Software\Classes\.pdf\OpenWithProgids" "${PROGID}"
  DeleteRegKey HKLM "Software\Classes\Applications\${EXE}"
  DeleteRegValue HKLM "Software\RegisteredApplications" "${APPNAME}"
  !macro UnImageVerb ext
    DeleteRegKey HKLM "Software\Classes\SystemFileAssociations\${ext}\shell\${VERB}"
  !macroend
  !insertmacro UnImageVerb ".png"
  !insertmacro UnImageVerb ".jpg"
  !insertmacro UnImageVerb ".jpeg"
  !insertmacro UnImageVerb ".tif"
  !insertmacro UnImageVerb ".tiff"
  !insertmacro UnImageVerb ".gif"
  !insertmacro UnImageVerb ".bmp"
  !insertmacro UnImageVerb ".jp2"
  !insertmacro UnImageVerb ".j2k"
  !insertmacro UnImageVerb ".jpx"
  DeleteRegKey HKLM "${APPKEY}"
  DeleteRegKey HKLM "${UNINSTKEY}"

  System::Call 'shell32::SHChangeNotify(i 0x08000000, i 0, p 0, p 0)'
  ; Per-user settings, recent files and logs (%APPDATA%\DreamLab PDF) are kept, like most apps.
SectionEnd
