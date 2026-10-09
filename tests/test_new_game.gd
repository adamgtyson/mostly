extends RefCounted

## Session 7, Block D: the nine-village data and the New Game screen.
##
## The screen's logic is driven through its functions, never input events
## (§11), and confirm uses its depart:false test seam — actually travelling
## would load the workshop and start the opening cutscene inside the suite.
## The schema and canon checks live in validate_data.gd; these tests cover
## what the validator cannot: the screen's behaviour.

const SCENE := "res://scenes/new_game.tscn"

## The obfuscated Seven Chickens pro as Docs/03 words it for the selection
## screen; the real pro must never be part of what the screen renders.
const SEVEN_CHICKENS_OBFUSCATED_START := "Patch has always been comfortable"

func _gs(t: TestContext) -> Node:
	return t.tree.root.get_node("GameState")

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

func test_the_screen_loads_the_canonical_nine(t: TestContext) -> void:
	var screen: Control = _screen(t)
	t.assert_true(screen != null, "new_game.tscn instantiates")
	if screen == null:
		return
	var ordered: Array = screen.village_ids_in_order()
	t.assert_eq(ordered.size(), 9, "all nine villages load")
	t.assert_eq(ordered[0], "again", "selection order follows the Docs/00 table")
	t.assert_eq(ordered[8], "new_again", "ending with New Again")
	_free_screen(screen)

func test_the_screen_builds_navigable_buttons(t: TestContext) -> void:
	var screen: Control = _screen(t)
	if screen == null:
		t.fail("new_game.tscn failed to instantiate")
		return
	t.assert_eq(screen.get_node("GenderStep/Options").get_children().filter(
		func(c: Node) -> bool: return c is Button).size(), 2, "two gender options")
	t.assert_eq(screen.get_node("VillageStep/Layout/VillageScroll/VillageButtons").get_child_count(), 9, "nine village buttons")
	t.assert_true(screen.get_node("GenderStep").visible, "the screen opens on the gender step")
	t.assert_false(screen.get_node("VillageStep").visible, "with the village step hidden")
	_free_screen(screen)

func test_gender_choice_writes_the_flag_and_advances(t: TestContext) -> void:
	var screen: Control = _screen(t)
	if screen == null:
		t.fail("new_game.tscn failed to instantiate")
		return
	t.assert_false(screen.choose_gender("x"), "an unknown code is refused")
	t.assert_true(screen.choose_gender("f"), "a valid code is accepted")
	t.assert_eq(_gs(t).get_flag("sys.patch_gender"), "f", "and lands in sys.patch_gender [U2-7]")
	t.assert_true(screen.get_node("VillageStep").visible, "the village step opens")
	t.assert_false(screen.get_node("GenderStep").visible, "and the gender step closes")
	_free_screen(screen)

func test_seven_chickens_stays_obfuscated_on_screen(t: TestContext) -> void:
	var screen: Control = _screen(t)
	if screen == null:
		t.fail("new_game.tscn failed to instantiate")
		return
	screen.select_village("seven_chickens")
	var village: Dictionary = screen.load_villages()["seven_chickens"]
	var shown: String = screen.detail_text(village)
	t.assert_true(shown.contains(SEVEN_CHICKENS_OBFUSCATED_START),
		"the screen shows the Docs/03 obfuscated wording")
	t.assert_true(village.has("pro_text_hidden"), "the real pro travels in pro_text_hidden")
	t.assert_false(shown.contains(str(village.get("pro_text_hidden"))),
		"and never reaches the selection screen")
	_free_screen(screen)

func test_confirm_applies_starting_state_and_names_the_destination(t: TestContext) -> void:
	var screen: Control = _screen(t)
	if screen == null:
		t.fail("new_game.tscn failed to instantiate")
		return
	screen.choose_gender("m")
	var destination: Dictionary = screen.confirm_village("seven_chickens", false)

	var gs: Node = _gs(t)
	t.assert_eq(gs.get_flag("sys.village"), "seven_chickens", "the village file's starting_flags apply")
	t.assert_eq(gs.get_flag("region.hold.unlocked", false), true,
		"a new run can reach its starting region (§6), or go_to would refuse the first move")
	t.assert_eq(destination, {"region": "hold", "area": "workshop", "spawn": "default"},
		"and the departure routes to hold/workshop from config, not literals (§13)")
	_free_screen(screen)

func test_confirm_refuses_an_unknown_village(t: TestContext) -> void:
	var screen: Control = _screen(t)
	if screen == null:
		t.fail("new_game.tscn failed to instantiate")
		return
	t.assert_eq(screen.confirm_village("atlantis", false), {}, "an unknown id applies nothing")
	t.assert_false(_gs(t).has_flag("sys.village"), "and sets no flag")
	_free_screen(screen)

# ── 320x180 canvas discipline (session 10) ──────────────────────────────────
## Both steps of the screen, in a real 320x180 SubViewport: every visible
## content Control fully inside the canvas (clip-aware for the scrolling
## village list), fonts at the dialogue box's 8 or smaller, containers owning
## every placement. The list is a ScrollContainer with follow_focus, so the
## last village is reached by focus alone — exactly how a gamepad reaches it.

const CANVAS := Rect2(0, 0, 320, 180)
const MAX_FONT := 8

func test_both_steps_lay_out_inside_the_canvas(t: TestContext) -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(320, 180)
	t.tree.root.add_child(viewport)
	var packed: PackedScene = load(SCENE)
	var screen: Control = packed.instantiate()
	viewport.add_child(screen)
	await t.tree.process_frame
	await t.tree.process_frame

	# Step 1: gender.
	var checked: int = _assert_canvas_discipline(t, screen, "new_game step 1")
	t.assert_true(checked >= 4, "step 1 sweep saw heading, prompt and both options (%d)" % checked)

	# Step 2: village selection.
	screen.choose_gender("m")
	screen.select_village("again")
	await t.tree.process_frame
	await t.tree.process_frame
	checked = _assert_canvas_discipline(t, screen, "new_game step 2")
	t.assert_true(checked >= 10, "step 2 sweep saw nine villages and the detail panel (%d)" % checked)

	# The list scrolled to its last entry by focus, the gamepad way.
	var last: Button = screen.get_node("VillageStep/Layout/VillageScroll/VillageButtons/Village_new_again")
	last.grab_focus()
	await t.tree.process_frame
	await t.tree.process_frame
	t.assert_true(CANVAS.grow(0.5).encloses(last.get_global_rect()),
		"the focused last village sits fully on screen at %s — follow_focus scrolled to it" % last.get_global_rect())
	_assert_canvas_discipline(t, screen, "new_game step 2 (scrolled to last)")

	viewport.queue_free()
	await t.tree.process_frame

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

func _clipped_rect(control: Control) -> Rect2:
	var rect: Rect2 = control.get_global_rect()
	var ancestor: Node = control.get_parent()
	while ancestor != null:
		if ancestor is ScrollContainer or (ancestor is Control and (ancestor as Control).clip_contents):
			rect = rect.intersection((ancestor as Control).get_global_rect())
		ancestor = ancestor.get_parent()
	return rect
