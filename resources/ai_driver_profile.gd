class_name AIDriverProfile
extends Resource
## Decision parameters only. No changes to KartConfig, grip, boost or gravity.
@export var display_name := "Standard"
@export_range(0.4, 1.0) var speed_fraction := 0.92
@export var lateral_acceleration := 7.0
@export var braking_confidence := 0.55
@export var lookahead_base := 3.8
@export var lookahead_seconds := 0.32
@export var steering_response := 4.5
@export var imperfection := 0.0
@export var passing_distance := 20.0
@export var lane_change_speed := 1.8
@export var recovery_delay := 4.0
@export var offroad_delay := 2.0
@export var drift_enabled := true
@export var drift_seconds := 1.25
@export var drift_reward_level := 1
