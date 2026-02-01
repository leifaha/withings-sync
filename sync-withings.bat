@echo off
set PYEXE="C:\Repos\withings-sync\.venv\Scripts\python.exe"
set PROJDIR=C:\Repos\withings-sync

REM Set working directory
cd /d "%PROJDIR%"

REM Use PowerShell for all date/time formatting (locale-independent)
for /f "tokens=*" %%a in ('powershell -NoProfile -Command "(Get-Date).AddDays(-30).ToString('yyyy-MM-dd')"') do set thirtyDaysAgo=%%a
for /f "tokens=*" %%a in ('powershell -NoProfile -Command "(Get-Date).ToString('yyyyMMdd_HHmmss')"') do set timestamp=%%a
set logFile=%PROJDIR%\sync_log_%timestamp%.txt

REM Header: environment snapshot for diagnostics
echo === Withings Sync started at %timestamp% === >> "%logFile%"
echo Working directory: %CD% >> "%logFile%"
echo Python executable: %PYEXE% >> "%logFile%"
echo From date: %thirtyDaysAgo% >> "%logFile%"
if exist %PYEXE% (echo Python found: YES >> "%logFile%") else (echo Python found: NO >> "%logFile%")
echo --- Python output below --- >> "%logFile%"

REM Run the sync and capture all output
%PYEXE% -m withings_sync.sync --fromdate %thirtyDaysAgo% --verbose --config-folder "%PROJDIR%" >> "%logFile%" 2>&1
set exitCode=%ERRORLEVEL%

REM Footer
echo --- End of Python output --- >> "%logFile%"
for /f "tokens=*" %%a in ('powershell -NoProfile -Command "(Get-Date).ToString('yyyyMMdd_HHmmss')"') do set endtime=%%a
echo === Withings Sync completed at %endtime%, exit code: %exitCode% === >> "%logFile%"

exit /b %exitCode%
