extends RefCounted

## Milestone 1: proves the harness itself behaves, so a green suite later means
## the code under test is green rather than the runner being broken.

const CONFIG_PATH := "res://data/config.json"

func test_deep_equal_matches_nested_values(t: TestContext) -> void:
	t.assert_eq({"a": [1, 2], "b": {"c": "x"}}, {"a": [1, 2], "b": {"c": "x"}}, "nested containers compare by value")
	t.assert_eq([], [], "empty arrays are equal")

func test_assert_helpers_record_failures(t: TestContext) -> void:
	# A throwaway context: its failures are inspected, not reported to the runner.
	var probe := TestContext.new()
	probe.assert_eq(1, 2)
	probe.assert_true(false)
	probe.assert_false(true)
	probe.fail("deliberate")
	t.assert_eq(probe.failures().size(), 4, "each failing assertion is recorded once")
	t.assert_false(probe.ok(), "a context with failures is not ok")

	var clean := TestContext.new()
	clean.assert_eq("same", "same")
	t.assert_true(clean.ok(), "a context with only passing assertions is ok")

func test_config_is_readable_at_runtime(t: TestContext) -> void:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	t.assert_true(file != null, "data/config.json opens")
	if file == null:
		return
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	t.assert_eq(err, OK, "data/config.json parses")
	var cfg: Variant = json.get_data()
	t.assert_true(cfg is Dictionary, "config root is an object")
	if not (cfg is Dictionary):
		return
	t.assert_true((cfg as Dictionary).has("save"), "config has a save section")

func test_tree_is_available_to_tests(t: TestContext) -> void:
	t.assert_true(t.tree != null, "TestContext carries the SceneTree")
