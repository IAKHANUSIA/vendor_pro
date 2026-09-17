@echo off
title Vendor Pro - Web Launcher
echo ========================================================
echo   Starting Vendor Pro Web for Desktop...
echo ========================================================
echo.

cd /d "%~dp0"

if not exist "build\web\index.html" (
    echo [INFO] Web build not found. Building Flutter web release...
    call flutter build web --release
    if errorlevel 1 (
        echo [ERROR] Flutter web build failed.
        pause
        exit /b 1
    )
)

echo [INFO] Starting local web server...
dart run tool\web_server.dart 8080
