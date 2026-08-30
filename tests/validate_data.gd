extends SceneTree

## Data validator (ENGINEERING_CONSTRAINTS.md §11) — the cheapest feedback signal,
## runnable alone:
##   godot --headless --path . -s tests/validate_data.gd
## Every category prints one line. Exits non-zero if any category found errors.
## Categories grow as milestones add data types; each is a _check_* method listed
## in _run(), so adding a data type means adding one method and one line.

const DATA_DIR := "res://data"
const REGIONS_DIR := "res://regions"
const SCHEMA_DIR := "res://data/schema"
const CONFIG_PATH := "res://data/config.json"

var _total_errors: int = 0

func _initialize() -> void:
	print("== validate_data ==")
	_run()
	print("")
	if _total_errors == 0:
		print("validate_data: 0 errors")
		quit(0)
	else:
		print("validate_data: %d error(s)" % _total_errors)
		quit(1)

func _run() -> void:
	_check("json syntax", _check_json_syntax)
	_check("gdscript parse", _check_gdscript_parse)
	_check("scenes load", _check_scenes_load)
	_check("config", _check_config)

# ── category plumbing ────────────────────────────────────────────────────────

func _check(category: String, fn: Callable) -> void:
	var result: Dictionary = fn.call()
	var errors: PackedStringArray = result.get("errors", PackedStringArray())
	var detail: String = result.get("detail", "")
	if errors.is_empty():
		print("[ok]   %-18s %s" % [category, detail])
		return
	print("[FAIL] %-18s %d error(s)" % [category, errors.size()])
	for e: String in errors:
		print("         - %s" % e)
	_total_errors += errors.size()

# ── categories ───────────────────────────────────────────────────────────────

## Every .json under data/ and regions/ must parse. A trailing comma in a data
## file is a build failure, not a playtest surprise.
func _check_json_syntax() -> Dictionary:
	var errors := PackedStringArray()
	var files: PackedStringArray = _walk(DATA_DIR, ".json")
	files.append_array(_walk(REGIONS_DIR, ".json"))
	for path: String in files:
		var parsed: Dictionary = _read_json(path)
		if not parsed["ok"]:
			errors.append(parsed["error"])
	return {"errors": errors, "detail": "%d file(s) parsed" % files.size()}

## Catches parse errors the engine's import pass reports but does not fail on.
## A script that fails to parse still loads as a non-null GDScript, so the real
## signal is can_instantiate(): false for a broken script, true for a sound one.
## (It is also false for an @abstract script; the project has none by §13.)
func _check_gdscript_parse() -> Dictionary:
	var errors := PackedStringArray()
	var files: PackedStringArray = _walk("res://scripts", ".gd")
	files.append_array(_walk("res://tests", ".gd"))
	for path: String in files:
		# Plain cached load: CACHE_MODE_IGNORE re-instantiates scripts that live
		# autoloads are already backed by, which crashes the engine.
		var res: Variant = load(path)
		if res == null or not (res is GDScript):
			errors.append("%s: failed to load" % path)
		elif not (res as GDScript).can_instantiate():
			errors.append("%s: parse error (see SCRIPT ERROR above)" % path)
	return {"errors": errors, "detail": "%d script(s) parsed" % files.size()}

func _check_scenes_load() -> Dictionary:
	var errors := PackedStringArray()
	var files: PackedStringArray = _walk("res://scenes", ".tscn")
	files.append_array(_walk(REGIONS_DIR, ".tscn"))
	for path: String in files:
		var res: Variant = load(path)
		if res == null:
			errors.append("%s: failed to load" % path)
	return {"errors": errors, "detail": "%d scene(s) loaded" % files.size()}

## config.json is the only home for tunables (§13). Every dotted path listed in
## _placeholders must resolve, so a flagged open value cannot silently vanish.
func _check_config() -> Dictionary:
	var errors := PackedStringArray()
	var parsed: Dictionary = _read_json(CONFIG_PATH)
	if not parsed["ok"]:
		return {"errors": PackedStringArray([parsed["error"]]), "detail": ""}
	var cfg: Variant = parsed["data"]
	if not (cfg is Dictionary):
		return {"errors": PackedStringArray(["config.json root is not an object"]), "detail": ""}
	var cfg_dict: Dictionary = cfg
	var placeholders: Variant = cfg_dict.get("_placeholders", [])
	if not (placeholders is Array):
		return {"errors": PackedStringArray(["config.json _placeholders is not an array"]), "detail": ""}
	for entry: Variant in placeholders:
		if not (entry is String):
			errors.append("_placeholders entry is not a string: %s" % str(entry))
			continue
		if _lookup_path(cfg_dict, entry) == null:
			errors.append("_placeholders names '%s', which is not a key in config.json" % entry)
	var flagged: int = (placeholders as Array).size()
	return {"errors": errors, "detail": "%d placeholder(s) flagged, all resolve" % flagged}

# ── helpers ──────────────────────────────────────────────────────────────────

func _lookup_path(root_dict: Dictionary, dotted: String) -> Variant:
	var node: Variant = root_dict
	for part: String in dotted.split("."):
		if not (node is Dictionary):
			return null
		var d: Dictionary = node
		if not d.has(part):
			return null
		node = d[part]
	return node

func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "error": "%s: missing" % path, "data": null}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "error": "%s: unreadable" % path, "data": null}
	var text: String = file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(text) != OK:
		return {"ok": false, "error": "%s:%d: %s" % [path, json.get_error_line(), json.get_error_message()], "data": null}
	return {"ok": true, "error": "", "data": json.get_data()}

func _walk(dir_path: String, suffix: String) -> PackedStringArray:
	var found := PackedStringArray()
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return found
	for f: String in dir.get_files():
		if f.ends_with(suffix):
			found.append("%s/%s" % [dir_path, f])
	for sub: String in dir.get_directories():
		found.append_array(_walk("%s/%s" % [dir_path, sub], suffix))
	found.sort()
	return found
