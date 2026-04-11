@echo off
echo 🌸 Lexi Central - Windows Launcher
echo =====================================
echo.

REM Check if Flutter is installed
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Flutter not found! Please install Flutter first:
    echo    https://flutter.dev/docs/get-started/install/windows
    pause
    exit /b 1
)

echo ✅ Flutter found
echo.

REM Navigate to project directory
cd /d "c:\Users\zborg\Desktop\Lexi Central"

REM Get dependencies
echo 📦 Getting dependencies...
flutter pub get
if %errorlevel% neq 0 (
    echo ❌ Failed to get dependencies
    pause
    exit /b 1
)

echo ✅ Dependencies installed
echo.

REM Check Windows desktop support
echo 🔧 Checking Windows desktop support...
flutter config --enable-windows-desktop

REM Run the app
echo 🚀 Starting Lexi Central...
echo.
echo 🎨 To customize the theme, edit: lib\core\theme\app_theme.dart
echo 🔄 Use 'r' for hot reload when making changes
echo.
echo Press Ctrl+C to stop the app
echo.

flutter run -d windows

pause
