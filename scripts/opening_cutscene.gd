extends Node2D

func _ready() -> void:
	call_deferred("_start")

func _start() -> void:
	var player := get_node("../Player") as CharacterBody2D
	if player == null:
		push_error("OpeningCutscene: could not find Player node.")
		return
	var sprite := player.get_node("AnimatedSprite2D") as AnimatedSprite2D
	if sprite == null:
		push_error("OpeningCutscene: could not find Player/AnimatedSprite2D.")
		return

	player.position = Vector2(48, 64)

	var beats: Array = [
		# Patch at workbench, finishing the last sphere
		{"type": "animation", "node": sprite, "animation": "idle_down"},
		{"type": "wait", "duration": 0.5},
		# Polishing motion: brief walk_up then settle idle_up
		{"type": "animation", "node": sprite, "animation": "walk_up"},
		{"type": "wait", "duration": 0.5},
		{"type": "animation", "node": sprite, "animation": "idle_up"},
		{"type": "wait", "duration": 1.0},
		{"type": "dialogue", "dialogue_id": "opening_workbench"},
		# Walk to table
		{"type": "animation", "node": sprite, "animation": "walk_right"},
		{"type": "move", "node": player, "target": Vector2(160, 96), "speed": 60.0},
		{"type": "animation", "node": sprite, "animation": "idle_down"},
		{"type": "wait", "duration": 0.5},
		{"type": "dialogue", "dialogue_id": "opening_table"},
		{"type": "wait", "duration": 0.5},
		# Glance at calendar (deliver in place)
		{"type": "dialogue", "dialogue_id": "opening_calendar"},
		# Walk to door (south wall gap)
		{"type": "animation", "node": sprite, "animation": "walk_down"},
		{"type": "move", "node": player, "target": Vector2(160, 210), "speed": 80.0},
		{"type": "animation", "node": sprite, "animation": "idle_down"},
		{"type": "wait", "duration": 0.3},
		{"type": "dialogue", "dialogue_id": "opening_date_shout"},
		{"type": "wait", "duration": 0.5},
		{"type": "dialogue", "dialogue_id": "opening_voices"},
		{"type": "wait", "duration": 0.8},
		{"type": "dialogue", "dialogue_id": "opening_nine_days"},
		{"type": "wait", "duration": 1.0},
		{"type": "dialogue", "dialogue_id": "opening_depart"},
		# Walk back toward workshop center
		{"type": "animation", "node": sprite, "animation": "walk_up"},
		{"type": "move", "node": player, "target": Vector2(160, 120), "speed": 60.0},
		{"type": "animation", "node": sprite, "animation": "idle_down"},
		{"type": "wait", "duration": 0.5},
		{"type": "end"},
	]

	CutsceneManager.cutscene_ended.connect(_on_cutscene_ended, CONNECT_ONE_SHOT)
	CutsceneManager.play_cutscene(beats, "opening")

func _on_cutscene_ended() -> void:
	CutsceneSkip.mark_seen("opening")
