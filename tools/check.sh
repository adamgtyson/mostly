#!/usr/bin/env sh
# =============================================================================
#  Mostly - single check entrypoint (ENGINEERING_CONSTRAINTS.md §11).
#  Runs, in order, stopping at the first failure:
#    1. godot --headless --editor --quit  (import pass: .godot/ artifacts plus
#       the global class-name cache, without which typed tests will not parse)
#    2. tests/validate_data.gd    (cheapest signal: data and schema integrity)
#    3. tests/run_tests.gd        (behaviour tests)
#  Exit code 0 means all three passed.
#
#  Godot is resolved from, in order: $GODOT, `godot` on PATH, then the default
#  install path on the Windows build machine. Set GODOT to override.
#  The build machine is Windows (§13 / [I1]); this script is for parity only.
# =============================================================================
set -eu

cd "$(dirname "$0")/.."

GODOT_BIN=""
if [ -n "${GODOT:-}" ] && [ -x "${GODOT}" ]; then
	GODOT_BIN="${GODOT}"
elif command -v godot >/dev/null 2>&1; then
	GODOT_BIN="$(command -v godot)"
elif [ -x "/c/Godot/Godot_v4.6.2-stable_win64_console.exe" ]; then
	GODOT_BIN="/c/Godot/Godot_v4.6.2-stable_win64_console.exe"
fi

if [ -z "${GODOT_BIN}" ]; then
	echo "[check] ERROR: Godot 4.6 not found."
	echo "[check] Set GODOT to your Godot executable, e.g."
	echo "[check]   export GODOT=/path/to/godot"
	exit 127
fi

echo "[check] godot: ${GODOT_BIN}"
echo

echo "[check] 1/3 engine import"
if ! "${GODOT_BIN}" --headless --editor --path . --quit >/dev/null 2>&1; then
	echo "[check] FAILED: engine import. Re-running to show the error:"
	"${GODOT_BIN}" --headless --editor --path . --quit || true
	exit 1
fi
echo "[check] 1/3 ok"
echo

echo "[check] 2/3 validate_data"
if ! "${GODOT_BIN}" --headless --path . -s tests/validate_data.gd; then
	echo "[check] FAILED: validate_data"
	exit 1
fi
echo

echo "[check] 3/3 run_tests"
if ! "${GODOT_BIN}" --headless --path . -s tests/run_tests.gd; then
	echo "[check] FAILED: run_tests"
	exit 1
fi

echo
echo "[check] all checks passed"
exit 0
