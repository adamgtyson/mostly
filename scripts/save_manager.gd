extends Node

## SaveManager (ENGINEERING_CONSTRAINTS.md §3).
##
## Saving is generic: every autoload that implements to_save_dict() contributes
## one top-level key, so adding a system never means editing this file. A
## contributor names its key with save_key(), falling back to the snake_case of
## its autoload name (GameState -> "game_state", Inventory -> "inventory").
## The §3 envelope key "party" therefore appears once its owning autoload does,
## in phase 5 with Battle; a save written before then simply omits it and the
## loader tolerates the absence.
##
## Layout is closed (§3): user://saves/, user://seen_cutscenes.json,
## user://settings.json. Nothing else is written under user://.

signal game_saved(slot: String)
signal game_loaded(slot: String)
signal save_refused(reason: String)

const SCHEMA_VERSION := 1
const SAVES_DIR := "user://saves"
const AUTO_SLOT := "auto"

## Autoloads that may hold state worth saving. A name here is only consulted if
## the node exists and implements the contract, so the list can lead the build.
const CONTRIBUTORS: Array[String] = [
	"GameState",
	"Inventory",
	"SceneRouter",
	"Weirdness",
	"Battle",
]

## Where slot files live. Overridable so a test can write inside the saves/
## tree without ever touching a real player slot; reset() restores the default.
var saves_dir: String = SAVES_DIR

var _playtime_s: float = 0.0

## from_version -> Callable(Dictionary) -> Dictionary, applied in ascending order
## until the payload reaches SCHEMA_VERSION. The v1 identity entry exists from
## day one so the mechanism is exercised before it is first needed.
var _migrations: Dictionary = {}

func _ready() -> void:
	_migrations = {
		1: _migrate_v1_identity,
	}
	DirAccess.make_dir_recursive_absolute(saves_dir)

func _process(delta: float) -> void:
	_playtime_s += delta

# ── saving ───────────────────────────────────────────────────────────────────

## Saving is refused mid-dialogue, mid-cutscene and mid-battle: those are
## transient states that are never serialized (§3).
func can_save() -> bool:
	return blocking_reason().is_empty()

func blocking_reason() -> String:
	var root_node: Node = get_tree().root
	if root_node.has_node("DialogueManager") and root_node.get_node("DialogueManager").get("dialogue_active"):
		return "dialogue is active"
	if root_node.has_node("CutsceneManager") and root_node.get_node("CutsceneManager").get("cutscene_active"):
		return "a cutscene is playing"
	if root_node.has_node("Battle") and root_node.get_node("Battle").get("battle_active"):
		return "a battle is in progress"
	return ""

func save_to_slot(slot: String) -> bool:
	var reason: String = blocking_reason()
	if not reason.is_empty():
		save_refused.emit(reason)
		return false
	if not is_valid_slot(slot):
		push_error("SaveManager: '%s' is not a valid slot" % slot)
		return false

	DirAccess.make_dir_recursive_absolute(saves_dir)
	var file := FileAccess.open(slot_path(slot), FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: cannot write %s" % slot_path(slot))
		return false
	file.store_string(JSON.stringify(build_payload(), "\t"))
	file.close()
	game_saved.emit(slot)
	return true

func autosave() -> bool:
	return save_to_slot(AUTO_SLOT)

func build_payload() -> Dictionary:
	var payload: Dictionary = {
		"schema_version": SCHEMA_VERSION,
		"timestamp": Time.get_datetime_string_from_system(true),
		"playtime_s": int(_playtime_s),
	}
	for contributor: String in CONTRIBUTORS:
		var node: Node = _contributor(contributor)
		if node == null:
			continue
		payload[_save_key_for(node, contributor)] = node.call("to_save_dict")
	return payload

# ── loading ──────────────────────────────────────────────────────────────────

func load_from_slot(slot: String) -> bool:
	if not has_slot(slot):
		push_error("SaveManager: no save in slot '%s'" % slot)
		return false
	var file := FileAccess.open(slot_path(slot), FileAccess.READ)
	if file == null:
		push_error("SaveManager: cannot read %s" % slot_path(slot))
		return false
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK:
		push_error("SaveManager: malformed save in slot '%s'" % slot)
		return false
	var data: Variant = json.get_data()
	if not (data is Dictionary):
		push_error("SaveManager: save in slot '%s' is not an object" % slot)
		return false

	var migrated: Dictionary = apply_migrations(data)
	if migrated.is_empty():
		return false
	apply_payload(migrated)
	game_loaded.emit(slot)
	return true

## Refuses a payload written by a newer build, and walks an older one up through
## the migration table. Returns {} if the payload cannot be brought to current.
func apply_migrations(data: Dictionary) -> Dictionary:
	var version: int = int(data.get("schema_version", 0))
	if version > SCHEMA_VERSION:
		push_error("SaveManager: save schema_version %d is newer than this build's %d" % [version, SCHEMA_VERSION])
		return {}
	if version < 1:
		push_error("SaveManager: save has no usable schema_version")
		return {}
	var payload: Dictionary = data
	while version < SCHEMA_VERSION:
		if not _migrations.has(version):
			push_error("SaveManager: no migration registered from schema_version %d" % version)
			return {}
		var step: Callable = _migrations[version]
		payload = step.call(payload)
		version += 1
		payload["schema_version"] = version
	return payload

func apply_payload(payload: Dictionary) -> void:
	_playtime_s = float(payload.get("playtime_s", 0))
	for contributor: String in CONTRIBUTORS:
		var node: Node = _contributor(contributor)
		if node == null:
			continue
		var key: String = _save_key_for(node, contributor)
		if not payload.has(key):
			continue
		var section: Variant = payload[key]
		if section is Dictionary:
			node.call("from_save_dict", section)

# ── slots ────────────────────────────────────────────────────────────────────

func slot_count() -> int:
	return GameConfig.get_int("save.slots", 3)

func is_valid_slot(slot: String) -> bool:
	if slot == AUTO_SLOT:
		return true
	if not slot.is_valid_int():
		return false
	var n: int = slot.to_int()
	return n >= 1 and n <= slot_count()

func slot_path(slot: String) -> String:
	return "%s/slot_%s.json" % [saves_dir, slot]

func has_slot(slot: String) -> bool:
	return FileAccess.file_exists(slot_path(slot))

## Metadata for a load menu, without restoring anything.
func slot_info(slot: String) -> Dictionary:
	if not has_slot(slot):
		return {}
	var file := FileAccess.open(slot_path(slot), FileAccess.READ)
	if file == null:
		return {}
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK:
		return {}
	var data: Variant = json.get_data()
	if not (data is Dictionary):
		return {}
	var d: Dictionary = data
	return {
		"slot": slot,
		"schema_version": int(d.get("schema_version", 0)),
		"timestamp": str(d.get("timestamp", "")),
		"playtime_s": int(d.get("playtime_s", 0)),
	}

func list_slots() -> Array:
	var out: Array = []
	for slot: String in all_slot_names():
		if has_slot(slot):
			out.append(slot_info(slot))
	return out

func all_slot_names() -> PackedStringArray:
	var names := PackedStringArray([AUTO_SLOT])
	for n: int in range(1, slot_count() + 1):
		names.append(str(n))
	return names

# ── stateful-autoload contract (§13) ─────────────────────────────────────────

func reset() -> void:
	_playtime_s = 0.0
	saves_dir = SAVES_DIR

func playtime_s() -> int:
	return int(_playtime_s)

# ── internals ────────────────────────────────────────────────────────────────

func _contributor(autoload_name: String) -> Node:
	var root_node: Node = get_tree().root
	if not root_node.has_node(autoload_name):
		return null
	var node: Node = root_node.get_node(autoload_name)
	if not node.has_method("to_save_dict") or not node.has_method("from_save_dict"):
		return null
	return node

func _save_key_for(node: Node, autoload_name: String) -> String:
	if node.has_method("save_key"):
		return str(node.call("save_key"))
	return _to_snake_case(autoload_name)

func _to_snake_case(pascal: String) -> String:
	var out := ""
	for i: int in pascal.length():
		var c: String = pascal[i]
		var is_upper: bool = c >= "A" and c <= "Z"
		if is_upper and i > 0:
			out += "_"
		out += c.to_lower()
	return out

## Identity step: schema_version 1 payloads are already current. Present from day
## one so the table is wired and tested before a real migration needs it.
func _migrate_v1_identity(payload: Dictionary) -> Dictionary:
	return payload
