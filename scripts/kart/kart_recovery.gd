class_name KartRecovery
extends Node
## Recovery stays separate from driving. RaceManager maintains safe_spawn.
@export var fall_height: float = -8.0
## World-space safety bounds independent of road kerbs / barrier openings.
@export var recovery_half_extents := Vector2(178, 158)
@export_range(0.1, 5.0) var cooldown_seconds: float = 1.0
@export_range(0.0, 15.0) var stuck_seconds: float = 5.0
@export_range(1.1, 2.0) var wall_probe_distance: float = 1.4
var cooldown_remaining: float = 0.0
var _stuck_time: float = 0.0
@onready var kart: KartController = get_parent() as KartController

func _ready() -> void:
	kart.reset_performed.connect(_on_reset)

func recover() -> bool:
	if cooldown_remaining > 0.0:
		return false
	kart.reset_to_spawn()
	return true

func _physics_process(delta: float) -> void:
	cooldown_remaining = maxf(0.0, cooldown_remaining - delta)
	if cooldown_remaining > 0.0:
		return
	var outside := absf(kart.global_position.x) > recovery_half_extents.x or absf(kart.global_position.z) > recovery_half_extents.y
	if outside or kart.global_position.y < fall_height or kart.global_basis.y.dot(Vector3.UP) < cos(deg_to_rad(kart.config.recovery_upright_angle)):
		recover()
		return
	# Conservative stuck definition: grounded, sustained throttle against a
	# wall, near zero motion, no braking/steering attempt. Set seconds=0 to disable.
	var against_wall := false
	for i in kart.get_slide_collision_count():
		against_wall = against_wall or absf(kart.get_slide_collision(i).get_normal().y) < 0.5
	var command := kart.current_command
	if not against_wall and stuck_seconds > 0 and kart.is_on_floor() and command.throttle > 0.5 and kart.velocity.length() < 0.4:
		# move_and_slide may report only floor contacts at a settled wall. Verify
		# a real front obstacle rather than losing the sustained-jam detector.
		var query := PhysicsRayQueryParameters3D.create(kart.global_position,
			kart.global_position - kart.global_basis.z * wall_probe_distance, 1, [kart.get_rid()])
		var hit := kart.get_world_3d().direct_space_state.intersect_ray(query)
		against_wall = not hit.is_empty() and absf(hit.normal.y) < 0.5
	if stuck_seconds > 0.0 and kart.driving_enabled and kart.is_on_floor() and against_wall \
			and kart.velocity.length() < 0.4 and command.throttle > 0.5 \
			and command.brake < 0.1 and absf(command.steering) < 0.2:
		_stuck_time += delta
		if _stuck_time >= stuck_seconds:
			recover()
	else:
		_stuck_time = 0.0

func _on_reset() -> void:
	cooldown_remaining = cooldown_seconds
	_stuck_time = 0.0
