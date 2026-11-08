class_name KartDynamics
extends RefCounted
## Pure functions, shared by the controller and headless tests.

static func longitudinal_speed(speed: float, command: DrivingCommand,
		config: KartConfig, delta: float) -> float:
	var result := speed
	# Brake has priority when both pedals are held. Opposite pedal first stops
	# the kart; reverse/forward begins on the following physics tick.
	if command.brake > 0.0:
		if speed > 0.0:
			result = move_toward(speed, 0.0, config.braking * command.brake * delta)
		else:
			result = move_toward(speed, -config.max_reverse_speed,
				config.acceleration * command.brake * delta)
	elif command.throttle > 0.0:
		if speed < 0.0:
			result = move_toward(speed, 0.0, config.braking * command.throttle * delta)
		else:
			result = move_toward(speed, config.max_forward_speed,
				config.acceleration * command.throttle * delta)
	else:
		result = move_toward(speed, 0.0, config.coasting_deceleration * delta)
	return clampf(result, -config.max_reverse_speed, config.max_forward_speed)

static func damp_lateral(speed: float, grip: float, delta: float) -> float:
	return speed * exp(-grip * delta)

static func steering_radians(speed: float, command: DrivingCommand,
		config: KartConfig, delta: float) -> float:
	var ratio := clampf(absf(speed) / config.max_forward_speed, 0.0, 1.0)
	var authority := minf(absf(speed) / 3.0, 1.0)
	return -command.steering * deg_to_rad(config.steering_rate) * authority \
		* lerpf(1.0, config.high_speed_steering, ratio) * signf(speed) * delta
