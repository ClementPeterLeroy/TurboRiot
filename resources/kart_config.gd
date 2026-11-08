class_name KartConfig
extends Resource
## Handling units: metres, seconds and degrees. Share or duplicate per kart.

@export_group("Longitudinal")
@export_range(1.0, 80.0) var max_forward_speed: float = 22.0
@export_range(1.0, 30.0) var max_reverse_speed: float = 7.0
@export_range(0.1, 80.0) var acceleration: float = 16.0
@export_range(0.1, 100.0) var braking: float = 28.0
@export_range(0.1, 30.0) var coasting_deceleration: float = 6.0
@export_group("Steering")
@export_range(1.0, 240.0) var steering_rate: float = 110.0
@export_range(0.0, 30.0) var lateral_grip: float = 9.0
@export_range(0.1, 1.0) var high_speed_steering: float = 0.48
@export_group("Ground")
@export_range(1.0, 60.0) var gravity: float = 24.0
@export_range(0.0, 1.0) var wall_retention: float = 0.45
