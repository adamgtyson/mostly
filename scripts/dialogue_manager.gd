extends Node

## DialogueManager — dialogue schema v2 (ENGINEERING_CONSTRAINTS.md §5).
##
## A dialogue file is a node graph:
##   { "id", "entries": [{"when", "start"}], "nodes": {id: {lines, choices?, set?, next?}} }
## `entries` is evaluated top-down and the first match wins, so the last entry
## carries "when": "true".
##
## The v1 flat shape {"id", "lines": [...]} is still accepted and is wrapped as a
## single node named "start", so nothing breaks mid-transition.
##
## get_current_line() returns a *resolved* line — speaker id turned into its
## display name, gender tokens substituted, portrait defaulted from the character
## registry — so the dialogue box renders a v2 line exactly as it rendered a v1 one.

signal dialogue_started
signal dialogue_ended
signal choices_presented(choices: Array)
signal node_entered(node_id: String)

const DIALOGUE_DIR := "res://data/dialogue"
const CHARACTERS_PATH := "res://data/characters.json"

## Gender token -> [masculine, feminine] (§5).
const GENDER_TOKENS: Dictionary = {
	"{he/she}": ["he", "she"],
	"{him/her}": ["him", "her"],
	"{his/her}": ["his", "her"],
	"{his/hers}": ["his", "hers"],
	"{himself/herself}": ["himself", "herself"],
}

## Which of Patch's genders authored pronouns resolve to. The New Game screen
## (phase 3) writes this; with it unset the substitutor falls back to masculine,
## an engineering default, not a canon statement.
const GENDER_FLAG := "sys.patch_gender"

## Guards a chain of empty nodes pointing at each other.
const MAX_NODE_HOPS := 64

var dialogue_active: bool = false

var _characters: Dictionary = {}
var _document: Dictionary = {}
var _node_id: String = ""
var _lines: Array = []
var _current_index: int = 0
var _choices: Array = []
var _awaiting_choice: bool = false

func _ready() -> void:
	_load_characters()
	var box_scene: Variant = load("res://scenes/dialogue_box.tscn")
	if box_scene == null:
		push_error("DialogueManager: could not load res://scenes/dialogue_box.tscn")
		return
	add_child((box_scene as PackedScene).instantiate())

# ── starting ─────────────────────────────────────────────────────────────────

func start_dialogue(dialogue_id: String) -> void:
	if dialogue_id.is_empty():
		push_warning("DialogueManager: interactable has no dialogue_id set, ignoring.")
		return
	var document: Dictionary = load_document(dialogue_id)
	if document.is_empty():
		return
	start_document(document)

## Loads and normalizes a dialogue file. Returns {} if it cannot be used.
func load_document(dialogue_id: String) -> Dictionary:
	var path: String = "%s/%s.json" % [DIALOGUE_DIR, dialogue_id]
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("DialogueManager: could not open '%s'" % path)
		return {}
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK:
		push_error("DialogueManager: JSON parse error in '%s'" % path)
		return {}
	var data: Variant = json.get_data()
	if not (data is Dictionary):
		push_error("DialogueManager: root is not a Dictionary in '%s'" % path)
		return {}
	return normalize(data, dialogue_id)

## Brings either schema to the v2 shape. A v1 file becomes one node named
## "start" reached by a single always-true entry.
func normalize(data: Dictionary, dialogue_id: String = "") -> Dictionary:
	if data.has("nodes"):
		return data
	if not data.has("lines"):
		push_error("DialogueManager: '%s' has neither 'nodes' nor 'lines'" % dialogue_id)
		return {}
	var lines: Variant = data["lines"]
	if not (lines is Array) or (lines as Array).is_empty():
		push_error("DialogueManager: 'lines' is empty or invalid in '%s'" % dialogue_id)
		return {}
	return {
		"id": str(data.get("id", dialogue_id)),
		"entries": [{"when": "true", "start": "start"}],
		"nodes": {"start": {"lines": lines}},
	}

func start_document(document: Dictionary) -> void:
	var start_node: String = select_entry(document)
	if start_node.is_empty():
		push_error("DialogueManager: no entry matched in '%s'" % str(document.get("id", "?")))
		return
	_document = document
	_choices = []
	_awaiting_choice = false
	dialogue_active = true
	_enter_node(start_node)
	if not dialogue_active:
		# The whole dialogue resolved to nothing; never announce it.
		return
	dialogue_started.emit()

## First entry whose condition holds (§5). "" if none does.
func select_entry(document: Dictionary) -> String:
	var entries: Variant = document.get("entries", [])
	if not (entries is Array):
		return ""
	for entry: Variant in entries:
		if not (entry is Dictionary):
			continue
		var e: Dictionary = entry
		if Condition.evaluate(str(e.get("when", "true")), _flag_getter()):
			return str(e.get("start", ""))
	return ""

# ── walking the graph ────────────────────────────────────────────────────────

func _enter_node(node_id: String, hops: int = 0) -> void:
	if hops > MAX_NODE_HOPS:
		push_error("DialogueManager: node chain from '%s' is too long; ending" % node_id)
		_end()
		return
	var nodes: Dictionary = _document.get("nodes", {})
	if not nodes.has(node_id):
		push_error("DialogueManager: no node '%s' in '%s'" % [node_id, str(_document.get("id", "?"))])
		_end()
		return

	_node_id = node_id
	var node: Dictionary = nodes[node_id]
	_apply_sets(node)

	var lines: Variant = node.get("lines", [])
	_lines = lines if lines is Array else []
	_current_index = 0
	node_entered.emit(node_id)

	if _lines.is_empty():
		_leave_node(hops)

## Applies the node's set[] on entry (§5).
func _apply_sets(node: Dictionary) -> void:
	var sets: Variant = node.get("set", [])
	if not (sets is Array):
		return
	var state: Node = _game_state()
	if state == null:
		return
	for entry: Variant in sets:
		if not (entry is Dictionary):
			continue
		var e: Dictionary = entry
		var key: String = str(e.get("flag", ""))
		if key.is_empty():
			continue
		if e.has("increment"):
			state.call("increment", key, int(e["increment"]))
		else:
			state.call("set_flag", key, e.get("value", true))

func advance() -> void:
	if not dialogue_active or _awaiting_choice:
		return
	_current_index += 1
	if _current_index < _lines.size():
		return
	_leave_node(0)

## Lines are exhausted: offer choices, follow `next`, or end.
func _leave_node(hops: int) -> void:
	var nodes: Dictionary = _document.get("nodes", {})
	var node: Dictionary = nodes.get(_node_id, {})

	var available: Array = available_choices(node)
	if not available.is_empty():
		_choices = available
		_awaiting_choice = true
		choices_presented.emit(available)
		return

	var next_id: String = str(node.get("next", ""))
	if not next_id.is_empty():
		_enter_node(next_id, hops + 1)
		return

	_end()

## Choices whose `when` holds, resolved for display (§5).
func available_choices(node: Dictionary) -> Array:
	var out: Array = []
	var choices: Variant = node.get("choices", [])
	if not (choices is Array):
		return out
	for choice: Variant in choices:
		if not (choice is Dictionary):
			continue
		var c: Dictionary = choice
		if not Condition.evaluate(str(c.get("when", "true")), _flag_getter()):
			continue
		out.append({
			"text": resolve_text(c),
			"next": str(c.get("next", "")),
		})
	return out

func get_current_choices() -> Array:
	return _choices

func awaiting_choice() -> bool:
	return _awaiting_choice

func choose(index: int) -> void:
	if not _awaiting_choice:
		return
	if index < 0 or index >= _choices.size():
		push_error("DialogueManager: choice %d is out of range" % index)
		return
	var chosen: Dictionary = _choices[index]
	_choices = []
	_awaiting_choice = false
	var next_id: String = str(chosen.get("next", ""))
	if next_id.is_empty():
		_end()
		return
	_enter_node(next_id)

# ── reading the current line ─────────────────────────────────────────────────

func get_current_line() -> Dictionary:
	if _current_index < 0 or _current_index >= _lines.size():
		return {}
	return resolve_line(_lines[_current_index])

## Turns an authored line into what the box shows: display name, substituted
## text, portrait. An unknown speaker id passes through as its own display name,
## which is what keeps un-migrated v1 files rendering unchanged.
func resolve_line(line: Dictionary) -> Dictionary:
	var speaker_id: String = str(line.get("speaker", ""))
	var character: Dictionary = _characters.get(speaker_id, {})
	return {
		"speaker": str(character.get("display_name", speaker_id)),
		"speaker_id": speaker_id,
		"text": resolve_text(line),
		"portrait": str(line.get("portrait", character.get("default_portrait", ""))),
	}

## text_f wins when it exists and Patch is female; otherwise inline gender tokens
## are substituted. Full duplicate lines are the escape hatch, not the default.
func resolve_text(line: Dictionary) -> String:
	var feminine: bool = is_feminine()
	if feminine and line.has("text_f"):
		return str(line["text_f"])
	return substitute_gender(str(line.get("text", "")), feminine)

static func substitute_gender(text: String, feminine: bool) -> String:
	var out: String = text
	for token: String in GENDER_TOKENS:
		var pair: Array = GENDER_TOKENS[token]
		out = out.replace(token, str(pair[1] if feminine else pair[0]))
	return out

func is_feminine() -> bool:
	var state: Node = _game_state()
	if state == null:
		return false
	return str(state.call("get_flag", GENDER_FLAG, "m")).to_lower().begins_with("f")

# ── ending ───────────────────────────────────────────────────────────────────

## Ends any active dialogue immediately, without walking the rest of the graph.
func force_end() -> void:
	if not dialogue_active:
		return
	_end()

func _end() -> void:
	var was_active: bool = dialogue_active
	dialogue_active = false
	_document = {}
	_node_id = ""
	_lines = []
	_current_index = 0
	_choices = []
	_awaiting_choice = false
	if was_active:
		dialogue_ended.emit()

func reset() -> void:
	dialogue_active = false
	_document = {}
	_node_id = ""
	_lines = []
	_current_index = 0
	_choices = []
	_awaiting_choice = false

# ── characters ───────────────────────────────────────────────────────────────

func character(character_id: String) -> Dictionary:
	return _characters.get(character_id, {})

func has_character(character_id: String) -> bool:
	return _characters.has(character_id)

func character_ids() -> Array:
	return _characters.keys()

func current_node_id() -> String:
	return _node_id

func _load_characters() -> void:
	_characters = {}
	if not FileAccess.file_exists(CHARACTERS_PATH):
		push_warning("DialogueManager: no character registry at %s" % CHARACTERS_PATH)
		return
	var file := FileAccess.open(CHARACTERS_PATH, FileAccess.READ)
	if file == null:
		return
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK:
		push_error("DialogueManager: malformed JSON in %s" % CHARACTERS_PATH)
		return
	var data: Variant = json.get_data()
	if not (data is Dictionary):
		return
	var characters: Variant = (data as Dictionary).get("characters", {})
	if characters is Dictionary:
		_characters = characters

func _game_state() -> Node:
	var root_node: Node = get_tree().root
	return root_node.get_node("GameState") if root_node.has_node("GameState") else null

func _flag_getter() -> Callable:
	var state: Node = _game_state()
	if state == null:
		return func(_flag: String) -> Variant: return null
	return func(flag: String) -> Variant: return state.call("get_flag", flag, null)
