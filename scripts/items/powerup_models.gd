@tool
class_name PowerupModels
extends RefCounted
## Original low-poly meshes. References are guides, never runtime textures.
static var materials := {}
static var meshes := {}

static func material(colour: Color) -> StandardMaterial3D:
	var key := colour.to_html()
	if not materials.has(key):
		var value := StandardMaterial3D.new()
		value.albedo_color = colour
		value.roughness = 0.55
		value.cull_mode = BaseMaterial3D.CULL_DISABLED
		materials[key] = value
	return materials[key]

static func mesh_node(root: Node3D, mesh: Mesh, colour: Color, at: Vector3, size := Vector3.ONE) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material(colour)
	node.position = at
	node.scale = size
	root.add_child(node)
	return node

static func ball(root: Node3D, colour: Color, at: Vector3, size: Vector3) -> MeshInstance3D:
	if not meshes.has("ball"):
		var shape := SphereMesh.new()
		shape.radius = 0.5
		shape.height = 1
		shape.radial_segments = 16
		shape.rings = 8
		meshes.ball = shape
	return mesh_node(root, meshes.ball, colour, at, size)

static func box(root: Node3D, colour: Color, at: Vector3, size: Vector3) -> MeshInstance3D:
	if not meshes.has("box"): meshes.box = BoxMesh.new()
	return mesh_node(root, meshes.box, colour, at, size)

static func lathe(root: Node3D, key: String, profile: Array[Vector2], colour: Color, sectors := 24) -> void:
	if not meshes.has(key):
		var tool := SurfaceTool.new()
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		for row in profile.size() - 1:
			for side in sectors:
				var points: Array[Vector3] = []
				for pair in [Vector2i(row, side), Vector2i(row + 1, side), Vector2i(row + 1, side + 1), Vector2i(row, side + 1)]:
					var p := profile[pair.x]
					var angle: float = TAU * pair.y / sectors
					points.append(Vector3(cos(angle) * p.x, p.y, sin(angle) * p.x))
				for index in [0, 1, 2, 0, 2, 3]: tool.add_vertex(points[index])
		tool.generate_normals()
		meshes[key] = tool.commit()
	mesh_node(root, meshes[key], colour, Vector3.ZERO)

static func eyes(root: Node3D, y: float, z: float, spacing: float) -> void:
	for sign_value in [-1, 1]:
		ball(root, Color("19202c"), Vector3(sign_value * spacing, y, z), Vector3(0.065, 0.16, 0.045))
		ball(root, Color.WHITE, Vector3(sign_value * spacing - 0.009, y + 0.035, z - 0.022), Vector3(0.022, 0.035, 0.014))

static func jewel_panel(root: Node3D, side: int) -> void:
	var key := "jewel_%d" % side
	if not meshes.has(key):
		var tool := SurfaceTool.new()
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		var corners := [Vector3(-0.48, -0.48, -0.49), Vector3(0.48, -0.48, -0.49), Vector3(0.48, 0.48, -0.49), Vector3(-0.48, 0.48, -0.49)]
		for index in [0, 1, 2, 0, 2, 3]:
			tool.set_color(Color.from_hsv(fposmod(0.43 + side * 0.12 + index * 0.07, 1), 0.6, 1))
			tool.add_vertex(corners[index])
		tool.generate_normals()
		var mesh := tool.commit()
		var paint := StandardMaterial3D.new()
		paint.vertex_color_use_as_albedo = true
		paint.cull_mode = BaseMaterial3D.CULL_DISABLED
		paint.metallic = 0.25
		paint.roughness = 0.3
		mesh.surface_set_material(0, paint)
		meshes[key] = mesh
	var node := MeshInstance3D.new()
	node.mesh = meshes[key]
	root.add_child(node)

static func cap_spot(root: Node3D, angle: float) -> void:
	# Follow the cap profile, instead of floating a flattened sphere above it.
	if not meshes.has("cap_spot"):
		var profile: Array[Vector2] = [Vector2(0.66, 0.55), Vector2(0.57, 0.8), Vector2(0.37, 1.02), Vector2(0, 1.12)]
		var tool := SurfaceTool.new()
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		for segment in 16:
			for polar in [Vector2.ZERO, Vector2(cos(segment * TAU / 16), sin(segment * TAU / 16)), Vector2(cos((segment + 1) * TAU / 16), sin((segment + 1) * TAU / 16))]:
				var y: float = 0.8 + polar.y * 0.105
				var radius := 0.0
				for index in profile.size() - 1:
					if y >= profile[index].y and y <= profile[index + 1].y:
						radius = lerpf(profile[index].x, profile[index + 1].x, inverse_lerp(profile[index].y, profile[index + 1].y, y)) + 0.002
						break
				var theta: float = polar.x * 0.19
				tool.add_vertex(Vector3(cos(theta) * radius, y, sin(theta) * radius))
		tool.generate_normals()
		meshes.cap_spot = tool.commit()
	var node := mesh_node(root, meshes.cap_spot, Color.WHITE, Vector3.ZERO)
	node.rotation.y = angle

static func build(root: Node3D, kind: String) -> void:
	var cream := Color("fff1bd")
	if kind == "mushroom":
		lathe(root, "stem", [Vector2(0, 0), Vector2(0.27, 0.02), Vector2(0.3, 0.12), Vector2(0.25, 0.55), Vector2(0, 0.58)], cream)
		lathe(root, "cap", [Vector2(0, 0.43), Vector2(0.62, 0.45), Vector2(0.66, 0.55), Vector2(0.57, 0.8), Vector2(0.37, 1.02), Vector2(0, 1.12)], Color("ef3547"))
		for i in 7:
			var angle := TAU * i / 7
			cap_spot(root, angle)
		ball(root, Color.WHITE, Vector3(0, 1.11, 0), Vector3(0.26, 0.025, 0.26))
		eyes(root, 0.28, -0.27, 0.1)
	elif kind.ends_with("shell"):
		var colour := Color("df3345") if kind == "red_shell" else Color("35b957")
		lathe(root, "underside", [Vector2(0, 0.04), Vector2(0.45, 0.04), Vector2(0.61, 0.16), Vector2(0.61, 0.23), Vector2(0, 0.23)], cream)
		lathe(root, "rim", [Vector2(0.46, 0.16), Vector2(0.64, 0.16), Vector2(0.7, 0.23), Vector2(0.68, 0.32), Vector2(0.57, 0.35), Vector2(0.46, 0.29)], Color("fffef0"))
		lathe(root, "shell_dark", [Vector2(0, 0.24), Vector2(0.6, 0.27), Vector2(0.53, 0.55), Vector2(0.32, 0.76), Vector2(0, 0.84)], colour.darkened(0.6))
		# Each scute is separated by a visible dark seam.
		for band in 3:
			var theta0 := band * PI / 6 + 0.025
			var theta1 := (band + 1) * PI / 6 - 0.025
			for segment in 8:
				var key := "scute_%d_%d" % [band, segment]
				if meshes.has(key):
					mesh_node(root, meshes[key], colour.lightened(0.035 * (segment % 3)), Vector3.ZERO)
					continue
				var tool := SurfaceTool.new()
				tool.begin(Mesh.PRIMITIVE_TRIANGLES)
				var corners: Array[Vector3] = []
				for pair in [Vector2(theta0, segment * TAU / 8 + 0.025), Vector2(theta1, segment * TAU / 8 + 0.025), Vector2(theta1, (segment + 1) * TAU / 8 - 0.025), Vector2(theta0, (segment + 1) * TAU / 8 - 0.025)]:
					corners.append(Vector3(cos(pair.x) * cos(pair.y) * 0.605, 0.27 + sin(pair.x) * 0.58, cos(pair.x) * sin(pair.y) * 0.605))
				for index in [0, 1, 2, 0, 2, 3]: tool.add_vertex(corners[index])
				tool.generate_normals()
				meshes[key] = tool.commit()
				mesh_node(root, meshes[key], colour.lightened(0.035 * (segment % 3)), Vector3.ZERO)
		for i in 3: lathe(root, "groove%d" % i, [Vector2(0.24 + i * 0.09, 0.075 + i * 0.027), Vector2(0.255 + i * 0.09, 0.075 + i * 0.027)], Color("ba955c"))
		ball(root, Color("463a28"), Vector3(0, 0.19, -0.59), Vector3(0.39, 0.22, 0.07))
	elif kind == "banana":
		lathe(root, "banana_body", [Vector2(0, 0), Vector2(0.24, 0.1), Vector2(0.22, 0.5), Vector2(0.13, 0.95), Vector2(0.075, 1.3), Vector2(0, 1.34)], Color("ffe23b"), 12)
		ball(root, Color("79532e"), Vector3(0, 1.31, 0), Vector3(0.15, 0.11, 0.15))
		for arm in 3:
			var angle := arm * TAU / 3 + PI / 6
			var path := [Vector2(0.13, 0.69), Vector2(0.33, 0.39), Vector2(0.6, 0.19), Vector2(0.8, 0.22), Vector2(0.9, 0.38)]
			for j in path.size() - 1:
				var a := Vector3(cos(angle) * path[j].x, path[j].y, sin(angle) * path[j].x)
				var b := Vector3(cos(angle) * path[j + 1].x, path[j + 1].y, sin(angle) * path[j + 1].x)
				var peel := box(root, Color("ffe552") if j < 3 else Color("8c5e32"), (a + b) / 2, Vector3(0.23 - j * 0.035, 0.075, a.distance_to(b) + 0.06))
				peel.basis = Basis.looking_at(b - a) * Basis.from_scale(peel.scale)
		eyes(root, 0.57, -0.205, 0.075)
		var smile := Label3D.new()
		smile.text = "⌣"
		smile.font_size = 45
		smile.pixel_size = 0.003
		smile.position = Vector3(0, 0.44, -0.23)
		smile.modulate = Color("4a3425")
		smile.rotation.y = PI
		root.add_child(smile)
	else:
		# Jewel-coloured panels, white frame, dots and readable question marks.
		for side in 4:
			var panel := Node3D.new()
			root.add_child(panel)
			panel.rotation.y = side * PI / 2
			jewel_panel(panel, side)
			for i in 8:
				ball(panel, Color.from_hsv(fposmod(side * 0.2 + i * 0.13, 1), 0.75, 1), Vector3(-0.34 + (i % 3) * 0.32, -0.34 + (i / 3) * 0.3, -0.511), Vector3(0.12, 0.12, 0.012))
			var question := Label3D.new()
			question.text = "?"
			question.font_size = 100
			question.pixel_size = 0.009
			question.outline_size = 13
			question.outline_modulate = Color("176aab")
			question.position = Vector3(0, -0.02, -0.535)
			question.rotation.y = PI
			panel.add_child(question)
		for axis in 3:
			for a in [-1, 1]:
				for b in [-1, 1]:
					var at := Vector3.ZERO
					at[(axis + 1) % 3] = a * 0.5
					at[(axis + 2) % 3] = b * 0.5
					var size := Vector3.ONE * 0.07
					size[axis] = 1.07
					box(root, Color("f6ffff"), at, size)
		box(root, Color("89eff0"), Vector3(0, 0.48, 0), Vector3(0.95, 0.03, 0.95))
