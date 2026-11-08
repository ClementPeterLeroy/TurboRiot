@tool
class_name TrackBuilder
extends Path3D
signal geometry_rebuilt

const CHECKPOINT_SCENE := preload("res://scenes/checkpoint.tscn")
## The saved Curve3D is the source of truth. Generated nodes are transient:
## opening a scene or editing a curve replaces one Generated subtree.

@export_range(6.0, 20.0) var road_width: float = 10.0:
	set(value):
		road_width = value
		_schedule_rebuild()
@export_range(0.5, 3.0) var sample_spacing: float = 1.5:
	set(value):
		sample_spacing = value
		_schedule_rebuild()
@export var barrier_spacing: float = 4.0:
	set(value):
		barrier_spacing = maxf(value, 1.0)
		_schedule_rebuild()
@export var rebuild: bool = false:
	set(_value):
		_schedule_rebuild()
@export_range(4, 32) var checkpoint_count: int = 12:
	set(value):
		checkpoint_count = value
		_schedule_rebuild()
@export var show_checkpoints: bool = false:
	set(value):
		show_checkpoints = value
		if has_node("Generated/Checkpoints"):
			for gate in get_node("Generated/Checkpoints").get_children():
				gate.set_debug_visible(value)
var _barrier_mesh: ArrayMesh
var _queued := false
var road_vertices := PackedVector3Array()
var road_indices := PackedInt32Array()

func _ready() -> void:
	curve_changed.connect(_schedule_rebuild)
	build()

func _schedule_rebuild() -> void:
	if not is_inside_tree() or _queued:
		return
	_queued = true
	build.call_deferred()

func is_curve_closed() -> bool:
	return curve != null and curve.point_count >= 4 and \
		curve.get_point_position(0).is_equal_approx(curve.get_point_position(curve.point_count - 1))

func build() -> void:
	_queued = false
	var previous := get_node_or_null("Generated")
	if previous:
		remove_child(previous)
		previous.queue_free()
	road_vertices.clear()
	road_indices.clear()
	if not is_curve_closed() or curve.get_baked_length() < 1.0:
		push_warning("Track requires a closed curve: duplicate the first point at the end.")
		return
	var generated := Node3D.new()
	generated.name = "Generated"
	add_child(generated)
	var asphalt := RiotGeometry.material(Color("5a5a5a"))
	asphalt.cull_mode = BaseMaterial3D.CULL_DISABLED
	var white := RiotGeometry.material(Color("fff5df"))
	var red := RiotGeometry.material(Color("f04b50"))
	var length := curve.get_baked_length()
	var steps := maxi(4, ceili(length / sample_spacing))
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	for i in range(steps + 1):
		var offset := length * float(i) / steps
		var center := sample_center(offset)
		var right := sample_forward(offset).cross(Vector3.UP).normalized()
		for side in [-1.0, 1.0]:
			road_vertices.append(center + right * side * road_width * 0.5)
			normals.append(Vector3.UP)
			uvs.append(Vector2((side + 1.0) * 0.5, offset / road_width))
		if i < steps:
			var a := i * 2
			# Godot front faces use clockwise winding when viewed from above.
			road_indices.append_array(PackedInt32Array([a, a + 2, a + 1, a + 1, a + 2, a + 3]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = road_vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = road_indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var road := MeshInstance3D.new()
	road.name = "Asphalt"
	road.mesh = mesh
	road.material_override = asphalt
	generated.add_child(road)
	road.create_trimesh_collision()
	_build_barriers(generated)
	var kerb_steps := ceili(length / 1.8)
	for i in kerb_steps:
		var a := length * float(i) / kerb_steps
		var b := length * float(i + 1) / kerb_steps
		for side in [-1.0, 1.0]:
			var start := boundary_point(a, side, 0.25)
			var end := boundary_point(b, side, 0.25)
			var kerb := RiotGeometry.box(generated, "Kerb", Vector3(0.65, 0.035, start.distance_to(end) + 0.04),
				(start + end) * 0.5, red if i % 2 == 0 else white)
			kerb.rotation.y = atan2(end.x - start.x, end.z - start.z)
	_build_start(generated, white)
	_build_checkpoints(generated)
	geometry_rebuilt.emit()

func sample_center(offset: float) -> Vector3:
	var point := curve.sample_baked(clampf(offset, 0.0, curve.get_baked_length()), true)
	point.y = 0.04 # Ignore accidental vertical handle edits: this milestone is flat.
	return point

func sample_forward(offset: float) -> Vector3:
	var length := curve.get_baked_length()
	var a := sample_center(fposmod(offset - 0.2, length))
	var b := sample_center(fposmod(offset + 0.2, length))
	return (b - a).normalized()

func boundary_point(offset: float, side: float, extra: float) -> Vector3:
	return sample_center(offset) + sample_forward(offset).cross(Vector3.UP) * side * (road_width * 0.5 + extra)

func spawn_transform() -> Transform3D:
	var forward := sample_forward(0.0)
	# Start behind the finish plane; crossing it initially never awards a lap.
	return global_transform * Transform3D(Basis.looking_at(forward),
		sample_center(0.0) - forward * 4.0 + Vector3.UP * 0.65)

func _build_checkpoints(parent: Node3D) -> void:
	var checkpoints := Node3D.new()
	checkpoints.name = "Checkpoints"
	parent.add_child(checkpoints)
	for i in checkpoint_count:
		var gate := CHECKPOINT_SCENE.instantiate() as CheckpointGate
		gate.name = "Finish" if i == 0 else "Checkpoint%02d" % i
		gate.gate_index = i
		gate.gate_width = road_width
		var offset := curve.get_baked_length() * float(i) / checkpoint_count
		gate.transform = Transform3D(Basis.looking_at(sample_forward(offset)), sample_center(offset))
		checkpoints.add_child(gate)
		gate.set_debug_visible(show_checkpoints)

func _build_barriers(parent: Node3D) -> void:
	if _barrier_mesh == null:
		_barrier_mesh = BarrierMesh.create()
	var palette: Array[Color] = [Color("ef4444"), Color("3b82f6"), Color("facc15"), Color("22c55e")]
	var transforms: Array = [[], [], [], []]
	var length := curve.get_baked_length()
	var blocks := ceili(length / 1.2)
	for i in blocks:
		var a := length * float(i) / blocks
		var b := length * float(i + 1) / blocks
		for side in [-1.0, 1.0]:
			var start := boundary_point(a, side, 0.95)
			var end := boundary_point(b, side, 0.95)
			var segment := end - start
			var basis := Basis(Vector3.UP, atan2(segment.x, segment.z))
			basis = basis * Basis.from_scale(Vector3(0.8, 1.0, segment.length() + 0.015))
			transforms[i % 4].append(Transform3D(basis, (start + end) * 0.5 + Vector3.UP * 0.5))
	for color_index in 4:
		var paint := RiotGeometry.material(palette[color_index])
		paint.vertex_color_use_as_albedo = true
		var batch := MultiMesh.new()
		batch.transform_format = MultiMesh.TRANSFORM_3D
		batch.mesh = _barrier_mesh
		batch.instance_count = transforms[color_index].size()
		for i in batch.instance_count:
			batch.set_instance_transform(i, transforms[color_index][i])
		var visual := MultiMeshInstance3D.new()
		visual.name = "BarrierVisuals%d" % color_index
		visual.multimesh = batch
		visual.material_override = paint
		parent.add_child(visual)
	# A single static body uses simple continuous box segments. Collision is
	# separate from the many faceted visuals and never uses their triangles.
	var body := StaticBody3D.new()
	body.name = "BarrierCollision"
	parent.add_child(body)
	var sections := ceili(length / barrier_spacing)
	for i in sections:
		for side in [-1.0, 1.0]:
			var a := boundary_point(length * float(i) / sections, side, 0.95)
			var b := boundary_point(length * float(i + 1) / sections, side, 0.95)
			var segment := b - a
			var shape := CollisionShape3D.new()
			var box_shape := BoxShape3D.new()
			box_shape.size = Vector3(0.864, 1.08, segment.length() + 0.1)
			shape.shape = box_shape
			body.add_child(shape)
			shape.position = (a + b) * 0.5 + Vector3.UP * 0.5
			shape.rotation.y = atan2(segment.x, segment.z)

func _build_start(parent: Node3D, white: Material) -> void:
	var black := RiotGeometry.material(Color("202735"))
	var forward := sample_forward(0.0)
	var right := forward.cross(Vector3.UP)
	var center := sample_center(0.0)
	var columns := ceili(road_width)
	var tile_width := road_width / columns
	for row in 2:
		for column in columns:
			var tile := RiotGeometry.box(parent, "StartTile", Vector3(tile_width, 0.012, 0.65),
				center + right * (-road_width * 0.5 + (column + 0.5) * tile_width)
				+ forward * (float(row) * 0.65) + Vector3.UP * 0.025,
				white if (row + column) % 2 == 0 else black)
			tile.rotation.y = atan2(-forward.x, -forward.z)
	for row in 3:
		for side in [-1.0, 1.0]:
			var grid := RiotGeometry.box(parent, "GridMark", Vector3(1.8, 0.012, 0.12),
				center + forward * (-4.0 - row * 4.0) + right * side * 2.5 + Vector3.UP * 0.025, white)
			grid.rotation.y = atan2(-forward.x, -forward.z)
	for side in [-1.0, 1.0]:
		RiotGeometry.box(parent, "StartPost", Vector3(0.4, 5.0, 0.4),
			center + right * side * (road_width * 0.5 + 1.5) + Vector3.UP * 2.5, white)
	var banner := RiotGeometry.box(parent, "StartBanner", Vector3(road_width + 3.5, 1.0, 0.45),
		center + Vector3.UP * 5.0, black)
	banner.rotation.y = atan2(-forward.x, -forward.z)
	var label := Label3D.new()
	label.text = "TURBO RIOT  /  START"
	label.font_size = 60
	label.pixel_size = 0.006
	label.no_depth_test = false
	parent.add_child(label)
	label.position = center + Vector3.UP * 5.0 - forward * 0.25
	label.rotation.y = atan2(-forward.x, -forward.z)
