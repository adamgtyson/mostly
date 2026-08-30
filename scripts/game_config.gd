class_name GameConfig
extends RefCounted

## Read-only access to data/config.json (ENGINEERING_CONSTRAINTS.md §13):
## tunables live there, never as script literals. A plain shared class rather
## than an autoload, because the autoload roster is closed (§13).
##
##   var slots: int = GameConfig.get_int("save.slots", 3)

const PATH := "res://data/config.json"

static var _cache: Dictionary = {}
static var _loaded: bool = false

static func get_value(dotted: String, default: Variant) -> Variant:
	_ensure_loaded()
	var node: Variant = _cache
	for part: String in dotted.split("."):
		if not (node is Dictionary):
			return default
		var d: Dictionary = node
		if not d.has(part):
			return default
		node = d[part]
	return node

static func get_int(dotted: String, default: int) -> int:
	var v: Variant = get_value(dotted, default)
	if v is int or v is float:
		return int(v)
	return default

static func get_float(dotted: String, default: float) -> float:
	var v: Variant = get_value(dotted, default)
	if v is int or v is float:
		return float(v)
	return default

static func get_bool(dotted: String, default: bool) -> bool:
	var v: Variant = get_value(dotted, default)
	if v is bool:
		return v
	return default

## Dotted paths flagged as open design values carrying a provisional default.
static func placeholders() -> PackedStringArray:
	_ensure_loaded()
	var out := PackedStringArray()
	var listed: Variant = _cache.get("_placeholders", [])
	if listed is Array:
		for entry: Variant in listed:
			out.append(str(entry))
	return out

static func reload() -> void:
	_loaded = false
	_ensure_loaded()

static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	_cache = {}
	if not FileAccess.file_exists(PATH):
		push_error("GameConfig: missing %s" % PATH)
		return
	var file := FileAccess.open(PATH, FileAccess.READ)
	if file == null:
		push_error("GameConfig: cannot read %s" % PATH)
		return
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK:
		push_error("GameConfig: malformed JSON in %s" % PATH)
		return
	var data: Variant = json.get_data()
	if data is Dictionary:
		_cache = data
	else:
		push_error("GameConfig: %s root is not an object" % PATH)
