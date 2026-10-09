extends RefCounted

## Session 8, Block B: the anchor-and-fill generator spike against its own
## rules ([G3] architecture, EC-7 input format, Docs/04 algorithm).
## Determinism is the load-bearing property — a seed IS the run — so it gets
## the byte-identical assertion, not a spot check.

const FIXTURE_REGION := "res://tests/fixtures/generator/synthetic_region.json"
const FIXTURE_CONFIG := "res://tests/fixtures/generator/fixture_config.json"
const REAL_CONFIG := "res://data/generator/config.json"
const REAL_REGIONS: Array[String] = ["hold", "turning"]

func _read(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	return json.get_data() if err == OK and json.get_data() is Dictionary else {}

func _region(region_id: String) -> Dictionary:
	return _read("res://regions/%s/region.json" % region_id)

# ── determinism ──────────────────────────────────────────────────────────────

func test_same_seed_is_byte_identical(t: TestContext) -> void:
	var config: Dictionary = _read(REAL_CONFIG)
	for region_id: String in REAL_REGIONS:
		var region_json: Dictionary = _region(region_id)
		var first: MapGraph = RegionGenerator.generate(region_json, config, 42)
		var second: MapGraph = RegionGenerator.generate(region_json, config, 42)
		t.assert_eq(JSON.stringify(first.to_json()), JSON.stringify(second.to_json()),
			"%s: the same seed generates byte-identical JSON" % region_id)

func test_different_seeds_vary_the_fill(t: TestContext) -> void:
	var config: Dictionary = _read(REAL_CONFIG)
	var region_json: Dictionary = _region("hold")
	var assignments: Dictionary = {}
	for generation_seed: int in 20:
		var graph: MapGraph = RegionGenerator.generate(region_json, config, generation_seed)
		var biomes: Array = []
		for fill_id: Variant in graph.fill_ids():
			biomes.append((graph.nodes[fill_id] as Dictionary).get("biome"))
		assignments[JSON.stringify(biomes)] = true
	t.assert_true(assignments.size() > 1,
		"over 20 seeds the fill assignment differs at least once (got %d distinct)" % assignments.size())

func test_json_round_trip(t: TestContext) -> void:
	var graph: MapGraph = RegionGenerator.generate(_region("hold"), _read(REAL_CONFIG), 7)
	var restored: MapGraph = MapGraph.from_json(graph.to_json())
	t.assert_eq(JSON.stringify(restored.to_json()), JSON.stringify(graph.to_json()),
		"to_json/from_json round-trips exactly")
	t.assert_eq(restored.reachable_from("workshop").size(), graph.reachable_from("workshop").size(),
		"and the restored graph behaves, not just serialises")

# ── the synthetic fixture: every rule trips exactly as designed ─────────────

func test_fixture_errors_and_warnings_are_exactly_as_expected(t: TestContext) -> void:
	var region_json: Dictionary = _read(FIXTURE_REGION)
	var config: Dictionary = _read(FIXTURE_CONFIG)
	t.assert_false(region_json.is_empty(), "the synthetic region fixture loads")
	var graph: MapGraph = RegionGenerator.generate(region_json, config, 1)

	t.assert_eq(graph.warnings.size(), 1, "exactly one generation warning")
	if graph.warnings.size() == 1:
		t.assert_true(str(graph.warnings[0]).contains("slot_mismatch"),
			"the empty pool intersection names its slot and the slot pool wins")

	var errors: Array[String] = GraphValidator.validate(graph, region_json, config)
	t.assert_eq(errors.size(), 3, "exactly three validation errors, got: %s" % str(errors))
	var text: String = "\n".join(errors)
	t.assert_true(text.contains("slot_orphan"), "the orphan slot is an error")
	t.assert_true(text.contains("'lost' is unreachable"), "the unreachable anchor is an error")
	t.assert_true(text.contains("not connected"), "and the graph is reported disconnected")

func test_fixture_chain_respects_the_band(t: TestContext) -> void:
	var graph: MapGraph = RegionGenerator.generate(_read(FIXTURE_REGION), _read(FIXTURE_CONFIG), 1)
	var slot_good_nodes: int = 0
	for fill_id: Variant in graph.fill_ids():
		if str((graph.nodes[fill_id] as Dictionary).get("slot", "")) == "slot_good":
			slot_good_nodes += 1
	t.assert_eq(slot_good_nodes, 2, "slot_good's length_hint 2 sits inside band [1,3] and is honoured")

# ── the real manifests ───────────────────────────────────────────────────────

func test_real_manifests_pass_a_hundred_seeds(t: TestContext) -> void:
	var config: Dictionary = _read(REAL_CONFIG)
	for region_id: String in REAL_REGIONS:
		var region_json: Dictionary = _region(region_id)
		var failures: int = 0
		for generation_seed: int in 100:
			var graph: MapGraph = RegionGenerator.generate(region_json, config, generation_seed)
			if not GraphValidator.validate(graph, region_json, config).is_empty():
				failures += 1
		t.assert_eq(failures, 0, "%s: 100/100 seeds validate" % region_id)

func test_resolve_default_areas_names_real_scenes(t: TestContext) -> void:
	var config: Dictionary = _read(REAL_CONFIG)
	for region_id: String in REAL_REGIONS:
		var graph: MapGraph = RegionGenerator.generate(_region(region_id), config, 3)
		var mapping: Dictionary = graph.resolve_default_areas()
		for fill_id: Variant in mapping:
			var area: Variant = mapping[fill_id]
			t.assert_true(area != null, "%s: fill node '%s' has a default_area (EC-7: v1 fills by hand)"
				% [region_id, str(fill_id)])
			if area != null:
				t.assert_true(FileAccess.file_exists("res://regions/%s/areas/%s.tscn" % [region_id, str(area)]),
					"%s: default_area '%s' is a real scene" % [region_id, str(area)])

func test_a_thousand_hold_seeds_under_five_seconds(t: TestContext) -> void:
	var config: Dictionary = _read(REAL_CONFIG)
	var region_json: Dictionary = _region("hold")
	var started: int = Time.get_ticks_msec()
	for generation_seed: int in 1000:
		RegionGenerator.generate(region_json, config, generation_seed)
	var elapsed: int = Time.get_ticks_msec() - started
	print("        generator performance: 1000 hold seeds in %d ms" % elapsed)
	t.assert_true(elapsed < 5000, "1000 seeds of the Hold generate in under 5s, took %d ms" % elapsed)
