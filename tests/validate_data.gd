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
const CUTSCENES_DIR := "res://data/cutscenes"

const DIALOGUE_DIR := "res://data/dialogue"
const CHARACTERS_PATH := "res://data/characters.json"
const I18N_KEYS_PATH := "res://data/i18n/keys.json"

## content directory -> schema. One line per JSON content type (§13).
const SCHEMA_MAP: Dictionary = {
	"res://data/items": "res://data/schema/item.schema.json",
	"res://data/dialogue": "res://data/schema/dialogue.schema.json",
}

## single file -> schema, for registries that are one document rather than a tree.
const FILE_SCHEMA_MAP: Dictionary = {
	"res://data/characters.json": "res://data/schema/characters.schema.json",
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
	_check("flag references", _check_flag_references)
	_check("dialogue graph", _check_dialogue_graph)
	_check("character ids", _check_character_ids)
	_check("dialogue refs", _check_dialogue_references)
	_check("i18n keys", _check_i18n_keys)

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

	for file_path: String in FILE_SCHEMA_MAP:
		var single_schema: Dictionary = _read_json(FILE_SCHEMA_MAP[file_path])
		var single_doc: Dictionary = _read_json(file_path)
		if not single_schema["ok"] or not single_doc["ok"]:
			errors.append("%s: schema or document unreadable" % file_path)
			continue
		checked += 1
		for problem: String in JsonSchema.validate(single_doc["data"], single_schema["data"], file_path.get_file()):
			errors.append("%s: %s" % [file_path, problem])

	var schema_count: int = SCHEMA_MAP.size() + FILE_SCHEMA_MAP.size()
	return {"errors": errors, "detail": "%d file(s) against %d schema(s)" % [checked, schema_count]}

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

## The other half of the §2 rule: every flag *referenced* anywhere in data/,
## regions/ or scenes/ must be declared. A typo fails the build, not the playtest.
func _check_flag_references() -> Dictionary:
	var errors := PackedStringArray()
	var declared: Dictionary = _declared_flags()
	if declared.is_empty():
		return {"errors": PackedStringArray(["flag registry is empty or unreadable"]), "detail": ""}

	var references: Dictionary = _collect_flag_references()
	for flag: String in references:
		if not declared.has(flag):
			errors.append("%s: flag '%s' is not declared in data/flags.json" % [references[flag], flag])
	return {"errors": errors, "detail": "%d reference(s), all declared" % references.size()}

## flag name -> where it was first seen. Reads dialogue conditions and set[]
## entries, plus `when` on scene nodes; grows with each data type that can name
## a flag.
func _collect_flag_references() -> Dictionary:
	var found: Dictionary = {}

	for path: String in _walk(DIALOGUE_DIR, ".json"):
		var parsed: Dictionary = _read_json(path)
		if not parsed["ok"] or not (parsed["data"] is Dictionary):
			continue
		var document: Dictionary = parsed["data"]
		for entry: Variant in document.get("entries", []):
			if entry is Dictionary:
				_note_condition_flags(str((entry as Dictionary).get("when", "")), path, found)
		var nodes: Variant = document.get("nodes", {})
		if not (nodes is Dictionary):
			continue
		for node_id: Variant in (nodes as Dictionary):
			var node: Variant = (nodes as Dictionary)[node_id]
			if not (node is Dictionary):
				continue
			for set_entry: Variant in (node as Dictionary).get("set", []):
				if set_entry is Dictionary:
					var key: String = str((set_entry as Dictionary).get("flag", ""))
					if not key.is_empty() and not found.has(key):
						found[key] = path
			for choice: Variant in (node as Dictionary).get("choices", []):
				if choice is Dictionary:
					_note_condition_flags(str((choice as Dictionary).get("when", "")), path, found)

	# Scene nodes carry conditions as exported `when` strings.
	for path: String in _walk("res://scenes", ".tscn") + _walk(REGIONS_DIR, ".tscn"):
		for expr: String in _extract_quoted(path, "when"):
			_note_condition_flags(expr, path, found)

	return found

func _note_condition_flags(expr: String, path: String, found: Dictionary) -> void:
	if expr.strip_edges().is_empty():
		return
	for flag: String in Condition.referenced_flags(expr):
		if not found.has(flag):
			found[flag] = path

## Structural rules the schema cannot express: entries point at real nodes, the
## last entry is the always-true fallback, next/choices target real nodes, and a
## set[] entry carries exactly one of value or increment.
func _check_dialogue_graph() -> Dictionary:
	var errors := PackedStringArray()
	var files: PackedStringArray = _walk(DIALOGUE_DIR, ".json")
	for path: String in files:
		var parsed: Dictionary = _read_json(path)
		if not parsed["ok"] or not (parsed["data"] is Dictionary):
			continue
		var document: Dictionary = parsed["data"]
		var name: String = path.get_file()
		var nodes: Variant = document.get("nodes", {})
		if not (nodes is Dictionary):
			continue
		var node_map: Dictionary = nodes

		var entries: Variant = document.get("entries", [])
		if entries is Array:
			var list: Array = entries
			if list.is_empty():
				errors.append("%s: no entries" % name)
			for i: int in list.size():
				var entry: Dictionary = list[i]
				var start: String = str(entry.get("start", ""))
				if not node_map.has(start):
					errors.append("%s: entry %d starts at unknown node '%s'" % [name, i, start])
				var problem: String = Condition.syntax_error(str(entry.get("when", "")))
				if not problem.is_empty():
					errors.append("%s: entry %d condition: %s" % [name, i, problem])
			if not list.is_empty():
				var last_when: String = str((list[list.size() - 1] as Dictionary).get("when", "")).strip_edges().to_lower()
				if last_when != "true":
					errors.append("%s: the last entry must be \"when\": \"true\" (§5)" % name)

		for node_id: Variant in node_map:
			var node: Dictionary = node_map[node_id]
			var next_id: String = str(node.get("next", ""))
			if not next_id.is_empty() and not node_map.has(next_id):
				errors.append("%s: node '%s' points next at unknown node '%s'" % [name, str(node_id), next_id])
			for choice: Variant in node.get("choices", []):
				var c: Dictionary = choice
				var target: String = str(c.get("next", ""))
				if not node_map.has(target):
					errors.append("%s: node '%s' has a choice to unknown node '%s'" % [name, str(node_id), target])
				var choice_problem: String = Condition.syntax_error(str(c.get("when", "")))
				if not choice_problem.is_empty():
					errors.append("%s: node '%s' choice condition: %s" % [name, str(node_id), choice_problem])
			for set_entry: Variant in node.get("set", []):
				var s: Dictionary = set_entry
				if s.has("value") and s.has("increment"):
					errors.append("%s: node '%s' set '%s' has both value and increment" % [name, str(node_id), str(s.get("flag", ""))])
				if not s.has("value") and not s.has("increment"):
					errors.append("%s: node '%s' set '%s' has neither value nor increment" % [name, str(node_id), str(s.get("flag", ""))])
	return {"errors": errors, "detail": "%d file(s) checked" % files.size()}

## Every character id a dialogue speaks as must exist in characters.json (§11).
func _check_character_ids() -> Dictionary:
	var errors := PackedStringArray()
	var parsed: Dictionary = _read_json(CHARACTERS_PATH)
	if not parsed["ok"] or not (parsed["data"] is Dictionary):
		return {"errors": PackedStringArray(["characters.json unreadable"]), "detail": ""}
	var registry: Variant = (parsed["data"] as Dictionary).get("characters", {})
	if not (registry is Dictionary):
		return {"errors": PackedStringArray(["characters.json has no 'characters' object"]), "detail": ""}
	var known: Dictionary = registry

	var used: Dictionary = {}
	for path: String in _walk(DIALOGUE_DIR, ".json"):
		var doc_parsed: Dictionary = _read_json(path)
		if not doc_parsed["ok"] or not (doc_parsed["data"] is Dictionary):
			continue
		var nodes: Variant = (doc_parsed["data"] as Dictionary).get("nodes", {})
		if not (nodes is Dictionary):
			continue
		for node_id: Variant in (nodes as Dictionary):
			var node: Dictionary = (nodes as Dictionary)[node_id]
			for line: Variant in node.get("lines", []):
				var speaker: String = str((line as Dictionary).get("speaker", ""))
				used[speaker] = true
				if not known.has(speaker):
					errors.append("%s: speaker '%s' is not in characters.json" % [path.get_file(), speaker])
	return {"errors": errors, "detail": "%d known, %d in use" % [known.size(), used.size()]}

## Every dialogue id a scene or cutscene names must have a file (§11).
func _check_dialogue_references() -> Dictionary:
	var errors := PackedStringArray()
	var referenced: Dictionary = {}

	for path: String in _walk("res://scenes", ".tscn") + _walk(REGIONS_DIR, ".tscn"):
		for id: String in _extract_quoted(path, "dialogue_id"):
			if not id.is_empty():
				referenced[id] = path

	for path: String in _walk(CUTSCENES_DIR, ".json"):
		var parsed: Dictionary = _read_json(path)
		if not parsed["ok"] or not (parsed["data"] is Dictionary):
			continue
		for beat: Variant in (parsed["data"] as Dictionary).get("beats", []):
			if not (beat is Dictionary):
				continue
			var id: String = str((beat as Dictionary).get("dialogue_id", ""))
			if not id.is_empty():
				referenced[id] = path

	for id: String in referenced:
		if not FileAccess.file_exists("%s/%s.json" % [DIALOGUE_DIR, id]):
			errors.append("%s: references dialogue '%s', which has no file" % [referenced[id], id])
	return {"errors": errors, "detail": "%d reference(s) resolve" % referenced.size()}

## Generates the stable line-key catalogue (§5): <file>.<node>.<index>. Text
## stays inline in v1; extracting it later is a script, not a rewrite. Written
## deterministically so a re-run leaves the working tree clean.
func _check_i18n_keys() -> Dictionary:
	var keys: Dictionary = {}
	var paths: PackedStringArray = _walk(DIALOGUE_DIR, ".json")
	for path: String in paths:
		var parsed: Dictionary = _read_json(path)
		if not parsed["ok"] or not (parsed["data"] is Dictionary):
			continue
		var file_key: String = path.get_file().get_basename()
		var nodes: Variant = (parsed["data"] as Dictionary).get("nodes", {})
		if not (nodes is Dictionary):
			continue
		var node_ids: Array = (nodes as Dictionary).keys()
		node_ids.sort()
		for node_id: Variant in node_ids:
			var node: Dictionary = (nodes as Dictionary)[node_id]
			var lines: Variant = node.get("lines", [])
			if not (lines is Array):
				continue
			for i: int in (lines as Array).size():
				var line: Dictionary = (lines as Array)[i]
				keys["%s.%s.%d" % [file_key, str(node_id), i]] = str(line.get("text", ""))

	var sorted_keys: Array = keys.keys()
	sorted_keys.sort()
	var ordered: Dictionary = {}
	for key: String in sorted_keys:
		ordered[key] = keys[key]

	var payload: Dictionary = {
		"_comment": "Generated by tests/validate_data.gd (§5). Stable line keys <file>.<node>.<index>; text stays inline in the dialogue files for v1. Do not edit by hand.",
		"keys": ordered,
	}
	DirAccess.make_dir_recursive_absolute(I18N_KEYS_PATH.get_base_dir())
	var file := FileAccess.open(I18N_KEYS_PATH, FileAccess.WRITE)
	if file == null:
		return {"errors": PackedStringArray(["cannot write %s" % I18N_KEYS_PATH]), "detail": ""}
	file.store_string(JSON.stringify(payload, "  ") + "\n")
	file.close()
	return {"errors": PackedStringArray(), "detail": "%d key(s) generated" % ordered.size()}

func _declared_flags() -> Dictionary:
	var parsed: Dictionary = _read_json(FLAGS_PATH)
	if not parsed["ok"] or not (parsed["data"] is Dictionary):
		return {}
	var flags: Variant = (parsed["data"] as Dictionary).get("flags", {})
	return flags if flags is Dictionary else {}

## Pulls `<property> = "value"` out of a .tscn without parsing the whole scene.
func _extract_quoted(path: String, property: String) -> PackedStringArray:
	var out := PackedStringArray()
	var text: String = FileAccess.get_file_as_string(path)
	if text.is_empty():
		return out
	var regex := RegEx.new()
	regex.compile("%s\\s*=\\s*\"([^\"]*)\"" % property)
	for found: RegExMatch in regex.search_all(text):
		out.append(found.get_string(1))
	return out

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
