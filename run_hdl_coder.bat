@echo off
REM =============================================================================
REM Script: run_hdl_coder.bat
REM Project: Standalone 2x2 MIMO Baseband Processor ASIC (SMVDU-MIMO-180)
REM Description: Launches MATLAB with interactive desktop interface to ensure
REM              online license validation and real-time HDL Coder synthesis logging.
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

echo Starting MATLAB GUI with automated synthesis script...
start "" %MATLAB_EXE% -r "generate_hdl_coder_all"

echo.
echo MATLAB is launching on your desktop. 
echo It will authenticate your license and run generate_hdl_coder_all automatically.
