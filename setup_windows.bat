@echo off
setlocal
cd /d "%~dp0"
where flutter >nul 2>nul
if errorlevel 1 (
  echo Flutter was not found on PATH.
  echo Install Flutter: https://docs.flutter.dev/get-started/install
  echo Then reopen the terminal and rerun this script.
  exit /b 1
)
echo [1/4] Generating native Android and Windows runners...
flutter create --project-name poketran --platforms=android,windows .
if errorlevel 1 goto fail
echo Configuring display name...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\set_app_name.ps1"
if errorlevel 1 goto fail
echo [2/4] Resolving packages...
flutter pub get
if errorlevel 1 goto fail
echo [3/4] Running static analysis...
flutter analyze
if errorlevel 1 goto fail
echo [4/4] Running tests...
flutter test
if errorlevel 1 goto fail
echo.
echo Setup completed. Start an Android emulator and run: flutter run
echo Or install the Windows C++ toolchain and run: flutter run -d windows
exit /b 0
:fail
echo A setup step failed. Review the error above.
exit /b 1
