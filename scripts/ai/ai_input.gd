class_name AIInput
extends DrivingInput
signal recovery_requested(reason: String)
var kart: KartController
var line: RacingLine
var profile: AIDriverProfile
var traffic: Array[KartController] = []
var driver_id := 0
var expected_offset := 0.0
var validated_offset := 0.0
var current_offset := 0.0
var target_point := Vector3.ZERO
var target_speed := 0.0
var lane_offset := 0.0
var lane_target := 0.0
var passing_side := 0
var recovery_state := "ready"
var _command := DrivingCommand.new()
var _hint := -1
var _time := 0.0
var _stall_time := 0.0
var _offroad_time := 0.0
var _missed_time := 0.0
var _drift_time := 0.0
var _last_offset := 0.0
var _pass_target: KartController
var _pass_hold := 0.0

func _ready() -> void:
	process_physics_priority = -10 # Decide before all kart movement updates.
	kart.reset_performed.connect(reset_navigation)
	reset_navigation()

func get_command() -> DrivingCommand:
	return _command

func reset_navigation() -> void:
	_time = 0
	target_speed = 0
	target_point = kart.global_position
	_hint = -1
	_stall_time = 0
	_offroad_time = 0
	_missed_time = 0
	_drift_time = 0
	_pass_target = null
	passing_side = 0
	lane_target = 0
	lane_offset = 0
	_pass_hold = 0
	_command = DrivingCommand.new()
	if line:
		var projection := line.project(kart.global_position)
		_last_offset = projection.x
		# Start lane transitions at the actual grid/recovery lateral position;
		# starting at zero can steer into traffic before an outward pass begins.
		lane_offset = projection.y
	current_offset = _last_offset
	recovery_state = "ready"

func _physics_process(delta: float) -> void:
	if not kart.driving_enabled:
		_command.throttle = 0
		_command.brake = 0
		_command.steering = 0
		_command.drift = false
		return
	_time += delta
	var projection := line.project(kart.global_position, _hint)
	_hint = int(projection.z)
	current_offset = projection.x
	var advance := fposmod(current_offset - _last_offset + line.length * 0.5, line.length) - line.length * 0.5
	_last_offset = current_offset
	_stall_time = maxf(0, _stall_time - delta * 3) if advance > 0.025 else _stall_time + delta
	_offroad_time = _offroad_time + delta if absf(projection.y) > line.road_half_width + 2 else 0.0
	var past := fposmod(current_offset - validated_offset, line.length)
	var interval := fposmod(expected_offset - validated_offset, line.length)
	_missed_time = _missed_time + delta if past > interval + 7 and past < line.length * 0.5 else 0.0
	recovery_state = "driving"
	if _stall_time > profile.recovery_delay or _offroad_time > profile.offroad_delay or _missed_time > 1.25:
		recovery_state = "requesting recovery"
		recovery_requested.emit("missed gate" if _missed_time > 1.25 else ("off road" if _offroad_time > profile.offroad_delay else "stalled"))
		return
	var speed := Vector2(kart.velocity.x, kart.velocity.z).length()
	var curvature := line.curvatures[_hint]
	target_speed = line.planned_speed(current_offset, speed, kart.config, profile)
	var front_speed := _traffic_decision(delta, speed, curvature)
	if front_speed >= 0:
		target_speed = minf(target_speed, front_speed)
	lane_offset = move_toward(lane_offset, lane_target, profile.lane_change_speed * delta)
	var lookahead := profile.lookahead_base + speed * profile.lookahead_seconds
	target_point = line.point_at(current_offset + lookahead, lane_offset)
	var local := kart.global_basis.inverse() * (target_point - kart.global_position)
	var authority := maxf(0.15, minf(absf(kart.signed_speed) / 3, 1))
	var maximum_yaw := deg_to_rad(kart.config.steering_rate) * authority * lerpf(1, kart.config.high_speed_steering, clampf(speed / kart.config.max_forward_speed, 0, 1))
	var steering := 2 * maxf(speed, 3) * local.x / maxf(1, Vector2(local.x, local.z).length_squared()) / maximum_yaw
	if curvature < 0.015 and passing_side == 0:
		steering += profile.imperfection * sin(_time * 0.7 + driver_id * 2.3)
	_command.steering = move_toward(_command.steering, clampf(steering, -1, 1), profile.steering_response * delta)
	var error := target_speed - speed
	_command.brake = clampf(-error / 3.5, 0, 1) if error < -0.7 and kart.signed_speed > 1 else 0.0
	_command.throttle = clampf(error / 2.0 + 0.25, 0, 1) if _command.brake == 0 else 0.0
	# Drifting uses exactly the existing grounded/slip/release reward rules.
	var drift_ok := profile.drift_enabled and kart.is_on_floor() and speed > 10 and curvature > 0.025 and curvature < 0.07 \
		and absf(_command.steering) > 0.34 and absf(projection.y - lane_offset) < 2 and passing_side == 0
	if drift_ok and _drift_time < profile.drift_seconds and kart.drift.level(kart.config) < profile.drift_reward_level:
		_command.drift = true
		_drift_time += delta
	else:
		_command.drift = false
		if curvature < 0.018:
			_drift_time = 0

func _traffic_decision(delta: float, speed: float, curvature: float) -> float:
	var forward := line.forwards[_hint]
	var right := forward.cross(Vector3.UP)
	_pass_hold = maxf(0, _pass_hold - delta)
	if is_instance_valid(_pass_target):
		var separation := (_pass_target.global_position - kart.global_position).dot(forward)
		if not _pass_target.driving_enabled or (_pass_hold == 0 and (separation < -4 or separation > 30)):
			_pass_target = null
			passing_side = 0
			lane_target = 0
	var nearest: KartController
	var nearest_distance := profile.passing_distance
	for other in traffic:
		if other == kart or not other.driving_enabled:
			continue
		var difference := other.global_position - kart.global_position
		if difference.length_squared() > 30 * 30:
			continue
		var longitudinal := difference.dot(forward)
		var lateral := difference.dot(right)
		if longitudinal > 0 and longitudinal < nearest_distance and absf(lateral) < 2.0:
			nearest = other
			nearest_distance = longitudinal
	var nearest_lateral := line.project(nearest.global_position, _hint).y if nearest else 0.0
	if nearest and not is_instance_valid(_pass_target) and curvature < 0.025 and line.curvatures[line.index_at(current_offset + 12)] < 0.035:
		if nearest.velocity.dot(forward) < speed + 1:
			var preferred := -1 if driver_id % 2 == 0 else 1
			for side in [preferred, -preferred]:
				var proposed := clampf(nearest_lateral + side * 2.8, -line.road_half_width + 1.8, line.road_half_width - 1.8)
				if absf(proposed - nearest_lateral) < 2.3:
					continue
				var clear := true
				for other in traffic:
					if other == kart or other == nearest or not other.driving_enabled:
						continue
					var difference := other.global_position - kart.global_position
					if absf(difference.dot(forward)) < 7 and absf(difference.dot(right) + lane_offset - proposed) < 2.1:
						clear = false
				if clear:
					_pass_target = nearest
					passing_side = side
					lane_target = proposed
					_pass_hold = 2.5
					break
	if nearest and nearest_distance < 4.0 and absf(lane_offset - nearest_lateral) < 2.1:
		return maxf(0, nearest.velocity.dot(forward) - 1)
	return -1.0
