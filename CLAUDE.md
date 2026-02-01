# CLAUDE.md — withings-sync

> **For future Claude sessions:** This file is the single source of truth for project context. Always read it at the start of a session. Always update it at the end — especially if you change architecture, fix bugs, or add gotchas. Never leave it stale.

## What this project does
Syncs body-composition measurements from a Withings scale to Garmin Connect (and optionally TrainerRoad). The flow is: Withings API → parse measurements → encode as FIT file → upload to Garmin.

## How to run
```bat
REM Scheduled task entry point (the only one needed on Windows):
sync-withings.bat

REM Or manually from the venv:
.venv\Scripts\python.exe -m withings_sync.sync --fromdate 2026-01-01 --verbose --config-folder "C:\Repos\withings-sync"
```
Logs land in `sync_log_YYYYMMDD_HHmmss.txt` at the repo root. Older logs are in `old_logs/`.

## Key architecture
- `withings_sync/sync.py` — orchestrator and CLI entry point. `ARGS` is parsed at module level; `main()` is the actual entry point (called via `if __name__ == "__main__"` or the poetry script entry point).
- `withings_sync/withings2.py` — Withings OAuth2 + measurement API. Tokens are stored in `.withings_user.json` and refreshed on every run.
- `withings_sync/garmin.py` — thin wrapper around the `garth` library. Session is persisted in `.garmin_session/` for token reuse.
- `withings_sync/fit.py` — binary FIT file encoder (weight + blood pressure).
- `sync-withings.bat` — the Windows Task Scheduler entry point. Handles logging, timestamps, and exit codes.

## Credentials and config
- `.env` — Garmin username/password. Loaded via `dotenv` using an explicit path relative to `sync.py`'s location (not CWD-dependent).
- `.withings_user.json` — Withings OAuth tokens (access + refresh). Written back after every refresh.
- `.garmin_session/` — Garmin OAuth1 + OAuth2 tokens (managed by `garth`).
- All three are in `.gitignore`. Do not commit them.

## Bugs fixed (2026-02-01 session)

### CRITICAL: script never executed via `python -m`
`sync.py` had no `if __name__ == "__main__": main()` block and no `__main__.py` existed in the package. Running `python -m withings_sync.sync` loaded the module and exited without doing anything — exit code 0, zero output, ~1 second runtime. This is why every scheduled-task log was empty. The poetry entry point (`withings-sync` command) worked because it calls `main()` directly.

### HIGH: Withings token refresh silently destroyed credentials
`refresh_accesstoken()` logged errors on failure but did not raise. Execution fell through and overwrote `access_token`, `refresh_token`, and `userid` with `None`. Subsequent runs were silently broken. Fixed: both `get_accesstoken()` and `refresh_accesstoken()` now raise `WithingsException` on non-zero status.

### HIGH: bare `raise` in `get_accesstoken()`
A naked `raise` with no active exception caused `RuntimeError: No active exception to reraise` instead of a useful error message. Replaced with an explicit `WithingsException`.

### MEDIUM: `dotenv.load_dotenv()` was CWD-dependent
Called with no arguments, it searched for `.env` relative to CWD. Task Scheduler does not guarantee CWD. Fixed: now resolves `.env` relative to `sync.py`'s own file path.

### MEDIUM: `main()` had no exception handling
Any crash in `sync()` produced an unhandled traceback with no structured logging. Fixed: `sync()` is now wrapped in try/except; exceptions are logged with full traceback and the process exits with code 1.

### LOW: bat file timestamp was locale-dependent
The `for /f "delims=/ "` date parsing assumed US-locale `/` separators. European `.` separators produced empty date strings in log filenames (e.g. `sync_log__0656.txt`). Fixed: all timestamps now use PowerShell `Get-Date` formatting.

## Verified working (2026-02-01)
Ran `sync-withings.bat` end-to-end after all fixes. Full success:
- Withings token refreshed (HTTP 200)
- Height + 22 measurement groups fetched
- Garmin session auto-refreshed by `garth`, FIT file uploaded (HTTP 201)
- 723-line log produced, exit code 0, no errors

## Things to watch
- **Garmin token expiry:** The OAuth2 access token in `.garmin_session/oauth2_token.json` expires periodically. `garth` should auto-refresh using the refresh token. If it doesn't, you'll see an explicit error in the log. The refresh token itself expires after ~30 days — if that happens, a fresh login via `garth` is needed (may require MFA).
- **Withings refresh token:** Similarly long-lived but not infinite. If `refresh_accesstoken()` returns status != 0, the refresh token has likely expired and you need to re-authenticate through the browser flow (the script will prompt for this interactively — won't work unattended).
- **`last_sync` is null:** The `.withings_user.json` file has `"last_sync": null`. This field is only used when `--fromdate` is *not* passed. The bat file always passes `--fromdate` (30-day window), so this is fine. If you ever switch to relying on `last_sync`, note it's only updated after a successful Garmin upload.
- **`sync-withings.ps1` was removed** — the bat file is the single entry point.
