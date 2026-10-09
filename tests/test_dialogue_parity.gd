extends RefCounted

## Milestone 5 parity gate (§5: "Migrated files must produce identical visible
## output"). tests/fixtures/dialogue_v1_render.json was captured from the v1 flat
## files *before* the migration and records exactly what the dialogue box showed:
## speaker name and text, in order. This walks every migrated file through the v2
## loader and asserts the rendered sequence still matches, line for line.

const FIXTURE := "res://tests/fixtures/dialogue_v1_render.json"

func _dm(t: TestContext) -> Node:
	return t.tree.root.get_node("DialogueManager")

func _fixture() -> Dictionary:
	var file := FileAccess.open(FIXTURE, FileAccess.READ)
	if file == null:
		return {}
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK:
		return {}
	var data: Variant = json.get_data()
	if not (data is Dictionary):
		return {}
	var renders: Variant = (data as Dictionary).get("renders", {})
	return renders if renders is Dictionary else {}

## Drives a dialogue to its end, collecting what the box would render.
func _render(dm: Node, dialogue_id: String) -> Array:
	var rendered: Array = []
	dm.start_dialogue(dialogue_id)
	var guard: int = 0
	while dm.dialogue_active and guard < 500:
		var line: Dictionary = dm.get_current_line()
		if line.is_empty():
			break
		rendered.append({"speaker": line.get("speaker", ""), "text": line.get("text", "")})
		dm.advance()
		guard += 1
	return rendered

func test_every_migrated_file_renders_identically(t: TestContext) -> void:
	var dm: Node = _dm(t)
	var expected: Dictionary = _fixture()
	t.assert_eq(expected.size(), 11, "the fixture covers all eleven v1 dialogue files")

	var total_lines: int = 0
	for dialogue_id: String in expected:
		var want: Array = expected[dialogue_id]
		var got: Array = _render(dm, dialogue_id)
		var matched: bool = t.assert_eq(got, want, "%s renders identically" % dialogue_id)
		total_lines += want.size()
		print("        parity  %-22s %2d line(s)  %s" % [dialogue_id, want.size(), "OK" if matched else "MISMATCH"])
	print("        parity  %d dialogue files, %d lines, all identical to v1" % [expected.size(), total_lines])

func test_all_dialogue_files_are_v2_now(t: TestContext) -> void:
	var dir := DirAccess.open("res://data/dialogue")
	t.assert_true(dir != null, "the dialogue directory exists")
	if dir == null:
		return
	var count: int = 0
	for file_name: String in dir.get_files():
		if not file_name.ends_with(".json"):
			continue
		count += 1
		var file := FileAccess.open("res://data/dialogue/%s" % file_name, FileAccess.READ)
		var json := JSON.new()
		json.parse(file.get_as_text())
		file.close()
		var data: Variant = json.get_data()
		t.assert_true((data as Dictionary).has("nodes"), "%s is v2" % file_name)
	# Session 7: new dialogue (PH_turning_locked) joins the migrated eleven, so
	# the guarantee is "none of the eleven was lost", not a frozen total — the
	# fixture names them.
	for migrated: String in _fixture():
		t.assert_true(FileAccess.file_exists("res://data/dialogue/%s.json" % migrated),
			"migrated file '%s' is still present" % migrated)
	t.assert_true(count >= 11, "at least the eleven migrated files exist, found %d" % count)

func test_v1_flat_shape_is_still_accepted(t: TestContext) -> void:
	# The loader keeps reading v1 so nothing breaks mid-transition (§5).
	var dm: Node = _dm(t)
	var legacy: Dictionary = {
		"id": "legacy_probe",
		"lines": [
			{"speaker": "Patch", "portrait": "patch_default", "text": "Still readable."},
		],
	}
	var normalized: Dictionary = dm.normalize(legacy, "legacy_probe")
	t.assert_true(normalized.has("nodes"), "a v1 document normalizes to nodes")
	t.assert_eq(normalized["entries"], [{"when": "true", "start": "start"}], "wrapped in one always-true entry")
	t.assert_true(normalized["nodes"].has("start"), "the single node is named 'start'")

	dm.start_document(normalized)
	var line: Dictionary = dm.get_current_line()
	t.assert_eq(line.get("text"), "Still readable.", "a v1 line still renders")
	t.assert_eq(line.get("speaker"), "Patch", "an unknown speaker id passes through as its own name")
	dm.force_end()
