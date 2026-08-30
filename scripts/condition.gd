class_name Condition
extends RefCounted

## The condition grammar (ENGINEERING_CONSTRAINTS.md §5), parsed here and only
## here — no Expression, no eval. Used by dialogue entries and choices, by
## CutsceneTrigger, and by the validator when it collects flag references.
##
##   term      := flag | !flag | flag == value | flag != value
##              | flag >= n | flag <= n | flag > n | flag < n
##   expr      := term | expr && expr | expr || expr | ( expr )
##   value     := true | false | number | bare_word | "quoted string"
##
## An empty condition, or the literal "true", is always true — §5 requires the
## last entry of a dialogue to be "when": "true".

const TRUE_LITERALS: Array[String] = ["", "true"]

## Evaluates expr. `getter` is called as getter.call(flag_name) and returns the
## flag's current value, or null when unset.
static func evaluate(expr: String, getter: Callable) -> bool:
	var trimmed: String = expr.strip_edges()
	if TRUE_LITERALS.has(trimmed.to_lower()):
		return true
	if trimmed.to_lower() == "false":
		return false
	var tokens: PackedStringArray = _tokenize(trimmed)
	if tokens.is_empty():
		return true
	var cursor: Array = [0]
	var result: bool = _parse_or(tokens, cursor, getter)
	if cursor[0] < tokens.size():
		push_error("Condition: trailing tokens in '%s'" % expr)
		return false
	return result

## Every flag named anywhere in expr. Lets the validator prove that a condition
## only mentions declared flags without evaluating it.
static func referenced_flags(expr: String) -> PackedStringArray:
	var found := PackedStringArray()
	var trimmed: String = expr.strip_edges()
	if TRUE_LITERALS.has(trimmed.to_lower()) or trimmed.to_lower() == "false":
		return found
	var tokens: PackedStringArray = _tokenize(trimmed)
	var expect_flag: bool = true
	for i: int in tokens.size():
		var token: String = tokens[i]
		if token == "(" or token == ")" or token == "!" or token == "&&" or token == "||":
			expect_flag = true
			continue
		if _is_operator(token):
			# The right-hand side of a comparison is a value, never a flag.
			expect_flag = false
			continue
		if expect_flag and _is_flag_name(token):
			if not found.has(token):
				found.append(token)
		expect_flag = false
	return found

## Reports a syntax problem in expr, or "" when it parses.
static func syntax_error(expr: String) -> String:
	var trimmed: String = expr.strip_edges()
	if TRUE_LITERALS.has(trimmed.to_lower()) or trimmed.to_lower() == "false":
		return ""
	var tokens: PackedStringArray = _tokenize(trimmed)
	if tokens.is_empty():
		return "empty condition"
	var depth: int = 0
	for token: String in tokens:
		if token == "(":
			depth += 1
		elif token == ")":
			depth -= 1
			if depth < 0:
				return "unbalanced ')'"
	if depth != 0:
		return "unbalanced '('"
	var cursor: Array = [0]
	var always_false := func(_flag: String) -> Variant: return null
	_parse_or(tokens, cursor, always_false)
	if cursor[0] < tokens.size():
		return "unexpected token '%s'" % tokens[cursor[0]]
	return ""

# ── recursive descent ────────────────────────────────────────────────────────

static func _parse_or(tokens: PackedStringArray, cursor: Array, getter: Callable) -> bool:
	var value: bool = _parse_and(tokens, cursor, getter)
	while cursor[0] < tokens.size() and tokens[cursor[0]] == "||":
		cursor[0] += 1
		# No short-circuit: the right side is parsed either way so the cursor
		# always advances past it, then folded in.
		var right: bool = _parse_and(tokens, cursor, getter)
		value = value or right
	return value

static func _parse_and(tokens: PackedStringArray, cursor: Array, getter: Callable) -> bool:
	var value: bool = _parse_unary(tokens, cursor, getter)
	while cursor[0] < tokens.size() and tokens[cursor[0]] == "&&":
		cursor[0] += 1
		var right: bool = _parse_unary(tokens, cursor, getter)
		value = value and right
	return value

static func _parse_unary(tokens: PackedStringArray, cursor: Array, getter: Callable) -> bool:
	if cursor[0] < tokens.size() and tokens[cursor[0]] == "!":
		cursor[0] += 1
		return not _parse_unary(tokens, cursor, getter)
	return _parse_primary(tokens, cursor, getter)

static func _parse_primary(tokens: PackedStringArray, cursor: Array, getter: Callable) -> bool:
	if cursor[0] >= tokens.size():
		push_error("Condition: unexpected end of condition")
		return false

	var token: String = tokens[cursor[0]]

	if token == "(":
		cursor[0] += 1
		var inner: bool = _parse_or(tokens, cursor, getter)
		if cursor[0] < tokens.size() and tokens[cursor[0]] == ")":
			cursor[0] += 1
		else:
			push_error("Condition: missing ')'")
		return inner

	cursor[0] += 1
	var flag_name: String = token

	# A bare flag, unless a comparison operator follows.
	if cursor[0] < tokens.size() and _is_operator(tokens[cursor[0]]):
		var op: String = tokens[cursor[0]]
		cursor[0] += 1
		if cursor[0] >= tokens.size():
			push_error("Condition: '%s' has no right-hand side" % op)
			return false
		var literal: Variant = _to_value(tokens[cursor[0]])
		cursor[0] += 1
		return _compare(getter.call(flag_name), op, literal)

	return _truthy(getter.call(flag_name))

static func _compare(actual: Variant, op: String, expected: Variant) -> bool:
	match op:
		"==":
			return _values_equal(actual, expected)
		"!=":
			return not _values_equal(actual, expected)
	# Ordering comparisons are numeric; an unset flag counts as 0 so a counter
	# reads the same before and after its first increment.
	var lhs: float = _to_number(actual)
	var rhs: float = _to_number(expected)
	match op:
		">=":
			return lhs >= rhs
		"<=":
			return lhs <= rhs
		">":
			return lhs > rhs
		"<":
			return lhs < rhs
	push_error("Condition: unknown operator '%s'" % op)
	return false

static func _values_equal(actual: Variant, expected: Variant) -> bool:
	if actual == null:
		# An unset flag equals false and 0, which is how flags read before use.
		if expected is bool:
			return expected == false
		if expected is int or expected is float:
			return _to_number(expected) == 0.0
		return false
	if actual is bool or expected is bool:
		return _truthy(actual) == _truthy(expected)
	if (actual is int or actual is float) and (expected is int or expected is float):
		return is_equal_approx(_to_number(actual), _to_number(expected))
	return str(actual) == str(expected)

static func _truthy(value: Variant) -> bool:
	if value == null:
		return false
	if value is bool:
		return value
	if value is int or value is float:
		return _to_number(value) != 0.0
	if value is String:
		return not (value as String).is_empty()
	return true

static func _to_number(value: Variant) -> float:
	if value is bool:
		return 1.0 if value else 0.0
	if value is int or value is float:
		return float(value)
	if value is String and (value as String).is_valid_float():
		return (value as String).to_float()
	return 0.0

static func _to_value(token: String) -> Variant:
	if token.begins_with("\"") and token.ends_with("\"") and token.length() >= 2:
		return token.substr(1, token.length() - 2)
	match token.to_lower():
		"true":
			return true
		"false":
			return false
	if token.is_valid_int():
		return token.to_int()
	if token.is_valid_float():
		return token.to_float()
	return token

static func _is_operator(token: String) -> bool:
	return ["==", "!=", ">=", "<=", ">", "<"].has(token)

static func _is_flag_name(token: String) -> bool:
	if token.is_empty() or token.begins_with("\""):
		return false
	if ["true", "false"].has(token.to_lower()):
		return false
	if token.is_valid_float():
		return false
	return true

# ── tokenizer ────────────────────────────────────────────────────────────────

static func _tokenize(expr: String) -> PackedStringArray:
	var tokens := PackedStringArray()
	var i: int = 0
	var length: int = expr.length()
	while i < length:
		var c: String = expr[i]

		if c == " " or c == "\t" or c == "\n" or c == "\r":
			i += 1
			continue

		if c == "(" or c == ")":
			tokens.append(c)
			i += 1
			continue

		if c == "\"":
			var closing: int = expr.find("\"", i + 1)
			if closing == -1:
				push_error("Condition: unterminated string in '%s'" % expr)
				tokens.append("\"\"")
				break
			tokens.append(expr.substr(i, closing - i + 1))
			i = closing + 1
			continue

		var two: String = expr.substr(i, 2)
		if ["&&", "||", "==", "!=", ">=", "<="].has(two):
			tokens.append(two)
			i += 2
			continue

		if c == "!" or c == ">" or c == "<":
			tokens.append(c)
			i += 1
			continue

		# A bare word: flag name, number, or true/false.
		var start: int = i
		while i < length:
			var ch: String = expr[i]
			if ch == " " or ch == "\t" or ch == "(" or ch == ")" or ch == "!" or ch == "&" or ch == "|" or ch == "=" or ch == ">" or ch == "<":
				break
			i += 1
		if i == start:
			# Nothing consumed: skip the character rather than loop forever.
			i += 1
			continue
		tokens.append(expr.substr(start, i - start))
	return tokens
