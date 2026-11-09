extends "res://scripts/camera/chase_camera.gd"
## Read-only historical comparison: _process from ddf2573 (v0.3.1), with
## render_target_transform exposed for measurement only. Probe mode A only.
func _process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	render_target_transform = target.global_transform
	var desired := target.global_position + target.global_basis.z * distance + Vector3.UP * height
	var focus := target.global_position + Vector3.UP * 0.8
	var query := PhysicsRayQueryParameters3D.create(focus, desired, 1, [target.get_rid()])
	var obstruction := get_world_3d().direct_space_state.intersect_ray(query)
	if not obstruction.is_empty():
		desired = obstruction.position + obstruction.normal * collision_margin
	global_position = global_position.lerp(desired, 1.0 - exp(-movement_smoothing * delta))
	global_position.y = maxf(global_position.y, 0.3)
	var desired_basis := Basis.looking_at(_look_point() - global_position, Vector3.UP)
	global_basis = global_basis.slerp(desired_basis, 1.0 - exp(-rotation_smoothing * delta))
