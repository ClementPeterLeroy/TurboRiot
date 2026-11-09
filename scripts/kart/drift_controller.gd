class_name DriftController
extends RefCounted
var active := false
var charge: float = 0.0

func update(command: DrivingCommand, speed: float, lateral: float, grounded: bool,
		interrupted: bool, config: KartConfig, delta: float) -> int:
	var eligible := grounded and speed >= config.drift_min_speed and not interrupted
	var engaged := absf(command.steering) >= config.drift_min_steering
	var activity := eligible and engaged and absf(lateral) >= config.drift_min_lateral_speed
	if not eligible:
		clear()
		return 0
	if active and not command.drift:
		var award := level(config) if activity else 0
		clear()
		return award
	if not command.drift:
		return 0
	if not active and engaged:
		active = true
	if active and activity:
		charge = minf(charge + delta, config.drift_charge_thresholds.z)
	return 0

func level(config: KartConfig) -> int:
	var result := 0
	for threshold in [config.drift_charge_thresholds.x, config.drift_charge_thresholds.y, config.drift_charge_thresholds.z]:
		if charge + 0.000001 >= threshold:
			result += 1
	return result

func clear() -> void:
	active = false
	charge = 0.0
