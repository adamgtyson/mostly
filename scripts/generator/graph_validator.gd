class_name GraphValidator
extends RefCounted

## GraphValidator — the [G3] assertion set over a resolved MapGraph. Returns
## every error it finds, never the first one: the sweep's rule is "report all
## failing seeds; do not relax assertions to force a pass".
##
## Errors (structural, break the run):
##   - an anchor unreachable from an entry point
##   - a fill slot no edge references (orphan — authored content nothing links)
##   - a resolved chain outside its touchpoint band (needs `config`)
##   - a required_exits entry with no corresponding region.json edge
##   - a disconnected graph
## Warnings live on the graph itself; they are a designer's problem, not a
## validation failure.

static func validate(graph: MapGraph, region_json: Dictionary, config: Dictionary = {}) -> Array[String]:
	var errors: Array[String] = []

	_check_entry_reachability(errors, graph, region_json)
	_check_orphan_slots(errors, graph, region_json)
	if not config.is_empty():
		_check_chain_bounds(errors, graph, config)
	_check_required_exits(errors, region_json)
	if not graph.is_connected_graph():
		errors.append("graph is not connected: %d node(s), %d reachable from the first"
			% [graph.nodes.size(), graph.reachable_from(str(graph.nodes.keys()[0])).size() if not graph.nodes.is_empty() else 0])

	return errors

## Every anchor reachable from every entry point. An entry_points[] entry is
## an area name (EC-7); it maps to the anchor that carries that area.
static func _check_entry_reachability(errors: Array[String], graph: MapGraph, region_json: Dictionary) -> void:
	for entry: Variant in region_json.get("entry_points", []):
		var entry_id: String = _anchor_for_area(region_json, str(entry))
		if entry_id.is_empty() or not graph.nodes.has(entry_id):
			errors.append("entry_point '%s' maps to no anchor node" % str(entry))
			continue
		var reachable: Dictionary = graph.reachable_from(entry_id)
		for anchor_id: Variant in graph.anchor_ids():
			if not reachable.has(anchor_id):
				errors.append("anchor '%s' is unreachable from entry '%s'" % [str(anchor_id), str(entry)])

## A slot is referenced when some edge names it as via_slot or as an endpoint.
static func _check_orphan_slots(errors: Array[String], graph: MapGraph, region_json: Dictionary) -> void:
	var referenced: Dictionary = {}
	for edge: Variant in region_json.get("edges", []):
		if not (edge is Dictionary):
			continue
		referenced[str((edge as Dictionary).get("via_slot", ""))] = true
		referenced[str((edge as Dictionary).get("from", ""))] = true
		referenced[str((edge as Dictionary).get("to", ""))] = true
	for slot: Variant in region_json.get("fill_slots", []):
		if not (slot is Dictionary):
			continue
		var slot_id: String = str((slot as Dictionary).get("id", ""))
		if not referenced.has(slot_id):
			errors.append("slot '%s' is an orphan: no edge references it" % slot_id)

## The generator clamps, so this only fires on a hand-built or doctored graph —
## which is exactly when a second, independent check earns its keep. Terminal
## slot nodes (an endpoint slot's single stand-in) are not chains and are
## exempt; a chain is the set of fill nodes a via_slot produced.
static func _check_chain_bounds(errors: Array[String], graph: MapGraph, config: Dictionary) -> void:
	var counts: Dictionary = {}
	for fill_id: Variant in graph.fill_ids():
		var node: Dictionary = graph.nodes[fill_id]
		var slot_id: String = str(node.get("slot", ""))
		# Chain members carry ids "<slot>_<n>"; a terminal stand-in is named
		# exactly after its slot.
		if str(fill_id) == slot_id:
			continue
		counts[slot_id] = int(counts.get(slot_id, 0)) + 1
	var band: Dictionary = {}
	var types: Variant = config.get("touchpoint_types", {})
	if types is Dictionary and (types as Dictionary).has("default"):
		band = (types as Dictionary)["default"]
	if band.is_empty():
		return
	for slot_id: Variant in counts:
		var count: int = counts[slot_id]
		if count < int(band.get("min_distance", 0)) or count > int(band.get("max_distance", count)):
			errors.append("slot '%s' resolved to %d fill node(s), outside band [%d, %d]"
				% [str(slot_id), count, int(band.get("min_distance", 0)), int(band.get("max_distance", 0))])

## Each required_exits entry on an anchor must correspond to a region.json
## edge touching that anchor whose other end is the named anchor or slot.
static func _check_required_exits(errors: Array[String], region_json: Dictionary) -> void:
	for anchor: Variant in region_json.get("anchors", []):
		if not (anchor is Dictionary):
			continue
		var a: Dictionary = anchor
		var anchor_id: String = str(a.get("id", ""))
		for required: Variant in a.get("required_exits", []):
			var target: String = str(required)
			var satisfied: bool = false
			for edge: Variant in region_json.get("edges", []):
				if not (edge is Dictionary):
					continue
				var from_id: String = str((edge as Dictionary).get("from", ""))
				var to_id: String = str((edge as Dictionary).get("to", ""))
				if (from_id == anchor_id and to_id == target) or (to_id == anchor_id and from_id == target):
					satisfied = true
					break
			if not satisfied:
				errors.append("anchor '%s' requires an exit to '%s', and no edge provides it" % [anchor_id, target])

static func _anchor_for_area(region_json: Dictionary, area: String) -> String:
	for anchor: Variant in region_json.get("anchors", []):
		if anchor is Dictionary:
			if str((anchor as Dictionary).get("area", "")) == area or str((anchor as Dictionary).get("id", "")) == area:
				return str((anchor as Dictionary).get("id", ""))
	return ""
