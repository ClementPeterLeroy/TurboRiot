@tool
class_name BarrierMesh
extends RefCounted
## One reusable, unit-sized faceted block. Four triangles on each face form
## the reference's X. Vertex tints keep the facets readable in flat lighting.
static func create() -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var faces := [
		[Vector3(-0.5, -0.5, -0.5), Vector3(-0.5, -0.5, 0.5), Vector3(-0.5, 0.5, 0.5), Vector3(-0.5, 0.5, -0.5)],
		[Vector3(0.5, -0.5, 0.5), Vector3(0.5, -0.5, -0.5), Vector3(0.5, 0.5, -0.5), Vector3(0.5, 0.5, 0.5)],
		[Vector3(0.5, -0.5, -0.5), Vector3(-0.5, -0.5, -0.5), Vector3(-0.5, 0.5, -0.5), Vector3(0.5, 0.5, -0.5)],
		[Vector3(-0.5, -0.5, 0.5), Vector3(0.5, -0.5, 0.5), Vector3(0.5, 0.5, 0.5), Vector3(-0.5, 0.5, 0.5)],
		[Vector3(-0.5, 0.5, -0.5), Vector3(-0.5, 0.5, 0.5), Vector3(0.5, 0.5, 0.5), Vector3(0.5, 0.5, -0.5)],
		[Vector3(-0.5, -0.5, 0.5), Vector3(-0.5, -0.5, -0.5), Vector3(0.5, -0.5, -0.5), Vector3(0.5, -0.5, 0.5)]]
	var shades := [0.63, 0.9, 1.0, 0.78]
	for face: Array in faces:
		face.reverse() # Clockwise exterior faces in Godot.
		var normal: Vector3 = (face[2] - face[0]).cross(face[1] - face[0]).normalized()
		var center: Vector3 = (face[0] + face[2]) * 0.5 + normal * 0.04
		for i in 4:
			var shade: float = shades[i]
			surface.set_color(Color(shade, shade, shade))
			for vertex: Vector3 in [face[i], face[(i + 1) % 4], center]:
				surface.add_vertex(vertex)
	surface.generate_normals()
	return surface.commit()
