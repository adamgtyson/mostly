extends SceneTree

## Test runner (ENGINEERING_CONSTRAINTS.md §11): plain GDScript, no framework.
##   godot --headless --path . -s tests/run_tests.gd
## Discovers tests/test_*.gd, each exposing `func run(t: TestContext) -> void`.
## One line per test; exits non-zero if any test failed.

const TESTS_DIR := "res://tests"

## Every stateful autoload gets reset() between tests so no test can depend on
## state another test left behind (§11). Names must match the autoload roster (§13).
const STATEFUL_AUTOLOADS: Array[String] = [
	"GameState",
	"SaveManager",
	"Inventory",
	"Weirdness",
	"SceneRouter",
	"DialogueManager",
	"CutsceneManager",
]

func _initialize() -> void:
	var failed: int = await _run_all()
	quit(1 if failed > 0 else 0)

func _run_all() -> int:
	# Autoloads are children of root by the time _initialize() runs, but their
	# _ready() has not fired yet — so anything they load in _ready (the flag
	# registry, the dialogue box) is absent until one frame has passed.
	await process_frame

	var files: PackedStringArray = _discover()
	if files.is_empty():
		print("run_tests: no tests/test_*.gd found")
		return 1

	var passed: int = 0
	var failed: int = 0

	for path: String in files:
		var script: Variant = load(path)
		if script == null or not (script is GDScript):
			print("FAIL  %s :: <load>  could not load script" % path.get_file())
			failed += 1
			continue
		var suite: Object = (script as GDScript).new()
		var file_name: String = path.get_file()

		for method_name: String in _test_methods(suite):
			_reset_autoloads()
			var t := TestContext.new()
			t.tree = self
			@warning_ignore("redundant_await")
			await suite.call(method_name, t)
			if t.ok():
				passed += 1
				print("PASS  %s :: %s  (%d asserts)" % [file_name, method_name, t.assert_count()])
			else:
				failed += 1
				print("FAIL  %s :: %s" % [file_name, method_name])
				for f: String in t.failures():
					print("        %s" % f)

	_reset_autoloads()
	print("")
	print("%d passed, %d failed" % [passed, failed])
	return failed

## A suite may expose one run(t) or many test_*(t) methods; both are supported so
## small data checks can live several to a file without a wrapper each.
func _test_methods(suite: Object) -> PackedStringArray:
	var names := PackedStringArray()
	var explicit := PackedStringArray()
	for m: Dictionary in suite.get_method_list():
		var n: String = m["name"]
		if n == "run":
			names.append(n)
		elif n.begins_with("test_"):
			explicit.append(n)
	explicit.sort()
	for n: String in explicit:
		names.append(n)
	return names

func _discover() -> PackedStringArray:
	var found := PackedStringArray()
	var dir := DirAccess.open(TESTS_DIR)
	if dir == null:
		push_error("run_tests: cannot open %s" % TESTS_DIR)
		return found
	for f: String in dir.get_files():
		# .gd.remap / .gd.uid appear in exported or reimported trees; ignore both.
		if f.begins_with("test_") and f.ends_with(".gd"):
			found.append("%s/%s" % [TESTS_DIR, f])
	found.sort()
	return found

func _reset_autoloads() -> void:
	for name: String in STATEFUL_AUTOLOADS:
		if not root.has_node(name):
			continue
		var node: Node = root.get_node(name)
		if node.has_method("reset"):
			node.call("reset")
