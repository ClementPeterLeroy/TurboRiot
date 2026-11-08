class_name KartController
extends CharacterBody3D

signal reset_performed

@export var config: KartConfig
@export var input_provider: DrivingInput
var safe_spawn: Transform3D
var current_command := DrivingCommand.new()
var signed_speed: float = 0.0

func _ready() -> void:
	assert(config != null, "Assign a KartConfig")
	safe_spawn = global_transform
	floor_snap_length = 0.4

func reset_to_spawn() -> void:
	global_transform = safe_spawn
	velocity = Vector3.ZERO
	signed_speed = 0.0
	reset_performed.emit()

func _physics_process(delta: float) -> void:
	if global_position.y < -12.0:
		reset_to_spawn()
		return
	current_command = input_provider.get_command() if input_provider else DrivingCommand.new()
	var forward := -global_basis.z
	var right := global_basis.x
	var speed := KartDynamics.longitudinal_speed(velocity.dot(forward), current_command, config, delta)
	var lateral := KartDynamics.damp_lateral(velocity.dot(right), config.lateral_grip, delta)
	rotate_y(KartDynamics.steering_radians(speed, current_command, config, delta))
	# Reproject after yaw so inertia produces a little slip, then grip removes it.
	var horizontal := forward * speed + right * lateral
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	velocity.y = -0.5 if is_on_floor() else velocity.y - config.gravity * delta
	move_and_slide()
	for i in get_slide_collision_count():
		var normal := get_slide_collision(i).get_normal()
		if absf(normal.y) < 0.5:
			velocity.x *= config.wall_retention
			velocity.z *= config.wall_retention
			break
	signed_speed = velocity.dot(-global_basis.z)
	_animate_wheels(delta)

func _animate_wheels(delta: float) -> void:
	for wheel: Node3D in $Visual/Wheels.get_children():
		wheel.rotate_object_local(Vector3.UP, -signed_speed * delta / 0.3)
