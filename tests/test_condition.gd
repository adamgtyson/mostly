extends RefCounted

## Milestone 5: the condition grammar (§5) — one parser, no Expression, no eval.

func _getter(values: Dictionary) -> Callable:
	return func(flag: String) -> Variant: return values.get(flag, null)

func _eval(expr: String, values: Dictionary) -> bool:
	return Condition.evaluate(expr, _getter(values))

func test_true_literal_and_empty_are_always_true(t: TestContext) -> void:
	t.assert_true(_eval("true", {}), "'true' is the always-match entry (§5)")
	t.assert_true(_eval("", {}), "an empty condition is true")
	t.assert_false(_eval("false", {}), "'false' is false")

func test_bare_flag_is_truthiness(t: TestContext) -> void:
	t.assert_true(_eval("region.hold.unlocked", {"region.hold.unlocked": true}), "a set bool is true")
	t.assert_false(_eval("region.hold.unlocked", {"region.hold.unlocked": false}), "a false bool is false")
	t.assert_false(_eval("region.hold.unlocked", {}), "an unset flag is false")
	t.assert_true(_eval("weird.misroutes", {"weird.misroutes": 3}), "a non-zero number is truthy")
	t.assert_false(_eval("weird.misroutes", {"weird.misroutes": 0}), "zero is falsy")

func test_negation(t: TestContext) -> void:
	t.assert_true(_eval("!region.hold.unlocked", {}), "! on an unset flag is true")
	t.assert_false(_eval("!region.hold.unlocked", {"region.hold.unlocked": true}), "! on a set flag is false")
	t.assert_true(_eval("!!region.hold.unlocked", {"region.hold.unlocked": true}), "double negation")

func test_equality(t: TestContext) -> void:
	t.assert_true(_eval("sys.patch_gender == \"f\"", {"sys.patch_gender": "f"}), "quoted string equality")
	t.assert_false(_eval("sys.patch_gender == \"f\"", {"sys.patch_gender": "m"}), "mismatched string")
	t.assert_true(_eval("sys.patch_gender != \"f\"", {"sys.patch_gender": "m"}), "inequality")
	t.assert_true(_eval("weird.misroutes == 2", {"weird.misroutes": 2}), "numeric equality")
	t.assert_true(_eval("region.hold.unlocked == true", {"region.hold.unlocked": true}), "boolean equality")
	t.assert_true(_eval("region.hold.unlocked == false", {}), "an unset flag equals false")

func test_ordering_comparisons(t: TestContext) -> void:
	t.assert_true(_eval("weird.misroutes >= 3", {"weird.misroutes": 3}), ">= at the boundary")
	t.assert_false(_eval("weird.misroutes >= 4", {"weird.misroutes": 3}), ">= below")
	t.assert_true(_eval("weird.misroutes <= 3", {"weird.misroutes": 3}), "<= at the boundary")
	t.assert_true(_eval("weird.misroutes > 2", {"weird.misroutes": 3}), "> above")
	t.assert_false(_eval("weird.misroutes < 3", {"weird.misroutes": 3}), "< at the boundary")
	t.assert_true(_eval("weird.misroutes >= 0", {}), "an unset counter reads as 0")

func test_and_or(t: TestContext) -> void:
	var state := {"a.b.c": true, "d.e.f": false}
	t.assert_true(_eval("a.b.c && !d.e.f", state), "&& of two true terms")
	t.assert_false(_eval("a.b.c && d.e.f", state), "&& with a false term")
	t.assert_true(_eval("a.b.c || d.e.f", state), "|| with one true term")
	t.assert_false(_eval("d.e.f || d.e.f", state), "|| with no true term")

func test_parentheses_change_grouping(t: TestContext) -> void:
	var state := {"a": false, "b": true, "c": true}
	# Without parens && binds tighter: a || (b && c) is true.
	t.assert_true(_eval("a || b && c", state), "&& binds tighter than ||")
	t.assert_false(_eval("(a || b) && !c", state), "parentheses regroup")
	t.assert_true(_eval("(a || b) && c", state), "parenthesised or, then and")

func test_referenced_flags_finds_every_name(t: TestContext) -> void:
	var found: PackedStringArray = Condition.referenced_flags("region.hold.unlocked && weird.misroutes >= 2")
	t.assert_eq(found.size(), 2, "both flags found")
	t.assert_true(found.has("region.hold.unlocked"), "the bare flag is found")
	t.assert_true(found.has("weird.misroutes"), "the compared flag is found")

func test_referenced_flags_ignores_literals(t: TestContext) -> void:
	t.assert_eq(Condition.referenced_flags("true").size(), 0, "'true' names no flag")
	var found: PackedStringArray = Condition.referenced_flags("sys.patch_gender == \"f\" || weird.misroutes > 3")
	t.assert_eq(found.size(), 2, "only the two flags, not the literals")
	t.assert_false(found.has("\"f\""), "a quoted value is not a flag")
	t.assert_false(found.has("3"), "a number is not a flag")

func test_syntax_error_reporting(t: TestContext) -> void:
	t.assert_eq(Condition.syntax_error("a.b && c.d"), "", "a sound condition reports no error")
	t.assert_eq(Condition.syntax_error("true"), "", "the true literal is sound")
	t.assert_false(Condition.syntax_error("(a.b && c.d").is_empty(), "an unbalanced paren is reported")
	t.assert_false(Condition.syntax_error("a.b && c.d)").is_empty(), "a stray close paren is reported")

func test_whitespace_is_insignificant(t: TestContext) -> void:
	var state := {"a.b": 5}
	t.assert_true(_eval("a.b>=5", state), "no spaces around the operator")
	t.assert_true(_eval("   a.b   >=   5   ", state), "extra spaces")
