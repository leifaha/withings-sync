# Set working directory
Set-Location "C:\Repos\withings-sync"

# Calculate date 30 days ago
$thirtyDaysAgo = (Get-Date).AddDays(-30).ToString('yyyy-MM-dd')

# Log file path
$logFile = "C:\Repos\withings-sync\sync_log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

# Run the sync with 30-day window and capture output
$output = & "C:\Repos\withings-sync\.venv\Scripts\python.exe" -m withings_sync.sync --fromdate $thirtyDaysAgo --verbose 2>&1

# Write output to log file
$output | Out-File -FilePath $logFile -Encoding UTF8

# Also write to Windows Event Log
$eventLog = @{
    LogName      = 'Application'
    Source       = 'WithingsSync'
    EventId      = 1000
    EntryType    = 'Information'
    Message      = "Withings sync completed at $(Get-Date)`nLog file: $logFile"
}

try {
    Write-EventLog @eventLog
} catch {
    # Silently fail if event log write fails (may need elevated privileges)
}

exit $LASTEXITCODE