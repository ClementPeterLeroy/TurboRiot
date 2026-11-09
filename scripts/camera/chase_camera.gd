extends Camera3D
## Independent world-space camera. Reset is deliberately an immediate snap.

@export var target: KartController
@export var distance: float = 7.5
@export var height: float = 4.5
@export var look_ahead: float = 4.0
@export var movement_smoothing: float = 8.0
@export var rotation_smoothing: float = 10.0
@export_range(40.0, 100.0) var field_of_view: float = 68.0
@export var collision_margin: float = 0.35
var diagnostic_mode := 0 # 0 normal, 1 fixed world orientation, 2 rigid follow.
var _fixed_basis := Basis.IDENTITY
var render_target_transform := Transform3D.IDENTITY
var _previous_desired := Vector3.ZERO

func set_diagnostic_mode(value: int) -> void:
	diagnostic_mode = value
	_fixed_basis = global_basis
	_previous_desired = render_target_transform.origin + render_target_transform.basis.z * distance + Vector3.UP * height

func _ready() -> void:
	# This independent camera is positioned per render frame, following the
	# same interpolated body pose used for rendering. Never interpolate it twice.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	fov = field_of_view
	if target:
		target.reset_performed.connect(snap_to_target)
		snap_to_target()

func snap_to_target() -> void:
	render_target_transform = target.global_transform
	global_position = target.global_position + target.global_basis.z * distance + Vector3.UP * height
	_previous_desired = global_position
	look_at(_look_point(), Vector3.UP)
	reset_physics_interpolation()

func _process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	render_target_transform = target.get_global_transform_interpolated()
	var desired := render_target_transform.origin + render_target_transform.basis.z * distance + Vector3.UP * height
	if diagnostic_mode == 2:
		global_position = desired
		_previous_desired = desired
		look_at(_look_point_from(render_target_transform), Vector3.UP)
		return
	# Keep the existing world-space follow; shorten only when physical terrain
	# obstructs the target-to-camera line (including a ramp during a jump).
	var focus := render_target_transform.origin + Vector3.UP * 0.8
	var query := PhysicsRayQueryParameters3D.create(focus, desired, 1, [target.get_rid()])
	var obstruction := get_world_3d().direct_space_state.intersect_ray(query)
	if not obstruction.is_empty():
		desired = obstruction.position + obstruction.normal * collision_margin
	global_position = smooth_moving_target(global_position, _previous_desired, desired, delta, movement_smoothing)
	_previous_desired = desired
	global_position.y = maxf(global_position.y, 0.3) # Floor is flat apart from authored ramps.
	if diagnostic_mode == 1:
		global_basis = _fixed_basis
	else:
		var desired_basis := Basis.looking_at(_look_point_from(render_target_transform) - global_position, Vector3.UP)
		global_basis = global_basis.slerp(desired_basis, 1.0 - exp(-rotation_smoothing * delta))

func _look_point() -> Vector3:
	return target.global_position - target.global_basis.z * look_ahead + Vector3.UP * 0.7

func _look_point_from(pose: Transform3D) -> Vector3:
	return pose.origin - pose.basis.z * look_ahead + Vector3.UP * 0.7

static func smooth_moving_target(current: Vector3, previous_target: Vector3, next_target: Vector3, delta: float, rate: float) -> Vector3:
	if delta <= 0 or rate <= 0:
		return current
	# Exact exponential follow for a target moving linearly during this frame.
	# Endpoint-only lerp changes follow distance with frame duration, creating
	# camera pitch/screen-Y pulses even at constant speed on a perfectly flat road.
	var decay := exp(-rate * delta)
	return next_target + (current - previous_target) * decay - (next_target - previous_target) * ((1.0 - decay) / (rate * delta))
