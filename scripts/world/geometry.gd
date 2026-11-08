@tool
class_name RiotGeometry
extends RefCounted
## Lightweight primitives shared by editor generators. No external art assets.

static func material(color: Color) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = 0.95
	return result

static func box(parent: Node3D, label: String, size: Vector3, location: Vector3,
		paint: Material, collision: bool = false) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.name = label
	instance.mesh = mesh
	instance.material_override = paint
	parent.add_child(instance)
	instance.position = location
	if collision:
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var box_shape := BoxShape3D.new()
		box_shape.size = size
		shape.shape = box_shape
		instance.add_child(body)
		body.add_child(shape)
	return instance

static func cylinder(parent: Node3D, label: String, location: Vector3,
		bottom: float, top: float, height: float, paint: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = bottom
	mesh.top_radius = top
	mesh.height = height
	mesh.radial_segments = 7
	var instance := MeshInstance3D.new()
	instance.name = label
	instance.mesh = mesh
	instance.material_override = paint
	parent.add_child(instance)
	instance.position = location
	return instance
