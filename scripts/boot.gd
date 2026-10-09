extends Node

const TITLE_SCENE := "res://scenes/title.tscn"

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

## Every windowed boot opens on the title screen (session 8, Block A), which
## owns the Continue/New Game decision — session 7's save-sniffing rule lived
## here only while no title existed. The workshop stays the engine's main
## scene; its opening trigger is gated on sys.village, so the one pre-route
## frame starts nothing.
func _route_fresh_boot() -> void:
	var tree: SceneTree = get_tree()
	# Script-driven SceneTrees (tests/run_tests.gd, tests/validate_data.gd)
	# must never have their scene swapped out from under them.
	if tree.get_script() != null:
		return
	if tree.current_scene == null:
		return
	tree.change_scene_to_file(TITLE_SCENE)
