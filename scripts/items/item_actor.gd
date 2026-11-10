class_name ItemActor
extends Node3D
## Swept physical queries, bounded steering and one hit per actor.
var definition: ItemDefinition
var source: KartController
var target: KartController
var system: Node
var direction := Vector3.FORWARD
var age := 0.0
var bounces := 0
var spent := false
var settled := false
var fall_speed := 0.0
var _shape := SphereShape3D.new()
var _model: Node3D

func _ready() -> void:
	_shape.radius = 0.26 if definition.identifier != &"5D" else 0.45
	_model = definition.model.instantiate()
	_model.scale = Vector3.ONE * 0.65
	_model.position.y = -0.22
	add_child(_model)

func _physics_process(delta: float) -> void:
	if spent: return
	age += delta
	if age >= definition.lifetime:
		expire()
		return
	if definition.identifier == &"5D":
		_update_banana(delta)
		return
	if definition.identifier == &"5B" and is_instance_valid(target) and target.driving_enabled:
		var difference := target.global_position - global_position
		difference.y = 0
		if difference.length() <= definition.target_range and difference.length() > 0.01:
			var angle := direction.signed_angle_to(difference.normalized(), Vector3.UP)
			direction = direction.rotated(Vector3.UP, clampf(angle, -deg_to_rad(definition.turn_degrees) * delta, deg_to_rad(definition.turn_degrees) * delta)).normalized()
	# Follow support without confusing floor faces with ricochet walls.
	var support := _floor(global_position)
	if not support.is_empty() and absf(global_position.y - support.position.y - 0.3) < 0.7:
		global_position.y = support.position.y + 0.3
		fall_speed = 0
	else: fall_speed -= 18 * delta
	var motion := direction * definition.speed * delta + Vector3.UP * fall_speed * delta
	_sweep(motion)
	rotation.y = atan2(-direction.x, -direction.z)

func _exclusions() -> Array[RID]:
	var result: Array[RID] = []
	if is_instance_valid(source) and age < (1.0 if definition.identifier == &"5D" else 0.6): result.append(source.get_rid())
	return result

func _floor(at: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 0.5, at - Vector3.UP * 1.4, 1)
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	return result if not result.is_empty() and result.normal.y > 0.65 and _drivable(result.collider) else {}

func _drivable(collider: Object) -> bool:
	return is_instance_valid(collider) and collider.has_meta("surface") and collider.get_meta("surface") is SurfaceConfig

func _sweep(motion: Vector3) -> void:
	for iteration in 4:
		if spent or motion.length_squared() < 0.0000001: return
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = _shape
		query.transform = Transform3D(Basis.IDENTITY, global_position)
		query.motion = motion
		query.collision_mask = 3
		query.exclude = _exclusions()
		var space := get_world_3d().direct_space_state
		var info := space.get_rest_info(query)
		# cast_motion deliberately ignores initial overlaps. Check those too,
		# excluding the owner during grace, so close-range launches cannot tunnel.
		if not info.is_empty() and info.normal.y > 0.65 and _drivable(instance_from_id(info.collider_id)): info = {}
		var fractions := PackedFloat32Array([0, 0]) if not info.is_empty() else space.cast_motion(query)
		if fractions[0] >= 1:
			global_position += motion
			return
		global_position += motion * fractions[0]
		query.transform.origin += motion * minf(1, fractions[1] + 0.002)
		query.motion = Vector3.ZERO
		if info.is_empty(): info = space.get_rest_info(query)
		if info.is_empty():
			expire()
			return
		var collider := instance_from_id(info.collider_id)
		if collider is KartController:
			_hit(collider)
			return
		var normal: Vector3 = info.normal
		if normal.y > 0.65:
			if _drivable(collider):
				global_position.y += 0.03
				fall_speed = 0
			else: expire() # Obstacle tops are not ground-follow support.
			return
		if definition.identifier != &"5C" or bounces >= definition.maximum_bounces:
			expire()
			return
		bounces += 1
		normal.y = 0
		direction = direction.bounce(normal.normalized()).normalized()
		global_position += normal.normalized() * 0.035
		motion = direction * motion.length() * (1 - fractions[0])
		system.feedback(global_position, 3)

func _update_banana(delta: float) -> void:
	if not settled:
		var support := _floor(global_position)
		fall_speed -= 18 * delta
		var next_y := global_position.y + fall_speed * delta
		if not support.is_empty() and next_y <= support.position.y + 0.23:
			global_position.y = support.position.y + 0.23
			settled = true
		else: global_position.y = next_y
		return
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = _shape
	query.transform.origin = global_position
	query.collision_mask = 2
	query.exclude = _exclusions()
	for contact in get_world_3d().direct_space_state.intersect_shape(query, 8):
		if contact.collider is KartController:
			_hit(contact.collider)
			return

func _hit(kart: KartController) -> void:
	if spent: return
	var kick := direction * 1.5 + kart.global_basis.x * definition.knockback
	if definition.identifier == &"5D": kick = kart.global_basis.x * definition.knockback
	var accepted := kart.receive_item_hit(kick, definition.hit_seconds, definition.speed_multiplier,
		definition.grip_multiplier, definition.momentum_retention, definition.spin_degrees,
		definition.hit_control, definition.control_recovery_seconds)
	if accepted: system.feedback(kart.global_position, 2)
	expire()

func expire() -> void:
	if spent: return
	spent = true
	visible = false
	set_physics_process(false)
	queue_free()
