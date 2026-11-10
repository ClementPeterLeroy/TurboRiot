@tool
extends Node3D
@export_enum("mushroom", "red_shell", "green_shell", "banana", "loot") var kind := "mushroom"

func _ready() -> void:
	PowerupModels.build(self, kind)
