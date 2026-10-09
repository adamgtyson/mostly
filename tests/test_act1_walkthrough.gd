extends RefCounted

## Session 7, Block E: the critical-path walkthrough skeleton (BUILD_PLAN §7).
##
## Drives GameState through the Act One sequence by flags alone — no scenes,
## no travel — and asserts the region locks hold at every step. As content
## phases land their beats, this file grows into the full walkthrough that
## asserts on every critical-tier flag; today it is the lock discipline plus
## the ladder, which is what exists.
##
## PENDING [U2-2] OPEN: nothing is designed to happen to the outer-region
## locks after act1.letter_received — the regional-lock reason and unlock
## event are an open design item (ENGINEERING_CONSTRAINTS Appendix B). The
## post-letter assertion below therefore checks only that the letter flag
## exists and that the outer regions are still locked AT the letter; what
## unlocks them afterwards is asserted by nobody until [U2-2] is ruled.

## The eight ladder rungs in story order (WEIRDNESS_SPEC §2.1, PROPOSED ids).
const LADDER: Array[String] = [
	"act1.nine_days_noted",
	"act1.last_post.road_seen",
	"act1.mill_fixed",
	"act1.wren.map_received",
	"act1.turning.entered",
	"act1.abbey.arrived",
	"act1.forge_seen",
	"act1.abbey.departed",
]

## Regions that must stay locked for all of Act One.
const OUTER_REGIONS: Array[String] = ["measure", "distance", "quiet", "flow", "balance"]

func _gs(t: TestContext) -> Node:
	return t.tree.root.get_node("GameState")

func _router(t: TestContext) -> Node:
	return t.tree.root.get_node("SceneRouter")

func test_the_walkthrough_holds_the_region_locks(t: TestContext) -> void:
	var gs: Node = _gs(t)
	var router: Node = _router(t)

	# A new run starts with exactly the starting region reachable.
	router.new_game()
	t.assert_true(router.is_region_unlocked("hold"), "a new run can reach The Hold")
	t.assert_false(router.is_region_unlocked("turning"), "The Turning starts locked")
	_assert_outer_locked(t, router, "at new game")

	for flag: String in LADDER:
		gs.set_flag(flag, true)
		if flag == "act1.turning.entered":
			# Entering The Turning presupposes its lock opened; the beat that
			# opens it is phase 4 content, so the walkthrough stands in for it
			# the same way it stands in for every other unbuilt beat.
			gs.set_flag("region.turning.unlocked", true)
		_assert_outer_locked(t, router, "after %s" % flag)

	t.assert_true(router.is_region_unlocked("turning"), "The Turning is open by the Abbey leg")

	# Act One ends on the letter, as scheduled (ledger L1).
	gs.set_flag("act1.letter_received", true)
	_assert_outer_locked(t, router, "at the letter itself")

	# PENDING [U2-2] OPEN: no assertion exists for what the letter does to the
	# outer locks, because nothing is designed to. When [U2-2] is ruled, the
	# post-letter state gets asserted here and this comment comes out.

func test_the_lock_flags_are_declared_and_critical(t: TestContext) -> void:
	var gs: Node = _gs(t)
	var lock_flags: Array[String] = ["region.hold.unlocked", "region.turning.unlocked"]
	for region: String in OUTER_REGIONS:
		lock_flags.append("region.%s.unlocked" % region)
	for flag: String in lock_flags:
		t.assert_true(gs.is_declared(flag), "%s is in the registry" % flag)
		t.assert_true(gs.is_critical(flag), "%s is critical-tier — the walkthrough asserts on it (§2)" % flag)

func test_the_letter_flag_is_declared_and_reachable(t: TestContext) -> void:
	var gs: Node = _gs(t)
	t.assert_true(gs.is_declared("act1.letter_received"), "act1.letter_received is declared (PROPOSED id)")
	t.assert_true(gs.is_critical("act1.letter_received"), "and critical-tier: the walkthrough's final beat")
	gs.set_flag("act1.letter_received", true)
	t.assert_eq(gs.get_flag("act1.letter_received"), true, "and settable like any flag")

func test_the_ladder_is_exactly_the_curve(t: TestContext) -> void:
	# One source of truth: a renamed curve rung must break this file too, not
	# just raise intensity from nowhere.
	var w: Node = t.tree.root.get_node("Weirdness")
	var rungs: Array = []
	for entry: Variant in (w.curve() as Dictionary).get("act_progress", []):
		rungs.append(str((entry as Dictionary).get("when", "")))
	t.assert_eq(rungs, Array(LADDER), "the walkthrough and the weirdness curve name the same eight beats")

func _assert_outer_locked(t: TestContext, router: Node, moment: String) -> void:
	for region: String in OUTER_REGIONS:
		t.assert_false(router.is_region_unlocked(region),
			"The %s stays locked %s — [U2-2] has not opened anything" % [region.capitalize(), moment])
