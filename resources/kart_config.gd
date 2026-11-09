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
@export_group("Surfaces")
@export_range(0.1, 30.0) var surface_smoothing: float = 8.0
@export_range(0.0, 0.3) var surface_debounce: float = 0.06
@export_range(0.5, 3.0) var surface_probe_distance: float = 1.4
@export_range(0.1, 40.0) var overspeed_deceleration: float = 10.0
@export_group("Drift")
@export_range(1.0, 30.0) var drift_min_speed: float = 8.5
@export_range(0.1, 1.0) var drift_min_steering: float = 0.3
@export_range(0.1, 5.0) var drift_min_lateral_speed: float = 0.65
@export_range(0.05, 1.0) var drift_grip_multiplier: float = 0.28
@export_range(0.5, 2.0) var drift_steering_multiplier: float = 1.18
@export_range(1.0, 30.0) var drift_interrupt_speed: float = 6.0
@export var drift_charge_thresholds := Vector3(1.0, 2.0, 3.5)
@export var mini_turbo_strengths := Vector3(1.18, 1.3, 1.45)
@export var mini_turbo_durations := Vector3(0.65, 1.0, 1.5)
@export_group("Boost")
enum BoostPolicy { STRONGEST_WINS, REPLACE }
@export var boost_policy: BoostPolicy = BoostPolicy.STRONGEST_WINS
@export_range(1.0, 4.0) var boost_acceleration_multiplier: float = 1.8
@export_range(1.0, 100.0) var pad_propulsion_acceleration: float = 42.0
@export_range(30.0, 360.0) var pad_turn_rate: float = 180.0
@export_group("Air and landing")
@export_range(0.0, 1.0) var air_steering_authority: float = 0.2
@export_range(0.0, 1.0) var landing_speed_retention: float = 0.98
@export_range(0.0, 20.0) var landing_soft_speed: float = 5.0
@export_range(0.0, 1.0) var ground_snap_distance: float = 0.4
@export_range(0.1, 3.0) var ground_contact_speed: float = 0.5
@export_range(10.0, 85.0) var recovery_upright_angle: float = 55.0
