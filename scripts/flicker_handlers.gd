class_name FlickerHandlers
extends RefCounted

## FlickerHandlers (Docs/WEIRDNESS_SPEC.md §8) — what a flicker actually does.
##
## Weirdness decides *whether* and *where*; this decides *what the player sees*.
## The split is the same pattern as Inventory's on_use registry: a catalog entry
## names a handler string, the registry maps it to a Callable, and adding a kind
## is a data change plus one registration — never a new autoload or a new signal.
##
## Every handler obeys §6 without exception: it sets no flag, writes nothing to
## a save, never touches collision, and cannot block, redirect or damage. Visual
## flickers last at most 0.25s (≤ 6 frames at 24fps); audio at most 1.5s; the
## npc_line bubble is the one longer case the spec allows, because it is text
## (§1: 2.0s).
##
## Art is programmatic by rule while EC-12a (the Mana Seed EULA gate) is OPEN:
## placeholders are generated in code — an ImageTexture filled in memory, the
## same technique as the workshop cat — and every placeholder node joins the
## `placeholder` group so the visibility test can find it.

## Nodes this registry spawns are tagged so they are findable and auditable.
const PLACEHOLDER_GROUP := "placeholder"

## §6 rule 5: a visual flicker is ~6 frames, a bubble is 2 seconds.
const SPRITE_EDGE_FRAMES := 6
const TILE_BLINK_FRAMES := 2
const WRONG_FRAME_FRAMES := 1
const LIGHT_SKIP_FRAMES := 1
const NPC_LINE_SECONDS := 2.0

## "Gone if the camera moves toward it" (§1): any camera movement past this
## many pixels while the figure is up removes it immediately.
const CAMERA_MOVE_TOLERANCE_PX := 2.0

## Ambient modulate dips by this much for a frame (§1 light_skip).
const LIGHT_SKIP_DIP := 0.03

## handler name -> Callable(spot: Node, params: Dictionary)
var _handlers: Dictionary = {}

## Every dispatch this run, for the harness: {kind, handler, spot}. Never
## persisted, never read by the game — the design says flickers are not logged.
var _calls: Array[Dictionary] = []

## The handler names the v1 catalog may name (§8). `log` is the no-op the
## deferred kinds and the tests use.
static func known_handlers() -> PackedStringArray:
	return PackedStringArray([
		"log",
		"sprite_edge",
		"tile_blink",
		"npc_wrong_frame",
		"sound_offstage",
		"light_skip",
		"npc_line",
	])

func _init() -> void:
	register("log", _handle_log)
	register("sprite_edge", _handle_sprite_edge)
	register("tile_blink", _handle_tile_blink)
	register("npc_wrong_frame", _handle_npc_wrong_frame)
	register("sound_offstage", _handle_sound_offstage)
	register("light_skip", _handle_light_skip)
	register("npc_line", _handle_npc_line)

func register(handler_name: String, handler: Callable) -> void:
	_handlers[handler_name] = handler

func has(handler_name: String) -> bool:
	return _handlers.has(handler_name)

func handler_names() -> Array:
	return _handlers.keys()

func calls() -> Array[Dictionary]:
	return _calls.duplicate(true)

func clear_calls() -> void:
	_calls.clear()

# ── dispatch ─────────────────────────────────────────────────────────────────

## Connected to Weirdness.flicker_requested. A missing handler or a spot that is
## not in a tree is a warning, never an error: a flicker failing to draw must
## never take a playtest down with it.
func dispatch(kind: String, spot: Node, params: Dictionary) -> void:
	var handler_name: String = str(params.get("handler", kind))
	_calls.append({"kind": kind, "handler": handler_name, "spot": str(spot.name) if is_instance_valid(spot) else ""})
	if not _handlers.has(handler_name):
		push_warning("FlickerHandlers: no handler '%s' for kind '%s'" % [handler_name, kind])
		return
	if not is_instance_valid(spot) or spot.get_tree() == null:
		# Unit tests register detached spots; nothing can be drawn against one.
		return
	await (_handlers[handler_name] as Callable).call(spot, params)

# ── handlers ─────────────────────────────────────────────────────────────────

func _handle_log(_spot: Node, _params: Dictionary) -> void:
	pass

## A figure at the viewport edge for ~6 frames. It is a generated 16x16 square
## until EC-12a is settled and real art exists.
func _handle_sprite_edge(spot: Node, params: Dictionary) -> void:
	if not (spot is Node2D):
		return
	var sprite := Sprite2D.new()
	sprite.name = "FlickerSpriteEdge"
	sprite.texture = make_placeholder_texture(16, 16, Color(0.16, 0.15, 0.2))
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.z_index = int(params.get("z_index", 10))
	sprite.add_to_group(PLACEHOLDER_GROUP)
	spot.add_child(sprite)

	var camera: Camera2D = spot.get_viewport().get_camera_2d()
	var origin: Vector2 = camera.global_position if camera != null else Vector2.ZERO
	for _i: int in SPRITE_EDGE_FRAMES:
		if not is_instance_valid(sprite):
			return
		if camera != null and camera.global_position.distance_to(origin) > CAMERA_MOVE_TOLERANCE_PX:
			break
		await spot.get_tree().process_frame
	if is_instance_valid(sprite):
		sprite.queue_free()

## One tile swaps to a wrong-but-plausible neighbour for 2 frames, then restores.
## The neighbour is authored in the spot's params — the handler never invents a
## tile, because a wrong guess reads as a bug rather than a flicker.
func _handle_tile_blink(spot: Node, params: Dictionary) -> void:
	var layer: TileMapLayer = _resolve(spot, params.get("layer_path", "")) as TileMapLayer
	if layer == null or not params.has("cell") or not params.has("source_id") or not params.has("atlas_coords"):
		push_warning("FlickerHandlers: tile_blink needs layer_path, cell, source_id and atlas_coords")
		return
	var cell: Vector2i = _to_vector2i(params["cell"])
	var previous_source: int = layer.get_cell_source_id(cell)
	var previous_atlas: Vector2i = layer.get_cell_atlas_coords(cell)
	var previous_alternative: int = layer.get_cell_alternative_tile(cell)

	layer.set_cell(cell, int(params["source_id"]), _to_vector2i(params["atlas_coords"]))
	for _i: int in TILE_BLINK_FRAMES:
		await spot.get_tree().process_frame
	if not is_instance_valid(layer):
		return
	if previous_source < 0:
		layer.erase_cell(cell)
	else:
		layer.set_cell(cell, previous_source, previous_atlas, previous_alternative)

## An idle NPC faces the wrong way, or shows one frame from somewhere else, for
## a single frame.
func _handle_npc_wrong_frame(spot: Node, params: Dictionary) -> void:
	var sprite: AnimatedSprite2D = _resolve(spot, params.get("npc_path", "")) as AnimatedSprite2D
	if sprite == null:
		push_warning("FlickerHandlers: npc_wrong_frame needs npc_path to an AnimatedSprite2D")
		return
	var was_flipped: bool = sprite.flip_h
	var previous_frame: int = sprite.frame
	var frame_count: int = 0
	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation(sprite.animation):
		frame_count = sprite.sprite_frames.get_frame_count(sprite.animation)
	if frame_count > 1:
		sprite.frame = (previous_frame + 1) % frame_count
	else:
		sprite.flip_h = not was_flipped

	for _i: int in WRONG_FRAME_FRAMES:
		await spot.get_tree().process_frame
	if not is_instance_valid(sprite):
		return
	sprite.flip_h = was_flipped
	if frame_count > 1:
		sprite.frame = previous_frame

## A non-positional one-shot: a bell where there is no bell. Audio arrives with
## content, so an unconfigured spot plays a generated blip rather than silently
## doing nothing — the path stays exercised either way.
func _handle_sound_offstage(spot: Node, params: Dictionary) -> void:
	var stream: AudioStream = null
	var stream_path: String = str(params.get("stream", ""))
	if not stream_path.is_empty() and ResourceLoader.exists(stream_path):
		var loaded: Variant = load(stream_path)
		if loaded is AudioStream:
			stream = loaded
	if stream == null:
		stream = make_placeholder_blip()

	var player := AudioStreamPlayer.new()
	player.name = "FlickerSoundOffstage"
	player.stream = stream
	player.add_to_group(PLACEHOLDER_GROUP)
	spot.add_child(player)
	player.play()
	await spot.get_tree().create_timer(minf(1.5, stream.get_length() if stream.get_length() > 0.0 else 0.2)).timeout
	if is_instance_valid(player):
		player.queue_free()

## Ambient modulate dips 3% for one frame. A scene with no CanvasModulate gets a
## white one, which changes nothing until the dip.
func _handle_light_skip(spot: Node, params: Dictionary) -> void:
	var modulate_node: CanvasModulate = _ensure_canvas_modulate(spot)
	if modulate_node == null:
		return
	var dip: float = 1.0 - float(params.get("dip", LIGHT_SKIP_DIP))
	var previous: Color = modulate_node.color
	modulate_node.color = Color(previous.r * dip, previous.g * dip, previous.b * dip, previous.a)
	for _i: int in LIGHT_SKIP_FRAMES:
		await spot.get_tree().process_frame
	if is_instance_valid(modulate_node):
		modulate_node.color = previous

## An idle bubble above an NPC — never the dialogue box, never logged, never the
## same line twice in a run. Weirdness owns the pool and the used-id set.
func _handle_npc_line(spot: Node, params: Dictionary) -> void:
	var target: Node = _resolve(spot, params.get("npc_path", ""))
	if target == null:
		target = spot
	if not (target is Node2D):
		return
	var line: Dictionary = pick_line(spot)
	var text: String = str(line.get("text", ""))
	if text.is_empty():
		# Pool exhausted: say nothing rather than repeat a line already heard.
		return

	var bubble := Label.new()
	bubble.name = "FlickerNpcLine"
	bubble.text = text
	bubble.position = Vector2(float(params.get("bubble_x", -48.0)), float(params.get("bubble_y", -28.0)))
	bubble.size = Vector2(96.0, 24.0)
	bubble.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bubble.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bubble.add_to_group(PLACEHOLDER_GROUP)
	(target as Node2D).add_child(bubble)
	await spot.get_tree().create_timer(NPC_LINE_SECONDS).timeout
	if is_instance_valid(bubble):
		bubble.queue_free()

## The selection half of npc_line, separated so a test can hammer it without a
## scene: it returns a line the current intensity allows and this run has not
## used, or {} once the pool is spent.
func pick_line(spot: Node) -> Dictionary:
	var tree: SceneTree = spot.get_tree() if is_instance_valid(spot) else null
	if tree == null or not tree.root.has_node("Weirdness"):
		return {}
	var line: Variant = tree.root.get_node("Weirdness").call("take_line")
	return line if line is Dictionary else {}

# ── programmatic placeholders (EC-12a is OPEN: no asset files) ───────────────

## A flat colour texture, generated in memory. The same technique as the
## workshop cat: no file is created, so no licensed art is involved.
static func make_placeholder_texture(width: int, height: int, color: Color) -> ImageTexture:
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)

## A short sine blip, generated in memory, so sound_offstage has something to
## play before any audio asset exists.
static func make_placeholder_blip(seconds: float = 0.2, hz: float = 440.0) -> AudioStreamWAV:
	var mix_rate: int = 22050
	var frame_count: int = int(mix_rate * seconds)
	var data := PackedByteArray()
	data.resize(frame_count * 2)
	for i: int in frame_count:
		# Fade the tail so the blip does not click when it stops.
		var envelope: float = 1.0 - (float(i) / float(frame_count))
		var sample: float = sin(TAU * hz * float(i) / float(mix_rate)) * envelope * 0.35
		var value: int = int(clampf(sample, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, value)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.stereo = false
	wav.data = data
	return wav

# ── helpers ──────────────────────────────────────────────────────────────────

## Resolves a params node path against the spot first, then the area root that
## owns it, so a spot can name either a sibling or a path from the area root.
func _resolve(spot: Node, value: Variant) -> Node:
	if value is Node:
		return value
	var path: String = str(value)
	if path.is_empty() or not is_instance_valid(spot):
		return null
	var found: Node = spot.get_node_or_null(NodePath(path))
	if found != null:
		return found
	if spot.owner != null:
		found = spot.owner.get_node_or_null(NodePath(path))
	if found == null:
		var scene: Node = spot.get_tree().current_scene if spot.get_tree() != null else null
		if scene != null:
			found = scene.get_node_or_null(NodePath(path))
	return found

func _ensure_canvas_modulate(spot: Node) -> CanvasModulate:
	var root_node: Node = spot.owner if spot.owner != null else spot.get_tree().current_scene
	if root_node == null:
		root_node = spot.get_parent()
	if root_node == null:
		return null
	for child: Node in root_node.get_children():
		if child is CanvasModulate:
			return child
	var created := CanvasModulate.new()
	created.name = "FlickerCanvasModulate"
	created.color = Color.WHITE
	root_node.add_child(created)
	return created

func _to_vector2i(value: Variant) -> Vector2i:
	if value is Vector2i:
		return value
	if value is Vector2:
		return Vector2i(value)
	if value is Array and (value as Array).size() >= 2:
		var a: Array = value
		return Vector2i(int(a[0]), int(a[1]))
	if value is Dictionary:
		var d: Dictionary = value
		return Vector2i(int(d.get("x", 0)), int(d.get("y", 0)))
	return Vector2i.ZERO
