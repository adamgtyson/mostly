extends RefCounted

## Milestone 8: the Weirdness skeleton (§10). Asserts the contract — derived
## intensity, region multiplier, the roll() hook, spot selection, the anti-repeat
## ring — not the eventual numbers, which are the BUILD_PLAN §5 design session.

func _w(t: TestContext) -> Node:
	return t.tree.root.get_node("Weirdness")

func _gs(t: TestContext) -> Node:
	return t.tree.root.get_node("GameState")

func _spot(name: String, kinds: Array[String] = []) -> Marker2D:
	var spot := Marker2D.new()
	spot.set_script(load("res://scripts/flicker_spot.gd"))
	spot.name = name
	spot.set("allowed_kinds", kinds)
	return spot

func test_intensity_starts_at_the_placeholder_floor(t: TestContext) -> void:
	var w: Node = _w(t)
	w.recompute()
	t.assert_eq(w.intensity, 0.0, "the placeholder curve yields 0, so nothing fires in Foundations")

func test_intensity_is_derived_not_saved(t: TestContext) -> void:
	var w: Node = _w(t)
	t.assert_eq(w.to_save_dict(), {}, "Weirdness saves nothing; intensity is derived (§10)")

	# A restore recomputes from flags rather than restoring a stored number.
	_gs(t).set_flag("weird.misroutes", 5)
	w.from_save_dict({})
	t.assert_true(w.intensity > 0.0, "loading recomputes intensity from the weird.* counters")

func test_counters_raise_intensity_and_are_capped(t: TestContext) -> void:
	var w: Node = _w(t)
	var gs: Node = _gs(t)
	gs.set_flag("weird.misroutes", 3)
	w.recompute()
	t.assert_true(w.intensity > 0.0, "misroutes nudge intensity up")

	gs.set_flag("weird.misroutes", 100000)
	w.recompute()
	t.assert_true(w.intensity <= 1.0, "intensity is clamped to 1.0")
	var capped: float = w.intensity
	gs.set_flag("weird.misroutes", 200000)
	w.recompute()
	t.assert_eq(w.intensity, capped, "a single counter cannot run away with the scale")

func test_intensity_recomputes_when_a_weird_counter_moves(t: TestContext) -> void:
	var w: Node = _w(t)
	var changes: Array = []
	var handler := func(value: float) -> void: changes.append(value)
	w.intensity_changed.connect(handler)

	_gs(t).increment("weird.misroutes", 4)

	w.intensity_changed.disconnect(handler)
	t.assert_true(changes.size() >= 1, "a weird.* write triggers a recompute")
	t.assert_true(w.intensity > 0.0, "and the new intensity reflects it")

func test_region_multiplier_scales_everything(t: TestContext) -> void:
	var w: Node = _w(t)
	_gs(t).set_flag("weird.misroutes", 5)
	w.recompute()
	var baseline: float = w.intensity
	t.assert_true(baseline > 0.0, "there is something to scale")

	# A region multiplier of 0 silences the region entirely (Hobb's village).
	w._region_multiplier = 0.0
	w.recompute()
	t.assert_eq(w.intensity, 0.0, "a 0 multiplier means nothing fires there at all")

	w._region_multiplier = 1.0
	w.recompute()
	t.assert_eq(w.intensity, baseline, "restoring the multiplier restores intensity")

func test_set_region_reads_the_region_manifest(t: TestContext) -> void:
	var w: Node = _w(t)
	w.set_region("hold")
	t.assert_eq(w.current_region(), "hold", "the region is recorded")
	t.assert_eq(w.region_multiplier(), 1.0, "the Hold's manifest multiplier is applied")

func test_roll_is_impossible_at_zero_intensity(t: TestContext) -> void:
	var w: Node = _w(t)
	w.recompute()
	t.assert_eq(w.chance_for("misroute"), 0.0, "with intensity 0 a misroute cannot happen")
	var fired: bool = false
	for i: int in 200:
		if w.roll("misroute"):
			fired = true
	t.assert_false(fired, "200 rolls, no misroute")

func test_roll_chance_scales_with_intensity(t: TestContext) -> void:
	var w: Node = _w(t)
	# Drive the curve directly rather than authoring placeholder numbers into it.
	w._curve = {"base_intensity": 0.5, "act_progress": [], "counters": {}, "events": {"misroute": 0.5}}
	w.recompute()
	t.assert_eq(w.intensity, 0.5, "intensity follows the curve")
	t.assert_eq(w.chance_for("misroute"), 0.25, "an event's chance is its curve entry scaled by intensity")
	t.assert_eq(w.chance_for("no_such_event"), 0.0, "an unknown event never fires")
	w._load_curve()

func test_unknown_event_is_never_rolled(t: TestContext) -> void:
	var w: Node = _w(t)
	var fired: bool = false
	for i: int in 100:
		if w.roll("not_in_the_curve"):
			fired = true
	t.assert_false(fired, "an event with no curve entry never fires")

func test_spots_register_and_unregister(t: TestContext) -> void:
	var w: Node = _w(t)
	t.assert_eq(w.spot_count(), 0, "no spots to start")
	var spot: Marker2D = _spot("Hearth")
	w.register_spot(spot)
	t.assert_eq(w.spot_count(), 1, "a spot registers")
	w.register_spot(spot)
	t.assert_eq(w.spot_count(), 1, "registering twice does not duplicate")
	w.unregister_spot(spot)
	t.assert_eq(w.spot_count(), 0, "a spot unregisters")
	spot.free()

func test_only_v1_kinds_are_eligible(t: TestContext) -> void:
	var w: Node = _w(t)
	var spot: Marker2D = _spot("Hearth")
	w.register_spot(spot)
	# The shipped catalog entry is a placeholder marked v1: false.
	t.assert_eq(w.eligible_pairs(), [], "a kind not marked v1 never fires")
	t.assert_false(w.fire_one(), "and the scheduler finds nothing to do")
	spot.free()

func test_eligibility_respects_intensity_spot_and_region(t: TestContext) -> void:
	var w: Node = _w(t)
	w._catalog = {
		"ph_low": {"min_intensity": 0.0, "weight": 1.0, "cooldown": 0.0, "regions_excluded": [], "handler": "log", "v1": true},
		"ph_high": {"min_intensity": 0.9, "weight": 1.0, "cooldown": 0.0, "regions_excluded": [], "handler": "log", "v1": true},
		"ph_elsewhere": {"min_intensity": 0.0, "weight": 1.0, "cooldown": 0.0, "regions_excluded": ["hold"], "handler": "log", "v1": true},
	}
	w._curve = {"base_intensity": 0.5, "act_progress": [], "counters": {}, "events": {}}
	w._current_region = "hold"
	w._region_multiplier = 1.0
	w.recompute()

	var spot: Marker2D = _spot("Hearth")
	w.register_spot(spot)
	var kinds: Array = []
	for pair: Dictionary in w.eligible_pairs():
		kinds.append(pair["kind"])
	t.assert_eq(kinds, ["ph_low"], "min_intensity and regions_excluded both filter")

	var picky: Marker2D = _spot("Well", ["ph_high"] as Array[String])
	w.register_spot(picky)
	var picky_kinds: Array = []
	for pair: Dictionary in w.eligible_pairs():
		if pair["spot"] == picky:
			picky_kinds.append(pair["kind"])
	t.assert_eq(picky_kinds, [], "a spot's allowed_kinds filter still respects min_intensity")

	spot.free()
	picky.free()
	w._load_catalog()
	w._load_curve()

func test_history_ring_prevents_an_immediate_repeat(t: TestContext) -> void:
	var w: Node = _w(t)
	w._catalog = {
		"ph_only": {"min_intensity": 0.0, "weight": 1.0, "cooldown": 0.0, "regions_excluded": [], "handler": "log", "v1": true},
	}
	w._curve = {"base_intensity": 1.0, "act_progress": [], "counters": {}, "events": {}}
	w.recompute()
	var spot: Marker2D = _spot("Hearth")
	w.register_spot(spot)

	t.assert_true(w.fire_one(), "the first firing happens")
	t.assert_eq(w.history(), ["ph_only@Hearth"], "and is remembered")
	t.assert_false(w.fire_one(), "the same kind at the same spot cannot fire twice in a row")

	spot.free()
	w._load_catalog()
	w._load_curve()

func test_firing_announces_and_records_for_debug(t: TestContext) -> void:
	var w: Node = _w(t)
	w._catalog = {
		"ph_only": {"min_intensity": 0.0, "weight": 1.0, "cooldown": 0.0, "regions_excluded": [], "handler": "log", "v1": true},
	}
	w._curve = {"base_intensity": 1.0, "act_progress": [], "counters": {}, "events": {}}
	w.recompute()
	var spot: Marker2D = _spot("Hearth")
	w.register_spot(spot)

	var announced: Array = []
	var handler := func(kind: String, fired_spot: Node, params: Dictionary) -> void:
		announced.append([kind, fired_spot.name])
	w.flicker_requested.connect(handler)
	w.fire_one()
	w.flicker_requested.disconnect(handler)

	t.assert_eq(announced, [["ph_only", "Hearth"]], "flicker_requested carries kind and spot")
	t.assert_eq(w.debug_log().size(), 1, "the debug ring recorded it")
	t.assert_eq((w.debug_log()[0] as Dictionary).get("kind"), "ph_only", "with the kind that fired")

	spot.free()
	w._load_catalog()
	w._load_curve()

func test_interval_shortens_as_intensity_rises(t: TestContext) -> void:
	var w: Node = _w(t)
	w._curve = {"base_intensity": 0.0, "act_progress": [], "counters": {}, "events": {}}
	w.recompute()
	var calm: float = w.next_interval()
	w._curve = {"base_intensity": 1.0, "act_progress": [], "counters": {}, "events": {}}
	w.recompute()
	var frantic: float = w.next_interval()
	t.assert_true(frantic < calm, "flickers come more often as the world deteriorates")
	w._load_curve()

func test_reset_clears_spots_history_and_debug(t: TestContext) -> void:
	var w: Node = _w(t)
	var spot: Marker2D = _spot("Hearth")
	w.register_spot(spot)
	w._remember("x@y")
	w.reset()
	t.assert_eq(w.spot_count(), 0, "reset drops registered spots")
	t.assert_eq(w.history(), [], "reset clears the anti-repeat ring")
	t.assert_eq(w.debug_log(), [], "reset clears the debug buffer")
	spot.free()
