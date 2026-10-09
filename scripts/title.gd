extends Control

## Title screen (session 8, Block A — assumed ruling, Adam may veto). Minimal
## by design: Continue when any save exists, New Game always. Continue loads
## the most recent slot through SaveManager — contributors restore themselves
## generically (§3) — then departs through SceneRouter, the single choke point
## (§6), to the saved area's default spawn — with misroute_eligible false:
## loading is not walking through an Exit, so a Continue never misroutes
## (session 9 assumed ruling).
##
## All copy is functional placeholder text pending BUILD_PLAN §4.12. The
## tagline is canon (Docs/00).

const NEW_GAME_SCENE := "res://scenes/new_game.tscn"

var _continue_button: Button = null
var _new_game_button: Button = null

func _ready() -> void:
	_build_ui()
	_apply_save_state()

# ── state ────────────────────────────────────────────────────────────────────

func has_any_save() -> bool:
	var sm: Node = _save_manager()
	if sm == null:
		return false
	return not (sm.call("list_slots") as Array).is_empty()

## The slot a Continue resumes: newest timestamp wins. SaveManager timestamps
## are ISO strings, so lexicographic order is chronological order.
func most_recent_slot() -> String:
	var sm: Node = _save_manager()
	if sm == null:
		return ""
	var best_slot: String = ""
	var best_stamp: String = ""
	for info: Variant in (sm.call("list_slots") as Array):
		if not (info is Dictionary):
			continue
		var stamp: String = str((info as Dictionary).get("timestamp", ""))
		if best_slot.is_empty() or stamp > best_stamp:
			best_slot = str((info as Dictionary).get("slot", ""))
			best_stamp = stamp
	return best_slot

# ── actions ──────────────────────────────────────────────────────────────────

## Loads the most recent save and departs to its area. Returns the destination,
## or {} when there is nothing to continue or the load fails. `depart` is the
## same test seam new_game.gd uses: the suite drives everything short of the
## transition itself.
func continue_game(depart: bool = true) -> Dictionary:
	var slot: String = most_recent_slot()
	if slot.is_empty():
		return {}
	var sm: Node = _save_manager()
	if sm == null or not bool(sm.call("load_from_slot", slot)):
		return {}

	var root_node: Node = get_tree().root
	if not root_node.has_node("SceneRouter"):
		push_error("Title: no SceneRouter to depart with")
		return {}
	var router: Node = root_node.get_node("SceneRouter")
	var destination: Dictionary = {
		"region": str(router.get("current_region")),
		"area": str(router.get("current_area")),
		"spawn": "default",
	}
	if str(destination["region"]).is_empty() or str(destination["area"]).is_empty():
		push_error("Title: save in slot '%s' restored no location" % slot)
		return {}
	if depart:
		# Loading is not walking through an Exit: never misroute a Continue
		# (session 9 assumed ruling).
		router.call("go_to", destination["region"], destination["area"], destination["spawn"], false)
	return destination

## New Game hands over to the selection screen. Returns the scene it opens.
func start_new_game(depart: bool = true) -> String:
	if depart:
		get_tree().change_scene_to_file(NEW_GAME_SCENE)
	return NEW_GAME_SCENE

# ── UI (programmatic; placeholder theme only) ───────────────────────────────

func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var column := VBoxContainer.new()
	column.name = "Menu"
	column.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	add_child(column)

	var title := Label.new()
	title.name = "GameTitle"
	title.text = "Mostly"
	column.add_child(title)

	var tagline := Label.new()
	tagline.name = "Tagline"
	tagline.text = "It's mostly fine."
	column.add_child(tagline)

	_continue_button = Button.new()
	_continue_button.name = "Continue"
	_continue_button.text = "Continue"
	_continue_button.pressed.connect(func() -> void: continue_game())
	column.add_child(_continue_button)

	_new_game_button = Button.new()
	_new_game_button.name = "NewGame"
	_new_game_button.text = "New Game"
	_new_game_button.pressed.connect(func() -> void: start_new_game())
	column.add_child(_new_game_button)

func _save_manager() -> Node:
	var root_node: Node = get_tree().root
	return root_node.get_node("SaveManager") if root_node.has_node("SaveManager") else null

## Continue only exists when there is something to continue; focus lands on
## the first visible option so keyboard/gamepad works with no pointer.
func _apply_save_state() -> void:
	var resumable: bool = has_any_save()
	_continue_button.visible = resumable
	if resumable:
		_continue_button.grab_focus()
	else:
		_new_game_button.grab_focus()
