class_name JsonSchema
extends RefCounted

## Minimal JSON-Schema-shaped validator (ENGINEERING_CONSTRAINTS.md §11 and §13:
## "every JSON content type has a schema in data/schema/"). Deliberately a small
## subset rather than a dependency — §11 mandates no framework, and the content
## shapes the project defines need only these keywords:
##
##   type                  "object" | "array" | "string" | "number" | "integer"
##                         | "boolean" | "null", or an array of those
##   required              [String, ...]        keys that must be present
##   properties            {key: subschema}
##   additionalProperties  false to reject unlisted keys (default true)
##   items                 subschema applied to every array element
##   valuesSchema          subschema applied to every value of an object whose
##                         keys are data (dialogue nodes, tag tables)
##   enum                  [Variant, ...]       allowed exact values
##   minimum / maximum     numeric bounds, inclusive
##   minLength             minimum String length
##
## Returns a list of human-readable errors; empty means valid.

static func validate(data: Variant, schema: Dictionary, path: String = "$") -> PackedStringArray:
	var errors := PackedStringArray()

	if schema.has("type"):
		var type_errors: PackedStringArray = _check_type(data, schema["type"], path)
		if not type_errors.is_empty():
			# A wrong type makes every nested check meaningless noise.
			return type_errors

	if schema.has("enum"):
		var allowed: Array = schema["enum"]
		if not allowed.has(data):
			errors.append("%s: %s is not one of %s" % [path, _fmt(data), _fmt(allowed)])

	if data is String:
		var s: String = data
		if schema.has("minLength") and s.length() < int(schema["minLength"]):
			errors.append("%s: string is shorter than %d" % [path, int(schema["minLength"])])

	if data is int or data is float:
		var n: float = float(data)
		if schema.has("minimum") and n < float(schema["minimum"]):
			errors.append("%s: %s is below the minimum %s" % [path, str(n), str(schema["minimum"])])
		if schema.has("maximum") and n > float(schema["maximum"]):
			errors.append("%s: %s is above the maximum %s" % [path, str(n), str(schema["maximum"])])

	if data is Dictionary:
		errors.append_array(_check_object(data, schema, path))

	if data is Array and schema.has("items"):
		var arr: Array = data
		var item_schema: Dictionary = schema["items"]
		for i: int in arr.size():
			errors.append_array(validate(arr[i], item_schema, "%s[%d]" % [path, i]))

	return errors

static func _check_object(data: Dictionary, schema: Dictionary, path: String) -> PackedStringArray:
	var errors := PackedStringArray()

	if schema.has("required"):
		for key: Variant in schema["required"]:
			if not data.has(str(key)):
				errors.append("%s: missing required key '%s'" % [path, str(key)])

	if schema.has("valuesSchema"):
		var value_schema: Dictionary = schema["valuesSchema"]
		for key: Variant in data:
			var key_str: String = str(key)
			if key_str.begins_with("_"):
				continue
			errors.append_array(validate(data[key], value_schema, "%s.%s" % [path, key_str]))
		return errors

	var properties: Dictionary = schema.get("properties", {})
	for key: Variant in data:
		var key_str: String = str(key)
		if properties.has(key_str):
			errors.append_array(validate(data[key], properties[key_str], "%s.%s" % [path, key_str]))
		elif schema.get("additionalProperties", true) == false:
			# Keys beginning with _ are documentation (_comment and friends) and
			# are allowed everywhere, so a data file can explain itself.
			if not key_str.begins_with("_"):
				errors.append("%s: unexpected key '%s'" % [path, key_str])

	return errors

static func _check_type(data: Variant, expected: Variant, path: String) -> PackedStringArray:
	var errors := PackedStringArray()
	var names: Array = expected if expected is Array else [expected]
	for name: Variant in names:
		if _is_type(data, str(name)):
			return errors
	errors.append("%s: expected %s, got %s" % [path, _fmt(expected), _type_name(data)])
	return errors

static func _is_type(data: Variant, type_name: String) -> bool:
	match type_name:
		"object":
			return data is Dictionary
		"array":
			return data is Array
		"string":
			return data is String
		"boolean":
			return data is bool
		"integer":
			# JSON has one number type; an integral float is a valid integer.
			if data is bool:
				return false
			if data is int:
				return true
			return data is float and is_equal_approx(data, floor(data))
		"number":
			if data is bool:
				return false
			return data is int or data is float
		"null":
			return data == null
	return false

static func _type_name(data: Variant) -> String:
	if data == null:
		return "null"
	if data is bool:
		return "boolean"
	if data is int:
		return "integer"
	if data is float:
		return "number"
	if data is String:
		return "string"
	if data is Array:
		return "array"
	if data is Dictionary:
		return "object"
	return "unknown"

static func _fmt(v: Variant) -> String:
	if v is String:
		return "\"%s\"" % v
	if v is Array or v is Dictionary:
		return JSON.stringify(v)
	return str(v)
