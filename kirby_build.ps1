# Kirby Project Build Script (Windows - Long Path Bypass Version)
$rootDir = Get-Location
Write-Host "`n--- Kirby Magic Builder (Zak) ---" -ForegroundColor Cyan

# --- JDK & SDK AUTO-DETECTION ---
$studioPath = "${env:ProgramFiles}\Android\Android Studio"
$jdkPath = ""
if (Test-Path "$studioPath\jbr") { $jdkPath = "$studioPath\jbr" }
elseif (Test-Path "$studioPath\jre") { $jdkPath = "$studioPath\jre" }

if ($jdkPath -ne "") {
    $env:JAVA_HOME = $jdkPath
    $env:Path = "$jdkPath\bin;" + $env:Path
    Write-Host "✅ Detected JDK at: $jdkPath" -ForegroundColor Gray
}

$sdkPath = "${env:LocalAppdata}\Android\Sdk"
if (-not (Test-Path $sdkPath)) { $sdkPath = "C:\Android\Sdk" }
if (Test-Path $sdkPath) {
    $env:ANDROID_HOME = $sdkPath
    $env:Path = "$sdkPath\platform-tools;$sdkPath\tools\bin;" + $env:Path
    Write-Host "✅ Detected SDK at: $sdkPath" -ForegroundColor Gray
}
# --------------------------

# --- Virtual Drive Hack (Bypasses Windows Path Limits) ---
$driveLetter = "K:"
if (Test-Path $driveLetter) {
    subst $driveLetter /D | Out-Null
}
subst $driveLetter "$rootDir"
Write-Host "✅ Created Virtual Drive $driveLetter to bypass Windows path limits." -ForegroundColor Gray
# ---------------------------------------------------------

Write-Host "1: Native Android App (Kotlin/Compose)"
Write-Host "2: Expo/EAS Project (Local Build - NO LIMITS)"
Write-Host "------------------------------------"

$rawInput = Read-Host "Select build target (Type 1 or 2)"
$choice = $rawInput.Trim()

if ($choice -eq "1" -or $choice -match "^1") {
    Set-Location "$driveLetter"
    Write-Host "`n🚀 Building Native APK..." -ForegroundColor Green
    .\gradlew.bat assembleDebug
}
elseif ($choice -eq "2" -or $choice -match "^2") {
    Set-Location "$driveLetter\project"

    Write-Host "`n🧹 Deep Cleaning..." -ForegroundColor Yellow
    if (Test-Path "node_modules") { Remove-Item -Recurse -Force node_modules -ErrorAction SilentlyContinue }
    if (Test-Path "android") { Remove-Item -Recurse -Force android -ErrorAction SilentlyContinue }
    if (Test-Path "package-lock.json") { Remove-Item -Force package-lock.json -ErrorAction SilentlyContinue }

    Write-Host "📦 Installing Dependencies..." -ForegroundColor Cyan
    npm install
    npx expo install --check

    Write-Host "🛠️ Generating & Compiling (Sit back and relax)..." -ForegroundColor Green
    npx expo prebuild --platform android --no-install

    # Force SDK path for local build
    $localProps = "sdk.dir=$($sdkPath.Replace('\', '/'))"
    $localProps | Out-File -FilePath "android\local.properties" -Encoding ascii

    Set-Location "android"
    .\gradlew.bat assembleRelease

    if ($LASTEXITCODE -eq 0) {
        Write-Host "`n✅ SUCCESS!" -ForegroundColor Green
        Write-Host "APK Location: $rootDir\project\android\app\build\outputs\apk\release\app-release.apk" -ForegroundColor White
    }
}

# Cleanup
Set-Location "$rootDir"
subst $driveLetter /D
Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
