@tool
class_name BoostPad
extends Node3D
@export_range(1.01, 2.5) var strength: float = 1.5
@export_range(0.1, 5.0) var duration: float = 1.4
@export_range(0.0, 5.0) var cooldown: float = 1.0
@export var pad_size := Vector2(3.5, 4.0)
@export var rebuild: bool = false:
	set(_value):
		if is_inside_tree():
			build.call_deferred()
var _area: Area3D
var _latched := {}
var _cooldowns := {}
var _bound := {}

func _ready() -> void:
	build()

func build() -> void:
	var previous := get_node_or_null("Generated")
	if previous:
		remove_child(previous)
		previous.queue_free()
	var generated := Node3D.new()
	generated.name = "Generated"
	add_child(generated)
	var paint := RiotGeometry.material(Color("17bad1"))
	paint.emission_enabled = true
	paint.emission = Color(0.05, 0.3, 0.4)
	RiotGeometry.box(generated, "Pad", Vector3(pad_size.x, 0.02, pad_size.y), Vector3.ZERO, paint)
	var arrows := SurfaceTool.new()
	arrows.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 3:
		var z := (i - 1) * pad_size.y * 0.25
		arrows.set_normal(Vector3.UP)
		arrows.add_vertex(Vector3(-0.55, 0.025, z + 0.3))
		arrows.add_vertex(Vector3(0, 0.025, z - 0.4))
		arrows.add_vertex(Vector3(0.55, 0.025, z + 0.3))
	var arrow_mesh := MeshInstance3D.new()
	arrow_mesh.mesh = arrows.commit()
	arrow_mesh.material_override = RiotGeometry.material(Color.WHITE)
	generated.add_child(arrow_mesh)
	_area = Area3D.new()
	_area.name = "SurfaceTrigger"
	_area.collision_layer = 8
	_area.collision_mask = 2
	generated.add_child(_area)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(pad_size.x, 0.9, pad_size.y)
	collision.shape = shape
	collision.position.y = 0.45
	_area.add_child(collision)
	_area.set_meta("surface", preload("res://resources/surfaces/boost_pad.tres"))

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or not is_instance_valid(_area):
		return
	for id in _cooldowns.keys():
		_cooldowns[id] = maxf(0.0, _cooldowns[id] - delta)
		if _cooldowns[id] == 0:
			_cooldowns.erase(id)
	var inside := {}
	for body in _area.get_overlapping_bodies():
		if body is KartController:
			inside[body.get_instance_id()] = true
			try_activate(body)
	for id in _latched.keys():
		if not inside.has(id):
			_latched.erase(id)

func try_activate(kart: KartController) -> bool:
	var id := kart.get_instance_id()
	if not _bound.has(id):
		kart.reset_performed.connect(_on_reset.bind(id))
		_bound[id] = true
	if not kart.driving_enabled or not kart.is_on_floor() or _latched.has(id) or _cooldowns.has(id):
		return false
	_latched[id] = true # Even a weaker ignored request consumes this entry.
	_cooldowns[id] = cooldown
	return kart.activate_boost(&"boost_pad", strength, duration)

func _on_reset(id: int) -> void:
	_cooldowns[id] = cooldown
	_latched[id] = true # Staying on a pad through a reset cannot immediately boost.
