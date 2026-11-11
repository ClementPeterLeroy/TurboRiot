class_name LootRowConfig
extends Resource
## Pixel anchors from the supplied blue-marked 1008 x 1011 overhead map.
@export var map_anchor := Vector2.ZERO
## Negative retains the original private-map anchor convention.
@export var route_fraction := -1.0
@export_range(1, 8) var count := 4
@export var spacing := 3.2
@export var respawn_seconds := 5.0
