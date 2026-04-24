@echo off
setlocal
title SM64 Coop DX (make build)
cd /d "%~dp0"

echo [SM64 Coop DX (make build)] Starting...
where make >nul 2>nul
if errorlevel 1 (
    echo [SM64 Coop DX (make build)] make not found. Please install it.
    pause
    exit /b 1
)

make

if errorlevel 1 (
    echo [SM64 Coop DX (make build)] Exited with error code %errorlevel%.
    pause
)
endlocal
