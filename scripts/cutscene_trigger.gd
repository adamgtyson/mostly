extends Node2D

## CutsceneTrigger (ENGINEERING_CONSTRAINTS.md §8) — the generic replacement for
## per-cutscene scripts like the old opening_cutscene.gd.
##
## Drop one in a scene, set cutscene_id to a file in data/cutscenes/, and
## optionally set `when` to a §5 condition gating it. Actors named in the beats
## resolve against actor_root, which defaults to this node's parent — the scene
## root — so a beat says "Player/AnimatedSprite2D" and means it.

## Cutscene to play, matching data/cutscenes/<id>.json.
@export var cutscene_id: String = ""

## Condition (§5 grammar) that must hold for the cutscene to play. Empty or
## "true" always plays.
@export var when: String = ""

## Play as soon as the scene is ready. Off for a cutscene fired by something else.
@export var play_on_ready: bool = true

## Node the beats' actor paths resolve against. Empty means this node's parent.
@export var actor_root_path: NodePath

## Record the cutscene as seen when it ends, so CutsceneSkip offers [ Z ] Skip
## on later runs.
@export var mark_seen_on_end: bool = true

func _ready() -> void:
	if play_on_ready:
		call_deferred("play")

func play() -> bool:
	# A deferred play can outlive its scene: the engine frees a swapped-out
	# scene before the deferred queue drains (session 9's boot crash). Off the
	# tree there is nothing to play into — return quietly, never an error.
	if not is_inside_tree():
		return false
	if cutscene_id.is_empty():
		push_error("CutsceneTrigger: no cutscene_id set on %s" % name)
		return false
	if not _condition_holds():
		return false

	var actor_root: Node = _actor_root()
	if actor_root == null:
		push_error("CutsceneTrigger: no actor root for '%s'" % cutscene_id)
		return false

	if mark_seen_on_end:
		CutsceneManager.cutscene_ended.connect(_on_cutscene_ended, CONNECT_ONE_SHOT)
	if not CutsceneManager.play_cutscene_id(cutscene_id, actor_root):
		if mark_seen_on_end and CutsceneManager.cutscene_ended.is_connected(_on_cutscene_ended):
			CutsceneManager.cutscene_ended.disconnect(_on_cutscene_ended)
		return false
	return true

## Conditions resolve flags, not nodes (§5), so this never walks the tree:
## GameState is an autoload singleton and reachable even when this node is not
## inside a tree — the exact state a deferred play() can find itself in.
func _condition_holds() -> bool:
	return Condition.evaluate(when, func(flag: String) -> Variant: return GameState.get_flag(flag, null))

func _actor_root() -> Node:
	if not actor_root_path.is_empty():
		return get_node_or_null(actor_root_path)
	return get_parent()

func _on_cutscene_ended() -> void:
	CutsceneSkip.mark_seen(cutscene_id)
