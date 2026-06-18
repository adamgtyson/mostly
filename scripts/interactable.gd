extends Area2D

@export var label: String = "Object"
@export var dialogue_id: String = ""

func interact() -> void:
	if dialogue_id.is_empty():
		push_warning("[Interactable] '%s' has no dialogue_id set." % label)
		return
	DialogueManager.start_dialogue(dialogue_id)
