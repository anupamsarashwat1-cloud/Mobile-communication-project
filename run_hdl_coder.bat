@echo off
REM =============================================================================
REM Script: run_hdl_coder.bat
REM Project: Standalone 2x2 MIMO Baseband Processor ASIC (SMVDU-MIMO-180)
REM Description: One-click launcher for MATLAB HDL Coder automated Verilog generation.
REM =============================================================================

echo ======================================================================
echo  Launching MATLAB HDL Coder Automated Synthesis Pipeline
echo ======================================================================
echo.

set MATLAB_EXE="C:\Program Files\MATLAB\R2026a\bin\matlab.exe"

if not exist %MATLAB_EXE% (
    echo [ERROR] MATLAB R2026a not found at %MATLAB_EXE%
    echo Please verify your MATLAB installation path.
    pause
    exit /b 1
)

echo Starting MATLAB in batch mode...
%MATLAB_EXE% -batch "generate_hdl_coder_all"

echo.
echo HDL Generation process completed. Inspect outputs in hdl_asic/build_rtl/
pause
