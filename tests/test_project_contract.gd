extends RefCounted

## Milestone 9: the §13 contracts that hold the Foundations layer together.
## These fail loudly if a later session quietly widens the autoload roster or
## adds a stateful system that cannot be saved or reset.

## The closed roster (§13), minus Battle, which arrives in phase 5.
const EXPECTED_AUTOLOADS: Array[String] = [
	"Boot",
	"GameState",
	"SaveManager",
	"Inventory",
	"DialogueManager",
	"CutsceneManager",
	"CutsceneSkip",
	"SceneRouter",
	"Weirdness",
]

## Autoloads holding state a test must clear between runs.
const STATEFUL_AUTOLOADS: Array[String] = [
	"GameState",
	"SaveManager",
	"Inventory",
	"SceneRouter",
	"Weirdness",
]

## Autoloads that contribute a *section* to a save. SaveManager is deliberately
## absent: it owns the envelope (schema_version, timestamp, playtime_s) rather
## than contributing under a key of its own, so it implements reset() but not
## the section pair.
const SAVE_CONTRIBUTORS: Array[String] = [
	"GameState",
	"Inventory",
	"SceneRouter",
	"Weirdness",
]

func test_autoload_roster_is_exactly_the_closed_set(t: TestContext) -> void:
	var present: Array = []
	for child: Node in t.tree.root.get_children():
		# The running scene, if any, is not an autoload.
		if child == t.tree.current_scene:
			continue
		present.append(child.name)

	for expected: String in EXPECTED_AUTOLOADS:
		t.assert_true(present.has(expected), "%s is registered" % expected)

	for name: String in present:
		t.assert_true(
			EXPECTED_AUTOLOADS.has(name) or name == "Battle",
			"'%s' is on the §13 roster; adding one requires changing the constraints first" % name)

func test_every_stateful_autoload_resets(t: TestContext) -> void:
	for name: String in STATEFUL_AUTOLOADS:
		var node: Node = t.tree.root.get_node_or_null(name)
		if not t.assert_true(node != null, "%s exists" % name):
			continue
		t.assert_true(node.has_method("reset"), "%s implements reset() (§13)" % name)

func test_save_contributors_implement_the_section_pair(t: TestContext) -> void:
	for name: String in SAVE_CONTRIBUTORS:
		var node: Node = t.tree.root.get_node_or_null(name)
		if not t.assert_true(node != null, "%s exists" % name):
			continue
		t.assert_true(node.has_method("to_save_dict"), "%s implements to_save_dict()" % name)
		t.assert_true(node.has_method("from_save_dict"), "%s implements from_save_dict()" % name)

func test_save_manager_owns_the_envelope_not_a_section(t: TestContext) -> void:
	var sm: Node = t.tree.root.get_node("SaveManager")
	t.assert_false(sm.has_method("to_save_dict"),
		"SaveManager writes the envelope directly; a section of its own would duplicate playtime_s")
	t.assert_false(sm.CONTRIBUTORS.has("SaveManager"), "and it does not list itself as a contributor")

func test_every_contributor_is_registered_with_save_manager(t: TestContext) -> void:
	var sm: Node = t.tree.root.get_node("SaveManager")
	var contributors: Array = sm.CONTRIBUTORS
	for name: String in SAVE_CONTRIBUTORS:
		t.assert_true(contributors.has(name), "%s is listed as a save contributor" % name)

func test_config_placeholders_all_resolve(t: TestContext) -> void:
	var flagged: PackedStringArray = GameConfig.placeholders()
	t.assert_true(flagged.size() > 0, "open design values are flagged in config (§13)")
	for path: String in flagged:
		t.assert_true(GameConfig.get_value(path, null) != null, "placeholder '%s' resolves" % path)

func test_asset_manifest_covers_every_art_file(t: TestContext) -> void:
	var file := FileAccess.open("res://assets/manifest.json", FileAccess.READ)
	t.assert_true(file != null, "the asset manifest exists (§12)")
	if file == null:
		return
	var json := JSON.new()
	json.parse(file.get_as_text())
	file.close()
	var listed: Dictionary = {}
	for entry: Variant in (json.get_data() as Dictionary).get("assets", []):
		listed[str((entry as Dictionary).get("path", ""))] = entry

	for path: String in _art_files("res://assets"):
		var relative: String = path.trim_prefix("res://")
		t.assert_true(listed.has(relative), "%s has a manifest entry" % relative)

func test_mana_seed_assets_are_flagged_pending_the_eula(t: TestContext) -> void:
	# EC-12a is an OPEN pre-launch gate: until the licence is read, no Mana Seed
	# file may be used as AI input or style reference, and none is final.
	var file := FileAccess.open("res://assets/manifest.json", FileAccess.READ)
	if file == null:
		return
	var json := JSON.new()
	json.parse(file.get_as_text())
	file.close()
	for entry: Variant in (json.get_data() as Dictionary).get("assets", []):
		var e: Dictionary = entry
		if str(e.get("source", "")) != "mana_seed":
			continue
		t.assert_eq(str(e.get("status", "")), "placeholder",
			"%s is not final while its terms are unverified" % str(e.get("path", "")))
		t.assert_true(str(e.get("license", "")).contains("unverified"),
			"%s records that its licence is unverified" % str(e.get("path", "")))

func _art_files(dir_path: String) -> PackedStringArray:
	var found := PackedStringArray()
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return found
	for f: String in dir.get_files():
		if ["png", "jpg", "jpeg", "webp", "ogg", "wav", "mp3", "ttf", "otf"].has(f.get_extension().to_lower()):
			found.append("%s/%s" % [dir_path, f])
	for sub: String in dir.get_directories():
		found.append_array(_art_files("%s/%s" % [dir_path, sub]))
	return found
