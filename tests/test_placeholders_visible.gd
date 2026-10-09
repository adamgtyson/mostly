extends RefCounted

## Session 7, Block C: "every placeholder is visibly rendered" (ledger L5).
##
## Invisible-but-loading passes every other automated check — the scene loads,
## the script parses, the texture code runs without error, and nothing on
## screen proves it. These tests assert the render-side facts a playtest would
## see: the node is there, every ancestor is visible, the texture exists, the
## drawn rect is non-empty, and the thing sits inside the area's camera bounds.
##
## Scenes are instantiated DETACHED (adding the workshop to the tree would fire
## the opening cutscene into the suite — see test_scene_router.gd's note), so
## each placeholder's _ready() is driven manually, exactly what the engine does
## on add_child. A placeholder that only becomes visible through _ready is
## therefore still covered.

const WORKSHOP := "res://regions/hold/areas/workshop.tscn"
const REGIONS_DIR := "res://regions"
const PLACEHOLDER_GROUP := "placeholder"

# ── the cat (L5) ─────────────────────────────────────────────────────────────

func test_cat_placeholder_is_visible_in_the_workshop(t: TestContext) -> void:
	var packed: PackedScene = load(WORKSHOP)
	t.assert_true(packed != null, "workshop.tscn loads")
	if packed == null:
		return
	var scene: Node = packed.instantiate()

	var cat: Node = scene.get_node_or_null("Interactables/Cat/CatSprite")
	t.assert_true(cat != null, "Interactables/Cat/CatSprite exists in the scene")
	if cat == null:
		scene.free()
		return

	t.assert_true(cat is Sprite2D, "CatSprite is a Sprite2D, got %s" % cat.get_class())
	t.assert_true(cat.get_script() != null,
		"cat_sprite.gd is attached — a dropped script would leave the texture null and draw nothing")

	# What the engine does on add_child; the texture is built here.
	if cat.has_method("_ready"):
		cat._ready()

	var sprite: Sprite2D = cat as Sprite2D
	t.assert_true(sprite.texture != null, "the programmatic texture was created and assigned")
	if sprite.texture != null:
		t.assert_eq(sprite.texture.get_size(), Vector2(16, 16), "and is the 16x16 the script builds")
		t.assert_true(sprite.get_rect().has_area(), "so the drawn rect is non-empty")

	# The whole ancestor chain must be visible — one hidden parent hides the cat
	# no matter what the sprite itself says.
	var node: CanvasItem = sprite
	while node != null:
		t.assert_true(node.visible, "'%s' in the cat's ancestor chain is visible" % node.name)
		node = node.get_parent() as CanvasItem

	# And it must sit inside the camera bounds, or it renders fine off screen.
	var rect: Rect2i = scene.call("used_rect")
	var at: Vector2 = _scene_position(sprite, scene)
	t.assert_true(Rect2(rect).has_point(at),
		"the cat at %s is inside the area's used_rect %s" % [at, rect])

	t.assert_true(sprite.is_in_group(PLACEHOLDER_GROUP),
		"the cat is in the '%s' group so this check can never lose track of it" % PLACEHOLDER_GROUP)

	scene.free()

## The same cat through the real lifecycle: in the tree, engine-driven _ready,
## actual visibility propagation. The OpeningCutscene trigger is removed from
## this instance first — a test must not play a 30-beat cutscene — which does
## not change what the cat does, because the cutscene never references it.
func test_cat_survives_the_real_tree_lifecycle(t: TestContext) -> void:
	var packed: PackedScene = load(WORKSHOP)
	if packed == null:
		t.fail("workshop.tscn failed to load")
		return
	var scene: Node = packed.instantiate()
	var trigger: Node = scene.get_node_or_null("OpeningCutscene")
	if trigger != null:
		scene.remove_child(trigger)
		trigger.free()

	t.tree.root.add_child(scene)
	await t.tree.process_frame
	await t.tree.process_frame

	var cat: Sprite2D = scene.get_node_or_null("Interactables/Cat/CatSprite") as Sprite2D
	t.assert_true(cat != null, "the cat is in the live tree")
	if cat != null:
		t.assert_true(cat.is_inside_tree(), "is_inside_tree()")
		t.assert_true(cat.is_visible_in_tree(), "is_visible_in_tree() — no ancestor hides it at runtime")
		t.assert_true(cat.texture != null, "the engine-driven _ready assigned the texture")
		if cat.texture != null:
			t.assert_true(cat.get_rect().has_area(), "and the drawn rect is non-empty")
		t.assert_eq(cat.global_position, Vector2(180, 96), "at the position the scene authored")

	scene.queue_free()
	await t.tree.process_frame

# ── every placeholder in every area (the phase-8 checklist item) ────────────

func test_every_placeholder_renders_in_every_area_scene(t: TestContext) -> void:
	var scene_paths: PackedStringArray = _area_scenes()
	t.assert_true(scene_paths.size() >= 2, "there are area scenes to check, found %d" % scene_paths.size())

	var placeholders_seen: int = 0
	for path: String in scene_paths:
		var packed: PackedScene = load(path)
		if packed == null:
			t.fail("%s failed to load" % path)
			continue
		var scene: Node = packed.instantiate()
		for node: Node in _descendants_in_group(scene, PLACEHOLDER_GROUP):
			# Transient runtime placeholders (FlickerHandlers' audio player,
			# bubble) never appear in a scene file; everything here should be
			# drawable, but filter to CanvasItem so a stray non-visual member
			# fails loudly with a reason rather than erroring on .visible.
			if not (node is CanvasItem):
				t.fail("%s: '%s' is in the placeholder group but is not a CanvasItem" % [path, node.name])
				continue
			placeholders_seen += 1
			if node.has_method("_ready"):
				node._ready()
			_assert_renders(t, node as CanvasItem, path, scene)
		scene.free()

	t.assert_true(placeholders_seen >= 2,
		"the sweep found the known placeholders (cat, dev-area NPC), found %d" % placeholders_seen)

func _assert_renders(t: TestContext, item: CanvasItem, path: String, scene_root: Node) -> void:
	var where: String = "%s: '%s'" % [path.get_file(), item.name]
	var node: CanvasItem = item
	while node != null:
		t.assert_true(node.visible, "%s — ancestor '%s' is visible" % [where, node.name])
		node = node.get_parent() as CanvasItem

	if item is Sprite2D:
		var sprite: Sprite2D = item
		t.assert_true(sprite.texture != null, "%s — Sprite2D has a texture" % where)
		if sprite.texture != null:
			t.assert_true(sprite.get_rect().has_area(), "%s — drawn rect is non-empty" % where)
	elif item is AnimatedSprite2D:
		var animated: AnimatedSprite2D = item
		t.assert_true(animated.sprite_frames != null, "%s — AnimatedSprite2D has frames" % where)
		if animated.sprite_frames != null:
			t.assert_true(animated.sprite_frames.get_animation_names().size() > 0,
				"%s — and at least one animation" % where)

	if item is Node2D and scene_root.has_method("used_rect"):
		var rect: Rect2i = scene_root.call("used_rect")
		var at: Vector2 = _scene_position(item as Node2D, scene_root)
		t.assert_true(Rect2(rect).has_point(at),
			"%s — sits at %s inside used_rect %s" % [where, at, rect])

# ── helpers ──────────────────────────────────────────────────────────────────

## Position in the scene root's space, summed up the parent chain — detached
## nodes have no global transform, so walk it by hand.
func _scene_position(node: Node2D, scene_root: Node) -> Vector2:
	var at: Vector2 = Vector2.ZERO
	var current: Node = node
	while current != null and current != scene_root:
		if current is Node2D:
			at += (current as Node2D).position
		current = current.get_parent()
	return at

func _descendants_in_group(node: Node, group: String) -> Array:
	var found: Array = []
	for child: Node in node.get_children():
		if child.is_in_group(group):
			found.append(child)
		found.append_array(_descendants_in_group(child, group))
	return found

func _area_scenes() -> PackedStringArray:
	var found := PackedStringArray()
	var dir := DirAccess.open(REGIONS_DIR)
	if dir == null:
		return found
	for region: String in dir.get_directories():
		var areas := DirAccess.open("%s/%s/areas" % [REGIONS_DIR, region])
		if areas == null:
			continue
		for f: String in areas.get_files():
			if f.ends_with(".tscn"):
				found.append("%s/%s/areas/%s" % [REGIONS_DIR, region, f])
	found.sort()
	return found
