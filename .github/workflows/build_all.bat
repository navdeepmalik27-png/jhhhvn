@echo off
setlocal
cd /d "%~dp0"
where flutter >nul 2>nul
if errorlevel 1 goto :missing
call flutter create --empty --platforms=android,windows .
if errorlevel 1 goto :failed
call flutter pub get
if errorlevel 1 goto :failed
call flutter build windows --release
if errorlevel 1 goto :failed
call flutter build apk --release
if errorlevel 1 goto :failed
echo APK: build\app\outputs\flutter-apk\app-release.apk
echo Windows: build\windows\x64\runner\Release\come_on.exe
echo Keep the entire Windows Release folder together.
pause
exit /b 0
:missing
echo Install Flutter and add it to PATH first.
:failed
echo Build failed. Read the error above.
pause
exit /b 1
