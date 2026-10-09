@echo off
REM ============================================================================
REM  Mostly - single check entrypoint (ENGINEERING_CONSTRAINTS.md §11).
REM  Runs, in order, stopping at the first failure:
REM    1. godot --headless --editor --quit  (import pass: .godot/ artifacts +
REM       the global class-name cache, without which typed tests will not parse)
REM    2. tests/validate_data.gd    (cheapest signal: data and schema integrity)
REM    3. tests/run_tests.gd        (behaviour tests)
REM    4. tools/generator_sweep.gd  (1000 seeds per region through the
REM       anchor-and-fill validator; ~0.1s on the build machine)
REM    5. tools/smoke.bat           (real boot headless: autoloads, the title
REM       as main scene, a [smoke] state block; ~4s)
REM  Exit code 0 means all five passed.
REM
REM  Godot is resolved from, in order: the GODOT environment variable, `godot`
REM  on PATH, then the default install path on the build machine. Set GODOT to
REM  override on any other machine.
REM ============================================================================
setlocal
cd /d "%~dp0.."

set "GODOT_BIN="
if defined GODOT if exist "%GODOT%" set "GODOT_BIN=%GODOT%"
if not defined GODOT_BIN for %%G in (godot.exe) do if not "%%~$PATH:G"=="" set "GODOT_BIN=%%~$PATH:G"
if not defined GODOT_BIN if exist "C:\Godot\Godot_v4.6.2-stable_win64_console.exe" set "GODOT_BIN=C:\Godot\Godot_v4.6.2-stable_win64_console.exe"

if not defined GODOT_BIN (
  echo [check] ERROR: Godot 4.6 not found.
  echo [check] Set the GODOT environment variable to your Godot executable, e.g.
  echo [check]   set GODOT=C:\Godot\Godot_v4.6.2-stable_win64_console.exe
  exit /b 127
)

echo [check] godot: %GODOT_BIN%
echo.

echo [check] 1/5 engine import
"%GODOT_BIN%" --headless --editor --path . --quit >nul 2>&1
if errorlevel 1 (
  echo [check] FAILED: engine import. Re-running to show the error:
  "%GODOT_BIN%" --headless --editor --path . --quit
  exit /b 1
)
echo [check] 1/5 ok
echo.

echo [check] 2/5 validate_data
"%GODOT_BIN%" --headless --path . -s tests/validate_data.gd
if errorlevel 1 (
  echo [check] FAILED: validate_data
  exit /b 1
)
echo.

echo [check] 3/5 run_tests
"%GODOT_BIN%" --headless --path . -s tests/run_tests.gd
if errorlevel 1 (
  echo [check] FAILED: run_tests
  exit /b 1
)
echo.

echo [check] 4/5 generator sweep
"%GODOT_BIN%" --headless --path . -s tools/generator_sweep.gd
if errorlevel 1 (
  echo [check] FAILED: generator sweep
  exit /b 1
)
echo.

echo [check] 5/5 boot smoke
call "%~dp0smoke.bat"
if errorlevel 1 (
  echo [check] FAILED: boot smoke
  exit /b 1
)

echo.
echo [check] all checks passed
exit /b 0
