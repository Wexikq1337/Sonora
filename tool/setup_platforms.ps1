# Generates the platform folders (windows/linux/android) with YOUR local Flutter
# version, then copies them into the project. Nothing in lib/ is touched.
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  Write-Host "flutter not found in PATH. Install Flutter 3.19+ and retry." -ForegroundColor Red
  exit 1
}

$tmp = Join-Path $env:TEMP ("sonora_scaffold_" + [guid]::NewGuid().ToString("N").Substring(0, 8))
New-Item -ItemType Directory -Path $tmp | Out-Null
Write-Host "Generating platform scaffolding in $tmp ..." -ForegroundColor Cyan

flutter create --platforms=windows,linux,android --org app.sonora --project-name sonora --no-pub $tmp | Out-Host
if ($LASTEXITCODE -ne 0) { throw "flutter create failed" }

foreach ($p in @("windows", "linux", "android")) {
  $src = Join-Path $tmp $p
  $dst = Join-Path $root $p
  if (Test-Path $src) {
    if (Test-Path $dst) { Remove-Item $dst -Recurse -Force }
    Copy-Item $src $dst -Recurse
    Write-Host "copied $p/" -ForegroundColor Green
  }
}

Remove-Item $tmp -Recurse -Force

# audioplayers needs API 24+; Flutter's default minSdk may be lower.
foreach ($f in @("$root\android\app\build.gradle", "$root\android\app\build.gradle.kts")) {
  if (Test-Path $f) {
    $c = Get-Content $f -Raw
    $c = $c -replace 'minSdkVersion\s+flutter\.minSdkVersion', 'minSdkVersion 24'
    $c = $c -replace 'minSdk\s*=\s*flutter\.minSdkVersion', 'minSdk = 24'
    Set-Content -Path $f -Value $c -NoNewline
    Write-Host "patched minSdk=24 in $(Split-Path $f -Leaf)" -ForegroundColor Green
  }
}

# Release builds need INTERNET explicitly, and self-hosted servers are usually
# plain http:// on the LAN, which Android 9+ blocks unless cleartext is allowed.
$mf = Join-Path $root "android\app\src\main\AndroidManifest.xml"
if (Test-Path $mf) {
  $x = Get-Content $mf -Raw
  if ($x -notmatch 'android.permission.INTERNET') {
    $x = $x -replace '<application', '<uses-permission android:name="android.permission.INTERNET" />' + "`r`n    " + '<application'
    Write-Host "added INTERNET permission" -ForegroundColor Green
  }
  if ($x -notmatch 'usesCleartextTraffic') {
    $x = $x -replace '<application', '<application android:usesCleartextTraffic="true"'
    Write-Host "enabled cleartext http for LAN servers" -ForegroundColor Green
  }
  Set-Content -Path $mf -Value $x -NoNewline
}

Write-Host ""
Write-Host "Done. Next:" -ForegroundColor Cyan
Write-Host "  flutter pub get"
Write-Host "  powershell -File tool/build.ps1 -Target windows -Run"
