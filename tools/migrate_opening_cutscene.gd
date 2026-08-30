extends SceneTree

## One-shot migration of the opening cutscene from GDScript to data (§8):
##   godot --headless --path . -s tools/migrate_opening_cutscene.gd
##
## Instantiates the workshop scene, calls OpeningCutscene.build_beats() to get
## the *actual* runtime array, and serializes it two ways:
##
##   tests/fixtures/opening_beats_v1.json  the captured v1 sequence, the parity
##                                         baseline the test compares against
##   data/cutscenes/opening.json           the same beats in the v2 envelope
##
## Both come from one capture, so the migrated cutscene cannot silently differ
## from the script it replaces. Node references become node paths relative to
## the scene root (§8: actors are referenced by scene node name, resolved at
## play time) and Vector2 targets become [x, y].

const WORKSHOP := "res://scenes/workshop.tscn"
const FIXTURE_PATH := "res://tests/fixtures/opening_beats_v1.json"
const CUTSCENE_PATH := "res://data/cutscenes/opening.json"

func _initialize() -> void:
	var packed: Variant = load(WORKSHOP)
	if packed == null:
		push_error("migrate: cannot load %s" % WORKSHOP)
		quit(1)
		return
	var scene_root: Node = (packed as PackedScene).instantiate()

	var trigger: Node = scene_root.get_node_or_null("OpeningCutscene")
	var player: Node = scene_root.get_node_or_null("Player")
	if trigger == null or player == null:
		push_error("migrate: workshop.tscn has no OpeningCutscene or Player")
		scene_root.free()
		quit(1)
		return
	if not trigger.has_method("build_beats"):
		push_error("migrate: OpeningCutscene has no build_beats(); already migrated?")
		scene_root.free()
		quit(1)
		return
	var sprite: Node = player.get_node_or_null("AnimatedSprite2D")

	var beats: Array = trigger.call("build_beats", player, sprite)
	var serialized: Array = []
	for beat: Variant in beats:
		serialized.append(_serialize_beat(beat, scene_root))
	scene_root.free()

	print("captured %d beats" % serialized.size())
	for beat: Dictionary in serialized:
		print("  %s" % JSON.stringify(beat))

	var fixture: Dictionary = {
		"_comment": "Captured from scripts/opening_cutscene.gd's runtime beats array before that script was deleted (session 5, milestone 6). Parity baseline: data/cutscenes/opening.json must load to exactly this sequence.",
		"cutscene_id": "opening",
		"beats": serialized,
	}
	var cutscene: Dictionary = {
		"id": "opening",
		"skippable": true,
		"once": false,
		"beats": serialized,
	}

	var ok: bool = _write_json(FIXTURE_PATH, fixture) and _write_json(CUTSCENE_PATH, cutscene)
	print("")
	print("wrote %s and %s" % [FIXTURE_PATH, CUTSCENE_PATH] if ok else "write FAILED")
	quit(0 if ok else 1)

func _serialize_beat(beat: Variant, scene_root: Node) -> Dictionary:
	var out: Dictionary = {}
	if not (beat is Dictionary):
		return out
	# "type" first, then the rest sorted, so the file is stable across runs.
	var source: Dictionary = beat
	out["type"] = str(source.get("type", ""))
	var keys: Array = source.keys()
	keys.sort()
	for key: Variant in keys:
		var key_str: String = str(key)
		if key_str == "type":
			continue
		out[key_str] = _serialize_value(source[key], scene_root)
	return out

func _serialize_value(value: Variant, scene_root: Node) -> Variant:
	if value is Node:
		return str(scene_root.get_path_to(value))
	if value is Vector2:
		var v: Vector2 = value
		return [v.x, v.y]
	return value

func _write_json(path: String, data: Dictionary) -> bool:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("migrate: cannot write %s" % path)
		return false
	file.store_string(JSON.stringify(data, "  ") + "\n")
	file.close()
	return true
