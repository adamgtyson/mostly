extends RefCounted

## Milestone 2: GameState (§2). Uses only keys declared in data/flags.json so the
## registry warning path stays quiet and the tests double as registry coverage.

func _state(t: TestContext) -> Node:
	return t.tree.root.get_node("GameState")

func test_set_get_and_has(t: TestContext) -> void:
	var gs: Node = _state(t)
	t.assert_false(gs.has_flag("region.hold.unlocked"), "a fresh state has no flags")
	t.assert_eq(gs.get_flag("region.hold.unlocked", false), false, "get_flag returns the default when unset")

	gs.set_flag("region.hold.unlocked", true)
	t.assert_true(gs.has_flag("region.hold.unlocked"), "has_flag sees the written key")
	t.assert_eq(gs.get_flag("region.hold.unlocked", false), true, "get_flag returns the written value")

func test_increment_creates_and_accumulates(t: TestContext) -> void:
	var gs: Node = _state(t)
	t.assert_eq(gs.increment("weird.misroutes"), 1, "increment creates a missing counter at 0 then adds")
	t.assert_eq(gs.increment("weird.misroutes"), 2, "increment accumulates")
	t.assert_eq(gs.increment("region.total_crossing_attempts", 3), 3, "increment honours the 'by' argument")
	t.assert_eq(gs.get_flag("weird.misroutes", 0), 2, "the counter is readable as a flag")

func test_flag_changed_signal_fires(t: TestContext) -> void:
	var gs: Node = _state(t)
	var seen: Array = []
	var handler := func(key: String, value: Variant) -> void:
		seen.append([key, value])
	gs.flag_changed.connect(handler)

	gs.set_flag("sys.realistic_weight", true)
	gs.increment("weird.misroutes")
	gs.flag_changed.disconnect(handler)

	t.assert_eq(seen.size(), 2, "set_flag and increment each emit once")
	t.assert_eq(seen[0], ["sys.realistic_weight", true], "set_flag reports key and value")
	t.assert_eq(seen[1], ["weird.misroutes", 1], "increment reports the new total")

func test_reset_clears_flags(t: TestContext) -> void:
	var gs: Node = _state(t)
	gs.set_flag("sys.realistic_weight", true)
	gs.reset()
	t.assert_false(gs.has_flag("sys.realistic_weight"), "reset clears every flag")
	t.assert_true(gs.declared_keys().size() > 0, "reset does not clear the registry")

func test_save_roundtrip(t: TestContext) -> void:
	var gs: Node = _state(t)
	gs.set_flag("region.hold.unlocked", true)
	gs.increment("region.hold.crossing_attempts", 2)
	var snapshot: Dictionary = gs.to_save_dict()

	gs.reset()
	t.assert_false(gs.has_flag("region.hold.unlocked"), "state is empty after reset")

	gs.from_save_dict(snapshot)
	t.assert_eq(gs.get_flag("region.hold.unlocked", false), true, "restored bool flag")
	t.assert_eq(gs.get_flag("region.hold.crossing_attempts", 0), 2, "restored counter")

func test_save_dict_is_a_copy(t: TestContext) -> void:
	var gs: Node = _state(t)
	gs.set_flag("weird.misroutes", 1)
	var snapshot: Dictionary = gs.to_save_dict()
	gs.set_flag("weird.misroutes", 99)
	t.assert_eq(snapshot.get("weird.misroutes"), 1, "a snapshot does not follow later writes")

func test_registry_declares_seeded_keys(t: TestContext) -> void:
	var gs: Node = _state(t)
	for key: String in ["sys.realistic_weight", "region.hold.unlocked", "weird.misroutes", "region.total_crossing_attempts"]:
		t.assert_true(gs.is_declared(key), "%s is declared in the registry" % key)
	t.assert_false(gs.is_declared("region.hold.definitely_not_a_flag"), "an unknown key is not declared")

func test_region_lock_flag_is_critical(t: TestContext) -> void:
	var gs: Node = _state(t)
	t.assert_true(gs.is_critical("region.hold.unlocked"), "region unlocks are critical tier")
	t.assert_false(gs.is_critical("weird.misroutes"), "counters are normal tier")
