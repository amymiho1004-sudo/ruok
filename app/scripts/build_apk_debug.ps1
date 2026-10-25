$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

flutter pub get
flutter build apk --debug

Write-Host "Debug APK:" -ForegroundColor Green
Write-Host "$root\build\app\outputs\flutter-apk\app-debug.apk"
