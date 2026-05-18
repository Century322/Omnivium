$ErrorActionPreference = "Stop"

$env:FLUTTER_BUILD_MODE = "release"

Write-Host "=== Omnivium Release Build ===" -ForegroundColor Cyan
Write-Host ""

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$debugInfoDir = "build/debug-info-$timestamp"

Write-Host "[1/4] Running flutter analyze..." -ForegroundColor Yellow
flutter analyze --no-pub
if ($LASTEXITCODE -ne 0) {
    Write-Host "Analysis failed! Fix errors before building." -ForegroundColor Red
    exit 1
}

Write-Host "[2/4] Running tests..." -ForegroundColor Yellow
flutter test
if ($LASTEXITCODE -ne 0) {
    Write-Host "Tests failed! Fix failures before building." -ForegroundColor Red
    exit 1
}

Write-Host "[3/4] Building APK with obfuscation..." -ForegroundColor Yellow
flutter build apk `
    --release `
    --obfuscate `
    --split-debug-info=$debugInfoDir `
    --tree-shake-icons

if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed!" -ForegroundColor Red
    exit 1
}

Write-Host "[4/4] Building App Bundle with obfuscation..." -ForegroundColor Yellow
flutter build appbundle `
    --release `
    --obfuscate `
    --split-debug-info=$debugInfoDir `
    --tree-shake-icons

if ($LASTEXITCODE -ne 0) {
    Write-Host "Bundle build failed!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=== Build Complete ===" -ForegroundColor Green
Write-Host "APK: build/app/outputs/flutter-apk/app-release.apk" -ForegroundColor White
Write-Host "AAB: build/app/outputs/bundle/release/app-release.aab" -ForegroundColor White
Write-Host "Debug symbols: $debugInfoDir/" -ForegroundColor White
Write-Host ""
Write-Host "IMPORTANT: Keep the debug-info directory safe!" -ForegroundColor Yellow
Write-Host "It is required to decode stack traces from obfuscated builds." -ForegroundColor Yellow
Write-Host ""
Write-Host "Security measures applied:" -ForegroundColor Cyan
Write-Host "  - Dart code obfuscation (--obfuscate)" -ForegroundColor White
Write-Host "  - Debug info separated (--split-debug-info)" -ForegroundColor White
Write-Host "  - Icon tree shaking (--tree-shake-icons)" -ForegroundColor White
Write-Host "  - Android R8/ProGuard minification" -ForegroundColor White
Write-Host "  - Android resource shrinking" -ForegroundColor White
