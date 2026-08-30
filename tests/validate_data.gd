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
const REGION_SCHEMA := "res://data/schema/region.schema.json"
const ASSETS_DIR := "res://assets"
const ASSET_MANIFEST := "res://assets/manifest.json"

## Extensions the manifest is responsible for. Engine sidecars (.import) and
## Godot resources (.tres/.res) are not art and are deliberately excluded.
const ART_EXTENSIONS: Array[String] = [
	"png", "jpg", "jpeg", "webp", "svg",
	"ogg", "wav", "mp3",
	"ttf", "otf",
]

## content directory -> schema. One line per JSON content type (§13).
const SCHEMA_MAP: Dictionary = {
	"res://data/items": "res://data/schema/item.schema.json",
	"res://data/dialogue": "res://data/schema/dialogue.schema.json",
	"res://data/cutscenes": "res://data/schema/cutscene.schema.json",
}

## single file -> schema, for registries that are one document rather than a tree.
const FILE_SCHEMA_MAP: Dictionary = {
	"res://data/characters.json": "res://data/schema/characters.schema.json",
	"res://data/weirdness/curve.json": "res://data/schema/weirdness_curve.schema.json",
	"res://data/weirdness/catalog.json": "res://data/schema/weirdness_catalog.schema.json",
	"res://assets/manifest.json": "res://data/schema/asset_manifest.schema.json",
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
	_check("regions", _check_regions)
	_check("anchor tier rule", _check_anchor_tier_rule)
	_check("asset manifest", _check_asset_manifest)
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

## Every regions/<id>/region.json validates against the §7 shape, its anchors
## point at scenes that exist, and its edges join things it declares.
func _check_regions() -> Dictionary:
	var errors := PackedStringArray()
	var schema_parsed: Dictionary = _read_json(REGION_SCHEMA)
	if not schema_parsed["ok"] or not (schema_parsed["data"] is Dictionary):
		return {"errors": PackedStringArray(["%s unreadable" % REGION_SCHEMA]), "detail": ""}
	var schema: Dictionary = schema_parsed["data"]

	var regions: PackedStringArray = _region_ids()
	var anchors_total: int = 0
	for region: String in regions:
		var path: String = "%s/%s/region.json" % [REGIONS_DIR, region]
		var parsed: Dictionary = _read_json(path)
		if not parsed["ok"]:
			errors.append(parsed["error"])
			continue
		for problem: String in JsonSchema.validate(parsed["data"], schema, "%s/region.json" % region):
			errors.append(problem)
		if not (parsed["data"] is Dictionary):
			continue
		var document: Dictionary = parsed["data"]

		if str(document.get("id", "")) != region:
			errors.append("%s: id '%s' does not match its folder" % [path, str(document.get("id", ""))])

		var known_slots: Dictionary = {}
		var anchor_areas: Dictionary = {}
		for anchor: Variant in document.get("anchors", []):
			var a: Dictionary = anchor
			var anchor_id: String = str(a.get("id", ""))
			var area: String = str(a.get("area", ""))
			known_slots[anchor_id] = true
			anchor_areas[area] = true
			anchors_total += 1
			var scene_path: String = "%s/%s/areas/%s.tscn" % [REGIONS_DIR, region, area]
			if not FileAccess.file_exists(scene_path):
				errors.append("%s: anchor '%s' names area '%s', which has no scene at %s"
					% [path, anchor_id, area, scene_path])
		for slot: Variant in document.get("fill_slots", []):
			known_slots[str((slot as Dictionary).get("id", ""))] = true

		for entry: Variant in document.get("entry_points", []):
			var entry_id: String = str(entry)
			if not anchor_areas.has(entry_id) and not known_slots.has(entry_id):
				errors.append("%s: entry_point '%s' is neither an anchor nor a fill slot" % [path, entry_id])

		for edge: Variant in document.get("edges", []):
			var e: Dictionary = edge
			for end: String in ["from", "to"]:
				var node_id: String = str(e.get(end, ""))
				if not known_slots.has(node_id):
					errors.append("%s: edge %s '%s' is not a declared anchor or fill slot" % [path, end, node_id])
	return {"errors": errors, "detail": "%d region(s), %d anchor(s)" % [regions.size(), anchors_total]}

## §7: only anchor areas may set critical-tier flags. An area scene can set a
## flag through the cutscenes and dialogue it references, so those are followed.
func _check_anchor_tier_rule() -> Dictionary:
	var errors := PackedStringArray()
	var declared: Dictionary = _declared_flags()
	var checked: int = 0

	for region: String in _region_ids():
		var document: Dictionary = _read_json("%s/%s/region.json" % [REGIONS_DIR, region]).get("data", {})
		if not (document is Dictionary):
			continue
		var anchor_areas: Dictionary = {}
		for anchor: Variant in (document as Dictionary).get("anchors", []):
			anchor_areas[str((anchor as Dictionary).get("area", ""))] = true

		for scene_path: String in _walk("%s/%s/areas" % [REGIONS_DIR, region], ".tscn"):
			checked += 1
			var area_name: String = scene_path.get_file().get_basename()
			if anchor_areas.has(area_name):
				continue
			for flag: String in _critical_flags_reachable_from(scene_path, declared):
				errors.append("%s: fill area '%s' sets critical-tier flag '%s'; only anchors may (§7)"
					% [scene_path, area_name, flag])
	return {"errors": errors, "detail": "%d area scene(s) checked" % checked}

## Critical flags an area scene can set, via the cutscenes and dialogue it names.
func _critical_flags_reachable_from(scene_path: String, declared: Dictionary) -> PackedStringArray:
	var found := PackedStringArray()
	var sources: PackedStringArray = PackedStringArray()

	for cutscene_id: String in _extract_quoted(scene_path, "cutscene_id"):
		sources.append("%s/%s.json" % [CUTSCENES_DIR, cutscene_id])
	for dialogue_id: String in _extract_quoted(scene_path, "dialogue_id"):
		sources.append("%s/%s.json" % [DIALOGUE_DIR, dialogue_id])

	for source: String in sources:
		var parsed: Dictionary = _read_json(source)
		if not parsed["ok"] or not (parsed["data"] is Dictionary):
			continue
		var document: Dictionary = parsed["data"]
		for beat: Variant in document.get("beats", []):
			if beat is Dictionary and str((beat as Dictionary).get("type", "")) == "set_flag":
				_note_critical(str((beat as Dictionary).get("flag", "")), declared, found)
		var nodes: Variant = document.get("nodes", {})
		if nodes is Dictionary:
			for node_id: Variant in (nodes as Dictionary):
				for set_entry: Variant in ((nodes as Dictionary)[node_id] as Dictionary).get("set", []):
					_note_critical(str((set_entry as Dictionary).get("flag", "")), declared, found)
	return found

func _note_critical(flag: String, declared: Dictionary, found: PackedStringArray) -> void:
	if flag.is_empty() or found.has(flag):
		return
	if str((declared.get(flag, {}) as Dictionary).get("tier", "normal")) == "critical":
		found.append(flag)

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

## §12: every art file under assets/ must have a manifest entry, and every
## manifest entry must name a file that exists.
func _check_asset_manifest() -> Dictionary:
	var errors := PackedStringArray()
	var parsed: Dictionary = _read_json(ASSET_MANIFEST)
	if not parsed["ok"] or not (parsed["data"] is Dictionary):
		return {"errors": PackedStringArray(["%s unreadable" % ASSET_MANIFEST]), "detail": ""}

	var listed: Dictionary = {}
	var placeholders: int = 0
	for entry: Variant in (parsed["data"] as Dictionary).get("assets", []):
		if not (entry is Dictionary):
			continue
		var e: Dictionary = entry
		var path: String = str(e.get("path", ""))
		listed[path] = true
		if str(e.get("status", "")) == "placeholder":
			placeholders += 1
		if not FileAccess.file_exists("res://%s" % path):
			errors.append("manifest lists '%s', which does not exist" % path)

	var art_count: int = 0
	for path: String in _walk_all(ASSETS_DIR):
		var extension: String = path.get_extension().to_lower()
		if not ART_EXTENSIONS.has(extension):
			continue
		art_count += 1
		var relative: String = path.trim_prefix("res://")
		if not listed.has(relative):
			errors.append("%s has no entry in assets/manifest.json (§12)" % relative)

	return {"errors": errors, "detail": "%d art file(s), %d placeholder(s)" % [art_count, placeholders]}

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

## Every file under a directory tree, whatever its extension.
func _walk_all(dir_path: String) -> PackedStringArray:
	var found := PackedStringArray()
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return found
	for f: String in dir.get_files():
		found.append("%s/%s" % [dir_path, f])
	for sub: String in dir.get_directories():
		found.append_array(_walk_all("%s/%s" % [dir_path, sub]))
	found.sort()
	return found

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
