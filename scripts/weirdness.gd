extends Node

## Weirdness (ENGINEERING_CONSTRAINTS.md §10) — the skeleton, not the system.
##
## Owns one scalar `intensity` (0.0-1.0) that is **derived and never saved**:
## it is recomputed from flags via data/weirdness/curve.json, so a loaded save
## reproduces it rather than restoring it. The only persisted weirdness state is
## the weird.* counters the design explicitly wants.
##
## A scheduler emits flicker_requested(kind, spot, params) at intervals derived
## from intensity, choosing from data/weirdness/catalog.json among the kinds a
## FlickerSpot allows. A short history ring stops the same kind firing at the
## same spot twice in a row.
##
## The curve numbers, catalog contents and flicker one-liners are the BUILD_PLAN
## §5 weirdness spec — a separate design session. Everything here ships with
## placeholder values flagged in config, and no handler beyond a no-op logger.

signal flicker_requested(kind: String, spot: Node, params: Dictionary)
signal intensity_changed(intensity: float)

const CURVE_PATH := "res://data/weirdness/curve.json"
const CATALOG_PATH := "res://data/weirdness/catalog.json"

## How many recent firings the anti-repeat ring remembers.
const HISTORY_SIZE := 8
## How many firings the debug buffer keeps for the test harness. Never persisted.
const DEBUG_BUFFER_SIZE := 32

var intensity: float = 0.0

var _curve: Dictionary = {}
var _catalog: Dictionary = {}
var _region_multiplier: float = 1.0
var _current_region: String = ""

var _spots: Array[Node] = []
var _history: Array[String] = []
var _debug_log: Array[Dictionary] = []

var _time_to_next: float = 0.0
var _scheduler_enabled: bool = true

func _ready() -> void:
	_load_curve()
	_load_catalog()
	recompute()
	_reschedule()
	var root_node: Node = get_tree().root
	if root_node.has_node("GameState"):
		root_node.get_node("GameState").connect("flag_changed", _on_flag_changed)

func _process(delta: float) -> void:
	if not _scheduler_enabled or intensity <= 0.0 or _spots.is_empty():
		return
	_time_to_next -= delta
	if _time_to_next > 0.0:
		return
	_reschedule()
	fire_one()

# ── intensity (§10) ──────────────────────────────────────────────────────────

## Recomputed from flags; never restored from a save. Called on load, on region
## change, and whenever a weird.* counter moves.
func recompute() -> float:
	var previous: float = intensity
	var value: float = float(_curve.get("base_intensity", 0.0))
	value += _act_contribution()
	value += _counter_contribution()
	intensity = clampf(value * _region_multiplier, 0.0, 1.0)
	if not is_equal_approx(previous, intensity):
		intensity_changed.emit(intensity)
	return intensity

## Act progress raises the floor. Entries arrive with Act One's flags; the list
## is empty until then rather than guessing at story beats.
func _act_contribution() -> float:
	var total: float = 0.0
	var state: Node = _game_state()
	if state == null:
		return total
	for entry: Variant in _curve.get("act_progress", []):
		if not (entry is Dictionary):
			continue
		var e: Dictionary = entry
		if Condition.evaluate(str(e.get("when", "true")), _flag_getter()):
			total += float(e.get("intensity", 0.0))
	return total

## weird.* counters nudge intensity up, each capped so no single counter can run
## away with the whole scale.
func _counter_contribution() -> float:
	var total: float = 0.0
	var state: Node = _game_state()
	if state == null:
		return total
	var counters: Variant = _curve.get("counters", {})
	if not (counters is Dictionary):
		return total
	for flag: Variant in (counters as Dictionary):
		var rule: Dictionary = (counters as Dictionary)[flag]
		var count: float = float(state.call("get_flag", str(flag), 0))
		var contribution: float = count * float(rule.get("per_unit", 0.0))
		total += minf(contribution, float(rule.get("max", 1.0)))
	return total

## A region's multiplier scales everything; 0 means nothing fires there at all
## (Hobb's village).
func set_region(region_id: String) -> void:
	_current_region = region_id
	_region_multiplier = 1.0
	var root_node: Node = get_tree().root
	if root_node.has_node("SceneRouter"):
		var data: Dictionary = root_node.get_node("SceneRouter").call("region_data", region_id)
		if data.has("weirdness"):
			_region_multiplier = float(data["weirdness"])
	recompute()

func region_multiplier() -> float:
	return _region_multiplier

func current_region() -> String:
	return _current_region

# ── the general-purpose hook (§10) ───────────────────────────────────────────

## Should this weirdness event fire? Its probability is a curve entry scaled by
## current intensity, so an event gets likelier as the world deteriorates.
## `misroute` (§6) is the first consumer.
func roll(event_name: String) -> bool:
	return randf() < chance_for(event_name)

func chance_for(event_name: String) -> float:
	var events: Variant = _curve.get("events", {})
	if not (events is Dictionary):
		return 0.0
	var base: float = float((events as Dictionary).get(event_name, 0.0))
	return clampf(base * intensity, 0.0, 1.0)

# ── flicker spots and the scheduler ──────────────────────────────────────────

func register_spot(spot: Node) -> void:
	if not _spots.has(spot):
		_spots.append(spot)

func unregister_spot(spot: Node) -> void:
	_spots.erase(spot)

func spot_count() -> int:
	return _spots.size()

func set_scheduler_enabled(enabled: bool) -> void:
	_scheduler_enabled = enabled

## Intervals shorten as intensity rises. Bounds are config placeholders (§13).
func next_interval() -> float:
	var longest: float = GameConfig.get_float("weirdness.flicker_interval_max_s", 90.0)
	var shortest: float = GameConfig.get_float("weirdness.flicker_interval_min_s", 20.0)
	return lerpf(longest, shortest, clampf(intensity, 0.0, 1.0))

func _reschedule() -> void:
	_time_to_next = next_interval()

## Picks one kind/spot pair and announces it. Returns false if nothing was
## eligible. Public so a test can drive the scheduler without waiting on time.
func fire_one() -> bool:
	var candidates: Array = eligible_pairs()
	if candidates.is_empty():
		return false
	var chosen: Dictionary = _weighted_pick(candidates)
	if chosen.is_empty():
		return false
	var kind: String = chosen["kind"]
	var spot: Node = chosen["spot"]
	_remember("%s@%s" % [kind, spot.name])
	_log_debug(kind, spot)
	flicker_requested.emit(kind, spot, _catalog.get(kind, {}))
	return true

## Every kind/spot pair allowed right now: the kind is v1, its min_intensity is
## met, its region is not excluded, the spot allows it, and the pair is not a
## repeat of something in the history ring.
func eligible_pairs() -> Array:
	var out: Array = []
	for spot: Node in _spots:
		if not is_instance_valid(spot):
			continue
		var allowed: Array = spot.get("allowed_kinds") if spot.get("allowed_kinds") != null else []
		for kind: Variant in _catalog:
			var kind_name: String = str(kind)
			if not allowed.is_empty() and not allowed.has(kind_name):
				continue
			if not _kind_is_eligible(kind_name):
				continue
			if _history.has("%s@%s" % [kind_name, spot.name]):
				continue
			out.append({"kind": kind_name, "spot": spot, "weight": float((_catalog[kind] as Dictionary).get("weight", 1.0))})
	return out

func _kind_is_eligible(kind_name: String) -> bool:
	var entry: Variant = _catalog.get(kind_name, {})
	if not (entry is Dictionary):
		return false
	var kind: Dictionary = entry
	if not bool(kind.get("v1", false)):
		return false
	if intensity < float(kind.get("min_intensity", 0.0)):
		return false
	var excluded: Variant = kind.get("regions_excluded", [])
	if excluded is Array and (excluded as Array).has(_current_region):
		return false
	return true

func _weighted_pick(candidates: Array) -> Dictionary:
	var total: float = 0.0
	for candidate: Dictionary in candidates:
		total += maxf(0.0, float(candidate.get("weight", 1.0)))
	if total <= 0.0:
		return candidates[0]
	var roll_value: float = randf() * total
	for candidate: Dictionary in candidates:
		roll_value -= maxf(0.0, float(candidate.get("weight", 1.0)))
		if roll_value <= 0.0:
			return candidate
	return candidates[candidates.size() - 1]

func _remember(key: String) -> void:
	_history.append(key)
	while _history.size() > HISTORY_SIZE:
		_history.remove_at(0)

func history() -> Array:
	return _history.duplicate()

# ── debug buffer (§10: readable from the harness, never persisted) ───────────

func debug_log() -> Array:
	return _debug_log.duplicate(true)

func _log_debug(kind: String, spot: Node) -> void:
	_debug_log.append({
		"kind": kind,
		"spot": spot.name,
		"intensity": intensity,
		"region": _current_region,
	})
	while _debug_log.size() > DEBUG_BUFFER_SIZE:
		_debug_log.remove_at(0)

# ── save contract (§3, §13) ──────────────────────────────────────────────────

## Intensity is derived, so there is nothing to save. The contract is
## implemented anyway: SaveManager discovers contributors by these methods, and
## an empty section keeps that discovery honest rather than special-cased.
func to_save_dict() -> Dictionary:
	return {}

func from_save_dict(_data: Dictionary) -> void:
	recompute()

func reset() -> void:
	_spots.clear()
	_history.clear()
	_debug_log.clear()
	_region_multiplier = 1.0
	_current_region = ""
	_scheduler_enabled = true
	recompute()
	_reschedule()

# ── loading ──────────────────────────────────────────────────────────────────

func catalog() -> Dictionary:
	return _catalog

func curve() -> Dictionary:
	return _curve

func _on_flag_changed(key: String, _value: Variant) -> void:
	# Only weird.* counters and act progress move intensity; ignore the rest.
	if key.begins_with("weird.") or key.begins_with("act"):
		recompute()

func _load_curve() -> void:
	var data: Variant = _read_json(CURVE_PATH)
	_curve = data if data is Dictionary else {}

func _load_catalog() -> void:
	_catalog = {}
	var data: Variant = _read_json(CATALOG_PATH)
	if not (data is Dictionary):
		return
	var kinds: Variant = (data as Dictionary).get("kinds", {})
	if kinds is Dictionary:
		_catalog = kinds

func _read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_warning("Weirdness: missing %s" % path)
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK:
		push_error("Weirdness: malformed JSON in %s" % path)
		return null
	return json.get_data()

func _game_state() -> Node:
	var root_node: Node = get_tree().root
	return root_node.get_node("GameState") if root_node.has_node("GameState") else null

func _flag_getter() -> Callable:
	var state: Node = _game_state()
	if state == null:
		return func(_flag: String) -> Variant: return null
	return func(flag: String) -> Variant: return state.call("get_flag", flag, null)
