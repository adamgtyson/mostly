extends Node

## SceneRouter (ENGINEERING_CONSTRAINTS.md §6) — the single choke point for
## scene transitions.
##
## go_to() fades out, loads the target area asynchronously, places the player at
## the named spawn, fades in and autosaves. It enforces the region lock
## (region.<id>.unlocked), tells Weirdness when the region changes, and asks it
## whether this transition misroutes (EC-6a).
##
## An area also registers itself on _ready, so booting straight into a scene
## leaves the router holding the correct current location from the first frame.

signal transition_started(from_id: String, to_id: String)
signal transition_finished(area_id: String)
signal region_changed(region_id: String)
signal travel_blocked(region_id: String, reason: String)
signal misrouted(intended_id: String, actual_id: String)

const REGIONS_DIR := "res://regions"

var current_region: String = ""
var current_area: String = ""

var _region_cache: Dictionary = {}
var _visited: Dictionary = {}
var _transitioning: bool = false
var _fade_rect: ColorRect = null

# ── registration ─────────────────────────────────────────────────────────────

## Called by an Area root on _ready. Bypasses the region lock deliberately: the
## scene is already loaded, and refusing here would strand the player rather
## than prevent travel.
func register_area(area: Node) -> void:
	var region: String = str(area.get("region_id"))
	var name: String = str(area.get("area_id"))
	if region.is_empty() or name.is_empty():
		push_warning("SceneRouter: area '%s' has no region_id/area_id" % area.name)
		return
	var region_changed_now: bool = region != current_region
	current_region = region
	current_area = name
	mark_visited(region, name)
	if region_changed_now:
		_apply_region_weirdness(region)
		region_changed.emit(region)

func current_id() -> String:
	if current_region.is_empty():
		return ""
	return "%s/%s" % [current_region, current_area]

# ── travel ───────────────────────────────────────────────────────────────────

## Moves the player to <region>/<area>, arriving at the named spawn.
## Returns false if the move was refused; a misroute still returns true.
func go_to(region: String, area: String, spawn: String = "default") -> bool:
	if _transitioning:
		push_warning("SceneRouter: already mid-transition, ignoring go_to")
		return false

	if not is_region_unlocked(region):
		_refuse(region)
		return false

	var intended_id: String = "%s/%s" % [region, area]
	var destination: Dictionary = {"region": region, "area": area, "spawn": spawn}

	# EC-6a: extremely rarely, an exit delivers Patch somewhere else. The chance
	# lives in the weirdness curve, not here, and a misroute can only land on an
	# unlocked area he has already visited, so it can never break the region
	# lock or the critical path.
	if _roll_misroute():
		var alternative: Dictionary = _misroute_destination(region, area)
		if not alternative.is_empty():
			destination = alternative
			increment_misroute_count()
			misrouted.emit(intended_id, "%s/%s" % [destination["region"], destination["area"]])

	await _travel(destination["region"], destination["area"], str(destination["spawn"]), intended_id)
	return true

func is_region_unlocked(region: String) -> bool:
	var state: Node = _game_state()
	if state == null:
		return true
	return bool(state.call("get_flag", "region.%s.unlocked" % region, false))

## Seeds a new run: the starting region is reachable from the first step. Which
## region that is comes from config, not a literal (§13); why the others are
## locked is [U2-2] and is not decided here.
func new_game() -> void:
	var state: Node = _game_state()
	if state == null:
		return
	state.call("set_flag", "region.%s.unlocked" % starting_region(), true)

func starting_region() -> String:
	return str(GameConfig.get_value("scene.starting_region", "hold"))

func starting_area() -> String:
	return str(GameConfig.get_value("scene.starting_area", "workshop"))

func starting_spawn() -> String:
	return str(GameConfig.get_value("scene.starting_spawn", "default"))

func _refuse(region: String) -> void:
	var reason: String = "region '%s' is locked" % region
	travel_blocked.emit(region, reason)
	var message: String = str(region_data(region).get("locked_message", ""))
	if message.is_empty():
		return
	var root_node: Node = get_tree().root
	if root_node.has_node("DialogueManager"):
		root_node.get_node("DialogueManager").call("start_dialogue", message)

func _travel(region: String, area: String, spawn: String, intended_id: String) -> void:
	_transitioning = true
	var from_id: String = current_id()
	var to_id: String = "%s/%s" % [region, area]
	transition_started.emit(from_id, to_id)

	await fade(true)

	var path: String = area_scene_path(region, area)
	var packed: PackedScene = await load_area_scene(path)
	if packed == null:
		push_error("SceneRouter: cannot load area scene '%s'" % path)
		await fade(false)
		_transitioning = false
		return

	var tree: SceneTree = get_tree()
	var previous: Node = tree.current_scene
	var instance: Node = packed.instantiate()
	if previous != null:
		previous.queue_free()
	tree.root.add_child(instance)
	tree.current_scene = instance

	# register_area() has already run in the new scene's _ready by this point.
	place_player(instance, spawn)

	await fade(false)
	_transitioning = false
	transition_finished.emit(to_id)

	# Autosave on every scene transition (§3).
	var root_node: Node = tree.root
	if root_node.has_node("SaveManager"):
		root_node.get_node("SaveManager").call("autosave")

func area_scene_path(region: String, area: String) -> String:
	return "%s/%s/areas/%s.tscn" % [REGIONS_DIR, region, area]

## Threaded load so a large area does not stall the fade.
func load_area_scene(path: String) -> PackedScene:
	if not ResourceLoader.exists(path):
		return null
	ResourceLoader.load_threaded_request(path)
	while true:
		var status: int = ResourceLoader.load_threaded_get_status(path)
		if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			await get_tree().process_frame
			continue
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			var resource: Variant = ResourceLoader.load_threaded_get(path)
			return resource as PackedScene
		return null
	return null

func place_player(scene_root: Node, spawn: String) -> void:
	var player: Node = scene_root.get_node_or_null("Player")
	if player == null or not (player is Node2D):
		return
	if scene_root.has_method("spawn_position"):
		(player as Node2D).position = scene_root.call("spawn_position", spawn)

# ── visited areas and misroutes (EC-6a) ──────────────────────────────────────

func mark_visited(region: String, area: String) -> void:
	if not _visited.has(region):
		_visited[region] = {}
	(_visited[region] as Dictionary)[area] = true

func has_visited(region: String, area: String) -> bool:
	return (_visited.get(region, {}) as Dictionary).has(area)

func visited_areas(region: String) -> Array:
	return (_visited.get(region, {}) as Dictionary).keys()

func increment_misroute_count() -> void:
	var state: Node = _game_state()
	if state != null:
		state.call("increment", "weird.misroutes", 1)

func _roll_misroute() -> bool:
	var root_node: Node = get_tree().root
	if not root_node.has_node("Weirdness"):
		return false
	return bool(root_node.get_node("Weirdness").call("roll", "misroute"))

## Only an unlocked, already-visited area in the current region, and never the
## place the player meant to go.
func _misroute_destination(region: String, area: String) -> Dictionary:
	if not is_region_unlocked(current_region):
		return {}
	var candidates: Array = []
	for visited: String in visited_areas(current_region):
		if current_region == region and visited == area:
			continue
		if visited == current_area:
			continue
		candidates.append(visited)
	if candidates.is_empty():
		return {}
	candidates.sort()
	var pick: String = candidates[randi() % candidates.size()]
	return {"region": current_region, "area": pick, "spawn": "default"}

# ── region data (§7) ─────────────────────────────────────────────────────────

func region_data(region: String) -> Dictionary:
	if _region_cache.has(region):
		return _region_cache[region]
	var path: String = "%s/%s/region.json" % [REGIONS_DIR, region]
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK:
		push_error("SceneRouter: malformed JSON in %s" % path)
		return {}
	var data: Variant = json.get_data()
	if not (data is Dictionary):
		return {}
	_region_cache[region] = data
	return data

func region_anchors(region: String) -> Array:
	var anchors: Variant = region_data(region).get("anchors", [])
	return anchors if anchors is Array else []

func _apply_region_weirdness(region: String) -> void:
	var root_node: Node = get_tree().root
	if root_node.has_node("Weirdness"):
		root_node.get_node("Weirdness").call("set_region", region)

# ── fade ─────────────────────────────────────────────────────────────────────

func fade_duration() -> float:
	return GameConfig.get_float("scene.fade_duration_s", 0.25)

func fade(to_black: bool) -> void:
	var rect: ColorRect = _ensure_fade_rect()
	var target: float = 1.0 if to_black else 0.0
	var duration: float = fade_duration()
	if duration <= 0.0:
		rect.color.a = target
		return
	var tween: Tween = create_tween()
	tween.tween_property(rect, "color:a", target, duration)
	await tween.finished
	rect.color.a = target

func _ensure_fade_rect() -> ColorRect:
	if is_instance_valid(_fade_rect):
		return _fade_rect
	var layer := CanvasLayer.new()
	layer.layer = 95
	add_child(layer)
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0.0, 0.0, 0.0, 0.0)
	_fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_fade_rect)
	return _fade_rect

# ── save contract (§3) ───────────────────────────────────────────────────────

## Stored under "location", the §3 envelope key, rather than the autoload's name.
func save_key() -> String:
	return "location"

func to_save_dict() -> Dictionary:
	var position: Vector2 = Vector2.ZERO
	var scene: Node = get_tree().current_scene
	if scene != null:
		var player: Node = scene.get_node_or_null("Player")
		if player is Node2D:
			position = (player as Node2D).position
	return {
		"region": current_region,
		"area": current_area,
		"spawn": "default",
		"position": [position.x, position.y],
		"visited": _visited.duplicate(true),
	}

func from_save_dict(data: Dictionary) -> void:
	current_region = str(data.get("region", ""))
	current_area = str(data.get("area", ""))
	var visited: Variant = data.get("visited", {})
	_visited = (visited as Dictionary).duplicate(true) if visited is Dictionary else {}

func reset() -> void:
	current_region = ""
	current_area = ""
	_visited.clear()
	_region_cache.clear()
	_transitioning = false

func _game_state() -> Node:
	var root_node: Node = get_tree().root
	return root_node.get_node("GameState") if root_node.has_node("GameState") else null
