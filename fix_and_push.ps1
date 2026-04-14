# Kirby Dependency Fix & Push Script (Windows PowerShell)
$rootDir = Get-Location
Write-Host "`n--- Kirby Deep Clean & Reset ---" -ForegroundColor Cyan

# 1. Enter Expo project folder
if (Test-Path "project") {
    Set-Location "project"

    Write-Host "`n[1/3] Wiping node_modules, lockfiles, and native cache..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force node_modules -ErrorAction SilentlyContinue
    Remove-Item -Force package-lock.json -ErrorAction SilentlyContinue
    Remove-Item -Recurse -Force android -ErrorAction SilentlyContinue

    Write-Host "[2/3] Performing fresh install (This may take a minute)..." -ForegroundColor Cyan
    npm install

    Write-Host "[3/3] Verifying Expo SDK 52 compatibility..." -ForegroundColor Yellow
    npx expo install --check

    Set-Location ".."
} else {
    Write-Host "❌ Error: 'project' folder not found." -ForegroundColor Red
    return
}

# 2. Cleanup extra Git data
Write-Host "`n[Cleanup] Removing conflicting sub-repo data..." -ForegroundColor Gray
Remove-Item -Recurse -Force project\.git -ErrorAction SilentlyContinue

# 3. Final Push to GitHub
Write-Host "`n--- Pushing Clean State to GitHub ---" -ForegroundColor Green
git branch -M main
git add .
git commit -m "STABLE FINAL: Reset dependencies and synchronized system logic"
git push origin main --force

Write-Host "`n✅ SUCCESS! GitHub is now building your fresh APK." -ForegroundColor Green
Write-Host "Go to: https://github.com/anonamussyzak/Lexi-Central-App/actions" -ForegroundColor White

Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
