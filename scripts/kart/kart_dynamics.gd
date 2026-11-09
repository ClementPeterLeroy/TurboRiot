class_name KartDynamics
extends RefCounted
## Pure functions, shared by the controller and headless tests.

static func longitudinal_speed(speed: float, command: DrivingCommand,
		config: KartConfig, delta: float, acceleration_multiplier: float = 1.0,
		speed_multiplier: float = 1.0, resistance_multiplier: float = 1.0,
		boost_multiplier: float = 1.0) -> float:
	var result := speed
	var forward_cap := config.max_forward_speed * speed_multiplier * boost_multiplier
	var reverse_cap := config.max_reverse_speed * speed_multiplier
	var acceleration := config.acceleration * acceleration_multiplier
	# Brake has priority when both pedals are held. Opposite pedal first stops
	# the kart; reverse/forward begins on the following physics tick.
	if command.brake > 0.0:
		if speed > 0.0:
			result = move_toward(speed, 0.0, config.braking * command.brake * delta)
		else:
			result = move_toward(speed, -reverse_cap, acceleration * command.brake * delta)
	elif command.throttle > 0.0:
		if speed < 0.0:
			result = move_toward(speed, 0.0, config.braking * command.throttle * delta)
		else:
			result = move_toward(speed, forward_cap, acceleration * command.throttle * delta)
	else:
		result = move_toward(speed, 0.0, config.coasting_deceleration * resistance_multiplier * delta)
	# When caps fall (terrain changes / boost expires), remove excess smoothly.
	# Opposing pedals still use the stronger explicit brake calculation above.
	if speed > forward_cap and command.brake <= 0:
		result = move_toward(speed, forward_cap, config.overspeed_deceleration * resistance_multiplier * delta)
	elif speed < -reverse_cap and command.throttle <= 0:
		result = move_toward(speed, -reverse_cap, config.overspeed_deceleration * resistance_multiplier * delta)
	return result

static func air_yaw(speed: float, command: DrivingCommand, config: KartConfig, delta: float) -> float:
	return steering_radians(speed, command, config, delta) * config.air_steering_authority

static func damp_lateral(speed: float, grip: float, delta: float) -> float:
	return speed * exp(-grip * delta)

static func steering_radians(speed: float, command: DrivingCommand,
		config: KartConfig, delta: float) -> float:
	var ratio := clampf(absf(speed) / config.max_forward_speed, 0.0, 1.0)
	var authority := minf(absf(speed) / 3.0, 1.0)
	return -command.steering * deg_to_rad(config.steering_rate) * authority \
		* lerpf(1.0, config.high_speed_steering, ratio) * signf(speed) * delta
