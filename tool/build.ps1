# Sonora builder — turns the sources into a real, double-clickable app.
#
#   powershell -ExecutionPolicy Bypass -File tool/build.ps1 -Target windows
#   powershell -ExecutionPolicy Bypass -File tool/build.ps1 -Target android
#
# Result:
#   dist\Sonora\sonora.exe        (Windows, portable folder)
#   dist\sonora.apk              (Android)
#
# Prerequisites (checked below, with links):
#   Windows : Flutter SDK + Visual Studio "Desktop development with C++"
#   Android : Flutter SDK + JDK 17 + Android SDK

param(
  [ValidateSet('windows', 'android')]
  [string]$Target = 'windows',

  # Optional explicit path to flutter\bin\flutter.bat
  [string]$FlutterPath = '',

  # Launch the app right after a successful build
  [switch]$Run
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

function Write-Step($msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Fail($msg) {
  Write-Host "`n[!] $msg" -ForegroundColor Red
  exit 1
}

# ---------------------------------------------------------------- find flutter
Write-Step 'Looking for the Flutter SDK'
$flutter = $null
if ($FlutterPath -and (Test-Path $FlutterPath)) {
  $flutter = $FlutterPath
} elseif (Get-Command flutter -ErrorAction SilentlyContinue) {
  $flutter = (Get-Command flutter).Source
} else {
  foreach ($p in @(
      "$env:LOCALAPPDATA\flutter\bin\flutter.bat",
      "C:\src\flutter\bin\flutter.bat",
      "C:\flutter\bin\flutter.bat",
      "$env:USERPROFILE\flutter\bin\flutter.bat")) {
    if (Test-Path $p) { $flutter = $p; break }
  }
}

if (-not $flutter) {
  Write-Host @"

Flutter SDK not found.

Install it once (10 minutes):
  1. Download:  https://docs.flutter.dev/get-started/install/windows/desktop
     (flutter_windows_<version>-stable.zip, ~1 GB)
  2. Unpack to: C:\src\flutter        (do NOT put it in Program Files)
  3. Add to PATH: C:\src\flutter\bin
  4. New terminal -> flutter doctor

For a Windows .exe you also need the C++ toolchain:
  Visual Studio Installer -> Modify -> check
  "Desktop development with C++"  (MSVC v143 + Windows 10/11 SDK)

Then rerun:
  powershell -ExecutionPolicy Bypass -File tool/build.ps1 -Target windows
"@ -ForegroundColor Yellow
  exit 1
}
Write-Host "flutter: $flutter" -ForegroundColor Green

# --------------------------------------------------------------- prerequisites
Write-Step 'flutter doctor (summary)'
& $flutter doctor
if ($LASTEXITCODE -ne 0) { Write-Host 'flutter doctor reported problems - continuing anyway' -ForegroundColor Yellow }

# ------------------------------------------------------------------- platform dirs
if (-not (Test-Path (Join-Path $root 'windows')) -and $Target -eq 'windows') {
  Write-Step 'Platform folders missing -> generating them with your Flutter'
  & powershell -ExecutionPolicy Bypass -File (Join-Path $root 'tool/setup_platforms.ps1')
  if ($LASTEXITCODE -ne 0) { Fail 'setup_platforms.ps1 failed' }
}
if (-not (Test-Path (Join-Path $root 'android')) -and $Target -eq 'android') {
  Write-Step 'Platform folders missing -> generating them with your Flutter'
  & powershell -ExecutionPolicy Bypass -File (Join-Path $root 'tool/setup_platforms.ps1')
  if ($LASTEXITCODE -ne 0) { Fail 'setup_platforms.ps1 failed' }
}

# ------------------------------------------------------------------- dependencies
Write-Step 'flutter pub get'
& $flutter pub get
if ($LASTEXITCODE -ne 0) { Fail 'pub get failed (check your network / proxy)' }

# ------------------------------------------------------------------------- build
$dist = Join-Path $root 'dist'
New-Item -ItemType Directory -Force -Path $dist | Out-Null

if ($Target -eq 'windows') {
  Write-Step 'Building Windows release (this takes 2-5 min the first time)'
  & $flutter build windows --release
  if ($LASTEXITCODE -ne 0) {
    Write-Host @"

Build failed. Most common causes:
  * "Visual Studio not installed" -> add the "Desktop development with C++" workload
  * Antivirus blocks CMake/ninja -> add an exclusion for the project folder
  * Old Flutter -> flutter upgrade
"@ -ForegroundColor Yellow
    exit 1
  }

  $release = Join-Path $root 'build\windows\x64\runner\Release'
  if (-not (Test-Path $release)) {
    $release = (Get-ChildItem (Join-Path $root 'build\windows') -Recurse -Directory |
      Where-Object { Test-Path (Join-Path $_.FullName 'flutter_windows.dll') } |
      Select-Object -First 1).FullName
  }
  if (-not $release) { Fail 'Release folder not found' }

  $out = Join-Path $dist 'Sonora'
  if (Test-Path $out) { Remove-Item $out -Recurse -Force }
  Copy-Item $release $out -Recurse
  Set-Content -Path (Join-Path $out 'PORTABLE.txt') -Value 'Portable build. Settings live in %APPDATA%\Sonora.' -Encoding UTF8

  $exe = Get-ChildItem $out -Filter *.exe | Select-Object -First 1
  Write-Host "`nDONE: $($exe.FullName)" -ForegroundColor Green
  Write-Host "This folder is the app. Zip it and it works on any Windows 10/11 x64." -ForegroundColor Gray
  if ($Run) { Start-Process $exe.FullName }
  else { Start-Process explorer.exe $out }
}
else {
  Write-Step 'Building Android release APK'
  & $flutter build apk --release --split-per-abi
  if ($LASTEXITCODE -ne 0) {
    Write-Host "`nBuild failed. Usually: no JDK 17 or no Android SDK. Run 'flutter doctor'." -ForegroundColor Yellow
    exit 1
  }
  $apkDir = Join-Path $root 'build\app\outputs\flutter-apk'
  $apk = Get-ChildItem $apkDir -Filter '*-arm64-v8a-release.apk' | Select-Object -First 1
  if (-not $apk) { $apk = Get-ChildItem $apkDir -Filter '*.apk' | Select-Object -First 1 }
  if (-not $apk) { Fail 'APK not found' }
  $dest = Join-Path $dist 'sonora.apk'
  Copy-Item $apk.FullName $dest -Force
  Write-Host "`nDONE: $dest" -ForegroundColor Green
  Write-Host 'Copy it to the phone and install (allow unknown sources).' -ForegroundColor Gray
  if ($Run) { Start-Process explorer.exe $dist }
}
