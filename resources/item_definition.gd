class_name ItemDefinition
extends Resource
## Immutable shared tuning; runtime state belongs to inventories and actors.
@export var identifier: StringName
@export var display_name := ""
@export var model: PackedScene
@export var icon: Texture2D
@export_range(1, 100) var weight := 25
@export var boost_strength := 1.4
@export var boost_duration := 1.8
@export var speed := 30.0
@export var lifetime := 8.0
@export var turn_degrees := 110.0
@export var target_range := 45.0
@export var maximum_bounces := 4
@export var hit_seconds := 1.35
@export var spin_degrees := 360.0
@export_range(0.0, 0.5) var hit_control := 0.12
@export_range(0.1, 0.8) var control_recovery_seconds := 0.35
@export var speed_multiplier := 0.55
@export var grip_multiplier := 0.24
@export var momentum_retention := 0.55
@export var knockback := 5.0
