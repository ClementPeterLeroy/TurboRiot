@tool
class_name LootBoxRow
extends Node3D
const BOX := preload("res://scenes/items/loot_box.tscn")
@export var configuration: LootRowConfig
var track_offset := 0.0
var boxes: Array[LootBox] = []
var system: Node

func _ready() -> void:
	if not configuration: return
	for index in configuration.count:
		var box := BOX.instantiate() as LootBox
		box.name = "Box%d" % (index + 1)
		box.system = system
		box.respawn_seconds = configuration.respawn_seconds
		box.position = Vector3((index - (configuration.count - 1) * 0.5) * configuration.spacing, 1.0, 0)
		add_child(box)
		boxes.append(box)
