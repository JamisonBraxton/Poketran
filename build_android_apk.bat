@echo off
setlocal
cd /d "%~dp0"
where flutter >nul 2>nul
if errorlevel 1 (echo Flutter not found on PATH.& exit /b 1)
if not exist android (echo Run setup_windows.bat first.& exit /b 1)
flutter pub get
if errorlevel 1 exit /b 1
flutter build apk --release
if errorlevel 1 exit /b 1
echo APK output: build\app\outputs\flutter-apk\app-release.apk
