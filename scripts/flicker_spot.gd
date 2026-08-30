extends Marker2D

## FlickerSpot (ENGINEERING_CONSTRAINTS.md §10). A scene places these where a
## weirdness flicker may happen and names the kinds allowed there. It registers
## itself with Weirdness and does nothing else — a spot is a location, not a
## handler.

## Catalog kinds permitted at this spot. Empty means any kind the catalog allows.
@export var allowed_kinds: Array[String] = []

func _ready() -> void:
	var root_node: Node = get_tree().root
	if root_node.has_node("Weirdness"):
		root_node.get_node("Weirdness").call("register_spot", self)

func _exit_tree() -> void:
	var root_node: Node = get_tree().root
	if root_node != null and root_node.has_node("Weirdness"):
		root_node.get_node("Weirdness").call("unregister_spot", self)
