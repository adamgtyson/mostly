extends Node

signal dialogue_started
signal dialogue_ended

var dialogue_active: bool = false

var _lines: Array = []
var _current_index: int = 0

func _ready() -> void:
	var box_scene = load("res://scenes/dialogue_box.tscn")
	if box_scene == null:
		push_error("DialogueManager: could not load res://scenes/dialogue_box.tscn")
		return
	add_child(box_scene.instantiate())

func start_dialogue(dialogue_id: String) -> void:
	if dialogue_id.is_empty():
		push_warning("DialogueManager: interactable has no dialogue_id set, ignoring.")
		return
	var path := "res://data/dialogue/%s.json" % dialogue_id
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("DialogueManager: could not open '%s'" % path)
		return
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK:
		push_error("DialogueManager: JSON parse error in '%s'" % path)
		return
	var data = json.get_data()
	if not (data is Dictionary):
		push_error("DialogueManager: root is not a Dictionary in '%s'" % path)
		return
	if not data.has("lines"):
		push_error("DialogueManager: no 'lines' key in '%s'" % path)
		return
	var lines = data["lines"]
	if not (lines is Array) or lines.is_empty():
		push_error("DialogueManager: 'lines' is empty or invalid in '%s'" % path)
		return
	_lines = lines
	_current_index = 0
	dialogue_active = true
	dialogue_started.emit()

func get_current_line() -> Dictionary:
	if _current_index >= 0 and _current_index < _lines.size():
		return _lines[_current_index]
	return {}

func advance() -> void:
	if not dialogue_active:
		return
	_current_index += 1
	if _current_index >= _lines.size():
		dialogue_active = false
		_lines.clear()
		_current_index = 0
		dialogue_ended.emit()
