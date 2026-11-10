class_name KartInventory
extends Node
var held: ItemDefinition
var latched := true
var cooldown := 0.0
var collected := 0
var used := 0

func _ready() -> void:
	get_parent().reset_performed.connect(clear)

func clear() -> void:
	held = null
	latched = true
	cooldown = 0

func pickup(definition: ItemDefinition) -> bool:
	if held or not definition or not get_parent().driving_enabled: return false
	held = definition
	collected += 1
	return true

func request(pressed: bool, delta: float) -> bool:
	cooldown = maxf(0, cooldown - delta)
	var rising := pressed and not latched
	latched = pressed
	return rising and held != null and cooldown == 0 and get_parent().driving_enabled

func consume() -> void:
	held = null
	cooldown = 0.35
	used += 1
