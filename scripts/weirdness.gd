extends Node

## Weirdness (ENGINEERING_CONSTRAINTS.md §10), built out to the rulings in
## Docs/WEIRDNESS_SPEC.md (ledger §M).
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
## The scheduler runs on player-time only: it is paused whenever something holds
## input, waits out an arrival grace after every transition, keeps a global floor
## between firings, and jitters every interval so it never reads as a metronome
## (§2). An area may override its region's multiplier, which is how Hobb's
## village is silent inside a region that is not (§4).
##
## Flickers are texture; scripted beats are plot. Nothing here ever touches the
## plot: handlers set no flag, write nothing to a save, and cannot block,
## redirect, collide or damage (§3, §6). The one exception the design asks for
## is the weird.* counters.

signal flicker_requested(kind: String, spot: Node, params: Dictionary)
signal intensity_changed(intensity: float)

## Good Soil (Probably)'s tell (WEIRDNESS_SPEC §5, ledger M-5): the ambient bus
## ducks and the loops stop a few seconds before a scripted overt beat or a
## misroute. Never before a random flicker — a warning would make a deniable
## event undeniable, which inverts the system.
signal tell_requested

const CURVE_PATH := "res://data/weirdness/curve.json"
const CATALOG_PATH := "res://data/weirdness/catalog.json"
const LINES_PATH := "res://data/weirdness/lines.json"

## The village whose pro is the tell. Any other village gets no warning.
const TELL_VILLAGE := "good_soil_probably"
## Audio bus the tell ducks; created at runtime if the project has no layout.
const AMBIENT_BUS := "Ambient"
## Scene group whose AudioStreamPlayers the tell silences.
const AMBIENT_LOOP_GROUP := "ambient_loop"

## How many recent firings the anti-repeat ring remembers.
const HISTORY_SIZE := 8
## How many firings the debug buffer keeps for the test harness. Never persisted.
const DEBUG_BUFFER_SIZE := 32

var intensity: float = 0.0

var _curve: Dictionary = {}
var _catalog: Dictionary = {}
var _lines: Array = []
## What a flicker actually draws (§8). Weirdness decides whether and where; the
## registry decides what. Not an autoload — the roster is closed (§13).
var _handlers: FlickerHandlers = null
var _region_multiplier: float = 1.0
var _current_region: String = ""
var _current_area: String = ""

## An area-level override of the region multiplier (WEIRDNESS_SPEC §4, M-4).
## null means "no override, use the region"; 0.0 silences one area (Hobb's
## village) without silencing its region.
var _area_override: Variant = null

var _spots: Array[Node] = []
var _history: Array[String] = []
var _debug_log: Array[Dictionary] = []
var _roll_counts: Dictionary = {}
## npc_line ids already used this run. In memory only: never saved, so a reload
## may repeat one, which §6 rule 3 accepts.
var _lines_shown: Dictionary = {}

var _time_to_next: float = 0.0
## Counts down the arrival grace after entering an area (§2): nothing fires
## while the player is still working out where they are.
var _grace_remaining: float = 0.0
## Player-time since the last firing, for the global floor (§2).
var _since_last_fire: float = 0.0
var _scheduler_enabled: bool = true

func _ready() -> void:
	_load_curve()
	_load_catalog()
	_load_lines()
	recompute()
	_reschedule()
	_handlers = FlickerHandlers.new()
	flicker_requested.connect(_handlers.dispatch)
	tell_requested.connect(_on_tell_requested)
	var root_node: Node = get_tree().root
	if root_node.has_node("GameState"):
		root_node.get_node("GameState").connect("flag_changed", _on_flag_changed)

## The clock is player-time (§2): it only runs while the player has control in
## an explorable area, so dialogue, cutscenes, battles and menus do not age the
## countdown. Grace and the global floor are checked here rather than folded
## into the interval, so both stay inspectable from a test.
func _process(delta: float) -> void:
	if not _scheduler_enabled or not player_has_control():
		return
	if _grace_remaining > 0.0:
		_grace_remaining = maxf(0.0, _grace_remaining - delta)
		return
	_since_last_fire += delta
	if intensity <= 0.0 or _spots.is_empty():
		return
	_time_to_next -= delta
	if _time_to_next > 0.0:
		return
	if _since_last_fire < global_floor_s():
		return
	_reschedule()
	fire_one()

## True unless something holds input. The flag is written by DialogueManager and
## CutsceneManager; unset means the player is walking around (§2).
func player_has_control() -> bool:
	var state: Node = _game_state()
	if state == null:
		return true
	return bool(state.call("get_flag", "sys.player_has_control", true))

# ── intensity (§10) ──────────────────────────────────────────────────────────

## Recomputed from flags; never restored from a save. Called on load, on region
## change, and whenever a weird.* counter moves.
func recompute() -> float:
	var previous: float = intensity
	var value: float = float(_curve.get("base_intensity", 0.0))
	value += _act_contribution()
	value += _counter_contribution()
	intensity = clampf(value * effective_multiplier(), 0.0, 1.0)
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

## A region's multiplier scales everything (The Hold 1.0, The Turning 1.5 —
## WEIRDNESS_SPEC §4). A region change also drops any area override: the router
## re-applies one for the area being entered if it has one.
func set_region(region_id: String) -> void:
	_current_region = region_id
	_region_multiplier = 1.0
	_area_override = null
	var root_node: Node = get_tree().root
	if root_node.has_node("SceneRouter"):
		var data: Dictionary = root_node.get_node("SceneRouter").call("region_data", region_id)
		if data.has("weirdness"):
			_region_multiplier = float(data["weirdness"])
	recompute()

## An anchor may carry weirdness_override (§4, M-4), which replaces the region
## multiplier for that one area: Hobb's village is 0 inside a region that is 1.0.
## Pass null to clear it. The router calls this after every transition, so an
## area without an override explicitly clears the previous area's.
func set_area_weirdness(value: Variant) -> void:
	if value == null:
		_area_override = null
	else:
		_area_override = clampf(float(value), 0.0, 1.0)
	recompute()

func area_override() -> Variant:
	return _area_override

## What recompute() actually scales by: the area override when one is present,
## the region multiplier otherwise.
func effective_multiplier() -> float:
	if _area_override == null:
		return _region_multiplier
	return float(_area_override)

## Called by SceneRouter after every transition and by an area registering on
## boot. Resets the arrival grace and the countdown; intensity is derived from
## flags and so is deliberately untouched (§2).
func on_area_entered(area_id: String) -> void:
	_current_area = area_id
	_grace_remaining = arrival_grace_s()
	_reschedule()

## One line for the boot smoke report (session 9).
func debug_summary() -> String:
	return "intensity=%.2f scheduler=%s control=%s spots=%d grace=%.1fs region='%s'" % [
		intensity, _scheduler_enabled, player_has_control(), _spots.size(), _grace_remaining, _current_region]

func region_multiplier() -> float:
	return _region_multiplier

func current_region() -> String:
	return _current_region

func current_area() -> String:
	return _current_area

func grace_remaining() -> float:
	return _grace_remaining

# ── the general-purpose hook (§10) ───────────────────────────────────────────

## Should this weirdness event fire? Its probability is a curve entry scaled by
## current intensity, so an event gets likelier as the world deteriorates.
## `misroute` (§6) is the first consumer.
func roll(event_name: String) -> bool:
	_roll_counts[event_name] = int(_roll_counts.get(event_name, 0)) + 1
	return randf() < chance_for(event_name)

## How often roll() has been consulted per event this run. Debug state for
## the harness, like the ring buffer - never persisted, cleared by reset().
func roll_count(event_name: String) -> int:
	return int(_roll_counts.get(event_name, 0))

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

## Intervals shorten as intensity rises: 300s calm down to 45s at full
## intensity (WEIRDNESS_SPEC §2). The shape stays lerp(max, min, intensity) —
## the feel comes from the ladder being non-linear, not from the code.
##
## Jitter is Adam's rule (M-2): a uniform offset in ±flicker_jitter_s, floored
## at global_floor_s. Never a metronome.
func base_interval() -> float:
	var longest: float = GameConfig.get_float("weirdness.flicker_interval_max_s", 300.0)
	var shortest: float = GameConfig.get_float("weirdness.flicker_interval_min_s", 45.0)
	return lerpf(longest, shortest, clampf(intensity, 0.0, 1.0))

func next_interval() -> float:
	var jitter: float = jitter_s()
	var offset: float = randf_range(-jitter, jitter)
	return maxf(base_interval() + offset, global_floor_s())

func jitter_s() -> float:
	return GameConfig.get_float("weirdness.flicker_jitter_s", 10.0)

func arrival_grace_s() -> float:
	return GameConfig.get_float("weirdness.arrival_grace_s", 8.0)

func global_floor_s() -> float:
	return GameConfig.get_float("weirdness.global_floor_s", 10.0)

func _reschedule() -> void:
	_time_to_next = maxf(next_interval(), global_floor_s())

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
	_since_last_fire = 0.0
	flicker_requested.emit(kind, spot, params_for(kind, spot))
	return true

## What a handler receives: the kind's catalog entry (handler name, timings)
## merged with the spot's own params (tile coords, NPC path), the spot winning a
## clash so one scene can specialise a kind without a second catalog entry.
func params_for(kind: String, spot: Node) -> Dictionary:
	var entry: Variant = _catalog.get(kind, {})
	var params: Dictionary = (entry as Dictionary).duplicate(true) if entry is Dictionary else {}
	if is_instance_valid(spot):
		var spot_params: Variant = spot.get("params")
		if spot_params is Dictionary:
			for key: Variant in (spot_params as Dictionary):
				params[key] = (spot_params as Dictionary)[key]
	params["kind"] = kind
	return params

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

# ── the tell (§5, M-5) ───────────────────────────────────────────────────────

## Whether this run gets the tell at all: Good Soil (Probably) only.
func tell_is_available() -> bool:
	var state: Node = _game_state()
	if state == null:
		return false
	return str(state.call("get_flag", "sys.village", "")) == TELL_VILLAGE

## How long before the beat the tell lands — uniform in [lead_min, lead_max].
func tell_lead_s() -> float:
	var low: float = GameConfig.get_float("tell.lead_min_s", 2.0)
	var high: float = GameConfig.get_float("tell.lead_max_s", 4.0)
	return randf_range(minf(low, high), maxf(low, high))

## Asks for the tell. Returns how long the caller should wait before the beat,
## or 0.0 when this run has no tell, so a caller can always await the result.
## Callers are CutsceneManager (before an `overt` beat) and SceneRouter (before
## a misroute) — never the flicker scheduler.
func request_tell() -> float:
	if not tell_is_available():
		return 0.0
	tell_requested.emit()
	return tell_lead_s()

## The tell itself: the ambient bus ducks and the loops stop. Nothing visual —
## the player learns the silence.
func _on_tell_requested() -> void:
	var duck_db: float = GameConfig.get_float("tell.duck_db", -6.0)
	var duration: float = GameConfig.get_float("tell.duration_s", 1.5)
	var bus: int = _ensure_ambient_bus()
	var restore_to: float = 0.0
	if bus >= 0:
		restore_to = AudioServer.get_bus_volume_db(bus)
		AudioServer.set_bus_volume_db(bus, restore_to + duck_db)

	var paused: Array[AudioStreamPlayer] = []
	var tree: SceneTree = get_tree()
	if tree != null:
		for node: Node in tree.get_nodes_in_group(AMBIENT_LOOP_GROUP):
			if node is AudioStreamPlayer and (node as AudioStreamPlayer).playing:
				(node as AudioStreamPlayer).stream_paused = true
				paused.append(node)

	if tree != null:
		await tree.create_timer(duration).timeout

	if bus >= 0:
		AudioServer.set_bus_volume_db(bus, restore_to)
	for player: AudioStreamPlayer in paused:
		if is_instance_valid(player):
			player.stream_paused = false

## The Ambient bus, created at runtime when the project ships no bus layout.
## Returns -1 if the audio server has no buses at all (a headless oddity).
func _ensure_ambient_bus() -> int:
	var count: int = AudioServer.bus_count
	if count <= 0:
		return -1
	for i: int in count:
		if AudioServer.get_bus_name(i) == AMBIENT_BUS:
			return i
	AudioServer.add_bus()
	var index: int = AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, AMBIENT_BUS)
	return index

# ── the npc_line pool (§9, M-8) ──────────────────────────────────────────────

func lines() -> Array:
	return _lines.duplicate(true)

## One line the current intensity allows and this run has not used. Returns an
## empty Dictionary when the pool is exhausted — the handler then does nothing,
## which is preferable to repeating a line the player has already heard.
func take_line() -> Dictionary:
	var candidates: Array = []
	for entry: Variant in _lines:
		if not (entry is Dictionary):
			continue
		var line: Dictionary = entry
		var id_value: String = str(line.get("id", ""))
		if id_value.is_empty() or _lines_shown.has(id_value):
			continue
		if intensity < float(line.get("min_intensity", 0.0)):
			continue
		candidates.append(line)
	if candidates.is_empty():
		return {}
	var chosen: Dictionary = candidates[randi() % candidates.size()]
	_lines_shown[str(chosen.get("id", ""))] = true
	return chosen

func lines_shown() -> Array:
	return _lines_shown.keys()

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
	_roll_counts.clear()
	_lines_shown.clear()
	_region_multiplier = 1.0
	_area_override = null
	_current_region = ""
	_current_area = ""
	_grace_remaining = 0.0
	_since_last_fire = 0.0
	_scheduler_enabled = true
	recompute()
	_reschedule()

# ── loading ──────────────────────────────────────────────────────────────────

func handlers() -> FlickerHandlers:
	return _handlers

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

func _load_lines() -> void:
	_lines = []
	var data: Variant = _read_json(LINES_PATH)
	if not (data is Dictionary):
		return
	var pool: Variant = (data as Dictionary).get("lines", [])
	if pool is Array:
		_lines = pool

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
