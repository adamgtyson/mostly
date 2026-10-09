extends RefCounted

## Session 9, Block B2: CutsceneTrigger must be safe off-tree. A deferred
## play() can outlive its scene — the engine frees a swapped-out scene before
## the deferred queue drains — and the session-9 boot crash was exactly that:
## _condition_holds() walking get_tree().root on a null tree. Conditions
## resolve flags, not nodes (§5), so evaluation now goes through the GameState
## singleton and play() returns quietly when the node has no tree.
##
## The startable case uses PH_smoke_blip (a one-beat harness cutscene) with
## mark_seen_on_end false, so the suite never plays the opening and never
## writes to the real seen-cutscenes file.

const TRIGGER_SCRIPT := "res://scripts/cutscene_trigger.gd"
const BLIP := "PH_smoke_blip"

func _gs(t: TestContext) -> Node:
	return t.tree.root.get_node("GameState")

func _cm(t: TestContext) -> Node:
	return t.tree.root.get_node("CutsceneManager")

func _trigger() -> Node2D:
	var trigger := Node2D.new()
	trigger.set_script(load(TRIGGER_SCRIPT))
	trigger.set("cutscene_id", BLIP)
	trigger.set("when", "sys.village")
	trigger.set("play_on_ready", false)
	trigger.set("mark_seen_on_end", false)
	return trigger

func test_play_off_tree_returns_quietly_and_starts_nothing(t: TestContext) -> void:
	var trigger: Node2D = _trigger()
	_gs(t).set_flag("sys.village", "again")

	# Not in any tree — the session-9 crash state. No error, no cutscene.
	t.assert_false(trigger.is_inside_tree(), "the trigger is deliberately off-tree")
	t.assert_false(trigger.call("play"), "play() refuses without a tree")
	t.assert_false(_cm(t).get("cutscene_active"), "and nothing started")
	trigger.free()

func test_condition_evaluates_off_tree_without_a_tree_walk(t: TestContext) -> void:
	var trigger: Node2D = _trigger()
	_gs(t).set_flag("sys.village", "again")
	# The crash was in the condition path specifically; prove it alone is safe.
	t.assert_true(trigger.call("_condition_holds"), "a satisfied flag condition resolves off-tree")
	_gs(t).set_flag("sys.village", "")
	t.assert_false(trigger.call("_condition_holds"), "and an unsatisfied one too")
	trigger.free()

func test_in_tree_with_the_flag_set_the_cutscene_starts(t: TestContext) -> void:
	var parent := Node2D.new()
	var trigger: Node2D = _trigger()
	parent.add_child(trigger)
	t.tree.root.add_child(parent)
	_gs(t).set_flag("sys.village", "again")

	# A one-beat cutscene starts and finishes inside the play() call itself,
	# so the start is observed through the signal, not by polling the flag.
	var started: Array = []
	var ended: Array = []
	var on_started := func(id: String) -> void: started.append(id)
	var on_ended := func() -> void: ended.append(true)
	_cm(t).cutscene_started.connect(on_started)
	_cm(t).cutscene_ended.connect(on_ended)

	t.assert_true(trigger.call("play"), "in a tree with the condition satisfied, play() starts its cutscene")

	_cm(t).cutscene_started.disconnect(on_started)
	_cm(t).cutscene_ended.disconnect(on_ended)
	t.assert_eq(started, [BLIP], "the manager announced the blip starting")
	t.assert_eq(ended.size(), 1, "and the one-beat blip ran to its end")
	t.assert_false(_cm(t).get("cutscene_active"), "leaving the manager idle")

	parent.queue_free()
	await t.tree.process_frame

func test_in_tree_with_the_flag_unset_nothing_starts(t: TestContext) -> void:
	var parent := Node2D.new()
	var trigger: Node2D = _trigger()
	parent.add_child(trigger)
	t.tree.root.add_child(parent)

	t.assert_false(trigger.call("play"), "sys.village unset: the gate holds")
	t.assert_false(_cm(t).get("cutscene_active"), "nothing started")

	parent.queue_free()
	await t.tree.process_frame
