extends RefCounted

## Milestone 5: the v2 features themselves — entries, set[], choices, gender
## tokens. Built from in-memory documents so no authored content is invented.

func _dm(t: TestContext) -> Node:
	return t.tree.root.get_node("DialogueManager")

func _gs(t: TestContext) -> Node:
	return t.tree.root.get_node("GameState")

func _doc(nodes: Dictionary, entries: Array = []) -> Dictionary:
	return {
		"id": "probe",
		"entries": entries if not entries.is_empty() else [{"when": "true", "start": "start"}],
		"nodes": nodes,
	}

func test_entries_pick_the_first_matching_branch(t: TestContext) -> void:
	var dm: Node = _dm(t)
	var gs: Node = _gs(t)
	var document: Dictionary = _doc({
		"unlocked": {"lines": [{"speaker": "patch", "text": "Open."}]},
		"start": {"lines": [{"speaker": "patch", "text": "Shut."}]},
	}, [
		{"when": "region.hold.unlocked", "start": "unlocked"},
		{"when": "true", "start": "start"},
	])

	dm.start_document(document)
	t.assert_eq(dm.get_current_line().get("text"), "Shut.", "the fallback entry runs while the flag is unset")
	dm.force_end()

	gs.set_flag("region.hold.unlocked", true)
	dm.start_document(document)
	t.assert_eq(dm.get_current_line().get("text"), "Open.", "the first matching entry wins once the flag is set")
	dm.force_end()

func test_set_applies_on_node_entry(t: TestContext) -> void:
	var dm: Node = _dm(t)
	var gs: Node = _gs(t)
	dm.start_document(_doc({
		"start": {
			"set": [
				{"flag": "region.hold.unlocked", "value": true},
				{"flag": "weird.misroutes", "increment": 2},
			],
			"lines": [{"speaker": "patch", "text": "Noted."}],
		},
	}))
	t.assert_eq(gs.get_flag("region.hold.unlocked", false), true, "set[] writes a value")
	t.assert_eq(gs.get_flag("weird.misroutes", 0), 2, "set[] honours increment")
	dm.force_end()

func test_next_chains_nodes(t: TestContext) -> void:
	var dm: Node = _dm(t)
	dm.start_document(_doc({
		"start": {"lines": [{"speaker": "patch", "text": "One."}], "next": "second"},
		"second": {"lines": [{"speaker": "patch", "text": "Two."}]},
	}))
	t.assert_eq(dm.get_current_line().get("text"), "One.", "first node")
	dm.advance()
	t.assert_true(dm.dialogue_active, "the dialogue continues into the next node")
	t.assert_eq(dm.get_current_line().get("text"), "Two.", "second node")
	dm.advance()
	t.assert_false(dm.dialogue_active, "the dialogue ends after the last node")

func test_choices_are_offered_and_followed(t: TestContext) -> void:
	var dm: Node = _dm(t)
	var presented: Array = []
	var handler := func(choices: Array) -> void: presented.append(choices)
	dm.choices_presented.connect(handler)

	dm.start_document(_doc({
		"start": {
			"lines": [{"speaker": "patch", "text": "Well?"}],
			"choices": [
				{"text": "Fix it.", "next": "fix"},
				{"text": "Leave it.", "next": "leave"},
			],
		},
		"fix": {"lines": [{"speaker": "patch", "text": "Fixed."}]},
		"leave": {"lines": [{"speaker": "patch", "text": "Left."}]},
	}))
	dm.advance()

	dm.choices_presented.disconnect(handler)
	t.assert_eq(presented.size(), 1, "choices are announced once")
	t.assert_true(dm.awaiting_choice(), "the dialogue waits on a choice")
	t.assert_eq(dm.get_current_choices().size(), 2, "both choices are offered")

	dm.choose(1)
	t.assert_false(dm.awaiting_choice(), "choosing clears the wait")
	t.assert_eq(dm.get_current_line().get("text"), "Left.", "the chosen branch is entered")
	dm.force_end()

func test_choices_are_filtered_by_their_condition(t: TestContext) -> void:
	var dm: Node = _dm(t)
	var document: Dictionary = _doc({
		"start": {
			"lines": [{"speaker": "patch", "text": "Well?"}],
			"choices": [
				{"text": "Use the shortcut.", "when": "region.hold.unlocked", "next": "a"},
				{"text": "Walk.", "next": "a"},
			],
		},
		"a": {"lines": [{"speaker": "patch", "text": "Fine."}]},
	})
	dm.start_document(document)
	dm.advance()
	t.assert_eq(dm.get_current_choices().size(), 1, "the gated choice is hidden while its flag is unset")
	t.assert_eq(dm.get_current_choices()[0].get("text"), "Walk.", "the ungated choice remains")
	dm.force_end()

	_gs(t).set_flag("region.hold.unlocked", true)
	dm.start_document(document)
	dm.advance()
	t.assert_eq(dm.get_current_choices().size(), 2, "both choices appear once the flag is set")
	dm.force_end()

func test_gender_tokens_substitute(t: TestContext) -> void:
	var dm: Node = _dm(t)
	var masculine := "Ask {him/her} about {his/her} cart; {he/she} built it {himself/herself}."
	t.assert_eq(
		dm.substitute_gender(masculine, false),
		"Ask him about his cart; he built it himself.",
		"masculine substitution")
	t.assert_eq(
		dm.substitute_gender(masculine, true),
		"Ask her about her cart; she built it herself.",
		"feminine substitution")
	t.assert_eq(dm.substitute_gender("{his/hers} now.", true), "hers now.", "his/hers is distinct from his/her")

func test_gender_follows_the_flag(t: TestContext) -> void:
	var dm: Node = _dm(t)
	var gs: Node = _gs(t)
	var document: Dictionary = _doc({
		"start": {"lines": [{"speaker": "patch", "text": "{he/she} finished."}]},
	})

	t.assert_false(dm.is_feminine(), "unset falls back to masculine")
	dm.start_document(document)
	t.assert_eq(dm.get_current_line().get("text"), "he finished.", "masculine by default")
	dm.force_end()

	gs.set_flag("sys.patch_gender", "f")
	t.assert_true(dm.is_feminine(), "the flag selects feminine")
	dm.start_document(document)
	t.assert_eq(dm.get_current_line().get("text"), "she finished.", "feminine once the flag is set")
	dm.force_end()

func test_text_f_overrides_tokens_when_feminine(t: TestContext) -> void:
	var dm: Node = _dm(t)
	var gs: Node = _gs(t)
	var document: Dictionary = _doc({
		"start": {"lines": [{
			"speaker": "patch",
			"text": "The smith and his apprentice.",
			"text_f": "The smith and her girl.",
		}]},
	})

	dm.start_document(document)
	t.assert_eq(dm.get_current_line().get("text"), "The smith and his apprentice.", "masculine uses text")
	dm.force_end()

	gs.set_flag("sys.patch_gender", "f")
	dm.start_document(document)
	t.assert_eq(dm.get_current_line().get("text"), "The smith and her girl.", "feminine uses text_f")
	dm.force_end()

func test_speaker_resolves_through_the_character_registry(t: TestContext) -> void:
	var dm: Node = _dm(t)
	t.assert_true(dm.has_character("patch"), "patch is registered")
	t.assert_true(dm.has_character("voices_from_outside"), "the outside voices are registered")

	var resolved: Dictionary = dm.resolve_line({"speaker": "patch", "text": "hmf."})
	t.assert_eq(resolved.get("speaker"), "Patch", "the id resolves to a display name")
	t.assert_eq(resolved.get("portrait"), "patch_default", "the character's default portrait is filled in")
	t.assert_eq(resolved.get("speaker_id"), "patch", "the raw id is still available")

func test_a_line_may_override_its_portrait(t: TestContext) -> void:
	var dm: Node = _dm(t)
	var resolved: Dictionary = dm.resolve_line({"speaker": "patch", "text": "x", "portrait": "patch_annoyed"})
	t.assert_eq(resolved.get("portrait"), "patch_annoyed", "an explicit portrait wins over the default")

func test_force_end_stops_mid_dialogue(t: TestContext) -> void:
	var dm: Node = _dm(t)
	var ended: Array = []
	var handler := func() -> void: ended.append(true)
	dm.dialogue_ended.connect(handler)

	dm.start_document(_doc({
		"start": {"lines": [
			{"speaker": "patch", "text": "One."},
			{"speaker": "patch", "text": "Two."},
		]},
	}))
	dm.force_end()
	dm.dialogue_ended.disconnect(handler)

	t.assert_false(dm.dialogue_active, "force_end ends the dialogue")
	t.assert_eq(ended.size(), 1, "dialogue_ended fires exactly once")

func test_a_missing_node_ends_rather_than_hangs(t: TestContext) -> void:
	var dm: Node = _dm(t)
	dm.start_document(_doc({
		"start": {"lines": [{"speaker": "patch", "text": "One."}], "next": "nowhere"},
	}))
	dm.advance()
	t.assert_false(dm.dialogue_active, "a dangling next ends the dialogue instead of hanging")
