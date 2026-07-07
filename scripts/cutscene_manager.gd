extends Node

signal cutscene_started(cutscene_id: String)
signal cutscene_ended

var cutscene_active: bool = false

var _skipping: bool = false
var _current_tween: Tween = null

func play_cutscene(beats: Array, cutscene_id: String = "") -> void:
	if cutscene_active:
		push_warning("CutsceneManager: play_cutscene called while already active, ignoring.")
		return
	cutscene_active = true
	_skipping = false
	cutscene_started.emit(cutscene_id)

	for beat in beats:
		if _skipping:
			break
		await _execute_beat(beat)

	_finish()

func skip() -> void:
	if not cutscene_active or _skipping:
		return
	_skipping = true
	if _current_tween and _current_tween.is_valid():
		_current_tween.kill()
		_current_tween = null
	if DialogueManager.dialogue_active:
		DialogueManager.force_end()

func _execute_beat(beat: Dictionary) -> void:
	var beat_type: String = beat.get("type", "")
	match beat_type:
		"wait":
			await _beat_wait(beat.get("duration", 0.0))
		"move":
			await _beat_move(beat)
		"animation":
			_beat_animation(beat)
		"dialogue":
			await _beat_dialogue(beat.get("dialogue_id", ""))
		"end":
			pass
		_:
			push_error("CutsceneManager: unknown beat type '%s'" % beat_type)

func _beat_wait(duration: float) -> void:
	var timer := get_tree().create_timer(duration)
	while timer.time_left > 0.0 and not _skipping:
		await get_tree().process_frame

func _beat_move(beat: Dictionary) -> void:
	var node: Node2D = beat.get("node", null)
	if not is_instance_valid(node):
		push_error("CutsceneManager: move beat has null or invalid node.")
		return
	var target: Vector2 = beat.get("target", node.position)
	var speed: float = beat.get("speed", 80.0)
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
	var node: AnimatedSprite2D = beat.get("node", null)
	var animation: String = beat.get("animation", "")
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

func _finish() -> void:
	cutscene_active = false
	_skipping = false
	_current_tween = null
	cutscene_ended.emit()
