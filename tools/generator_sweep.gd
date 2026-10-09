extends SceneTree

## 1000-seed generator sweep ([G3]'s validator, session 8 spike).
##   godot --headless --path . -s tools/generator_sweep.gd
## For every regions/*/region.json: generate SEEDS graphs, validate each, and
## report. The [G3] meta-rules hold: every failing seed is reported (display
## capped, count exact), and an assertion is never relaxed to force a pass —
## a contradiction stops the run red.
## Exit code 0 only when every seed of every region validates.

const SEEDS := 1000
const REGIONS_DIR := "res://regions"
const CONFIG_PATH := "res://data/generator/config.json"
const MAX_FAILURES_SHOWN := 20

func _initialize() -> void:
	var started: int = Time.get_ticks_msec()
	print("== generator sweep: %d seed(s) per region ==" % SEEDS)

	var config: Dictionary = _read_json(CONFIG_PATH)
	if config.is_empty():
		print("generator_sweep: cannot read %s" % CONFIG_PATH)
		quit(1)
		return

	var failed_total: int = 0
	for region_id: String in _region_ids():
		var region_json: Dictionary = _read_json("%s/%s/region.json" % [REGIONS_DIR, region_id])
		if region_json.is_empty():
			print("region %s: unreadable manifest" % region_id)
			failed_total += 1
			continue

		var valid: int = 0
		var warning_count: int = 0
		var failures: Array = []
		for generation_seed: int in SEEDS:
			var graph: MapGraph = RegionGenerator.generate(region_json, config, generation_seed)
			warning_count += graph.warnings.size()
			var errors: Array[String] = GraphValidator.validate(graph, region_json, config)
			if errors.is_empty():
				valid += 1
			else:
				failures.append({"seed": generation_seed, "errors": errors})

		print("region %s: %d/%d valid, %d warnings" % [region_id, valid, SEEDS, warning_count])
		for i: int in mini(failures.size(), MAX_FAILURES_SHOWN):
			var failure: Dictionary = failures[i]
			print("  seed %d:" % int(failure["seed"]))
			for error: String in (failure["errors"] as Array):
				print("    - %s" % error)
		if failures.size() > MAX_FAILURES_SHOWN:
			print("  ... and %d more failing seed(s)" % (failures.size() - MAX_FAILURES_SHOWN))
		failed_total += failures.size()

	print("sweep: %d ms" % (Time.get_ticks_msec() - started))
	if failed_total == 0:
		print("generator_sweep: all seeds valid")
		quit(0)
	else:
		print("generator_sweep: %d failing seed(s)" % failed_total)
		quit(1)

func _region_ids() -> PackedStringArray:
	var ids := PackedStringArray()
	var dir := DirAccess.open(REGIONS_DIR)
	if dir == null:
		return ids
	for sub: String in dir.get_directories():
		if FileAccess.file_exists("%s/%s/region.json" % [REGIONS_DIR, sub]):
			ids.append(sub)
	ids.sort()
	return ids

func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK:
		return {}
	return json.get_data() if json.get_data() is Dictionary else {}
