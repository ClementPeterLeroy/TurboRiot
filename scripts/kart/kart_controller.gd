class_name KartController
extends CharacterBody3D

signal reset_performed
signal landed(impact_speed: float)
signal wall_impacted(strength: float)

@export var config: KartConfig
@export var input_provider: DrivingInput
var safe_spawn: Transform3D
var current_command := DrivingCommand.new()
var signed_speed: float = 0.0
var boost := BoostController.new()
var drift := DriftController.new()
var surface_detector := SurfaceDetector.new()
var effects := KartEffects.new()
var contact_velocity := Vector3.ZERO
var contact_frame := -1
var kart_contacts: Array[Dictionary] = []
var environment_contacts := PackedVector3Array()
var _pending_impulse := Vector3.ZERO
var _pending_retention := 1.0
var _ground_motion := Vector3.ZERO
var _follow_heading: Node3D
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
	_follow_heading = Node3D.new()
	_follow_heading.name = "FollowHeading"
	add_child(_follow_heading)

func camera_heading_interpolated() -> Basis:
	return _follow_heading.get_global_transform_interpolated().basis if is_instance_valid(_follow_heading) else get_global_transform_interpolated().basis

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
	effects.clear()
	_pending_impulse = Vector3.ZERO
	_pending_retention = 1
	kart_contacts.clear()
	environment_contacts.clear()
	contact_frame = -1
	surface_detector.clear_boost_override()
	if is_instance_valid(_follow_heading):
		_follow_heading.basis = Basis.IDENTITY
		_follow_heading.reset_physics_interpolation()

func activate_boost(source: StringName, strength: float, duration: float) -> bool:
	if not driving_enabled:
		return false
	return boost.activate(source, strength, duration, config.boost_policy)

func receive_item_hit(impulse: Vector3, duration: float, speed_multiplier: float, grip_multiplier: float, retention: float,
		spin_degrees := 0.0, control := 0.12, recovery_seconds := 0.35) -> bool:
	if not driving_enabled or not impulse.is_finite() or not effects.apply(duration, speed_multiplier, grip_multiplier,
		spin_degrees, control, recovery_seconds, global_basis): return false
	_pending_impulse = impulse.limit_length(12)
	_pending_impulse.y = 0
	_pending_retention = clampf(retention, 0.5, 1)
	drift.clear()
	return true

func activate_item_boost(source: StringName, strength: float, duration: float) -> bool:
	if not driving_enabled: return false
	var own_duration := duration
	if config.boost_policy == KartConfig.BoostPolicy.STRONGEST_WINS and boost.active():
		strength = maxf(strength, boost.strength)
		duration = maxf(duration, boost.remaining)
	return boost.activate(source, strength, duration, config.boost_policy, own_duration)

func activate_directional_boost(direction: Vector3, strength: float, duration: float, initial_impulse: float = -1.0) -> bool:
	if not driving_enabled or not direction.is_finite():
		return false
	direction.y = 0
	if direction.length_squared() < 0.0001:
		return false
	# Pads always act. Under strongest-wins retain a stronger active cap and
	# the longer timer; they cannot be ignored because approach is backwards.
	var own_duration := duration
	if config.boost_policy == KartConfig.BoostPolicy.STRONGEST_WINS and boost.active():
		strength = maxf(strength, boost.strength)
		duration = maxf(duration, boost.remaining)
	if not boost.activate(&"boost_pad", strength, duration, config.boost_policy, own_duration):
		return false
	direction = direction.normalized()
	# One entry impulse, never a persistent velocity/yaw override. Cancel any
	# reverse component, then allow normal steering, braking and drift immediately.
	var entry := config.pad_entry_impulse if initial_impulse < 0 else initial_impulse
	var along := velocity.dot(direction)
	var desired := minf(config.max_forward_speed * strength, maxf(0, along) + entry)
	velocity += direction * (desired - along)
	boost.direction = Vector3.ZERO
	boost.direction_remaining = 0
	return true

func _physics_process(delta: float) -> void:
	kart_contacts.clear()
	environment_contacts.clear()
	contact_frame = Engine.get_physics_frames()
	surface_detector.update(self, config, delta)
	floor_snap_length = config.ground_snap_distance
	if not driving_enabled:
		current_command = DrivingCommand.new()
		velocity = Vector3(0, -config.ground_contact_speed if is_on_floor() else velocity.y - config.gravity * delta, 0)
		move_and_slide()
		signed_speed = 0.0
		return
	boost.advance(delta)
	rotate_y(effects.advance(delta))
	var surface := surface_detector.handling_multipliers(boost, delta, config.surface_smoothing)
	velocity.x = velocity.x * _pending_retention + _pending_impulse.x
	velocity.z = velocity.z * _pending_retention + _pending_impulse.z
	_pending_impulse = Vector3.ZERO
	_pending_retention = 1
	current_command = input_provider.get_command() if input_provider else DrivingCommand.new()
	var drive_command := effects.driving_command(current_command)
	var traction_basis := effects.driving_basis(global_basis)
	var forward := -traction_basis.z
	var right := traction_basis.x
	var grounded := is_on_floor()
	var launch_surface := false
	if grounded:
		for i in get_slide_collision_count():
			var contact := get_slide_collision(i)
			if contact.get_normal().dot(up_direction) >= cos(floor_max_angle) and contact.get_collider().has_meta("launch_ramp"):
				launch_surface = true
				break
	var speed := velocity.dot(forward)
	var lateral := velocity.dot(right)
	var award := drift.update(drive_command, speed, lateral, grounded, false, config, delta)
	if grounded:
		var horizontal: Vector3
		var acceleration_multiplier := surface.x * (config.boost_acceleration_multiplier if boost.active() else 1.0)
		speed = KartDynamics.longitudinal_speed(speed, drive_command, config, delta,
			acceleration_multiplier, surface.y * effects.speed_multiplier, surface.w, boost.strength)
		var grip := config.lateral_grip * surface.z * effects.grip_multiplier * (config.drift_grip_multiplier if drift.active else 1.0)
		lateral = KartDynamics.damp_lateral(lateral, grip, delta)
		var yaw := KartDynamics.steering_radians(speed, drive_command, config, delta) * (config.drift_steering_multiplier if drift.active else 1.0)
		rotate_y(yaw)
		effects.steer_inertia(yaw)
		horizontal = forward * speed + right * lateral
		# Let move_and_slide project motion onto the floor. Supplying our own
		# upward tangent disables automatic snapping at shoulder/ramp crests,
		# producing false takeoffs even when adjoining asphalt supports us.
		# A downward request keeps snapping available; floor_constant_speed
		# preserves slope speed. Real incline motion is retained at a launch edge.
		velocity = horizontal - Vector3.UP * config.ground_contact_speed
		if launch_surface:
			# Authored launch ramps intentionally keep their rising tangent.
			# Restrict this snap-disabling path to their physical floor contact;
			# ordinary road/shoulder joins must never manufacture takeoffs.
			var normal := get_floor_normal()
			var tangent := horizontal.slide(normal)
			if tangent.length_squared() > 0.00001:
				tangent = tangent.normalized() * horizontal.length()
			velocity = tangent - normal * config.ground_contact_speed
	else:
		# Air steering changes heading only; throttle cannot manufacture momentum.
		var yaw := KartDynamics.air_yaw(speed, drive_command, config, delta)
		rotate_y(yaw)
		effects.steer_inertia(yaw)
		velocity.y -= config.gravity * delta
	var before_move := velocity
	contact_velocity = velocity
	move_and_slide()
	var severe_collision := false
	for i in get_slide_collision_count():
		var contact := get_slide_collision(i)
		var normal := contact.get_normal()
		if absf(normal.y) < 0.5:
			if contact.get_collider() is KartController:
				kart_contacts.append({"other": contact.get_collider(), "normal": normal, "position": contact.get_position()})
			else:
				severe_collision = severe_collision or -before_move.dot(normal) >= config.drift_interrupt_speed
				environment_contacts.append(normal)
	if not environment_contacts.is_empty():
		velocity.x *= config.wall_retention
		velocity.z *= config.wall_retention
	if grounded and launch_surface and not is_on_floor():
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
		if severe_collision: wall_impacted.emit(Vector2(before_move.x, before_move.z).length())
	elif award > 0:
		activate_boost(&"mini_turbo", config.mini_turbo_strengths[award - 1], config.mini_turbo_durations[award - 1])
	_follow_heading.global_basis = effects.driving_basis(global_basis)
	signed_speed = velocity.dot(-global_basis.z)
