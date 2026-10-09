extends Node

## Boot (§13): window setup, the one route into the title screen, and the
## real-boot smoke mode (session 9) — the only harness that runs the actual
## autoload/main-scene/scene-swap path instead of instantiating scenes by hand.

const TITLE_SCENE := "res://scenes/title.tscn"

const SMOKE_DEFAULT_FRAMES := 180
## A hard internal deadline so a parked await still produces a report.
const SMOKE_DEADLINE_MS := 25000

## What _route_fresh_boot decided, for debug_summary and the smoke report.
var _route_result: String = "not run"

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
	if smoke_requested(OS.get_cmdline_user_args()):
		call_deferred("_run_smoke")

## Every windowed boot opens on the title screen (session 8), which owns the
## Continue/New Game decision.
func _route_fresh_boot() -> void:
	var tree: SceneTree = get_tree()
	# Script-driven SceneTrees (tests/run_tests.gd, tests/validate_data.gd)
	# must never have their scene swapped out from under them.
	if tree.get_script() != null:
		_route_result = "skipped: scripted SceneTree"
		return
	if tree.current_scene == null:
		_route_result = "skipped: no current_scene"
		return
	if tree.current_scene.scene_file_path == TITLE_SCENE:
		_route_result = "already on title"
		return
	var err: int = tree.change_scene_to_file(TITLE_SCENE)
	_route_result = "changed to title (err=%d)" % err

func debug_summary() -> String:
	return "route: %s" % _route_result

# ── smoke mode (session 9, Block A) ─────────────────────────────────────────
## Activated ONLY by the user arg --smoke (after `--` on the command line),
## never by default:  godot --headless --path . -- --smoke [--smoke-frames=N]
## Boot runs its normal path; after N frames the tree's actual state is
## printed and the process exits 0 (healthy) or 2 (no scene, an area as the
## scene, or nothing visible). Headless executes the full boot path — only
## rendering is skipped — so a wrong tree reproduces here.

static func smoke_requested(user_args: PackedStringArray) -> bool:
	return user_args.has("--smoke")

static func smoke_frames(user_args: PackedStringArray) -> int:
	for arg: String in user_args:
		if arg.begins_with("--smoke-frames="):
			var value: int = arg.trim_prefix("--smoke-frames=").to_int()
			if value > 0:
				return value
	return SMOKE_DEFAULT_FRAMES

func _run_smoke() -> void:
	var frames: int = smoke_frames(OS.get_cmdline_user_args())
	var started: int = Time.get_ticks_msec()
	for _i: int in frames:
		if Time.get_ticks_msec() - started > SMOKE_DEADLINE_MS:
			print("[smoke] DEADLINE: %d ms elapsed before %d frames ran" % [SMOKE_DEADLINE_MS, frames])
			break
		await get_tree().process_frame
	var healthy: bool = _smoke_report(frames)
	get_tree().quit(0 if healthy else 2)

## Prints the block and returns the health verdict.
func _smoke_report(frames: int) -> bool:
	var tree: SceneTree = get_tree()
	var scene: Node = tree.current_scene

	print("[smoke] ---- real-boot state after %d frame(s) ----" % frames)
	print("[smoke] main_scene setting: %s" % str(ProjectSettings.get_setting("application/run/main_scene")))
	print("[smoke] current_scene: %s" % (scene.scene_file_path if scene != null else "<null>"))

	var child_names: Array = []
	for child: Node in tree.root.get_children():
		child_names.append(child.name)
	print("[smoke] root children: %s" % ", ".join(child_names))

	for autoload_name: Variant in child_names:
		var node: Node = tree.root.get_node(str(autoload_name))
		if node.has_method("debug_summary"):
			print("[smoke] %s: %s" % [str(autoload_name), str(node.call("debug_summary"))])

	var visible_items: int = _count_visible(scene) if scene != null else 0
	print("[smoke] visible CanvasItems under current_scene: %d" % visible_items)

	print("[smoke] ---- tree ----")
	tree.root.print_tree_pretty()

	var healthy: bool = true
	if scene == null:
		print("[smoke] UNHEALTHY: current_scene is null")
		healthy = false
	elif scene.scene_file_path.begins_with("res://regions/"):
		print("[smoke] UNHEALTHY: current_scene is an area scene (%s); areas are reached only through SceneRouter" % scene.scene_file_path)
		healthy = false
	elif visible_items == 0:
		print("[smoke] UNHEALTHY: nothing under current_scene reports is_visible_in_tree()")
		healthy = false
	print("[smoke] verdict: %s" % ("healthy" if healthy else "UNHEALTHY"))
	return healthy

func _count_visible(node: Node) -> int:
	var count: int = 0
	if node is CanvasItem and (node as CanvasItem).is_visible_in_tree():
		count += 1
	for child: Node in node.get_children():
		count += _count_visible(child)
	return count
