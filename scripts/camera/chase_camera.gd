extends Camera3D
## Independent world-space camera. Reset is deliberately an immediate snap.

@export var target: KartController
@export var distance: float = 7.5
@export var height: float = 4.5
@export var look_ahead: float = 4.0
@export var movement_smoothing: float = 8.0
@export var rotation_smoothing: float = 10.0
@export_range(40.0, 100.0) var field_of_view: float = 68.0

func _ready() -> void:
	fov = field_of_view
	if target:
		target.reset_performed.connect(snap_to_target)
		snap_to_target()

func snap_to_target() -> void:
	global_position = target.global_position + target.global_basis.z * distance + Vector3.UP * height
	look_at(_look_point(), Vector3.UP)
	reset_physics_interpolation()

func _process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	var desired := target.global_position + target.global_basis.z * distance + Vector3.UP * height
	global_position = global_position.lerp(desired, 1.0 - exp(-movement_smoothing * delta))
	var desired_basis := Basis.looking_at(_look_point() - global_position, Vector3.UP)
	global_basis = global_basis.slerp(desired_basis, 1.0 - exp(-rotation_smoothing * delta))

func _look_point() -> Vector3:
	return target.global_position - target.global_basis.z * look_ahead + Vector3.UP * 0.7
