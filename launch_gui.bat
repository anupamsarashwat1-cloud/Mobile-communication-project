@echo off
REM ============================================================================
REM  5G MIMO MULTIPLEXING OPTIMIZATION - MATLAB GUI LAUNCHER
REM  Launches the interactive MATLAB Desktop GUI environment in this project root.
REM ============================================================================

echo Starting MATLAB GUI Environment in: %CD%
start "" "C:\Program Files\MATLAB\R2026a\bin\matlab.exe" -sd "%CD%"
echo MATLAB GUI process launched.
