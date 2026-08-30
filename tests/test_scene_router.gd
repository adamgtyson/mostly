extends RefCounted

## Milestone 7: SceneRouter and the region package (§6, §7).
##
## The transition mechanism is exercised in pieces — load, place, lock, misroute
## guard — rather than by swapping the running scene, which would fire the
## workshop's opening cutscene into the middle of the suite.

func _router(t: TestContext) -> Node:
	return t.tree.root.get_node("SceneRouter")

func _gs(t: TestContext) -> Node:
	return t.tree.root.get_node("GameState")

func _fake_area(region: String, area: String) -> Node2D:
	var node := Node2D.new()
	node.set_script(load("res://scripts/area.gd"))
	node.set("region_id", region)
	node.set("area_id", area)
	return node

# ── region packages (§7) ─────────────────────────────────────────────────────

func test_hold_region_manifest_loads(t: TestContext) -> void:
	var router: Node = _router(t)
	var region: Dictionary = router.region_data("hold")
	t.assert_eq(region.get("id"), "hold", "the Hold manifest loads")
	t.assert_eq(region.get("display_name"), "The Hold", "with its display name")
	t.assert_true(region.has("fill_slots"), "and the generator-shaped fields (§7)")
	t.assert_eq(region.get("fill_slots"), [], "empty fill_slots are valid in v1")

func test_workshop_is_the_hold_anchor(t: TestContext) -> void:
	var router: Node = _router(t)
	var anchors: Array = router.region_anchors("hold")
	t.assert_eq(anchors.size(), 1, "the Hold declares one anchor in Foundations")
	t.assert_eq((anchors[0] as Dictionary).get("area"), "workshop", "and it is the workshop")

func test_area_scene_path_follows_the_package_layout(t: TestContext) -> void:
	var router: Node = _router(t)
	t.assert_eq(
		router.area_scene_path("hold", "workshop"),
		"res://regions/hold/areas/workshop.tscn",
		"area scenes live at regions/<region>/areas/<area>.tscn (§6)")

func test_the_workshop_scene_moved_into_the_region(t: TestContext) -> void:
	t.assert_true(
		FileAccess.file_exists("res://regions/hold/areas/workshop.tscn"),
		"the workshop lives in the region package")
	t.assert_false(
		FileAccess.file_exists("res://scenes/workshop.tscn"),
		"and no longer at its old path")

# ── the Area root (§6) ───────────────────────────────────────────────────────

func test_area_exposes_its_id_rect_and_spawns(t: TestContext) -> void:
	var packed: PackedScene = load("res://regions/hold/areas/workshop.tscn")
	t.assert_true(packed != null, "the workshop scene loads")
	var scene: Node = packed.instantiate()

	t.assert_eq(scene.call("full_id"), "hold/workshop", "area ids are <region>/<area>")
	t.assert_eq(scene.call("used_rect"), Rect2i(0, 0, 320, 240), "camera bounds are unchanged from session 3")
	scene.free()

func test_area_spawn_positions(t: TestContext) -> void:
	var packed: PackedScene = load("res://regions/hold/areas/workshop.tscn")
	var scene: Node = packed.instantiate()
	# _ready has not run for a detached instance, so build the table directly.
	scene.set("spawns", scene.call("_collect_spawns"))

	t.assert_eq(scene.call("spawn_position", "default"), Vector2(48, 64), "the default spawn is Patch's start position")
	t.assert_eq(scene.call("spawn_position", "no_such_spawn"), Vector2(48, 64), "an unknown spawn falls back to default")
	scene.free()

func test_registering_an_area_sets_the_current_location(t: TestContext) -> void:
	var router: Node = _router(t)
	var area: Node2D = _fake_area("hold", "workshop")
	var regions_seen: Array = []
	var handler := func(region: String) -> void: regions_seen.append(region)
	router.region_changed.connect(handler)

	router.register_area(area)

	router.region_changed.disconnect(handler)
	t.assert_eq(router.current_id(), "hold/workshop", "the router knows where the game is")
	t.assert_true(router.has_visited("hold", "workshop"), "arriving marks the area visited")
	t.assert_eq(regions_seen, ["hold"], "entering a new region announces it")
	area.free()

# ── the region lock (§2, §6) ─────────────────────────────────────────────────

func test_a_region_is_locked_until_its_flag_is_set(t: TestContext) -> void:
	var router: Node = _router(t)
	var gs: Node = _gs(t)
	t.assert_false(router.is_region_unlocked("hold"), "an unset region flag means locked")
	gs.set_flag("region.hold.unlocked", true)
	t.assert_true(router.is_region_unlocked("hold"), "the flag alone represents the lock")

func test_new_game_unlocks_the_starting_region(t: TestContext) -> void:
	var router: Node = _router(t)
	var gs: Node = _gs(t)
	t.assert_eq(router.starting_region(), "hold", "the starting region comes from config, not a literal")
	router.new_game()
	t.assert_eq(gs.get_flag("region.hold.unlocked", false), true, "a new run can reach the starting region")

func test_travel_into_a_locked_region_is_refused(t: TestContext) -> void:
	var router: Node = _router(t)
	var blocked: Array = []
	var handler := func(region: String, reason: String) -> void: blocked.append(region)
	router.travel_blocked.connect(handler)

	var moved: bool = await router.go_to("turning", "border")

	router.travel_blocked.disconnect(handler)
	t.assert_false(moved, "the move is refused")
	t.assert_eq(blocked, ["turning"], "and reported against the locked region")
	t.assert_eq(router.current_id(), "", "the player did not move")

# ── misroutes (EC-6a) ────────────────────────────────────────────────────────

func test_a_misroute_never_targets_an_unvisited_area(t: TestContext) -> void:
	var router: Node = _router(t)
	_gs(t).set_flag("region.hold.unlocked", true)
	router.register_area(_fake_area("hold", "workshop"))

	# Only the workshop has been visited, and it is where the player already is,
	# so there is nowhere legal to misroute to.
	t.assert_eq(router._misroute_destination("hold", "last_post"), {},
		"with no other visited area, no misroute is possible")

func test_a_misroute_picks_only_visited_areas(t: TestContext) -> void:
	var router: Node = _router(t)
	_gs(t).set_flag("region.hold.unlocked", true)
	router.mark_visited("hold", "workshop")
	router.mark_visited("hold", "yard")
	router.register_area(_fake_area("hold", "workshop"))

	var destination: Dictionary = router._misroute_destination("hold", "last_post")
	t.assert_eq(destination.get("region"), "hold", "a misroute stays inside the current region")
	t.assert_eq(destination.get("area"), "yard", "and lands only on somewhere already visited")

func test_a_misroute_increments_the_only_persisted_trace(t: TestContext) -> void:
	var router: Node = _router(t)
	var gs: Node = _gs(t)
	router.increment_misroute_count()
	t.assert_eq(gs.get_flag("weird.misroutes", 0), 1, "weird.misroutes is the only trace a misroute leaves")

# ── save contract (§3) ───────────────────────────────────────────────────────

func test_router_saves_under_the_location_key(t: TestContext) -> void:
	var router: Node = _router(t)
	t.assert_eq(router.save_key(), "location", "the router contributes the §3 'location' section")

func test_location_save_roundtrip(t: TestContext) -> void:
	var router: Node = _router(t)
	router.register_area(_fake_area("hold", "workshop"))
	router.mark_visited("hold", "yard")
	var snapshot: Dictionary = router.to_save_dict()
	t.assert_eq(snapshot.get("region"), "hold", "the saved location names the region")
	t.assert_eq(snapshot.get("area"), "workshop", "and the area")
	t.assert_true(snapshot.has("position"), "and the player's position")

	router.reset()
	t.assert_eq(router.current_id(), "", "reset clears the location")

	router.from_save_dict(snapshot)
	t.assert_eq(router.current_id(), "hold/workshop", "the location comes back")
	t.assert_true(router.has_visited("hold", "yard"), "and so does the visited set the misroute guard needs")

func test_save_payload_includes_location(t: TestContext) -> void:
	var router: Node = _router(t)
	router.register_area(_fake_area("hold", "workshop"))
	var payload: Dictionary = t.tree.root.get_node("SaveManager").build_payload()
	t.assert_true(payload.has("location"), "SaveManager picks the router up generically")
	t.assert_eq((payload["location"] as Dictionary).get("area"), "workshop", "with the current area in it")
