REM Setup MATLAB working directory
SET MLDIR="%USERPROFILE%\Documents\MATLAB"
REM Script begins
setlocal enabledelayedexpansion enableextensions
REM Recreate empty MATLAB directory
rmdir /S /Q %MLDIR%
mkdir %MLDIR%