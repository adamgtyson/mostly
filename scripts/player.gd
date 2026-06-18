extends CharacterBody2D

const SPEED := 80.0

# Last non-zero movement direction; used for idle animation and interaction probe
var facing_direction := Vector2.DOWN

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_area: Area2D = $InteractionArea

func _ready() -> void:
	_build_sprite_frames()
	animated_sprite.play("idle_down")

func _physics_process(_delta: float) -> void:
	if DialogueManager.dialogue_active:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Gather WASD + arrow input on both axes
	var dir := Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down")
	)

	if dir != Vector2.ZERO:
		velocity = dir.normalized() * SPEED
		facing_direction = dir
		_play_anim(dir, true)
	else:
		velocity = Vector2.ZERO
		_play_anim(facing_direction, false)

	move_and_slide()
	_reposition_interaction_probe()

func _input(event: InputEvent) -> void:
	# Interact key: Z or Enter, no repeat
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_Z or event.physical_keycode == KEY_ENTER:
			if DialogueManager.dialogue_active:
				return
			_try_interact()
			# Consume the event so dialogue_box._unhandled_input doesn't also fire
			if DialogueManager.dialogue_active:
				get_viewport().set_input_as_handled()

# ── Animation ────────────────────────────────────────────────────────────────

func _play_anim(dir: Vector2, walking: bool) -> void:
	var prefix := "walk" if walking else "idle"
	var suffix: String
	# Choose cardinal direction from dominant axis
	if abs(dir.x) >= abs(dir.y):
		suffix = "_right" if dir.x > 0.0 else "_left"
	else:
		suffix = "_down" if dir.y > 0.0 else "_up"
	var anim := prefix + suffix
	# Only restart the animation if it has actually changed
	if animated_sprite.animation != anim:
		animated_sprite.play(anim)

func _build_sprite_frames() -> void:
	# char_a_p1_0bas_humn_v00.png: 512x512, 8 cols x 8 rows, each frame 64x64
	# Row order per section: Down(0), Left(1), Right(2), Up(3)
	# Top 4 rows  → stand (col 0 only) used for idle
	# Bottom 4 rows → walk cols 0-5, run cols 6-7 (run unused this session)
	var tex: Texture2D = load("res://assets/characters/char_a_p1_0bas_humn_v00.png")
	if tex == null:
		push_error("Player sprite not found — open the project in the Godot editor once to import assets.")
		return
	const FW := 64  # frame width
	const FH := 64  # frame height
	var dirs: Array[String] = ["down", "up", "right", "left"]
	var frames := SpriteFrames.new()

	# Idle: one frame per direction from column 0 of the top half
	for i in dirs.size():
		var anim: String = "idle_" + dirs[i]
		frames.add_animation(anim)
		frames.set_animation_loop(anim, true)
		frames.set_animation_speed(anim, 5.0)
		var atlas := AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(0, i * FH, FW, FH)
		frames.add_frame(anim, atlas)

	# Walk: 6 frames per direction from columns 0-5 of the bottom half (rows 4-7)
	for i in dirs.size():
		var anim: String = "walk_" + dirs[i]
		frames.add_animation(anim)
		frames.set_animation_loop(anim, true)
		frames.set_animation_speed(anim, 8.0)
		for col in range(6):
			var atlas := AtlasTexture.new()
			atlas.atlas = tex
			atlas.region = Rect2(col * FW, (4 + i) * FH, FW, FH)
			frames.add_frame(anim, atlas)

	animated_sprite.sprite_frames = frames

# ── Interaction ───────────────────────────────────────────────────────────────

func _reposition_interaction_probe() -> void:
	# Snap facing to its dominant cardinal axis and project 12px in front
	var cardinal: Vector2
	if abs(facing_direction.x) >= abs(facing_direction.y):
		cardinal = Vector2(sign(facing_direction.x), 0.0)
	else:
		cardinal = Vector2(0.0, sign(facing_direction.y))
	interaction_area.position = cardinal * 12.0

func _try_interact() -> void:
	for area in interaction_area.get_overlapping_areas():
		if area.has_method("interact"):
			area.interact()
			return
