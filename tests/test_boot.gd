extends RefCounted

## Session 9, Block B1: the engine boots the title, never an area. The
## session-9 gray-box bug was main_scene pointing at the workshop, which
## existed for one frame, queued a deferred cutscene play, and was freed by
## Boot's swap — the deferred call then ran off-tree. The fix removes the
## swap entirely: the title IS the main scene, and areas are reached only
## through SceneRouter. The real-boot path itself is covered by the smoke
## mode (tools\\smoke.bat), which these assertions back up from inside the
## suite.

func test_main_scene_is_not_an_area(t: TestContext) -> void:
	var main_scene: String = str(ProjectSettings.get_setting("application/run/main_scene"))
	t.assert_false(main_scene.begins_with("res://regions/"),
		"the engine must never boot straight into an area scene, got '%s'" % main_scene)
	t.assert_eq(main_scene, "res://scenes/title.tscn",
		"the title is the main scene; Boot swaps nothing")

func test_smoke_arg_parsing(t: TestContext) -> void:
	var boot: Node = t.tree.root.get_node("Boot")
	t.assert_false(boot.smoke_requested(PackedStringArray([])),
		"smoke mode never activates by default")
	t.assert_true(boot.smoke_requested(PackedStringArray(["--smoke"])), "--smoke activates it")
	t.assert_eq(boot.smoke_frames(PackedStringArray(["--smoke"])), 180, "default frame count")
	t.assert_eq(boot.smoke_frames(PackedStringArray(["--smoke", "--smoke-frames=60"])), 60,
		"--smoke-frames=N overrides")
	t.assert_eq(boot.smoke_frames(PackedStringArray(["--smoke-frames=0"])), 180,
		"a non-positive override falls back to the default")

func test_boot_never_swaps_scenes(t: TestContext) -> void:
	# The scripted test tree has no current_scene; a Boot that still routed
	# would have tried to install one. Nothing to call — assert the state.
	t.assert_true(t.tree.current_scene == null,
		"Boot left the scripted SceneTree alone: no scene was installed under it")
