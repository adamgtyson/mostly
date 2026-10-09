@echo off
REM ============================================================================
REM  Mostly - real-boot smoke test (session 9).
REM  Boots the actual game headless (autoloads, main scene, Boot's routing,
REM  scene swap) with the --smoke user arg; Boot prints a [smoke] state block
REM  after N frames and exits 0 (healthy) / 2 (wrong or empty tree). A 30s
REM  watchdog kills a hung boot and exits 124.
REM  Usage: tools\smoke.bat [extra user args, e.g. --smoke-frames=60]
REM ============================================================================
setlocal
cd /d "%~dp0.."

set "GODOT_BIN="
if defined GODOT if exist "%GODOT%" set "GODOT_BIN=%GODOT%"
if not defined GODOT_BIN for %%G in (godot.exe) do if not "%%~$PATH:G"=="" set "GODOT_BIN=%%~$PATH:G"
if not defined GODOT_BIN if exist "C:\Godot\Godot_v4.6.2-stable_win64_console.exe" set "GODOT_BIN=C:\Godot\Godot_v4.6.2-stable_win64_console.exe"
if not defined GODOT_BIN (
  echo [smoke] ERROR: Godot 4.6 not found. Set GODOT.
  exit /b 127
)

set "SMOKE_OUT=%TEMP%\mostly_smoke_out.txt"
set "SMOKE_ERR=%TEMP%\mostly_smoke_err.txt"

set "SMOKE_ARGS=--headless --path . -- --smoke"
if not "%~1"=="" set "SMOKE_ARGS=%SMOKE_ARGS% %~1"

powershell -NoProfile -Command ^
  "$p = Start-Process -FilePath '%GODOT_BIN%' -ArgumentList '%SMOKE_ARGS%' -NoNewWindow -PassThru -RedirectStandardOutput '%SMOKE_OUT%' -RedirectStandardError '%SMOKE_ERR%';" ^
  "if ($null -eq $p) { exit 125 };" ^
  "if (-not $p.WaitForExit(30000)) { $p.Kill(); exit 124 };" ^
  "exit $p.ExitCode"
set "SMOKE_EXIT=%ERRORLEVEL%"

type "%SMOKE_ERR%" 2>nul
type "%SMOKE_OUT%" 2>nul
if "%SMOKE_EXIT%"=="124" echo [smoke] TIMEOUT: boot did not finish in 30s - a parked await or a frozen main loop.
echo [smoke] exit code: %SMOKE_EXIT%
exit /b %SMOKE_EXIT%
