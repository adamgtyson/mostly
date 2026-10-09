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
	t.assert_eq(screen.get_node("GenderStep").get_children().filter(
		func(c: Node) -> bool: return c is Button).size(), 2, "two gender options")
	t.assert_eq(screen.get_node("VillageStep/VillageButtons").get_child_count(), 9, "nine village buttons")
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
