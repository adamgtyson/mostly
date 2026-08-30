extends Area2D

## Exit (ENGINEERING_CONSTRAINTS.md §6). An Area2D the player walks into that
## names where it leads. It does no work itself — every transition goes through
## SceneRouter, the single choke point.

@export var target_region: String = ""
@export var target_area: String = ""
@export var target_spawn: String = "default"

## Off for an exit opened by a cutscene or an interaction rather than by walking.
@export var trigger_on_body_entered: bool = true

func _ready() -> void:
	if trigger_on_body_entered:
		body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	# Only the player travels; anything else brushing the exit is ignored.
	if not body.is_in_group("player") and body.name != "Player":
		return
	use()

func use() -> void:
	if target_region.is_empty() or target_area.is_empty():
		push_error("Exit '%s' has no target set." % name)
		return
	var root_node: Node = get_tree().root
	if not root_node.has_node("SceneRouter"):
		push_error("Exit '%s': no SceneRouter." % name)
		return
	root_node.get_node("SceneRouter").call("go_to", target_region, target_area, target_spawn)
