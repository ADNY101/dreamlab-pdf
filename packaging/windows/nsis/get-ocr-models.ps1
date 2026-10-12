<#
.SYNOPSIS
  Download the OCR models DreamLab PDF uses for Scan & OCR into the models\ folder beside
  dreamlab-pdf.exe, verifying each file's SHA-256.

.DESCRIPTION
  The setup.exe runs this when "OCR models" is ticked. You can also run it yourself later
  (from an elevated PowerShell when DreamLab PDF is installed under Program Files):

    powershell -ExecutionPolicy Bypass -File "C:\Program Files\DreamLab PDF\get-ocr-models.ps1"

  The models are by Robert Knight (https://github.com/robertknight/ocrs-models), CC-BY-SA-4.0.
  Hashes match ATTRIBUTION.toml in the DreamLab PDF source.
#>
param([string] $ModelsDir = (Join-Path $PSScriptRoot 'models'))
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'   # Invoke-WebRequest is far slower with the progress bar
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$licence = @{
  Url    = 'https://creativecommons.org/licenses/by-sa/4.0/legalcode.txt'
  Sha256 = '28a9529c7d0bb4dc51f4bf5c116a3d16ef247a052f7591466768ddf563fd1cf5'
}
$models = @(
  @{ File = 'text-detection.rten';   Url = 'https://ocrs-models.s3-accelerate.amazonaws.com/text-detection.rten';   Sha256 = 'f15cfb56bd02c4bf478a20343986504a1f01e1665c2b3a0ad66340f054b1b5ca' },
  @{ File = 'text-recognition.rten'; Url = 'https://ocrs-models.s3-accelerate.amazonaws.com/text-recognition.rten'; Sha256 = 'e484866d4cce403175bd8d00b128feb08ab42e208de30e42cd9889d8f1735a6e' }
)

function Get-Verified([string] $Url, [string] $Sha256, [string] $Dest) {
  if ((Test-Path $Dest) -and ((Get-FileHash $Dest -Algorithm SHA256).Hash -eq $Sha256)) {
    Write-Output "ok (already present): $Dest"
    return
  }
  $tmp = "$Dest.part"
  Invoke-WebRequest -Uri $Url -OutFile $tmp -UseBasicParsing
  $got = (Get-FileHash $tmp -Algorithm SHA256).Hash
  if ($got -ne $Sha256) {
    Remove-Item $tmp -Force
    throw "SHA-256 mismatch for $Url (got $got)"
  }
  Move-Item $tmp $Dest -Force
  Write-Output "downloaded: $Dest"
}

New-Item -ItemType Directory -Force -Path $ModelsDir | Out-Null
$licenceTmp = Join-Path $ModelsDir 'CC-BY-SA-4.0.txt'
Get-Verified $licence.Url $licence.Sha256 $licenceTmp
foreach ($m in $models) {
  Get-Verified $m.Url $m.Sha256 (Join-Path $ModelsDir $m.File)
  Copy-Item $licenceTmp (Join-Path $ModelsDir "$($m.File).LICENCE.txt") -Force
}
Remove-Item $licenceTmp -Force
Write-Output "OCR models ready in $ModelsDir"
