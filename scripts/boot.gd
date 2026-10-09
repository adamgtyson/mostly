extends Node

const NEW_GAME_SCENE := "res://scenes/new_game.tscn"

func _ready() -> void:
	# Scale the OS window to 4x the 320x180 viewport so the game is visible.
	# canvas_items stretch keeps pixel art crisp at any window size.
	DisplayServer.window_set_size(Vector2i(1280, 720))
	DisplayServer.window_set_position(
		DisplayServer.screen_get_position() + DisplayServer.screen_get_size() / 2 - Vector2i(640, 360)
	)
	# Routing waits a tick: autoloads ready before the main scene exists, so
	# current_scene is not knowable here.
	call_deferred("_route_fresh_boot")

## A fresh install boots into New Game instead of the bare workshop. Session 7,
## phase-3 slice: there is no title screen yet, so the rule is minimal — no
## save in any slot and no village chosen means this launch has never started
## a run. A later title/continue flow replaces this, it does not extend it.
func _route_fresh_boot() -> void:
	var tree: SceneTree = get_tree()
	# Script-driven SceneTrees (tests/run_tests.gd, tests/validate_data.gd)
	# must never have their scene swapped out from under them.
	if tree.get_script() != null:
		return
	if tree.current_scene == null:
		return
	if _a_run_exists():
		return
	tree.change_scene_to_file(NEW_GAME_SCENE)

func _a_run_exists() -> bool:
	var root_node: Node = get_tree().root
	if root_node.has_node("SaveManager"):
		if not (root_node.get_node("SaveManager").call("list_slots") as Array).is_empty():
			return true
	if root_node.has_node("GameState"):
		if bool(root_node.get_node("GameState").call("has_flag", "sys.village")):
			return true
	return false
