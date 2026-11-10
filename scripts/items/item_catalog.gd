class_name ItemCatalog
extends RefCounted
const RESERVED := &"5E"
const ITEMS := [preload("res://resources/items/mushroom.tres"), preload("res://resources/items/red_shell.tres"), preload("res://resources/items/green_shell.tres"), preload("res://resources/items/banana.tres")]

static func choose(rng: RandomNumberGenerator) -> ItemDefinition:
	var total := 0
	for item: ItemDefinition in ITEMS: total += item.weight
	var draw := rng.randi_range(0, total - 1)
	for item: ItemDefinition in ITEMS:
		draw -= item.weight
		if draw < 0: return item
	return ITEMS[0]
