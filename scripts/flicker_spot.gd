class_name FlickerSpot
extends Marker2D

## FlickerSpot (ENGINEERING_CONSTRAINTS.md §10; Docs/WEIRDNESS_SPEC.md §8). A
## scene places these where a weirdness flicker may happen, names the kinds
## allowed there, and carries whatever that kind needs to draw itself. It
## registers with Weirdness and does nothing else — a spot is a location and a
## handful of parameters, never a handler.
##
## §6 rule 6: spots are placed by hand and never on an exit, an interactable, or
## the critical-path walk line. Nothing a flicker does can block or redirect.

## Catalog kinds permitted at this spot. Empty means any kind the catalog allows.
@export var allowed_kinds: Array[String] = []

## Per-spot handler arguments, merged over the kind's catalog entry when a
## flicker fires (the spot wins a clash). What each kind reads:
##   tile_blink        layer_path, cell, source_id, atlas_coords
##   npc_wrong_frame   npc_path (an AnimatedSprite2D)
##   npc_line          npc_path, optional bubble_x / bubble_y
##   sound_offstage    stream (optional; a generated blip plays without one)
##   light_skip        dip (optional)
##   sprite_edge       z_index (optional)
## Node paths resolve against this spot first, then the area root that owns it.
@export var params: Dictionary = {}

func _ready() -> void:
	var root_node: Node = get_tree().root
	if root_node.has_node("Weirdness"):
		root_node.get_node("Weirdness").call("register_spot", self)

func _exit_tree() -> void:
	var root_node: Node = get_tree().root
	if root_node != null and root_node.has_node("Weirdness"):
		root_node.get_node("Weirdness").call("unregister_spot", self)
