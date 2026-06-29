#!/bin/bash
# macOS entry point for withings-sync (LaunchAgent + on-demand).
# Mirrors sync-withings.bat: 30-day --fromdate window, timestamped log, exit code.

set -uo pipefail

PROJDIR="/Users/leif/Repos/withings-sync"
PYEXE="/Users/leif/Library/Caches/pypoetry/virtualenvs/withings-sync-es5I6D5q-py3.12/bin/python"

cd "$PROJDIR" || exit 1

LOGDIR="$PROJDIR/logs"
mkdir -p "$LOGDIR"

thirtyDaysAgo=$(date -v-30d +%Y-%m-%d)
timestamp=$(date +%Y%m%d_%H%M%S)
logFile="$LOGDIR/sync_log_${timestamp}.txt"

{
  echo "=== Withings Sync started at $timestamp ==="
  echo "Working directory: $PWD"
  echo "Python executable: $PYEXE"
  echo "From date: $thirtyDaysAgo"
  if [ -x "$PYEXE" ]; then echo "Python found: YES"; else echo "Python found: NO"; fi
  echo "--- Python output below ---"
} >> "$logFile"

"$PYEXE" -m withings_sync.sync \
  --fromdate "$thirtyDaysAgo" \
  --verbose \
  --config-folder "$PROJDIR" >> "$logFile" 2>&1
exitCode=$?

{
  echo "--- End of Python output ---"
  echo "=== Withings Sync completed at $(date +%Y%m%d_%H%M%S), exit code: $exitCode ==="
} >> "$logFile"

exit $exitCode
