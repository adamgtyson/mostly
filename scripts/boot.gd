extends Node

func _ready() -> void:
	# Scale the OS window to 4x the 320x180 viewport so the game is visible.
	# canvas_items stretch keeps pixel art crisp at any window size.
	DisplayServer.window_set_size(Vector2i(1280, 720))
	DisplayServer.window_set_position(
		DisplayServer.screen_get_position() + DisplayServer.screen_get_size() / 2 - Vector2i(640, 360)
	)
