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
const FLAGS_PATH := "res://data/flags.json"
const TAGS_PATH := "res://data/tags.json"
const ITEMS_DIR := "res://data/items"

## content directory -> schema. One line per JSON content type (§13).
const SCHEMA_MAP: Dictionary = {
	"res://data/items": "res://data/schema/item.schema.json",
}

const VALID_FLAG_TYPES: Array[String] = ["bool", "int", "float", "string"]
const VALID_FLAG_TIERS: Array[String] = ["critical", "normal"]
## Mirrors GameState.V1_SCOPES (§2); the validator runs without instantiating it.
const V1_SCOPES: Array[String] = ["act1", "region", "village", "weird", "sys", "recipe", "quest"]

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
	_check("flag registry", _check_flag_registry)
	_check("schemas", _check_schemas)
	_check("item tags", _check_item_tags)

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

## Every JSON content type validates against its schema in data/schema/ (§13).
## One entry per content directory; adding a content type means adding a line.
func _check_schemas() -> Dictionary:
	var errors := PackedStringArray()
	var checked: int = 0
	for content_dir: String in SCHEMA_MAP:
		var schema_path: String = SCHEMA_MAP[content_dir]
		var schema_parsed: Dictionary = _read_json(schema_path)
		if not schema_parsed["ok"]:
			errors.append(schema_parsed["error"])
			continue
		if not (schema_parsed["data"] is Dictionary):
			errors.append("%s: schema root is not an object" % schema_path)
			continue
		var schema: Dictionary = schema_parsed["data"]
		for path: String in _walk(content_dir, ".json"):
			var parsed: Dictionary = _read_json(path)
			if not parsed["ok"]:
				errors.append(parsed["error"])
				continue
			checked += 1
			for problem: String in JsonSchema.validate(parsed["data"], schema, path.get_file()):
				errors.append("%s: %s" % [path, problem])
	return {"errors": errors, "detail": "%d file(s) against %d schema(s)" % [checked, SCHEMA_MAP.size()]}

## Tag-based inputs drive recipe substitution (§9), so an item carrying a tag
## that data/tags.json does not declare is a build failure, not a silent miss.
func _check_item_tags() -> Dictionary:
	var errors := PackedStringArray()
	var tags_parsed: Dictionary = _read_json(TAGS_PATH)
	if not tags_parsed["ok"]:
		return {"errors": PackedStringArray([tags_parsed["error"]]), "detail": ""}
	var tags_root: Variant = tags_parsed["data"]
	if not (tags_root is Dictionary) or not (tags_root as Dictionary).has("tags"):
		return {"errors": PackedStringArray(["tags.json has no 'tags' object"]), "detail": ""}
	var declared: Dictionary = (tags_root as Dictionary)["tags"]

	var used: Dictionary = {}
	for path: String in _walk(ITEMS_DIR, ".json"):
		var parsed: Dictionary = _read_json(path)
		if not parsed["ok"] or not (parsed["data"] is Dictionary):
			continue
		for tag: Variant in (parsed["data"] as Dictionary).get("tags", []):
			var tag_str: String = str(tag)
			used[tag_str] = true
			if not declared.has(tag_str):
				errors.append("%s: tag '%s' is not declared in data/tags.json" % [path, tag_str])
	return {"errors": errors, "detail": "%d declared, %d in use" % [declared.size(), used.size()]}

## data/flags.json is the mandatory registry (§2): every declaration needs a
## type, a tier, and a description, and every key must be a legal flag name.
## The "every reference is declared" half of the rule arrives with the data types
## that can reference a flag (dialogue v2 and cutscene beats).
func _check_flag_registry() -> Dictionary:
	var errors := PackedStringArray()
	var parsed: Dictionary = _read_json(FLAGS_PATH)
	if not parsed["ok"]:
		return {"errors": PackedStringArray([parsed["error"]]), "detail": ""}
	var root_data: Variant = parsed["data"]
	if not (root_data is Dictionary) or not (root_data as Dictionary).has("flags"):
		return {"errors": PackedStringArray(["flags.json has no 'flags' object"]), "detail": ""}
	var flags: Variant = (root_data as Dictionary)["flags"]
	if not (flags is Dictionary):
		return {"errors": PackedStringArray(["flags.json 'flags' is not an object"]), "detail": ""}

	var declared: Dictionary = flags
	var critical: int = 0
	for key: Variant in declared:
		var key_str: String = str(key)
		errors.append_array(_flag_key_errors(key_str))
		var decl: Variant = declared[key]
		if not (decl is Dictionary):
			errors.append("%s: declaration is not an object" % key_str)
			continue
		var d: Dictionary = decl
		var type_value: String = str(d.get("type", ""))
		if not VALID_FLAG_TYPES.has(type_value):
			errors.append("%s: type '%s' is not one of %s" % [key_str, type_value, ", ".join(VALID_FLAG_TYPES)])
		var tier: String = str(d.get("tier", ""))
		if not VALID_FLAG_TIERS.has(tier):
			errors.append("%s: tier '%s' is not one of %s" % [key_str, tier, ", ".join(VALID_FLAG_TIERS)])
		if tier == "critical":
			critical += 1
		if str(d.get("description", "")).strip_edges().is_empty():
			errors.append("%s: description is empty" % key_str)
	var detail := "%d declared (%d critical)" % [declared.size(), critical]
	return {"errors": errors, "detail": detail}

## <scope>.<subject>.<predicate>, snake_case. The design names some two-segment
## totals directly (region.total_crossing_attempts, weird.misroutes), so two
## segments is the floor rather than three.
func _flag_key_errors(key: String) -> PackedStringArray:
	var errors := PackedStringArray()
	var parts: PackedStringArray = key.split(".")
	if parts.size() < 2:
		errors.append("%s: needs at least <scope>.<name>" % key)
		return errors
	if not V1_SCOPES.has(parts[0]):
		errors.append("%s: scope '%s' is not one of %s" % [key, parts[0], ", ".join(V1_SCOPES)])
	for part: String in parts:
		if part.is_empty():
			errors.append("%s: empty segment" % key)
		elif not _is_snake_case(part):
			errors.append("%s: segment '%s' is not snake_case" % [key, part])
	return errors

func _is_snake_case(s: String) -> bool:
	for i: int in s.length():
		var c: String = s[i]
		var is_lower: bool = c >= "a" and c <= "z"
		var is_digit: bool = c >= "0" and c <= "9"
		if not (is_lower or is_digit or c == "_"):
			return false
	return true

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
