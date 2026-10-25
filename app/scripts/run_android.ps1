$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

Write-Host "Available Flutter devices:" -ForegroundColor Cyan
flutter devices

Write-Host "Starting app..." -ForegroundColor Cyan
flutter run
