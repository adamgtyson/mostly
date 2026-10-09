extends RefCounted

## Session 7: the weirdness system against Docs/WEIRDNESS_SPEC.md (ledger §M).
##
## test_weirdness.gd already covers the EC-10 skeleton's contract. This file
## asserts the things the *spec* decided and the skeleton did not: the ladder,
## the jitter band, the arrival grace, the player-time clock, the area override
## that silences Hobb's village, the no-repeat line pool, and that every v1
## handler actually runs in the dev area.
##
## Tuning numbers stay PROPOSED, so nothing here asserts a specific
## min_intensity or weight — only the rules those numbers have to obey.

const DEV_AREA := "res://regions/hold/areas/weirdness_test.tscn"

## The eight rungs of §2.1, in order, with the running total each should reach.
const LADDER: Array = [
	["act1.nine_days_noted", 0.05],
	["act1.last_post.road_seen", 0.15],
	["act1.mill_fixed", 0.25],
	["act1.wren.map_received", 0.35],
	["act1.turning.entered", 0.5],
	["act1.abbey.arrived", 0.65],
	["act1.forge_seen", 0.75],
	["act1.abbey.departed", 1.0],
]

const V1_KINDS: Array[String] = [
	"sprite_edge",
	"tile_blink",
	"npc_wrong_frame",
	"sound_offstage",
	"light_skip",
	"npc_line",
]

func _w(t: TestContext) -> Node:
	return t.tree.root.get_node("Weirdness")

func _gs(t: TestContext) -> Node:
	return t.tree.root.get_node("GameState")

func _spot(spot_name: String, kinds: Array[String] = []) -> FlickerSpot:
	var spot := FlickerSpot.new()
	spot.name = spot_name
	spot.allowed_kinds = kinds
	return spot

# ── the ladder (§2.1, M-2) ───────────────────────────────────────────────────

func test_the_ladder_is_monotonic_and_reaches_one(t: TestContext) -> void:
	var w: Node = _w(t)
	var gs: Node = _gs(t)
	w.set_area_weirdness(null)
	var previous: float = w.recompute()
	t.assert_eq(previous, 0.0, "a fresh run starts deniable: intensity 0")

	for rung: Array in LADDER:
		gs.set_flag(str(rung[0]), true)
		var now: float = w.recompute()
		t.assert_true(now >= previous, "'%s' never lowers intensity" % str(rung[0]))
		t.assert_true(is_equal_approx(snappedf(now, 0.001), float(rung[1])),
			"'%s' puts the running total at %.2f, got %.3f" % [str(rung[0]), float(rung[1]), now])
		previous = now

	t.assert_true(is_equal_approx(previous, 1.0), "the return trip tops the ladder out at 1.0")

func test_every_ladder_flag_is_declared(t: TestContext) -> void:
	var gs: Node = _gs(t)
	for rung: Array in LADDER:
		t.assert_true(gs.is_declared(str(rung[0])),
			"%s is in the flag registry, so the validator can police it" % str(rung[0]))

# ── eligibility (§1) ────────────────────────────────────────────────────────

func test_no_kind_is_eligible_below_its_min_intensity(t: TestContext) -> void:
	var w: Node = _w(t)
	var catalog: Dictionary = w.catalog()
	var spot: FlickerSpot = _spot("Anywhere")
	w.register_spot(spot)

	for kind: String in V1_KINDS:
		var minimum: float = float((catalog[kind] as Dictionary).get("min_intensity", 0.0))
		# Just below its floor the kind must be invisible to the scheduler…
		w._curve = {"base_intensity": maxf(0.0, minimum - 0.01), "act_progress": [], "counters": {}, "events": {}}
		w.recompute()
		t.assert_false(_kinds_now(w).has(kind), "%s cannot fire below its min_intensity" % kind)

		# …and at it, available.
		w._curve = {"base_intensity": minimum, "act_progress": [], "counters": {}, "events": {}}
		w.recompute()
		t.assert_true(_kinds_now(w).has(kind), "%s becomes available at its min_intensity" % kind)

	w.unregister_spot(spot)
	spot.free()
	w._load_curve()

func _kinds_now(w: Node) -> Array:
	var kinds: Array = []
	for pair: Dictionary in w.eligible_pairs():
		kinds.append(pair["kind"])
	return kinds

# ── the area override (§4, M-4) ─────────────────────────────────────────────

func test_an_area_override_replaces_the_region_multiplier(t: TestContext) -> void:
	var w: Node = _w(t)
	w._curve = {"base_intensity": 1.0, "act_progress": [], "counters": {}, "events": {"misroute": 1.0}}
	w._region_multiplier = 1.5
	w.recompute()
	t.assert_eq(w.intensity, 1.0, "The Turning's 1.5 multiplier clamps at the ceiling")

	w.set_area_weirdness(0.0)
	t.assert_eq(w.effective_multiplier(), 0.0, "the area override wins over the region")
	t.assert_eq(w.intensity, 0.0, "and silences this one area")

	w.set_area_weirdness(null)
	t.assert_eq(w.effective_multiplier(), 1.5, "clearing it hands the region back")
	w._load_curve()

func test_hobbs_village_fires_nothing_across_a_thousand_attempts(t: TestContext) -> void:
	var w: Node = _w(t)
	# Everything else maximised: full intensity, every kind allowed, a spot present.
	w._curve = {"base_intensity": 1.0, "act_progress": [], "counters": {}, "events": {"misroute": 1.0}}
	w._region_multiplier = 1.0
	var spot: FlickerSpot = _spot("HobbsYard")
	w.register_spot(spot)
	w.set_area_weirdness(0.0)

	var fired: int = 0
	var misroutes: int = 0
	for _i: int in 1000:
		if w.fire_one():
			fired += 1
		if w.roll("misroute"):
			misroutes += 1

	t.assert_eq(fired, 0, "1000 forced firings produce nothing where the override is 0")
	t.assert_eq(misroutes, 0, "and no misroute either — the override suppresses the roll too")
	t.assert_eq(w.chance_for("misroute"), 0.0, "because intensity itself is 0 there")

	w.unregister_spot(spot)
	spot.free()
	w.set_area_weirdness(null)
	w._load_curve()

# ── the line pool (§9, M-8) ─────────────────────────────────────────────────

func test_npc_line_never_repeats_across_five_hundred_draws(t: TestContext) -> void:
	var w: Node = _w(t)
	w._curve = {"base_intensity": 1.0, "act_progress": [], "counters": {}, "events": {}}
	w.recompute()

	var seen: Dictionary = {}
	var drawn: int = 0
	for _i: int in 500:
		var line: Dictionary = w.take_line()
		if line.is_empty():
			continue
		var id_value: String = str(line.get("id", ""))
		t.assert_false(seen.has(id_value), "line '%s' is never offered twice in one run" % id_value)
		seen[id_value] = true
		drawn += 1

	t.assert_eq(drawn, 19, "the whole §9 pool is reachable, and only once each")
	t.assert_eq(w.take_line(), {}, "an exhausted pool says nothing rather than repeating")
	w._load_curve()

func test_a_gated_line_waits_for_its_intensity(t: TestContext) -> void:
	var w: Node = _w(t)
	# 'six' is the one line §9 gates (min_intensity 0.5).
	w._curve = {"base_intensity": 0.4, "act_progress": [], "counters": {}, "events": {}}
	w.recompute()
	var reachable: Dictionary = {}
	for _i: int in 100:
		var line: Dictionary = w.take_line()
		if line.is_empty():
			break
		reachable[str(line.get("id", ""))] = true
	t.assert_false(reachable.has("six"), "a gated line is unavailable below its min_intensity")
	t.assert_eq(reachable.size(), 18, "the other eighteen are available")
	w._load_curve()

# ── the scheduler (§2, M-2) ─────────────────────────────────────────────────

func test_jittered_intervals_stay_inside_the_band(t: TestContext) -> void:
	var w: Node = _w(t)
	var jitter: float = w.jitter_s()
	var floor_s: float = w.global_floor_s()

	for level: float in [0.0, 1.0]:
		w._curve = {"base_intensity": level, "act_progress": [], "counters": {}, "events": {}}
		w.recompute()
		var base: float = w.base_interval()
		var low: float = maxf(floor_s, base - jitter)
		var high: float = base + jitter
		var distinct: Dictionary = {}
		var out_of_band: int = 0
		for _i: int in 1000:
			var sample: float = w.next_interval()
			if sample < low - 0.001 or sample > high + 0.001:
				out_of_band += 1
			distinct[snappedf(sample, 0.01)] = true
		t.assert_eq(out_of_band, 0, "at intensity %.1f every interval lands in [%.1f, %.1f]" % [level, low, high])
		t.assert_true(distinct.size() > 1, "and the interval is never a metronome")
	w._load_curve()

func test_the_clock_stops_when_the_player_has_no_control(t: TestContext) -> void:
	var w: Node = _w(t)
	var gs: Node = _gs(t)
	w._curve = {"base_intensity": 1.0, "act_progress": [], "counters": {}, "events": {}}
	w.recompute()
	var spot: FlickerSpot = _spot("Hearth")
	w.register_spot(spot)
	w.on_area_entered("hold/test")
	w._grace_remaining = 0.0

	gs.set_flag("sys.player_has_control", false)
	w._process(10000.0)
	t.assert_eq(w.debug_log().size(), 0, "dialogue, cutscene or menu: the scheduler does not age")

	gs.set_flag("sys.player_has_control", true)
	w._process(10000.0)
	t.assert_eq(w.debug_log().size(), 1, "with control back, the overdue flicker fires")

	w.unregister_spot(spot)
	spot.free()
	w._load_curve()

func test_nothing_fires_during_the_arrival_grace(t: TestContext) -> void:
	var w: Node = _w(t)
	w._curve = {"base_intensity": 1.0, "act_progress": [], "counters": {}, "events": {}}
	w.recompute()
	var spot: FlickerSpot = _spot("Hearth")
	w.register_spot(spot)

	w.on_area_entered("hold/test")
	t.assert_eq(w.grace_remaining(), w.arrival_grace_s(), "arriving starts the grace at 8s")

	# A tick shorter than the grace, however long the countdown says it is owed.
	w._process(w.arrival_grace_s() - 1.0)
	t.assert_eq(w.debug_log().size(), 0, "nothing fires in the first 8 seconds in an area")
	t.assert_true(w.grace_remaining() > 0.0, "and the grace is still running")

	w._process(1.0)
	t.assert_eq(w.grace_remaining(), 0.0, "the grace runs out")
	t.assert_eq(w.debug_log().size(), 0, "the frame that ends it is not a firing frame either")

	w._process(10000.0)
	t.assert_eq(w.debug_log().size(), 1, "afterwards the scheduler behaves normally")

	w.unregister_spot(spot)
	spot.free()
	w._load_curve()

func test_the_global_floor_separates_two_firings(t: TestContext) -> void:
	var w: Node = _w(t)
	w._curve = {"base_intensity": 1.0, "act_progress": [], "counters": {}, "events": {}}
	w.recompute()
	var spot: FlickerSpot = _spot("Hearth")
	var other: FlickerSpot = _spot("Well")
	w.register_spot(spot)
	w.register_spot(other)
	w.on_area_entered("hold/test")
	w._grace_remaining = 0.0

	w._process(10000.0)
	t.assert_eq(w.debug_log().size(), 1, "one firing")

	# Overdue again, but inside the 10s floor: still silence.
	w._process(w.global_floor_s() - 1.0)
	t.assert_eq(w.debug_log().size(), 1, "no second flicker within 10s of the first (§6 rule 4)")

	w._process(10000.0)
	t.assert_true(w.debug_log().size() >= 2, "past the floor it may fire again")

	w.unregister_spot(spot)
	w.unregister_spot(other)
	spot.free()
	other.free()
	w._load_curve()

# ── the dev area and the handlers (§8) ──────────────────────────────────────

func test_the_dev_area_carries_a_spot_for_every_v1_kind(t: TestContext) -> void:
	var packed: PackedScene = load(DEV_AREA)
	t.assert_true(packed != null, "the weirdness dev area loads")
	if packed == null:
		return
	var scene: Node = packed.instantiate()
	var covered: Dictionary = {}
	for node: Node in scene.get_node("Spots").get_children():
		for kind: String in (node.get("allowed_kinds") as Array):
			covered[kind] = true
	for kind: String in V1_KINDS:
		t.assert_true(covered.has(kind), "the dev area can exercise '%s'" % kind)
	scene.free()

func test_every_v1_handler_runs_without_error(t: TestContext) -> void:
	var w: Node = _w(t)
	var packed: PackedScene = load(DEV_AREA)
	if packed == null:
		t.fail("the weirdness dev area failed to load")
		return
	var scene: Node = packed.instantiate()
	t.tree.root.add_child(scene)
	await t.tree.process_frame

	t.assert_eq(w.spot_count(), V1_KINDS.size(), "every FlickerSpot registered itself on entering the tree")

	var handlers: FlickerHandlers = w.handlers()
	t.assert_true(handlers != null, "Weirdness owns a handler registry")
	if handlers == null:
		scene.queue_free()
		return
	handlers.clear_calls()

	# Full intensity so npc_line's own gate is open, then force each kind at the
	# spot that allows it rather than waiting on the scheduler.
	w._curve = {"base_intensity": 1.0, "act_progress": [], "counters": {}, "events": {}}
	w.recompute()

	for kind: String in V1_KINDS:
		var spot: Node = _spot_for(scene, kind)
		if spot == null:
			t.fail("no spot in the dev area allows '%s'" % kind)
			continue
		await handlers.dispatch(kind, spot, w.params_for(kind, spot))

	var ran: Dictionary = {}
	for call_record: Dictionary in handlers.calls():
		ran[str(call_record.get("kind", ""))] = true
	for kind: String in V1_KINDS:
		t.assert_true(ran.has(kind), "handler for '%s' ran" % kind)

	t.assert_true(is_instance_valid(scene), "and the area survived all six")
	scene.queue_free()
	await t.tree.process_frame
	w._load_curve()

func _spot_for(scene: Node, kind: String) -> Node:
	for node: Node in scene.get_node("Spots").get_children():
		if (node.get("allowed_kinds") as Array).has(kind):
			return node
	return null

func test_a_flicker_writes_nothing_to_a_save(t: TestContext) -> void:
	var w: Node = _w(t)
	var gs: Node = _gs(t)
	w._curve = {"base_intensity": 1.0, "act_progress": [], "counters": {}, "events": {}}
	w.recompute()
	var spot: FlickerSpot = _spot("Hearth")
	w.register_spot(spot)

	var before: Dictionary = gs.to_save_dict()
	w.fire_one()
	t.assert_eq(gs.to_save_dict(), before, "§6 rule 2: a flicker sets no flag and saves nothing")
	t.assert_eq(w.to_save_dict(), {}, "and Weirdness itself still contributes no section")

	w.unregister_spot(spot)
	spot.free()
	w._load_curve()

func test_player_control_is_never_saved(t: TestContext) -> void:
	var gs: Node = _gs(t)
	gs.set_flag("sys.player_has_control", false)
	gs.set_flag("act1.mill_fixed", true)
	var payload: Dictionary = gs.to_save_dict()
	t.assert_false(payload.has("sys.player_has_control"),
		"a transient flag stays out of the save, so no load can restore a lock")
	t.assert_true(payload.has("act1.mill_fixed"), "progress flags are unaffected")
