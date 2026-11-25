class_name RouteBranch
extends Resource
## A directed alternative between two stations on the canonical lap.
@export var label := "Alternative"
@export var curve: Curve3D
@export var entry_offset := 0.0
@export var exit_offset := 0.0
@export var width := 9.0
