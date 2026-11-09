extends Node3D
## Cosmetic only: wheel pivots, body lean, procedural dust and boost exhaust.
@onready var kart: KartController = get_parent() as KartController
var _dust: CPUParticles3D
var _flame: MeshInstance3D

func _ready() -> void:
	_dust = CPUParticles3D.new()
	_dust.name = "TyreDust"
	_dust.amount = 32
	_dust.lifetime = 0.45
	_dust.emitting = false
	_dust.local_coords = false
	_dust.position = Vector3(0, -0.2, 0.7)
	_dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_dust.emission_box_extents = Vector3(0.65, 0.03, 0.08)
	_dust.direction = Vector3.UP
	_dust.spread = 35
	_dust.initial_velocity_min = 0.3
	_dust.initial_velocity_max = 0.7
	_dust.gravity = Vector3(0, 0.4, 0)
	_dust.scale_amount_min = 0.4
	_dust.scale_amount_max = 1.2
	var puff := SphereMesh.new()
	puff.radius = 0.09
	puff.height = 0.18
	puff.radial_segments = 6
	puff.rings = 3
	var paint := RiotGeometry.material(Color.WHITE)
	paint.vertex_color_use_as_albedo = true
	paint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	puff.material = paint
	_dust.mesh = puff
	add_child(_dust)
	var flame := CylinderMesh.new()
	flame.top_radius = 0
	flame.bottom_radius = 0.18
	flame.height = 0.8
	flame.radial_segments = 7
	_flame = MeshInstance3D.new()
	_flame.name = "BoostExhaust"
	_flame.mesh = flame
	_flame.position = Vector3(0, 0.05, 1.25)
	_flame.rotation.x = PI * 0.5
	var fire := RiotGeometry.material(Color("68e9ff"))
	fire.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_flame.material_override = fire
	add_child(_flame)

func _process(delta: float) -> void:
	var blend := 1.0 - exp(-10.0 * delta)
	var level := kart.drift.level(kart.config)
	var steering := kart.current_command.steering
	rotation.z = lerpf(rotation.z, -steering * (0.14 if kart.drift.active else 0.045), blend)
	var normal := kart.surface_detector.normal
	var pitch := -atan2(normal.dot(-kart.global_basis.z), maxf(0.1, normal.y)) if kart.is_on_floor() \
		else atan2(kart.velocity.y, maxf(1.0, Vector2(kart.velocity.x, kart.velocity.z).length())) * 0.45
	rotation.x = lerpf(rotation.x, pitch, blend)
	for pivot: Node3D in $Wheels.get_children():
		if str(pivot.name).begins_with("Front"):
			pivot.rotation.y = lerpf(pivot.rotation.y, -steering * deg_to_rad(28), blend)
		pivot.get_node("Tire").rotate_object_local(Vector3.UP, -kart.signed_speed * delta / 0.3)
	var dusty := kart.surface_detector.current.particle_identifier == &"dust"
	_dust.emitting = kart.is_on_floor() and absf(kart.signed_speed) > 3 and (kart.drift.active or dusty)
	var colors := [Color(0.8, 0.8, 0.8, 0.45), Color(0.25, 0.7, 1, 0.65), Color(1, 0.75, 0.2, 0.65), Color(0.95, 0.35, 1, 0.7)]
	_dust.color = colors[level] if kart.drift.active else Color(0.85, 0.7, 0.45, 0.45)
	_flame.visible = kart.boost.active()
	_flame.scale.y = 0.8 + 0.15 * sin(Time.get_ticks_msec() * 0.05)
