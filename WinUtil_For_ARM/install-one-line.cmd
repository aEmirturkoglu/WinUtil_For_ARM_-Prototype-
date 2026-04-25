@echo off
REM ── WinUtil ARM64 One-Line Installer (Double-Click) ────────────────
powershell -NoProfile -ExecutionPolicy Bypass `
    -File "%~dp0arm-converter\main-arm64.ps1" %*
