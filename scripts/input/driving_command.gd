class_name DrivingCommand
extends RefCounted
## Input providers return these normalized values; no devices in physics code.

var throttle: float
var brake: float
var steering: float
var drift: bool
var use_item: bool

func _init(gas: float = 0.0, stop: float = 0.0, turn: float = 0.0, drift_held: bool = false, activate: bool = false) -> void:
	throttle = clampf(gas, 0.0, 1.0) if is_finite(gas) else 0.0
	brake = clampf(stop, 0.0, 1.0) if is_finite(stop) else 0.0
	steering = clampf(turn, -1.0, 1.0) if is_finite(turn) else 0.0
	drift = drift_held
	use_item = activate
