class_name RegionGenerator
extends RefCounted

## RegionGenerator — resolves an EC-7 region.json into a MapGraph ([G3]
## architecture; Docs/04 "Map Generation (Anchor-and-Fill)" is the algorithm's
## source). No scenes, no tiles: output is a graph, and SceneRouter does not
## know it exists.
##
## Algorithm, per Docs/04: anchors first, in declared order — fixed every run;
## then fill, per run. Each region.json edge resolves as:
##   with via_slot    a chain of fill nodes, count = length_hint clamped to the
##                    touchpoint type's min/max distance (config; all numbers
##                    [G4] placeholders). Nothing in the EC-7 shape names a
##                    touchpoint type yet, so every chain uses "default" — an
##                    open question GENERATOR_SPIKE.md records.
##   endpoint slot    an edge whose from/to IS a slot id (EC-7 allows it, and
##                    the Hold's dev slot hangs off the workshop exactly so)
##                    materialises that slot as a single terminal fill node.
##   plain            a direct anchor-to-anchor link.
##
## Deterministic by construction: one RandomNumberGenerator seeded by the
## caller, drawn in a fixed order; identical inputs give byte-identical
## to_json(). Fill biomes come from slot pool ∩ region pool (slot pool wins an
## empty intersection, with a warning); settlement names stay null — the name
## pools are writing-track.

## generate() is stateless between calls; everything travels through locals.
static func generate(region_json: Dictionary, config: Dictionary, generation_seed: int) -> MapGraph:
	var graph := MapGraph.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = generation_seed

	var region_id: String = str(region_json.get("id", ""))
	var region_pool: Array = _region_biome_pool(config, region_id)
	var slots: Dictionary = _slots_by_id(region_json)

	# 1. Anchors, in declared order (Docs/04: fixed elements first).
	for anchor: Variant in region_json.get("anchors", []):
		if not (anchor is Dictionary):
			continue
		var a: Dictionary = anchor
		graph.add_node(str(a.get("id", "")), {
			"kind": "anchor",
			"area": str(a.get("area", "")),
		})

	# 2. Edges, in declared order; fill is the per-run half.
	for edge: Variant in region_json.get("edges", []):
		if not (edge is Dictionary):
			continue
		var e: Dictionary = edge
		var from_id: String = str(e.get("from", ""))
		var to_id: String = str(e.get("to", ""))

		# An endpoint that is a slot id materialises that slot in place.
		if slots.has(from_id) and not graph.nodes.has(from_id):
			from_id = _materialise_terminal_slot(graph, rng, slots[from_id], region_pool)
		if slots.has(to_id) and not graph.nodes.has(to_id):
			to_id = _materialise_terminal_slot(graph, rng, slots[to_id], region_pool)

		if not e.has("via_slot"):
			graph.add_edge(from_id, to_id)
			continue

		var slot_id: String = str(e.get("via_slot", ""))
		if not slots.has(slot_id):
			graph.warn("edge %s->%s names via_slot '%s', which the region does not declare; linked directly"
				% [from_id, to_id, slot_id])
			graph.add_edge(from_id, to_id)
			continue
		_resolve_chain(graph, rng, slots[slot_id], config, region_pool, from_id, to_id)

	return graph

# ── fill resolution ──────────────────────────────────────────────────────────

## A via_slot chain: length_hint clamped to the touchpoint band, one fill node
## per step, chained between the two endpoints.
static func _resolve_chain(graph: MapGraph, rng: RandomNumberGenerator, slot: Dictionary,
		config: Dictionary, region_pool: Array, from_id: String, to_id: String) -> void:
	var slot_id: String = str(slot.get("id", ""))
	var band: Dictionary = _touchpoint_band(config, "default")
	var hint: int = int(slot.get("length_hint", 0))
	var count: int = clampi(hint, int(band.get("min_distance", 1)), int(band.get("max_distance", 8)))
	if count != hint:
		graph.warn("slot '%s': length_hint %d clamped to %d by touchpoint band [%d, %d]"
			% [slot_id, hint, count, int(band.get("min_distance", 1)), int(band.get("max_distance", 8))])

	var pool: Array = _effective_pool(graph, slot, region_pool)
	var previous: String = from_id
	for i: int in count:
		var node_id: String = "%s_%d" % [slot_id, i + 1]
		graph.add_node(node_id, _fill_node(rng, slot, pool))
		graph.add_edge(previous, node_id)
		previous = node_id
	graph.add_edge(previous, to_id)

## An endpoint slot: one terminal fill node standing for the slot itself.
## Returns the node id the edge should use.
static func _materialise_terminal_slot(graph: MapGraph, rng: RandomNumberGenerator,
		slot: Dictionary, region_pool: Array) -> String:
	var node_id: String = str(slot.get("id", ""))
	var pool: Array = _effective_pool(graph, slot, region_pool)
	graph.add_node(node_id, _fill_node(rng, slot, pool))
	return node_id

static func _fill_node(rng: RandomNumberGenerator, slot: Dictionary, pool: Array) -> Dictionary:
	var spawn_pool: Variant = slot.get("spawn_pool", [])
	return {
		"kind": "fill",
		"slot": str(slot.get("id", "")),
		"area": slot.get("default_area") if str(slot.get("default_area", "")) != "" else null,
		"biome": pool[rng.randi_range(0, pool.size() - 1)] if not pool.is_empty() else null,
		"spawn": (spawn_pool as Array)[rng.randi_range(0, (spawn_pool as Array).size() - 1)]
			if spawn_pool is Array and not (spawn_pool as Array).is_empty() else null,
		# Settlement names are drawn from biome-appropriate pools (Docs/04) —
		# a writing-track item. The generator never invents one.
		"name": null,
	}

## Slot pool ∩ region pool; an empty intersection falls back to the slot's own
## pool with a warning (the slot author knew something the region table does
## not — flag it, don't erase it).
static func _effective_pool(graph: MapGraph, slot: Dictionary, region_pool: Array) -> Array:
	var slot_pool: Variant = slot.get("biome_pool", [])
	if not (slot_pool is Array) or (slot_pool as Array).is_empty():
		return region_pool
	var intersection: Array = []
	for biome: Variant in (slot_pool as Array):
		if region_pool.has(biome) or region_pool.is_empty():
			intersection.append(biome)
	if intersection.is_empty():
		graph.warn("slot '%s': biome_pool has no intersection with the region pool; slot pool wins"
			% str(slot.get("id", "")))
		return (slot_pool as Array).duplicate()
	return intersection

# ── config access ────────────────────────────────────────────────────────────

static func _touchpoint_band(config: Dictionary, type_name: String) -> Dictionary:
	var types: Variant = config.get("touchpoint_types", {})
	if types is Dictionary and (types as Dictionary).has(type_name):
		return (types as Dictionary)[type_name]
	return {"min_distance": 1, "max_distance": 8}

static func _region_biome_pool(config: Dictionary, region_id: String) -> Array:
	var regions: Variant = config.get("regions", {})
	if regions is Dictionary and (regions as Dictionary).has(region_id):
		var entry: Variant = (regions as Dictionary)[region_id]
		if entry is Dictionary and (entry as Dictionary).get("biome_pool") is Array:
			return (entry as Dictionary)["biome_pool"]
	return []

static func _slots_by_id(region_json: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for slot: Variant in region_json.get("fill_slots", []):
		if slot is Dictionary:
			out[str((slot as Dictionary).get("id", ""))] = slot
	return out
