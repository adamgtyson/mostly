extends RefCounted

## Session 8, Block A: the title screen. Continue exists exactly when a save
## does; loading goes through SaveManager's generic contributor restore and
## departs through the §6 choke point. Fixture saves use the same scratch
## saves_dir pattern as test_save_manager.gd, so a test run can never touch a
## real slot. Departure uses the depart:false seam — actually travelling would
## load the workshop (and, with sys.village restored, its opening) mid-suite.

const SCENE := "res://scenes/title.tscn"
const TEST_SAVES_DIR := "user://saves/test_title"

func _sm(t: TestContext) -> Node:
	var sm: Node = t.tree.root.get_node("SaveManager")
	sm.saves_dir = TEST_SAVES_DIR
	return sm

func _gs(t: TestContext) -> Node:
	return t.tree.root.get_node("GameState")

func _cleanup(sm: Node) -> void:
	for slot: String in sm.all_slot_names():
		var path: String = sm.slot_path(slot)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	if DirAccess.dir_exists_absolute(TEST_SAVES_DIR):
		DirAccess.remove_absolute(TEST_SAVES_DIR)

func _screen(t: TestContext) -> Control:
	var packed: PackedScene = load(SCENE)
	if packed == null:
		return null
	var screen: Control = packed.instantiate()
	t.tree.root.add_child(screen)
	return screen

func _free_screen(screen: Control) -> void:
	if is_instance_valid(screen):
		screen.queue_free()

## A save written through the real pipeline, with enough state to prove the
## restore: flags, a location, a visited area.
func _write_fixture_save(t: TestContext, sm: Node) -> void:
	var gs: Node = _gs(t)
	gs.set_flag("region.hold.unlocked", true)
	gs.set_flag("sys.village", "fine_now")
	var router: Node = t.tree.root.get_node("SceneRouter")
	router.current_region = "hold"
	router.current_area = "workshop"
	router.mark_visited("hold", "workshop")
	sm.save_to_slot("1")
	gs.reset()
	router.reset()

func test_without_a_save_continue_is_hidden(t: TestContext) -> void:
	var sm: Node = _sm(t)
	var screen: Control = _screen(t)
	t.assert_true(screen != null, "title.tscn instantiates")
	if screen == null:
		return
	t.assert_false(screen.has_any_save(), "the scratch saves dir is empty")
	t.assert_false((screen.get_node("Center/Menu/Continue") as Button).visible,
		"Continue is hidden with nothing to continue")
	t.assert_true((screen.get_node("Center/Menu/NewGame") as Button).visible, "New Game is always offered")
	t.assert_eq(screen.continue_game(false), {}, "and a Continue with no save applies nothing")
	_free_screen(screen)
	_cleanup(sm)

func test_with_a_save_continue_is_visible_and_loads(t: TestContext) -> void:
	var sm: Node = _sm(t)
	_write_fixture_save(t, sm)
	var gs: Node = _gs(t)
	t.assert_false(gs.has_flag("sys.village"), "state was wiped after writing the fixture")

	var screen: Control = _screen(t)
	if screen == null:
		t.fail("title.tscn failed to instantiate")
		_cleanup(sm)
		return
	t.assert_true(screen.has_any_save(), "the fixture save is seen")
	t.assert_true((screen.get_node("Center/Menu/Continue") as Button).visible, "Continue is visible with a save")
	t.assert_eq(screen.most_recent_slot(), "1", "and resumes the fixture slot")

	var destination: Dictionary = screen.continue_game(false)
	t.assert_eq(destination, {"region": "hold", "area": "workshop", "spawn": "default"},
		"Continue routes to the saved area")
	t.assert_eq(gs.get_flag("sys.village"), "fine_now", "the load restored the flags")
	t.assert_eq(gs.get_flag("region.hold.unlocked", false), true,
		"including the region lock the departure needs")

	_free_screen(screen)
	_cleanup(sm)

func test_new_game_hands_over_to_the_selection_screen(t: TestContext) -> void:
	var sm: Node = _sm(t)
	var screen: Control = _screen(t)
	if screen == null:
		t.fail("title.tscn failed to instantiate")
		return
	t.assert_eq(screen.start_new_game(false), "res://scenes/new_game.tscn",
		"New Game opens the session-7 selection screen")
	_free_screen(screen)
	_cleanup(sm)

# ── 320x180 canvas discipline (session 10) ──────────────────────────────────
## The windowed bug this guards against: Controls laid out in window
## coordinates with the default 16px font inside the 320x180 canvas — the
## title in a corner, text 4x too large. The screen is instantiated in an
## actual 320x180 SubViewport and every visible content Control must land
## fully inside it, at the dialogue box's font size or smaller, with a
## Container owning its placement (hand-set positions are what containers
## exist to forbid).

const CANVAS := Rect2(0, 0, 320, 180)
const MAX_FONT := 8

func test_title_lays_out_inside_the_canvas(t: TestContext) -> void:
	var sm: Node = _sm(t)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(320, 180)
	t.tree.root.add_child(viewport)
	var packed: PackedScene = load(SCENE)
	var screen: Control = packed.instantiate()
	viewport.add_child(screen)
	await t.tree.process_frame
	await t.tree.process_frame

	var checked: int = _assert_canvas_discipline(t, screen, "title")
	t.assert_true(checked >= 3, "the sweep saw the title, tagline and New Game (%d content controls)" % checked)

	viewport.queue_free()
	await t.tree.process_frame
	_cleanup(sm)

## Shared sweep: rect ⊂ canvas (clip-aware for ScrollContainers), font ≤ the
## dialogue box's 8, and a Container parent for every content Control.
func _assert_canvas_discipline(t: TestContext, root: Control, label: String) -> int:
	var checked: int = 0
	for control: Control in _content_controls(root):
		checked += 1
		var where: String = "%s: %s" % [label, control.name]
		var rect: Rect2 = _clipped_rect(control)
		t.assert_true(CANVAS.grow(0.5).encloses(rect),
			"%s — global rect %s lies inside 320x180" % [where, rect])
		if control is Label or control is Button:
			t.assert_true(control.get_theme_font_size("font_size") <= MAX_FONT,
				"%s — font size %d is at most the dialogue box's %d" % [where, control.get_theme_font_size("font_size"), MAX_FONT])
		elif control is RichTextLabel:
			t.assert_true(control.get_theme_font_size("normal_font_size") <= MAX_FONT,
				"%s — rich text font is at most %d" % [where, MAX_FONT])
		t.assert_true(control.get_parent() is Container,
			"%s — a Container owns its placement; no hand-set positions" % where)
	return checked

## Visible Controls that actually draw something: text, or a panel's StyleBox.
func _content_controls(node: Node) -> Array:
	var out: Array = []
	if node is Control and (node as Control).is_visible_in_tree():
		if (node is Label and not str(node.get("text")).is_empty()) \
				or (node is Button and not str(node.get("text")).is_empty()) \
				or node is RichTextLabel or node is PanelContainer:
			out.append(node)
	for child: Node in node.get_children():
		out.append_array(_content_controls(child))
	return out

## Global rect intersected with every clipping ancestor (a ScrollContainer
## clips its children), so a legitimately scrolled-away row does not fail the
## bounds rule while a mislaid control still does.
func _clipped_rect(control: Control) -> Rect2:
	var rect: Rect2 = control.get_global_rect()
	var ancestor: Node = control.get_parent()
	while ancestor != null:
		if ancestor is ScrollContainer or (ancestor is Control and (ancestor as Control).clip_contents):
			rect = rect.intersection((ancestor as Control).get_global_rect())
		ancestor = ancestor.get_parent()
	return rect
