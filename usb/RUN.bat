REM Setup MATLAB working directory
SET MLDIR="%USERPROFILE%\Documents\MATLAB"
REM Script begins
setlocal enabledelayedexpansion enableextensions
REM Recreate empty MATLAB directory
rmdir /S /Q %MLDIR%
mkdir %MLDIR%
REM Find all .zip in 'archive' folder
set ARCHIVE=
for %%x in (".\archive\*.zip") do set ARCHIVE=!ARCHIVE! %%x
set ARCHIVE=%ARCHIVE:~1%
REM Unzip .zip archive to MATLAB directory
powershell.exe -nologo -noprofile -command "& { Add-Type -A 'System.IO.Compression.FileSystem'; [IO.Compression.ZipFile]::ExtractToDirectory('%ARCHIVE%', '%MLDIR%'); }"
REM Copy startup.m script to MATLAB directory
xcopy /s .\archive\startup.m %MLDIR%
REM Delete all MATLAB settings and history
rmdir /S /Q "%USERPROFILE%\AppData\Roaming\MathWorks\MATLAB"
REM Run MATLAB
matlab
