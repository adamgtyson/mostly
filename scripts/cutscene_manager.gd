extends Node

## CutsceneManager — cutscene beats as data (ENGINEERING_CONSTRAINTS.md §8).
##
## A cutscene is data/cutscenes/<id>.json:
##   { "id", "skippable", "once", "beats": [ {...}, ... ] }
##
## Actors are referenced by scene node name and resolved at play time against
## the actor root the caller supplies, so the same beat file works for any scene
## that has the named nodes.
##
## Beat vocabulary: wait, move, animation, dialogue, end (v1), plus set_flag,
## camera, fade, sfx, spawn, despawn, choice and emit. `emit` fires
## beat_emitted() for a scene to hook — JSON never calls a script directly.

signal cutscene_started(cutscene_id: String)
signal cutscene_ended
## Raised by an `emit` beat; a scene connects to react without the data knowing
## anything about scripts.
signal beat_emitted(signal_name: String, args: Array)

const CUTSCENE_DIR := "res://data/cutscenes"

var cutscene_active: bool = false

var _skipping: bool = false
var _current_tween: Tween = null
var _actor_root: Node = null
var _document: Dictionary = {}
var _fade_rect: ColorRect = null

# ── playing ──────────────────────────────────────────────────────────────────

## Loads data/cutscenes/<id>.json and plays it. Returns false if the cutscene is
## missing, or is marked `once` and has already been seen.
func play_cutscene_id(cutscene_id: String, actor_root: Node) -> bool:
	var document: Dictionary = load_cutscene(cutscene_id)
	if document.is_empty():
		return false
	if bool(document.get("once", false)) and _has_seen(cutscene_id):
		return false
	_document = document
	var beats: Variant = document.get("beats", [])
	play_cutscene(beats if beats is Array else [], cutscene_id, actor_root)
	return true

func load_cutscene(cutscene_id: String) -> Dictionary:
	var path: String = "%s/%s.json" % [CUTSCENE_DIR, cutscene_id]
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("CutsceneManager: could not open '%s'" % path)
		return {}
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK:
		push_error("CutsceneManager: JSON parse error in '%s'" % path)
		return {}
	var data: Variant = json.get_data()
	if not (data is Dictionary):
		push_error("CutsceneManager: root is not a Dictionary in '%s'" % path)
		return {}
	return data

func play_cutscene(beats: Array, cutscene_id: String = "", actor_root: Node = null) -> void:
	if cutscene_active:
		push_warning("CutsceneManager: play_cutscene called while already active, ignoring.")
		return
	cutscene_active = true
	_skipping = false
	_actor_root = actor_root
	cutscene_started.emit(cutscene_id)

	for beat: Variant in beats:
		if _skipping:
			break
		if beat is Dictionary:
			await _execute_beat(beat)

	_finish()

func skip() -> void:
	if not cutscene_active or _skipping:
		return
	if not current_is_skippable():
		return
	_skipping = true
	if _current_tween and _current_tween.is_valid():
		_current_tween.kill()
		_current_tween = null
	if DialogueManager.dialogue_active:
		DialogueManager.force_end()

func current_is_skippable() -> bool:
	return bool(_document.get("skippable", true))

func reset() -> void:
	_skipping = false
	cutscene_active = false
	_document = {}
	_actor_root = null
	if _current_tween and _current_tween.is_valid():
		_current_tween.kill()
	_current_tween = null

# ── beats ────────────────────────────────────────────────────────────────────

func _execute_beat(beat: Dictionary) -> void:
	var beat_type: String = str(beat.get("type", ""))
	match beat_type:
		"wait":
			await _beat_wait(float(beat.get("duration", 0.0)))
		"move":
			await _beat_move(beat)
		"animation":
			_beat_animation(beat)
		"dialogue", "choice":
			# A choice beat is a dialogue whose graph offers choices; the wait is
			# the same, so it delegates rather than duplicating the loop (§8).
			await _beat_dialogue(str(beat.get("dialogue_id", "")))
		"set_flag":
			_beat_set_flag(beat)
		"camera":
			await _beat_camera(beat)
		"fade":
			await _beat_fade(beat)
		"sfx":
			_beat_sfx(beat)
		"spawn":
			_beat_spawn(beat)
		"despawn":
			_beat_despawn(beat)
		"emit":
			_beat_emit(beat)
		"end":
			pass
		_:
			push_error("CutsceneManager: unknown beat type '%s'" % beat_type)

func _beat_wait(duration: float) -> void:
	var timer := get_tree().create_timer(duration)
	while timer.time_left > 0.0 and not _skipping:
		await get_tree().process_frame

func _beat_move(beat: Dictionary) -> void:
	var node: Node2D = _resolve_node(beat.get("node", null)) as Node2D
	if not is_instance_valid(node):
		push_error("CutsceneManager: move beat has null or invalid node.")
		return
	var target: Vector2 = _to_vector2(beat.get("target", node.position))
	var speed: float = float(beat.get("speed", 80.0))
	var dist: float = node.position.distance_to(target)
	if dist < 0.5:
		return
	var duration: float = dist / speed
	_current_tween = create_tween()
	_current_tween.tween_property(node, "position", target, duration)
	while _current_tween.is_running() and not _skipping:
		await get_tree().process_frame
	if _current_tween and _current_tween.is_valid():
		_current_tween.kill()
	_current_tween = null

func _beat_animation(beat: Dictionary) -> void:
	var node: AnimatedSprite2D = _resolve_node(beat.get("node", null)) as AnimatedSprite2D
	var animation: String = str(beat.get("animation", ""))
	if not is_instance_valid(node):
		push_error("CutsceneManager: animation beat has null or invalid node.")
		return
	if animation.is_empty():
		push_error("CutsceneManager: animation beat missing animation name.")
		return
	node.play(animation)

func _beat_dialogue(dialogue_id: String) -> void:
	if dialogue_id.is_empty():
		push_error("CutsceneManager: dialogue beat missing dialogue_id.")
		return
	DialogueManager.start_dialogue(dialogue_id)
	if not DialogueManager.dialogue_active:
		return
	while DialogueManager.dialogue_active and not _skipping:
		await get_tree().process_frame

func _beat_set_flag(beat: Dictionary) -> void:
	var key: String = str(beat.get("flag", ""))
	if key.is_empty():
		push_error("CutsceneManager: set_flag beat missing flag.")
		return
	var state: Node = _game_state()
	if state == null:
		return
	if beat.has("increment"):
		state.call("increment", key, int(beat["increment"]))
	else:
		state.call("set_flag", key, beat.get("value", true))

func _beat_camera(beat: Dictionary) -> void:
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera == null:
		push_warning("CutsceneManager: camera beat with no active Camera2D.")
		return
	var action: String = str(beat.get("action", "pan"))
	var duration: float = float(beat.get("duration", 0.5))
	match action:
		"pan":
			var target: Vector2 = _to_vector2(beat.get("target", camera.position))
			_current_tween = create_tween()
			_current_tween.tween_property(camera, "position", target, duration)
			while _current_tween.is_running() and not _skipping:
				await get_tree().process_frame
			if _current_tween and _current_tween.is_valid():
				_current_tween.kill()
			_current_tween = null
		"shake":
			var amplitude: float = float(beat.get("amplitude", 2.0))
			var origin: Vector2 = camera.position
			var elapsed: float = 0.0
			while elapsed < duration and not _skipping:
				camera.position = origin + Vector2(
					randf_range(-amplitude, amplitude),
					randf_range(-amplitude, amplitude)
				).round()
				elapsed += get_process_delta_time()
				await get_tree().process_frame
			camera.position = origin
		_:
			push_error("CutsceneManager: unknown camera action '%s'" % action)

func _beat_fade(beat: Dictionary) -> void:
	var to_black: bool = str(beat.get("to", "black")) == "black"
	var duration: float = float(beat.get("duration", 0.25))
	var rect: ColorRect = _ensure_fade_rect()
	var target_alpha: float = 1.0 if to_black else 0.0
	if duration <= 0.0:
		rect.color.a = target_alpha
		return
	_current_tween = create_tween()
	_current_tween.tween_property(rect, "color:a", target_alpha, duration)
	while _current_tween.is_running() and not _skipping:
		await get_tree().process_frame
	if _current_tween and _current_tween.is_valid():
		_current_tween.kill()
	_current_tween = null
	rect.color.a = target_alpha

func _beat_sfx(beat: Dictionary) -> void:
	var stream_path: String = str(beat.get("stream", ""))
	if stream_path.is_empty():
		push_error("CutsceneManager: sfx beat missing stream.")
		return
	if not ResourceLoader.exists(stream_path):
		# Audio assets arrive with content; the beat stays valid meanwhile.
		push_warning("CutsceneManager: sfx '%s' not found, skipping." % stream_path)
		return
	var stream: Variant = load(stream_path)
	if not (stream is AudioStream):
		push_error("CutsceneManager: sfx '%s' is not an AudioStream." % stream_path)
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()

func _beat_spawn(beat: Dictionary) -> void:
	var scene_path: String = str(beat.get("scene", ""))
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		push_error("CutsceneManager: spawn beat scene '%s' not found." % scene_path)
		return
	if _actor_root == null:
		push_error("CutsceneManager: spawn beat with no actor root.")
		return
	var packed: Variant = load(scene_path)
	if not (packed is PackedScene):
		push_error("CutsceneManager: spawn beat scene '%s' is not a PackedScene." % scene_path)
		return
	var instance: Node = (packed as PackedScene).instantiate()
	var node_name: String = str(beat.get("name", ""))
	if not node_name.is_empty():
		instance.name = node_name
	if instance is Node2D and beat.has("position"):
		(instance as Node2D).position = _to_vector2(beat["position"])
	_actor_root.add_child(instance)

func _beat_despawn(beat: Dictionary) -> void:
	var node: Node = _resolve_node(beat.get("node", null))
	if not is_instance_valid(node):
		push_warning("CutsceneManager: despawn beat has no such node.")
		return
	node.queue_free()

func _beat_emit(beat: Dictionary) -> void:
	var signal_name: String = str(beat.get("signal", ""))
	if signal_name.is_empty():
		push_error("CutsceneManager: emit beat missing signal name.")
		return
	var args: Variant = beat.get("args", [])
	beat_emitted.emit(signal_name, args if args is Array else [])

# ── helpers ──────────────────────────────────────────────────────────────────

## Accepts a live Node (in-code beats) or a node path resolved against the actor
## root at play time (§8).
func _resolve_node(value: Variant) -> Node:
	if value is Node:
		return value
	if value is String:
		if _actor_root == null:
			push_error("CutsceneManager: beat names node '%s' but no actor root was given." % value)
			return null
		var node: Node = _actor_root.get_node_or_null(NodePath(value))
		if node == null:
			push_error("CutsceneManager: actor '%s' not found under %s" % [value, _actor_root.name])
		return node
	return null

func _to_vector2(value: Variant) -> Vector2:
	if value is Vector2:
		return value
	if value is Array and (value as Array).size() >= 2:
		var a: Array = value
		return Vector2(float(a[0]), float(a[1]))
	if value is Dictionary:
		var d: Dictionary = value
		return Vector2(float(d.get("x", 0.0)), float(d.get("y", 0.0)))
	return Vector2.ZERO

func _ensure_fade_rect() -> ColorRect:
	if is_instance_valid(_fade_rect):
		return _fade_rect
	var layer := CanvasLayer.new()
	layer.layer = 90
	add_child(layer)
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0.0, 0.0, 0.0, 0.0)
	_fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_fade_rect)
	return _fade_rect

func _game_state() -> Node:
	var root_node: Node = get_tree().root
	return root_node.get_node("GameState") if root_node.has_node("GameState") else null

func _has_seen(cutscene_id: String) -> bool:
	var root_node: Node = get_tree().root
	if not root_node.has_node("CutsceneSkip"):
		return false
	return bool(root_node.get_node("CutsceneSkip").call("has_seen", cutscene_id))

func _finish() -> void:
	cutscene_active = false
	_skipping = false
	_current_tween = null
	_actor_root = null
	_document = {}
	cutscene_ended.emit()
