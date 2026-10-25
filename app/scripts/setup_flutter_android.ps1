$ErrorActionPreference = "Stop"

Write-Host "=== R U OK Flutter Android setup ===" -ForegroundColor Cyan

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  Write-Host "Flutter SDK가 설치되어 있지 않거나 PATH에 없습니다." -ForegroundColor Red
  Write-Host "설치 후 PowerShell을 다시 열고 flutter doctor를 먼저 실행하세요."
  exit 1
}

flutter doctor

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

if (-not (Test-Path ".\android")) {
  Write-Host "Android native project files are missing. Generating with flutter create..." -ForegroundColor Yellow
  $temp = Join-Path $root ".flutter_template"
  if (Test-Path $temp) { Remove-Item -Recurse -Force $temp }
  flutter create --platforms=android --project-name ruok_guardian_app $temp
  Copy-Item -Recurse -Force (Join-Path $temp "android") (Join-Path $root "android")
  Copy-Item -Force (Join-Path $temp ".metadata") (Join-Path $root ".metadata") -ErrorAction SilentlyContinue
  Remove-Item -Recurse -Force $temp
}

$manifest = Join-Path $root "android\app\src\main\AndroidManifest.xml"
if (Test-Path $manifest) {
  $content = Get-Content -Raw $manifest
  if ($content -notmatch "android.permission.INTERNET") {
    $content = $content -replace "<manifest([^>]*)>", "<manifest`$1>`r`n    <uses-permission android:name=`"android.permission.INTERNET`" />"
  }
  if ($content -notmatch "usesCleartextTraffic") {
    $content = $content -replace "<application", "<application android:usesCleartextTraffic=`"true`""
  }
  Set-Content -Path $manifest -Value $content -Encoding UTF8
  Write-Host "AndroidManifest.xml patched: INTERNET + cleartext HTTP allowed." -ForegroundColor Green
}

flutter pub get

Write-Host "Setup complete." -ForegroundColor Green
Write-Host "Run: .\scripts\run_android.ps1" -ForegroundColor Cyan
