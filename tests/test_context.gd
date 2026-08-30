class_name TestContext
extends RefCounted

## Assertion sink for a single test function (ENGINEERING_CONSTRAINTS.md §11).
## run_tests.gd creates one TestContext per test, passes it to the test's
## run(t), then reads the counters to decide pass/fail. No framework.

## The running SceneTree, for tests that need to await frames or reach autoloads.
var tree: SceneTree = null

var _asserts: int = 0
var _failures: PackedStringArray = PackedStringArray()

func assert_eq(actual: Variant, expected: Variant, message: String = "") -> bool:
	_asserts += 1
	if _deep_equal(actual, expected):
		return true
	_record("expected %s, got %s" % [_fmt(expected), _fmt(actual)], message)
	return false

func assert_true(condition: bool, message: String = "") -> bool:
	_asserts += 1
	if condition:
		return true
	_record("expected true, got false", message)
	return false

func assert_false(condition: bool, message: String = "") -> bool:
	_asserts += 1
	if not condition:
		return true
	_record("expected false, got true", message)
	return false

func fail(message: String) -> void:
	_asserts += 1
	_record("fail()", message)

func assert_count() -> int:
	return _asserts

func failures() -> PackedStringArray:
	return _failures

func ok() -> bool:
	return _failures.is_empty()

func _record(detail: String, message: String) -> void:
	if message.is_empty():
		_failures.append(detail)
	else:
		_failures.append("%s (%s)" % [message, detail])

# Own recursive compare rather than Variant '==' so nested Dictionaries and
# Arrays — the shape almost every data test asserts on — compare by value
# regardless of how the engine treats reference types.
func _deep_equal(a: Variant, b: Variant) -> bool:
	if a is Dictionary and b is Dictionary:
		var da: Dictionary = a
		var db: Dictionary = b
		if da.size() != db.size():
			return false
		for k: Variant in da:
			if not db.has(k):
				return false
			if not _deep_equal(da[k], db[k]):
				return false
		return true
	if a is Array and b is Array:
		var aa: Array = a
		var ab: Array = b
		if aa.size() != ab.size():
			return false
		for i: int in aa.size():
			if not _deep_equal(aa[i], ab[i]):
				return false
		return true
	return a == b

func _fmt(v: Variant) -> String:
	if v is String:
		return "\"%s\"" % v
	if v is Dictionary or v is Array:
		return JSON.stringify(v)
	return str(v)
