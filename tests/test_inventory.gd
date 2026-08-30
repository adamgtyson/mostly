extends RefCounted

## Milestone 4: Inventory (§4). Runs entirely against the PH_ test fixtures in
## data/items/, so nothing here depends on content that does not exist yet.

const ORE := "ph_test_ore"
const TONIC := "ph_test_tonic"
const SWORD := "ph_test_sword"

func _inv(t: TestContext) -> Node:
	return t.tree.root.get_node("Inventory")

func test_definitions_load_from_data(t: TestContext) -> void:
	var inv: Node = _inv(t)
	t.assert_true(inv.has_definition(ORE), "the ore fixture loaded")
	t.assert_true(inv.has_definition(TONIC), "the tonic fixture loaded")
	t.assert_true(inv.has_definition(SWORD), "the sword fixture loaded")
	t.assert_eq(inv.definition(ORE).get("type"), "resource", "definitions carry their type")
	t.assert_eq(inv.item_weight(SWORD), 3.0, "every item carries a weight (EC-4a)")

func test_every_definition_declares_a_weight(t: TestContext) -> void:
	var inv: Node = _inv(t)
	for id: String in inv.definition_ids():
		var def: Dictionary = inv.definition(id)
		t.assert_true(def.has("weight"), "%s declares a weight" % id)

func test_stackable_instances_use_the_count_shape(t: TestContext) -> void:
	var inv: Node = _inv(t)
	var instance: Dictionary = inv.make_instance(ORE, 5)
	t.assert_eq(instance, {"item_id": ORE, "count": 5}, "stackables are {item_id, count}")

func test_gear_instances_use_the_charges_shape(t: TestContext) -> void:
	var inv: Node = _inv(t)
	var instance: Dictionary = inv.make_instance(SWORD)
	t.assert_eq(instance.get("item_id"), SWORD, "gear instances name their item")
	t.assert_true(instance.has("charges_left"), "gear instances carry charges_left")
	t.assert_eq(instance.get("attachments"), [], "gear instances carry an attachments list")

func test_adding_stacks_merges_up_to_max_stack(t: TestContext) -> void:
	var inv: Node = _inv(t)
	inv.add_item(ORE, 5)
	t.assert_eq(inv.bag().size(), 1, "one stack so far")
	inv.add_item(ORE, 3)
	t.assert_eq(inv.bag().size(), 1, "a second add tops up the existing stack")
	t.assert_eq(inv.count_of(ORE), 8, "counts accumulate")

	inv.reset()
	inv.add_item(TONIC, 25)
	t.assert_eq(inv.count_of(TONIC), 25, "all 25 are held")
	t.assert_eq(inv.bag().size(), 3, "a max_stack of 10 splits 25 across three stacks")

func test_non_stackables_get_one_entry_each(t: TestContext) -> void:
	var inv: Node = _inv(t)
	inv.add_item(SWORD, 3)
	t.assert_eq(inv.bag().size(), 3, "each sword is its own instance")
	t.assert_eq(inv.count_of(SWORD), 3, "counted individually")

func test_removing_items(t: TestContext) -> void:
	var inv: Node = _inv(t)
	inv.add_item(ORE, 10)
	t.assert_true(inv.remove_item(ORE, 4), "removing what is held succeeds")
	t.assert_eq(inv.count_of(ORE), 6, "the remainder stays")
	t.assert_false(inv.remove_item(ORE, 99), "removing more than is held fails")
	t.assert_eq(inv.count_of(ORE), 6, "a failed removal changes nothing")
	t.assert_true(inv.remove_item(ORE, 6), "removing the rest succeeds")
	t.assert_eq(inv.bag().size(), 0, "an emptied stack leaves the bag")

func test_unknown_items_are_refused(t: TestContext) -> void:
	var inv: Node = _inv(t)
	t.assert_false(inv.add_item("not_a_real_item"), "an undefined item cannot be added")
	t.assert_eq(inv.bag().size(), 0, "nothing entered the bag")

func test_add_and_remove_signals(t: TestContext) -> void:
	var inv: Node = _inv(t)
	var events: Array = []
	var on_added := func(id: String, n: int) -> void: events.append(["added", id, n])
	var on_removed := func(id: String, n: int) -> void: events.append(["removed", id, n])
	inv.item_added.connect(on_added)
	inv.item_removed.connect(on_removed)

	inv.add_item(ORE, 2)
	inv.remove_item(ORE, 1)

	inv.item_added.disconnect(on_added)
	inv.item_removed.disconnect(on_removed)
	t.assert_eq(events, [["added", ORE, 2], ["removed", ORE, 1]], "both signals fire with item and count")

func test_tag_lookup_backs_recipe_substitution(t: TestContext) -> void:
	var inv: Node = _inv(t)
	inv.add_item(ORE, 3)
	t.assert_true(inv.has_tag("ph_test_material"), "the bag reports a held tag")
	t.assert_eq(inv.count_with_tag("ph_test_material"), 3, "tag counts follow item counts")
	t.assert_false(inv.has_tag("ph_test_edge"), "an unheld tag is absent")

func test_equipping_moves_between_bag_and_slot(t: TestContext) -> void:
	var inv: Node = _inv(t)
	inv.add_item(SWORD)
	t.assert_true(inv.equip("patch", SWORD), "equipping succeeds")
	t.assert_eq(inv.count_of(SWORD), 0, "the equipped sword left the bag")
	t.assert_eq(inv.equipped_in("patch", "weapon").get("item_id"), SWORD, "it is in the weapon slot")

	t.assert_true(inv.unequip("patch", "weapon"), "unequipping succeeds")
	t.assert_eq(inv.count_of(SWORD), 1, "it returned to the bag")
	t.assert_eq(inv.equipped_in("patch", "weapon"), {}, "the slot is empty")

func test_equipment_is_per_member(t: TestContext) -> void:
	var inv: Node = _inv(t)
	inv.add_item(SWORD, 2)
	inv.equip("patch", SWORD)
	inv.equip("fletch", SWORD)
	t.assert_eq(inv.equipped_in("patch", "weapon").get("item_id"), SWORD, "patch has one")
	t.assert_eq(inv.equipped_in("fletch", "weapon").get("item_id"), SWORD, "fletch has the other")
	t.assert_eq(inv.count_of(SWORD), 0, "both left the shared bag")

func test_non_equippable_items_are_refused(t: TestContext) -> void:
	var inv: Node = _inv(t)
	inv.add_item(ORE)
	t.assert_false(inv.equip("patch", ORE), "a resource cannot be equipped")

func test_modifiers_come_from_equipped_gear(t: TestContext) -> void:
	var inv: Node = _inv(t)
	t.assert_eq(inv.modifiers_for("patch"), [], "nothing equipped, no modifiers")
	inv.add_item(SWORD)
	inv.equip("patch", SWORD)
	var mods: Array = inv.modifiers_for("patch")
	t.assert_eq(mods.size(), 1, "the sword contributes one modifier")
	t.assert_eq(mods[0], {"stat": "attack", "op": "add", "value": 2}, "modifier shape is {stat, op, value}")

func test_default_effects_are_registered(t: TestContext) -> void:
	var inv: Node = _inv(t)
	for effect: String in ["heal", "apply_buff", "set_flag"]:
		t.assert_true(inv.has_effect(effect), "%s is registered" % effect)

func test_using_a_consumable_runs_its_effect_and_consumes_it(t: TestContext) -> void:
	var inv: Node = _inv(t)
	inv.add_item(TONIC, 2)
	t.assert_true(inv.use_item(TONIC), "the tonic's on_use effect runs")
	t.assert_eq(inv.count_of(TONIC), 1, "a consumable is consumed on use")

func test_set_flag_effect_reaches_game_state(t: TestContext) -> void:
	var inv: Node = _inv(t)
	var gs: Node = t.tree.root.get_node("GameState")
	# A new consumable is a JSON file plus at most a registry entry, never a script:
	# drive the registered effect directly rather than inventing an item for it.
	var handler_ran: bool = inv._effects["set_flag"].call({"flag": "sys.realistic_weight", "value": true})
	t.assert_true(handler_ran, "the set_flag effect reports success")
	t.assert_eq(gs.get_flag("sys.realistic_weight", false), true, "it wrote through to GameState")

func test_using_an_unheld_item_fails(t: TestContext) -> void:
	var inv: Node = _inv(t)
	t.assert_false(inv.use_item(TONIC), "an item not in the bag cannot be used")

func test_weight_is_ignored_unless_realistic_mode_is_on(t: TestContext) -> void:
	var inv: Node = _inv(t)
	var gs: Node = t.tree.root.get_node("GameState")
	inv.add_item(ORE, 99)
	t.assert_eq(inv.total_weight(), 99.0, "weight is always tracked")
	t.assert_false(inv.realistic_weight_enabled(), "realistic weight is off by default")
	t.assert_false(inv.is_over_weight(), "with the flag off, no limit applies")

	gs.set_flag("sys.realistic_weight", true)
	t.assert_true(inv.is_over_weight(), "with the flag on, the config limit applies")

func test_bag_limit_is_unlimited_by_default(t: TestContext) -> void:
	var inv: Node = _inv(t)
	t.assert_eq(inv.max_bag_slots(), 0, "config default is 0")
	t.assert_false(inv.bag_is_full(), "0 means unlimited (§4)")

func test_save_roundtrip(t: TestContext) -> void:
	var inv: Node = _inv(t)
	inv.add_item(ORE, 7)
	inv.add_item(SWORD)
	inv.equip("patch", SWORD)
	var snapshot: Dictionary = inv.to_save_dict()

	inv.reset()
	t.assert_eq(inv.count_of(ORE), 0, "reset empties the bag")
	t.assert_eq(inv.equipped("patch"), {}, "reset clears equipment")

	inv.from_save_dict(snapshot)
	t.assert_eq(inv.count_of(ORE), 7, "the bag comes back")
	t.assert_eq(inv.equipped_in("patch", "weapon").get("item_id"), SWORD, "equipment comes back")
