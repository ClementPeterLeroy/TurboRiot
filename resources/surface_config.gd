@tool
class_name SurfaceConfig
extends Resource
@export var identifier: StringName = &"asphalt"
@export_range(0.1, 2.0) var acceleration_multiplier: float = 1.0
@export_range(0.1, 2.0) var max_speed_multiplier: float = 1.0
@export_range(0.1, 2.0) var lateral_grip_multiplier: float = 1.0
@export_range(0.1, 4.0) var resistance_multiplier: float = 1.0
@export var debug_color := Color.WHITE
@export var particle_identifier: StringName = &""

func multipliers() -> Vector4:
	return Vector4(acceleration_multiplier, max_speed_multiplier, lateral_grip_multiplier, resistance_multiplier)
