extends Node2D

## Area root script (ENGINEERING_CONSTRAINTS.md §6). Every area scene has one
## root carrying this, exposing:
##   spawns      Dictionary[String, Vector2] — named arrival points
##   used_rect() Rect2i — the camera's bounds for this area
##
## Area ids are "<region>/<area>" everywhere (flags, saves, exits), built here
## from region_id and area_id. On ready the area registers itself with
## SceneRouter, so the router owns the current location from the first frame
## whether the game booted straight into this scene or travelled here.

## Region package this area belongs to, matching regions/<region_id>/.
@export var region_id: String = ""

## Area name within the region. Together these form the "<region>/<area>" id.
@export var area_id: String = ""

## Camera bounds in pixels. Kept explicit rather than derived from the
## TileMapLayer so an area's framing is a deliberate choice, not a side effect
## of which tiles happen to be painted.
@export var area_rect: Rect2i = Rect2i(0, 0, 320, 240)

## Optional: arrival points as {name: Vector2}. Marker2D children of a "Spawns"
## node are merged in as well and win on a name clash.
@export var extra_spawns: Dictionary = {}

var spawns: Dictionary = {}

func _ready() -> void:
	spawns = _collect_spawns()
	var root_node: Node = get_tree().root
	if root_node.has_node("SceneRouter"):
		root_node.get_node("SceneRouter").call("register_area", self)

func full_id() -> String:
	return "%s/%s" % [region_id, area_id]

func used_rect() -> Rect2i:
	return area_rect

## Where a traveller arriving under this spawn name should stand. Falls back to
## the area's "default" spawn, then to the centre of its rect.
func spawn_position(spawn_name: String) -> Vector2:
	if spawns.has(spawn_name):
		return spawns[spawn_name]
	if spawns.has("default"):
		return spawns["default"]
	var rect: Rect2i = used_rect()
	return Vector2(rect.position) + Vector2(rect.size) * 0.5

func _collect_spawns() -> Dictionary:
	var found: Dictionary = {}
	for key: Variant in extra_spawns:
		found[str(key)] = extra_spawns[key]
	var container: Node = get_node_or_null("Spawns")
	if container != null:
		for child: Node in container.get_children():
			if child is Marker2D:
				found[child.name] = (child as Marker2D).position
	return found
