class_name KartController
extends CharacterBody3D

signal reset_performed
signal landed(impact_speed: float)

@export var config: KartConfig
@export var input_provider: DrivingInput
var safe_spawn: Transform3D
var current_command := DrivingCommand.new()
var signed_speed: float = 0.0
var boost := BoostController.new()
var drift := DriftController.new()
var surface_detector := SurfaceDetector.new()
var _ground_motion := Vector3.ZERO
var driving_enabled: bool = true:
	set(value):
		driving_enabled = value
		if not value:
			clear_temporary_states()

func _ready() -> void:
	assert(config != null, "Assign a KartConfig")
	safe_spawn = global_transform
	floor_snap_length = config.ground_snap_distance
	floor_constant_speed = true
	floor_stop_on_slope = true

func reset_to_spawn() -> void:
	global_transform = safe_spawn
	velocity = Vector3.ZERO
	signed_speed = 0.0
	clear_temporary_states()
	surface_detector.reset()
	reset_physics_interpolation()
	reset_performed.emit()

func clear_temporary_states() -> void:
	current_command = DrivingCommand.new()
	drift.clear()
	boost.clear()
	_ground_motion = Vector3.ZERO

func activate_boost(source: StringName, strength: float, duration: float) -> bool:
	if not driving_enabled:
		return false
	return boost.activate(source, strength, duration, config.boost_policy)

func activate_directional_boost(direction: Vector3, strength: float, duration: float, redirect_seconds: float) -> bool:
	if not driving_enabled or not direction.is_finite():
		return false
	direction.y = 0
	if direction.length_squared() < 0.0001:
		return false
	# Pads always act. Under strongest-wins retain a stronger active cap and
	# the longer timer; they cannot be ignored because approach is backwards.
	if config.boost_policy == KartConfig.BoostPolicy.STRONGEST_WINS and boost.active():
		strength = maxf(strength, boost.strength)
		duration = maxf(duration, boost.remaining)
	if not boost.activate(&"boost_pad", strength, duration, KartConfig.BoostPolicy.REPLACE):
		return false
	boost.direction = direction.normalized()
	boost.direction_remaining = minf(redirect_seconds, duration)
	drift.clear()
	return true

func _physics_process(delta: float) -> void:
	surface_detector.update(self, config, delta)
	floor_snap_length = config.ground_snap_distance
	if not driving_enabled:
		current_command = DrivingCommand.new()
		velocity = Vector3(0, -config.ground_contact_speed if is_on_floor() else velocity.y - config.gravity * delta, 0)
		move_and_slide()
		signed_speed = 0.0
		return
	boost.advance(delta)
	current_command = input_provider.get_command() if input_provider else DrivingCommand.new()
	var forward := -global_basis.z
	var right := global_basis.x
	var grounded := is_on_floor()
	var speed := velocity.dot(forward)
	var lateral := velocity.dot(right)
	var award := drift.update(current_command, speed, lateral, grounded, false, config, delta)
	if grounded:
		var surface := surface_detector.effective
		var horizontal: Vector3
		if boost.direction_remaining > 0:
			drift.clear()
			award = 0
			horizontal = Vector3(velocity.x, 0, velocity.z).move_toward(
				boost.direction * config.max_forward_speed * surface.y * boost.strength, config.pad_propulsion_acceleration * delta)
			var target_yaw := atan2(-boost.direction.x, -boost.direction.z)
			rotate_y(clampf(wrapf(target_yaw - global_rotation.y, -PI, PI), -deg_to_rad(config.pad_turn_rate) * delta, deg_to_rad(config.pad_turn_rate) * delta))
		else:
			var acceleration_multiplier := surface.x * (config.boost_acceleration_multiplier if boost.active() else 1.0)
			speed = KartDynamics.longitudinal_speed(speed, current_command, config, delta,
				acceleration_multiplier, surface.y, surface.w, boost.strength)
			var grip := config.lateral_grip * surface.z * (config.drift_grip_multiplier if drift.active else 1.0)
			lateral = KartDynamics.damp_lateral(lateral, grip, delta)
			var yaw := KartDynamics.steering_radians(speed, current_command, config, delta)
			rotate_y(yaw * (config.drift_steering_multiplier if drift.active else 1.0))
			horizontal = forward * speed + right * lateral
		var normal := get_floor_normal()
		var tangent := horizontal.slide(normal)
		if tangent.length_squared() > 0.00001:
			tangent = tangent.normalized() * horizontal.length()
		# Keep contact with an ascending ramp until its actual edge. A purely
		# tangent upward velocity can otherwise detach because upward movement
		# disables automatic floor snapping in CharacterBody3D.
		velocity = tangent - normal * config.ground_contact_speed
	else:
		# Air steering changes heading only; throttle cannot manufacture momentum.
		rotate_y(KartDynamics.air_yaw(speed, current_command, config, delta))
		velocity.y -= config.gravity * delta
	var before_move := velocity
	move_and_slide()
	var severe_collision := false
	for i in get_slide_collision_count():
		var normal := get_slide_collision(i).get_normal()
		if absf(normal.y) < 0.5:
			severe_collision = -before_move.dot(normal) >= config.drift_interrupt_speed
			velocity.x *= config.wall_retention
			velocity.z *= config.wall_retention
			break
	if grounded and not is_on_floor():
		velocity.y = maxf(velocity.y, _ground_motion.y)
	if is_on_floor():
		_ground_motion = get_real_velocity()
		if not grounded:
			if -before_move.y > config.landing_soft_speed:
				velocity.x *= config.landing_speed_retention
				velocity.z *= config.landing_speed_retention
			landed.emit(maxf(0.0, -before_move.y))
	if severe_collision or not is_on_floor():
		drift.clear()
	elif award > 0:
		activate_boost(&"mini_turbo", config.mini_turbo_strengths[award - 1], config.mini_turbo_durations[award - 1])
	signed_speed = velocity.dot(-global_basis.z)
