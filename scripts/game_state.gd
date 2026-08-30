extends Node

## GameState (ENGINEERING_CONSTRAINTS.md §2) — the one flag store in the project.
## A flat Dictionary[String, Variant]; there is no second representation of game
## progress anywhere. Every key is declared in data/flags.json; the validator
## fails the build on an undeclared key, so a typo cannot survive to a playtest.
##
## Key format: <scope>.<subject>.<predicate>, snake_case. A few keys the design
## names directly are two-segment totals (region.total_crossing_attempts,
## weird.misroutes); the registry is the authority on which keys exist.

signal flag_changed(key: String, value: Variant)

const REGISTRY_PATH := "res://data/flags.json"

## Valid first segments (§2). A mod region uses its package id as scope, so this
## list is the v1 set, not a permanent closed set.
const V1_SCOPES: Array[String] = ["act1", "region", "village", "weird", "sys", "recipe", "quest"]

var _flags: Dictionary = {}
var _registry: Dictionary = {}

func _ready() -> void:
	_load_registry()

# ── flag API (§2) ────────────────────────────────────────────────────────────

## Always emits flag_changed, including when the value is unchanged, so a
## listener never has to care whether it was the first write.
func set_flag(key: String, value: Variant) -> void:
	_warn_if_undeclared(key)
	_flags[key] = value
	flag_changed.emit(key, value)

func get_flag(key: String, default: Variant = null) -> Variant:
	return _flags.get(key, default)

func has_flag(key: String) -> bool:
	return _flags.has(key)

## Adds to a numeric counter, creating it at 0 first. Returns the new total.
func increment(key: String, by: int = 1) -> int:
	_warn_if_undeclared(key)
	var current: Variant = _flags.get(key, 0)
	if not (current is int or current is float):
		push_error("GameState: increment('%s') on non-numeric value %s" % [key, str(current)])
		return 0
	var updated: int = int(current) + by
	_flags[key] = updated
	flag_changed.emit(key, updated)
	return updated

func reset() -> void:
	_flags.clear()

# ── save contract (§3, §13) ──────────────────────────────────────────────────

func to_save_dict() -> Dictionary:
	return _flags.duplicate(true)

func from_save_dict(data: Dictionary) -> void:
	_flags = data.duplicate(true)

# ── registry ─────────────────────────────────────────────────────────────────

func is_declared(key: String) -> bool:
	# With no registry loaded (a bare unit-test tree), nothing is rejected.
	if _registry.is_empty():
		return true
	return _registry.has(key)

func declaration(key: String) -> Dictionary:
	return _registry.get(key, {})

func declared_keys() -> Array:
	return _registry.keys()

## Flags whose tier is "critical" — the ones the Act One walkthrough asserts on.
## Only anchor areas may set these (§7); the validator enforces that rule.
func is_critical(key: String) -> bool:
	return _registry.get(key, {}).get("tier", "normal") == "critical"

func _warn_if_undeclared(key: String) -> void:
	if not is_declared(key):
		push_warning("GameState: flag '%s' is not declared in %s" % [key, REGISTRY_PATH])

func _load_registry() -> void:
	_registry = {}
	if not FileAccess.file_exists(REGISTRY_PATH):
		push_warning("GameState: no flag registry at %s" % REGISTRY_PATH)
		return
	var file := FileAccess.open(REGISTRY_PATH, FileAccess.READ)
	if file == null:
		push_error("GameState: cannot read %s" % REGISTRY_PATH)
		return
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK:
		push_error("GameState: malformed JSON in %s" % REGISTRY_PATH)
		return
	var data: Variant = json.get_data()
	if not (data is Dictionary):
		push_error("GameState: %s root is not an object" % REGISTRY_PATH)
		return
	var flags: Variant = (data as Dictionary).get("flags", {})
	if not (flags is Dictionary):
		push_error("GameState: %s has no 'flags' object" % REGISTRY_PATH)
		return
	_registry = flags
