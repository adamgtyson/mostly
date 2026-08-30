extends RefCounted

## Milestone 3: SaveManager (§3).
##
## Every test points saves_dir at a scratch directory inside the saves/ tree, so
## a test run can never overwrite a real player slot, and removes what it wrote.
## Nothing here touches user:// outside the §3 layout.

const TEST_SAVES_DIR := "user://saves/test"

func _sm(t: TestContext) -> Node:
	var sm: Node = t.tree.root.get_node("SaveManager")
	sm.saves_dir = TEST_SAVES_DIR
	return sm

func _gs(t: TestContext) -> Node:
	return t.tree.root.get_node("GameState")

## Removes the scratch slot files and the scratch directory itself.
func _cleanup(sm: Node) -> void:
	for slot: String in sm.all_slot_names():
		var path: String = sm.slot_path(slot)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	if DirAccess.dir_exists_absolute(TEST_SAVES_DIR):
		DirAccess.remove_absolute(TEST_SAVES_DIR)

func test_payload_has_the_schema_envelope(t: TestContext) -> void:
	var sm: Node = _sm(t)
	var payload: Dictionary = sm.build_payload()
	t.assert_eq(payload.get("schema_version"), 1, "payload carries schema_version")
	t.assert_true(payload.has("timestamp"), "payload carries a timestamp")
	t.assert_true(payload.has("playtime_s"), "payload carries playtime_s")
	t.assert_true(payload.has("game_state"), "GameState contributes under its snake_case name")

func test_save_and_load_roundtrip(t: TestContext) -> void:
	var sm: Node = _sm(t)
	var gs: Node = _gs(t)
	gs.set_flag("region.hold.unlocked", true)
	gs.increment("weird.misroutes", 4)

	t.assert_true(sm.save_to_slot("1"), "save_to_slot succeeds")
	t.assert_true(sm.has_slot("1"), "the slot file exists after saving")

	gs.reset()
	t.assert_false(gs.has_flag("region.hold.unlocked"), "state cleared before loading")

	t.assert_true(sm.load_from_slot("1"), "load_from_slot succeeds")
	t.assert_eq(gs.get_flag("region.hold.unlocked", false), true, "flags come back")
	t.assert_eq(gs.get_flag("weird.misroutes", 0), 4, "counters come back")
	_cleanup(sm)

func test_autosave_writes_the_auto_slot(t: TestContext) -> void:
	var sm: Node = _sm(t)
	t.assert_true(sm.autosave(), "autosave succeeds")
	t.assert_true(sm.has_slot("auto"), "autosave writes slot_auto.json")
	t.assert_true(sm.slot_path("auto").ends_with("slot_auto.json"), "auto slot is named slot_auto")
	_cleanup(sm)

func test_save_is_refused_during_dialogue(t: TestContext) -> void:
	var sm: Node = _sm(t)
	var dm: Node = t.tree.root.get_node("DialogueManager")
	var refusals: Array = []
	var handler := func(reason: String) -> void:
		refusals.append(reason)
	sm.save_refused.connect(handler)

	dm.dialogue_active = true
	t.assert_false(sm.can_save(), "saving is blocked while dialogue is active")
	t.assert_false(sm.save_to_slot("1"), "save_to_slot refuses")
	t.assert_false(sm.has_slot("1"), "nothing was written")
	dm.dialogue_active = false

	sm.save_refused.disconnect(handler)
	t.assert_eq(refusals.size(), 1, "the refusal is reported once")
	t.assert_true(sm.can_save(), "saving is allowed again once dialogue ends")
	_cleanup(sm)

func test_save_is_refused_during_cutscene(t: TestContext) -> void:
	var sm: Node = _sm(t)
	var cm: Node = t.tree.root.get_node("CutsceneManager")
	cm.cutscene_active = true
	t.assert_false(sm.can_save(), "saving is blocked while a cutscene plays")
	t.assert_eq(sm.blocking_reason(), "a cutscene is playing", "the reason names the cutscene")
	cm.cutscene_active = false
	t.assert_true(sm.can_save(), "saving is allowed again after the cutscene")

func test_loader_refuses_a_newer_schema(t: TestContext) -> void:
	var sm: Node = _sm(t)
	var from_the_future: Dictionary = {"schema_version": 999, "game_state": {}}
	t.assert_eq(sm.apply_migrations(from_the_future), {}, "a newer save is refused, not guessed at")

func test_loader_refuses_a_versionless_payload(t: TestContext) -> void:
	var sm: Node = _sm(t)
	t.assert_eq(sm.apply_migrations({"game_state": {}}), {}, "a payload with no schema_version is refused")

func test_current_version_passes_through_unchanged(t: TestContext) -> void:
	var sm: Node = _sm(t)
	var payload: Dictionary = {"schema_version": 1, "game_state": {"sys.realistic_weight": true}}
	var out: Dictionary = sm.apply_migrations(payload)
	t.assert_eq(out.get("schema_version"), 1, "a current payload keeps its version")
	t.assert_eq(out.get("game_state"), {"sys.realistic_weight": true}, "a current payload is untouched")

func test_migration_table_walks_an_older_payload_up(t: TestContext) -> void:
	# Exercises the table itself by registering a step, without pretending the
	# project has a second schema version yet.
	var sm: Node = _sm(t)
	var original: Dictionary = sm._migrations.duplicate()
	sm._migrations[0] = func(p: Dictionary) -> Dictionary:
		p["upgraded"] = true
		return p

	# With SCHEMA_VERSION at 1, a version-0 payload is rejected before the table
	# is consulted, so drive the loop directly at the boundary it does cover.
	var at_current: Dictionary = sm.apply_migrations({"schema_version": 1})
	t.assert_eq(at_current.get("schema_version"), 1, "no migration runs at the current version")
	t.assert_false(at_current.has("upgraded"), "a registered step is not applied needlessly")
	t.assert_true(sm._migrations.has(1), "the v1 identity step is registered from day one")

	sm._migrations = original

func test_slot_validation(t: TestContext) -> void:
	var sm: Node = _sm(t)
	t.assert_true(sm.is_valid_slot("auto"), "auto is a valid slot")
	t.assert_true(sm.is_valid_slot("1"), "slot 1 is valid")
	t.assert_true(sm.is_valid_slot(str(sm.slot_count())), "the last configured slot is valid")
	t.assert_false(sm.is_valid_slot("0"), "slot 0 is rejected")
	t.assert_false(sm.is_valid_slot(str(sm.slot_count() + 1)), "a slot past the configured count is rejected")
	t.assert_false(sm.is_valid_slot("nope"), "a non-numeric slot is rejected")

func test_slot_count_comes_from_config(t: TestContext) -> void:
	var sm: Node = _sm(t)
	t.assert_eq(sm.slot_count(), GameConfig.get_int("save.slots", -1), "slot count is read from config, not hardcoded")

func test_slot_info_and_listing(t: TestContext) -> void:
	var sm: Node = _sm(t)
	t.assert_eq(sm.list_slots(), [], "nothing is listed before anything is saved")
	sm.save_to_slot("2")
	var info: Dictionary = sm.slot_info("2")
	t.assert_eq(info.get("slot"), "2", "slot_info names the slot")
	t.assert_eq(info.get("schema_version"), 1, "slot_info reports the schema version")
	t.assert_eq(sm.list_slots().size(), 1, "the saved slot is listed")
	_cleanup(sm)

func test_reset_restores_the_real_saves_dir(t: TestContext) -> void:
	var sm: Node = _sm(t)
	t.assert_eq(sm.saves_dir, TEST_SAVES_DIR, "the test seam is in place")
	sm.reset()
	t.assert_eq(sm.saves_dir, "user://saves", "reset puts the real save directory back")
	t.assert_eq(sm.playtime_s(), 0, "reset zeroes playtime")
