@echo off
REM Set working directory
cd /d "C:\Repos\withings-sync"

REM Calculate date 30 days ago using PowerShell
for /f "tokens=*" %%a in ('powershell -NoProfile -Command "(Get-Date).AddDays(-30).ToString('yyyy-MM-dd')"') do set thirtyDaysAgo=%%a

REM Create log file with timestamp
for /f "tokens=2-4 delims=/ " %%a in ('date /t') do (set mydate=%%c%%a%%b)
for /f "tokens=1-2 delims=/:" %%a in ('time /t') do (set mytime=%%a%%b)
set logFile=C:\Repos\withings-sync\sync_log_%mydate%_%mytime%.txt

REM Run the sync and log output
echo Withings Sync started at %date% %time% >> "%logFile%"
echo From date: %thirtyDaysAgo% >> "%logFile%"

"C:\Repos\withings-sync\.venv\Scripts\python.exe" -m withings_sync.sync --fromdate %thirtyDaysAgo% --verbose --config-folder "C:\Repos\withings-sync" >> "%logFile%" 2>&1

echo Withings Sync completed at %date% %time% >> "%logFile%"
echo Exit code: %ERRORLEVEL% >> "%logFile%"

exit /b %ERRORLEVEL%
