extends Node

## Inventory (ENGINEERING_CONSTRAINTS.md §4).
##
## One shared party bag; equipment is per party member. Item definitions are
## data — a new consumable is a JSON file in data/items/ plus, at most, an entry
## in the on_use effect registry, never a new script.
##
## Instance shapes (§4):
##   stackable      { "item_id": String, "count": int }
##   gear / gadget  { "item_id": String, "charges_left": int, "attachments": [] }

signal item_added(item_id: String, count: int)
signal item_removed(item_id: String, count: int)
signal item_equipped(member: String, slot: String, instance: Dictionary)
signal item_unequipped(member: String, slot: String)
signal item_used(item_id: String, effect: String)

const ITEMS_DIR := "res://data/items"
const TAGS_PATH := "res://data/tags.json"

const GEAR_TYPES: Array[String] = ["gear", "gadget"]

var _definitions: Dictionary = {}
var _tags: Dictionary = {}

var _bag: Array = []
var _equipped: Dictionary = {}

## effect id -> Callable(context: Dictionary) -> bool. A consumable's "on_use"
## names one of these; adding an effect is the only code a new item can need.
var _effects: Dictionary = {}

func _ready() -> void:
	_load_definitions()
	_load_tags()
	_register_default_effects()

# ── definitions ──────────────────────────────────────────────────────────────

func definition(item_id: String) -> Dictionary:
	return _definitions.get(item_id, {})

func has_definition(item_id: String) -> bool:
	return _definitions.has(item_id)

func definition_ids() -> Array:
	return _definitions.keys()

func known_tags() -> Array:
	return _tags.keys()

func is_stackable(item_id: String) -> bool:
	return bool(definition(item_id).get("stackable", false))

func max_stack(item_id: String) -> int:
	return int(definition(item_id).get("max_stack", 1))

func item_weight(item_id: String) -> float:
	return float(definition(item_id).get("weight", 0.0))

# ── instances ────────────────────────────────────────────────────────────────

## Builds the instance shape §4 specifies for this item's type.
func make_instance(item_id: String, count: int = 1) -> Dictionary:
	if not has_definition(item_id):
		push_error("Inventory: no definition for item '%s'" % item_id)
		return {}
	var def: Dictionary = definition(item_id)
	if is_stackable(item_id):
		return {"item_id": item_id, "count": count}
	return {
		"item_id": item_id,
		"charges_left": int(def.get("charges", 0)),
		"attachments": [],
	}

# ── the shared bag ───────────────────────────────────────────────────────────

func bag() -> Array:
	return _bag

## 0 means unlimited (§4).
func max_bag_slots() -> int:
	return GameConfig.get_int("inventory.max_bag_slots", 0)

func bag_is_full() -> bool:
	var limit: int = max_bag_slots()
	return limit > 0 and _bag.size() >= limit

func add_item(item_id: String, count: int = 1) -> bool:
	if not has_definition(item_id):
		push_error("Inventory: cannot add unknown item '%s'" % item_id)
		return false
	if count <= 0:
		return false

	var remaining: int = count
	if is_stackable(item_id):
		var cap: int = max_stack(item_id)
		# Top up existing stacks before opening a new one.
		for entry: Dictionary in _bag:
			if remaining <= 0:
				break
			if entry.get("item_id") != item_id:
				continue
			var space: int = cap - int(entry.get("count", 0))
			if space <= 0:
				continue
			var moved: int = min(space, remaining)
			entry["count"] = int(entry["count"]) + moved
			remaining -= moved
		while remaining > 0:
			if bag_is_full():
				push_warning("Inventory: bag is full, %d x %s dropped" % [remaining, item_id])
				break
			var stack: int = min(cap, remaining)
			_bag.append(make_instance(item_id, stack))
			remaining -= stack
	else:
		while remaining > 0:
			if bag_is_full():
				push_warning("Inventory: bag is full, %d x %s dropped" % [remaining, item_id])
				break
			_bag.append(make_instance(item_id))
			remaining -= 1

	var added: int = count - remaining
	if added > 0:
		item_added.emit(item_id, added)
	return remaining == 0

func remove_item(item_id: String, count: int = 1) -> bool:
	if count <= 0:
		return false
	if count_of(item_id) < count:
		return false

	var remaining: int = count
	for i: int in range(_bag.size() - 1, -1, -1):
		if remaining <= 0:
			break
		var entry: Dictionary = _bag[i]
		if entry.get("item_id") != item_id:
			continue
		if entry.has("count"):
			var taken: int = min(int(entry["count"]), remaining)
			entry["count"] = int(entry["count"]) - taken
			remaining -= taken
			if int(entry["count"]) <= 0:
				_bag.remove_at(i)
		else:
			_bag.remove_at(i)
			remaining -= 1

	item_removed.emit(item_id, count)
	return true

func count_of(item_id: String) -> int:
	var total: int = 0
	for entry: Dictionary in _bag:
		if entry.get("item_id") != item_id:
			continue
		total += int(entry.get("count", 1))
	return total

func has_item(item_id: String, count: int = 1) -> bool:
	return count_of(item_id) >= count

## True if the bag holds anything carrying this tag — the shape recipe inputs
## use for non-ideal substitution (§9).
func has_tag(tag: String, count: int = 1) -> bool:
	return count_with_tag(tag) >= count

func count_with_tag(tag: String) -> int:
	var total: int = 0
	for entry: Dictionary in _bag:
		var def: Dictionary = definition(str(entry.get("item_id", "")))
		var tags: Array = def.get("tags", [])
		if tags.has(tag):
			total += int(entry.get("count", 1))
	return total

# ── weight (EC-4a) ───────────────────────────────────────────────────────────

func total_weight() -> float:
	var total: float = 0.0
	for entry: Dictionary in _bag:
		var id: String = str(entry.get("item_id", ""))
		total += item_weight(id) * int(entry.get("count", 1))
	return total

func weight_limit() -> float:
	return GameConfig.get_float("inventory.realistic_weight_max", 40.0)

## Carry limits apply only in realistic-weight mode, a per-run choice made at
## New Game. With the flag off, v1 ignores weight entirely.
func realistic_weight_enabled() -> bool:
	var root_node: Node = get_tree().root
	if not root_node.has_node("GameState"):
		return false
	return bool(root_node.get_node("GameState").call("get_flag", "sys.realistic_weight", false))

func is_over_weight() -> bool:
	if not realistic_weight_enabled():
		return false
	return total_weight() > weight_limit()

# ── equipment ────────────────────────────────────────────────────────────────

func equipped(member: String) -> Dictionary:
	return _equipped.get(member, {})

func equipped_in(member: String, slot: String) -> Dictionary:
	return equipped(member).get(slot, {})

## Moves one instance of item_id from the bag into the member's slot. Anything
## already in that slot returns to the bag.
func equip(member: String, item_id: String) -> bool:
	if not has_definition(item_id):
		push_error("Inventory: cannot equip unknown item '%s'" % item_id)
		return false
	var def: Dictionary = definition(item_id)
	if not GEAR_TYPES.has(str(def.get("type", ""))):
		push_error("Inventory: '%s' is not equippable" % item_id)
		return false
	var slot: String = str(def.get("slot", ""))
	if slot.is_empty():
		push_error("Inventory: '%s' has no slot" % item_id)
		return false
	if not has_item(item_id):
		return false

	if not _equipped.has(member):
		_equipped[member] = {}
	var member_slots: Dictionary = _equipped[member]
	if member_slots.has(slot):
		unequip(member, slot)

	var instance: Dictionary = make_instance(item_id)
	remove_item(item_id)
	member_slots[slot] = instance
	item_equipped.emit(member, slot, instance)
	return true

func unequip(member: String, slot: String) -> bool:
	var member_slots: Dictionary = _equipped.get(member, {})
	if not member_slots.has(slot):
		return false
	var instance: Dictionary = member_slots[slot]
	member_slots.erase(slot)
	_bag.append(instance)
	item_unequipped.emit(member, slot)
	return true

## Flattened modifiers from everything the member has equipped — the shape §1
## damage resolution reads.
func modifiers_for(member: String) -> Array:
	var out: Array = []
	for slot: String in equipped(member):
		var instance: Dictionary = equipped(member)[slot]
		var def: Dictionary = definition(str(instance.get("item_id", "")))
		for modifier: Variant in def.get("modifiers", []):
			out.append(modifier)
	return out

# ── on_use effect registry (§4) ──────────────────────────────────────────────

func register_effect(effect_id: String, handler: Callable) -> void:
	_effects[effect_id] = handler

func has_effect(effect_id: String) -> bool:
	return _effects.has(effect_id)

func effect_ids() -> Array:
	return _effects.keys()

## Consumes one of item_id and runs its on_use effect. context carries whatever
## the effect needs (target, amount, flag) and is passed through untouched.
func use_item(item_id: String, context: Dictionary = {}) -> bool:
	if not has_item(item_id):
		return false
	var def: Dictionary = definition(item_id)
	var effect_id: String = str(def.get("on_use", ""))
	if effect_id.is_empty():
		push_warning("Inventory: '%s' has no on_use effect" % item_id)
		return false
	if not _effects.has(effect_id):
		push_error("Inventory: no registered effect '%s' (used by %s)" % [effect_id, item_id])
		return false

	var merged: Dictionary = context.duplicate()
	merged["item_id"] = item_id
	merged["item"] = def
	var handler: Callable = _effects[effect_id]
	if not bool(handler.call(merged)):
		return false

	if str(def.get("type", "")) == "consumable":
		remove_item(item_id)
	item_used.emit(item_id, effect_id)
	return true

func _register_default_effects() -> void:
	# set_flag is fully wired; heal and apply_buff are the §4 named effects whose
	# targets (combatants, status) arrive with Battle in phase 5. They report
	# success so item plumbing is testable, and do nothing else yet.
	register_effect("set_flag", func(context: Dictionary) -> bool:
		var key: String = str(context.get("flag", ""))
		if key.is_empty():
			push_error("Inventory: set_flag effect needs a 'flag' in its context")
			return false
		var root_node: Node = get_tree().root
		if not root_node.has_node("GameState"):
			return false
		root_node.get_node("GameState").call("set_flag", key, context.get("value", true))
		return true)

	register_effect("heal", func(context: Dictionary) -> bool:
		# TODO(phase 5): apply to the target combatant once Battle exists.
		return true)

	register_effect("apply_buff", func(context: Dictionary) -> bool:
		# TODO(phase 5): apply the named status once Battle exists.
		return true)

# ── save contract (§3, §13) ──────────────────────────────────────────────────

func to_save_dict() -> Dictionary:
	return {
		"bag": _bag.duplicate(true),
		"equipped": _equipped.duplicate(true),
	}

func from_save_dict(data: Dictionary) -> void:
	var saved_bag: Variant = data.get("bag", [])
	_bag = (saved_bag as Array).duplicate(true) if saved_bag is Array else []
	var saved_equipped: Variant = data.get("equipped", {})
	_equipped = (saved_equipped as Dictionary).duplicate(true) if saved_equipped is Dictionary else {}

func reset() -> void:
	_bag.clear()
	_equipped.clear()

# ── loading ──────────────────────────────────────────────────────────────────

func _load_definitions() -> void:
	_definitions = {}
	var dir := DirAccess.open(ITEMS_DIR)
	if dir == null:
		push_warning("Inventory: no item directory at %s" % ITEMS_DIR)
		return
	for file_name: String in dir.get_files():
		if not file_name.ends_with(".json"):
			continue
		var path: String = "%s/%s" % [ITEMS_DIR, file_name]
		var data: Variant = _read_json(path)
		if not (data is Dictionary):
			continue
		var def: Dictionary = data
		var id: String = str(def.get("id", ""))
		if id.is_empty():
			push_error("Inventory: %s has no id" % path)
			continue
		if _definitions.has(id):
			push_error("Inventory: duplicate item id '%s' in %s" % [id, path])
			continue
		_definitions[id] = def

func _load_tags() -> void:
	_tags = {}
	var data: Variant = _read_json(TAGS_PATH)
	if not (data is Dictionary):
		return
	var tags: Variant = (data as Dictionary).get("tags", {})
	if tags is Dictionary:
		_tags = tags

func _read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Inventory: cannot read %s" % path)
		return null
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK:
		push_error("Inventory: malformed JSON in %s" % path)
		return null
	return json.get_data()
