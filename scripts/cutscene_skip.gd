extends Node

const SAVE_PATH := "user://seen_cutscenes.json"

var _seen: Dictionary = {}
var _skip_label: Label

func _ready() -> void:
	_load_seen()
	_build_skip_ui()
	CutsceneManager.cutscene_started.connect(_on_cutscene_started)
	CutsceneManager.cutscene_ended.connect(_on_cutscene_ended)

func has_seen(cutscene_id: String) -> bool:
	return _seen.get(cutscene_id, false)

func mark_seen(cutscene_id: String) -> void:
	_seen[cutscene_id] = true
	_save_seen()

func _on_cutscene_started(cutscene_id: String) -> void:
	if not cutscene_id.is_empty() and has_seen(cutscene_id):
		_skip_label.visible = true

func _on_cutscene_ended() -> void:
	_skip_label.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if not _skip_label.visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_Z:
			get_viewport().set_input_as_handled()
			CutsceneManager.skip()

func _build_skip_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(root)

	_skip_label = Label.new()
	_skip_label.text = "[ Z ] Skip"
	_skip_label.anchor_left = 1.0
	_skip_label.anchor_right = 1.0
	_skip_label.anchor_top = 0.0
	_skip_label.anchor_bottom = 0.0
	_skip_label.set_offset(SIDE_LEFT, -80)
	_skip_label.set_offset(SIDE_RIGHT, -6)
	_skip_label.set_offset(SIDE_TOP, 6)
	_skip_label.set_offset(SIDE_BOTTOM, 22)
	_skip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_skip_label.visible = false
	root.add_child(_skip_label)

func _load_seen() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		_seen = {}
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("CutsceneSkip: could not read '%s', treating all as unseen." % SAVE_PATH)
		_seen = {}
		return
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK:
		push_error("CutsceneSkip: malformed JSON in '%s', resetting." % SAVE_PATH)
		_seen = {}
		_save_seen()
		return
	var data = json.get_data()
	if data is Dictionary:
		_seen = data
	else:
		push_error("CutsceneSkip: unexpected format in '%s', resetting." % SAVE_PATH)
		_seen = {}
		_save_seen()

func _save_seen() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("CutsceneSkip: could not write to '%s'" % SAVE_PATH)
		return
	file.store_string(JSON.stringify(_seen))
	file.close()
