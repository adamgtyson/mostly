class_name MapGraph
extends RefCounted

## MapGraph — the anchor-and-fill generator's output ([G3] architecture;
## EC-7 is the input format's authority). A resolved graph: every anchor from
## region.json as a node, every fill slot resolved into concrete fill nodes,
## every connection explicit. RefCounted by [G3]'s own rule, because the
## validator runs it a thousand times headless.
##
## The graph drives nothing yet. v1 fills every slot by hand (EC-7);
## resolve_default_areas() is the promised bridge — exercised by tests,
## consumed by nobody.
##
## Node shape, by kind:
##   anchor  { "kind": "anchor", "area": String }
##   fill    { "kind": "fill", "slot": String, "area": String|null,
##             "biome": String|null, "spawn": String|null, "name": null }
## `name` is always null: settlement names come from biome-appropriate pools
## (Docs/04 "Generated Elements") and those pools are a writing-track item.

const JSON_VERSION := 1

## node id -> node Dictionary. Insertion order is generation order, which is
## what keeps to_json() byte-stable for a given seed.
var nodes: Dictionary = {}

## Array of { "from": String, "to": String }. Undirected for reachability —
## roads are walked both ways (§6).
var edges: Array = []

## Human-readable notes the generator left (clamped lengths, pool fallbacks).
## Warnings are not errors: the graph is usable, but a designer should look.
var warnings: Array = []

func add_node(id: String, node: Dictionary) -> void:
	nodes[id] = node

func add_edge(from_id: String, to_id: String) -> void:
	edges.append({"from": from_id, "to": to_id})

func warn(message: String) -> void:
	warnings.append(message)

func anchor_ids() -> Array:
	var out: Array = []
	for id: Variant in nodes:
		if str((nodes[id] as Dictionary).get("kind", "")) == "anchor":
			out.append(str(id))
	return out

func fill_ids() -> Array:
	var out: Array = []
	for id: Variant in nodes:
		if str((nodes[id] as Dictionary).get("kind", "")) == "fill":
			out.append(str(id))
	return out

## Every node id reachable from `start_id`, including itself. Breadth-first
## over undirected edges; a missing start yields {}.
func reachable_from(start_id: String) -> Dictionary:
	if not nodes.has(start_id):
		return {}
	var neighbours: Dictionary = {}
	for edge: Variant in edges:
		var a: String = str((edge as Dictionary).get("from", ""))
		var b: String = str((edge as Dictionary).get("to", ""))
		if not neighbours.has(a):
			neighbours[a] = []
		if not neighbours.has(b):
			neighbours[b] = []
		(neighbours[a] as Array).append(b)
		(neighbours[b] as Array).append(a)

	var seen: Dictionary = {start_id: true}
	var frontier: Array = [start_id]
	while not frontier.is_empty():
		var current: String = frontier.pop_front()
		for next_id: Variant in neighbours.get(current, []):
			if not seen.has(next_id):
				seen[next_id] = true
				frontier.append(next_id)
	return seen

func is_connected_graph() -> bool:
	if nodes.is_empty():
		return true
	return reachable_from(str(nodes.keys()[0])).size() == nodes.size()

## The EC-7 v1 bridge: every fill node mapped to its slot's default_area —
## the hand-filled scene it stands for until the generator drives scenes.
func resolve_default_areas() -> Dictionary:
	var out: Dictionary = {}
	for id: Variant in nodes:
		var node: Dictionary = nodes[id]
		if str(node.get("kind", "")) == "fill":
			out[str(id)] = node.get("area")
	return out

# ── serialisation ([G3]: MapGraph JSON) ─────────────────────────────────────

func to_json() -> Dictionary:
	return {
		"version": JSON_VERSION,
		"nodes": nodes.duplicate(true),
		"edges": edges.duplicate(true),
		"warnings": warnings.duplicate(true),
	}

static func from_json(data: Dictionary) -> MapGraph:
	var graph := MapGraph.new()
	var node_data: Variant = data.get("nodes", {})
	if node_data is Dictionary:
		for id: Variant in (node_data as Dictionary):
			graph.nodes[str(id)] = ((node_data as Dictionary)[id] as Dictionary).duplicate(true)
	var edge_data: Variant = data.get("edges", [])
	if edge_data is Array:
		for edge: Variant in (edge_data as Array):
			if edge is Dictionary:
				graph.edges.append((edge as Dictionary).duplicate(true))
	var warning_data: Variant = data.get("warnings", [])
	if warning_data is Array:
		graph.warnings = (warning_data as Array).duplicate(true)
	return graph
