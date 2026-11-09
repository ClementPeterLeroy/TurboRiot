@tool
class_name KartRamp
extends Node3D
@export_range(2.0, 10.0) var width: float = 4.0:
	set(value):
		width = value
		_schedule()
@export_range(3.0, 15.0) var length: float = 7.0:
	set(value):
		length = value
		_schedule()
@export_range(0.2, 4.0) var height: float = 1.3:
	set(value):
		height = value
		_schedule()
var _queued := false

func _ready() -> void:
	build()

func _schedule() -> void:
	if is_inside_tree() and not _queued:
		_queued = true
		build.call_deferred()

func build() -> void:
	_queued = false
	var previous := get_node_or_null("Generated")
	if previous:
		remove_child(previous)
		previous.queue_free()
	var generated := Node3D.new()
	generated.name = "Generated"
	add_child(generated)
	var a := Vector3(-width * 0.5, 0, 0)
	var b := Vector3(width * 0.5, 0, 0)
	var c := Vector3(-width * 0.5, height, -length)
	var d := Vector3(width * 0.5, height, -length)
	var e := Vector3(-width * 0.5, 0, -length)
	var f := Vector3(width * 0.5, 0, -length)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for vertex: Vector3 in [a, c, b, b, c, d, a, e, c, b, d, f, e, f, c, c, f, d, a, b, e, b, f, e]:
		surface.add_vertex(vertex)
	surface.generate_normals()
	var ramp_mesh := MeshInstance3D.new()
	ramp_mesh.name = "Incline"
	ramp_mesh.mesh = surface.commit()
	ramp_mesh.material_override = RiotGeometry.material(Color("d89235"))
	generated.add_child(ramp_mesh)
	ramp_mesh.create_trimesh_collision()
	SurfaceDetector.tag_collision(ramp_mesh, preload("res://resources/surfaces/asphalt.tres"))
	for side in [-1.0, 1.0]:
		var stripe := RiotGeometry.box(generated, "EdgeStripe", Vector3(0.12, 0.025, Vector2(length, height).length()),
			Vector3(side * (width * 0.5 - 0.15), height * 0.5 + 0.02, -length * 0.5), RiotGeometry.material(Color("fff1ba")))
		stripe.rotation.x = atan2(height, length)
