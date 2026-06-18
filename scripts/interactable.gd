extends Area2D

@export var label: String = "Object"

func interact() -> void:
	print("[Interact] %s" % label)
