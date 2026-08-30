extends RefCounted

## Milestone 6: cutscenes as data (§8), including the acceptance test the
## constraints call for — the 30-beat opening migrated to JSON produces exactly
## the beat sequence the deleted GDScript produced.
##
## tests/fixtures/opening_beats_v1.json was captured from
## scripts/opening_cutscene.gd's runtime array before that script was removed.

const FIXTURE := "res://tests/fixtures/opening_beats_v1.json"

func _cm(t: TestContext) -> Node:
	return t.tree.root.get_node("CutsceneManager")

func _read(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK:
		return {}
	var data: Variant = json.get_data()
	return data if data is Dictionary else {}

# ── the acceptance test (§8) ─────────────────────────────────────────────────

func test_opening_json_matches_the_captured_v1_beats(t: TestContext) -> void:
	var cm: Node = _cm(t)
	var fixture: Dictionary = _read(FIXTURE)
	var expected: Array = fixture.get("beats", [])
	var document: Dictionary = cm.load_cutscene("opening")
	var got: Array = document.get("beats", [])

	t.assert_eq(expected.size(), 30, "the captured v1 opening has 30 beats")
	t.assert_eq(got.size(), expected.size(), "the migrated cutscene has the same beat count")

	var mismatches: int = 0
	for i: int in expected.size():
		if i >= got.size():
			break
		if not t.assert_eq(got[i], expected[i], "beat %d matches" % i):
			mismatches += 1
	print("        cutscene parity  opening: %d/%d beats identical to the v1 script array"
		% [expected.size() - mismatches, expected.size()])

func test_opening_document_envelope(t: TestContext) -> void:
	var cm: Node = _cm(t)
	var document: Dictionary = cm.load_cutscene("opening")
	t.assert_eq(document.get("id"), "opening", "the document names itself")
	t.assert_true(document.has("skippable"), "the envelope declares skippable")
	t.assert_true(document.has("once"), "the envelope declares once")

func test_opening_beat_types_are_all_known(t: TestContext) -> void:
	var cm: Node = _cm(t)
	var known := ["wait", "move", "animation", "dialogue", "end", "set_flag",
		"camera", "fade", "sfx", "spawn", "despawn", "choice", "emit"]
	var seen: Dictionary = {}
	for beat: Variant in cm.load_cutscene("opening").get("beats", []):
		var beat_type: String = str((beat as Dictionary).get("type", ""))
		seen[beat_type] = true
		t.assert_true(known.has(beat_type), "beat type '%s' is in the vocabulary" % beat_type)
	print("        cutscene parity  opening uses: %s" % ", ".join(seen.keys()))

func test_the_old_script_is_gone(t: TestContext) -> void:
	t.assert_false(
		FileAccess.file_exists("res://scripts/opening_cutscene.gd"),
		"opening_cutscene.gd is deleted, replaced by data plus CutsceneTrigger (§8)")

func test_workshop_uses_the_generic_trigger(t: TestContext) -> void:
	var text: String = FileAccess.get_file_as_string("res://regions/hold/areas/workshop.tscn")
	t.assert_true(text.contains("cutscene_trigger.gd"), "the scene points at CutsceneTrigger")
	t.assert_true(text.contains("cutscene_id = \"opening\""), "the trigger names the opening cutscene")
	t.assert_false(text.contains("opening_cutscene.gd"), "no reference to the deleted script remains")

# ── actor resolution and the extended vocabulary ─────────────────────────────

func test_actors_resolve_by_node_path(t: TestContext) -> void:
	var cm: Node = _cm(t)
	var root := Node2D.new()
	var child := Node2D.new()
	child.name = "Marker"
	root.add_child(child)

	# Drives one animation-free beat sequence purely to prove path resolution.
	await cm.play_cutscene([
		{"type": "move", "node": "Marker", "target": [10, 0], "speed": 1000.0},
		{"type": "end"},
	], "probe_actor", root)

	t.assert_eq(child.position, Vector2(10, 0), "the beat moved the node named by its path")
	root.free()

func test_a_missing_actor_does_not_hang(t: TestContext) -> void:
	var cm: Node = _cm(t)
	var root := Node2D.new()
	await cm.play_cutscene([
		{"type": "move", "node": "NoSuchNode", "target": [10, 0], "speed": 1000.0},
		{"type": "end"},
	], "probe_missing", root)
	t.assert_false(cm.cutscene_active, "the cutscene finishes rather than hanging")
	root.free()

func test_set_flag_beat_writes_game_state(t: TestContext) -> void:
	var cm: Node = _cm(t)
	var gs: Node = t.tree.root.get_node("GameState")
	var root := Node2D.new()
	await cm.play_cutscene([
		{"type": "set_flag", "flag": "region.hold.unlocked", "value": true},
		{"type": "set_flag", "flag": "weird.misroutes", "increment": 3},
		{"type": "end"},
	], "probe_flags", root)

	t.assert_eq(gs.get_flag("region.hold.unlocked", false), true, "a set_flag beat writes a value")
	t.assert_eq(gs.get_flag("weird.misroutes", 0), 3, "a set_flag beat honours increment")
	root.free()

func test_emit_beat_raises_a_signal_for_scenes_to_hook(t: TestContext) -> void:
	var cm: Node = _cm(t)
	var root := Node2D.new()
	var emitted: Array = []
	var handler := func(signal_name: String, args: Array) -> void:
		emitted.append([signal_name, args])
	cm.beat_emitted.connect(handler)

	await cm.play_cutscene([
		{"type": "emit", "signal": "door_opened", "args": ["south"]},
		{"type": "end"},
	], "probe_emit", root)

	cm.beat_emitted.disconnect(handler)
	t.assert_eq(emitted, [["door_opened", ["south"]]], "emit fires the named signal with its args")
	root.free()

func test_targets_accept_the_json_array_form(t: TestContext) -> void:
	var cm: Node = _cm(t)
	t.assert_eq(cm._to_vector2([160, 96]), Vector2(160, 96), "an [x, y] array becomes a Vector2")
	t.assert_eq(cm._to_vector2(Vector2(1, 2)), Vector2(1, 2), "a Vector2 passes through")

func test_skip_is_refused_for_an_unskippable_cutscene(t: TestContext) -> void:
	var cm: Node = _cm(t)
	t.assert_true(cm.current_is_skippable(), "cutscenes are skippable unless declared otherwise")
	cm._document = {"skippable": false}
	t.assert_false(cm.current_is_skippable(), "a cutscene may declare itself unskippable")
	cm._document = {}

func test_missing_cutscene_file_is_refused(t: TestContext) -> void:
	var cm: Node = _cm(t)
	t.assert_eq(cm.load_cutscene("no_such_cutscene"), {}, "a missing cutscene loads as empty")
	t.assert_false(cm.play_cutscene_id("no_such_cutscene", null), "and is refused rather than played")
