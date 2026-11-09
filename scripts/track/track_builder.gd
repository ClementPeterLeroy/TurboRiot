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
@export_group("Outer barriers (clearance beyond road edge)")
@export var barrier_runs: Array[BarrierRun] = []:
	set(value):
		for run in barrier_runs:
			if run and run.changed.is_connected(_schedule_rebuild):
				run.changed.disconnect(_schedule_rebuild)
		barrier_runs = value
		for run in value:
			if run and not run.changed.is_connected(_schedule_rebuild):
				run.changed.connect(_schedule_rebuild)
		_schedule_rebuild()
@export_range(1, 20) var barrier_color_group_size: int = 5:
	set(value):
		barrier_color_group_size = maxi(1, value)
		_schedule_rebuild()
@export var barrier_sections: Array[BarrierSection] = []:
	set(value):
		for section in barrier_sections:
			if section and section.changed.is_connected(_schedule_rebuild):
				section.changed.disconnect(_schedule_rebuild)
		barrier_sections = value
		for section in value:
			if section and not section.changed.is_connected(_schedule_rebuild):
				section.changed.connect(_schedule_rebuild)
		_schedule_rebuild()
@export var outer_perimeter_enabled: bool = true:
	set(value):
		outer_perimeter_enabled = value
		_schedule_rebuild()
@export var playable_half_extents := Vector2(170, 150):
	set(value):
		playable_half_extents = value.max(Vector2(100, 100))
		_schedule_rebuild()
@export var left_barrier_clearance: Curve:
	set(value):
		if left_barrier_clearance and left_barrier_clearance.changed.is_connected(_schedule_rebuild):
			left_barrier_clearance.changed.disconnect(_schedule_rebuild)
		left_barrier_clearance = value
		if value and not value.changed.is_connected(_schedule_rebuild):
			value.changed.connect(_schedule_rebuild)
		_schedule_rebuild()
@export var right_barrier_clearance: Curve:
	set(value):
		if right_barrier_clearance and right_barrier_clearance.changed.is_connected(_schedule_rebuild):
			right_barrier_clearance.changed.disconnect(_schedule_rebuild)
		right_barrier_clearance = value
		if value and not value.changed.is_connected(_schedule_rebuild):
			value.changed.connect(_schedule_rebuild)
		_schedule_rebuild()
@export_group("")
@export var rebuild: bool = false:
	set(_value):
		_schedule_rebuild()
@export_range(4, 32) var checkpoint_count: int = 12:
	set(value):
		checkpoint_count = value
		_schedule_rebuild()
@export var checkpoint_fractions := PackedFloat32Array():
	set(value):
		checkpoint_fractions = value
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
var barrier_paths: Array[Curve3D] = [] # Left then right; separate from asphalt.
var barrier_block_transforms: Array[Transform3D] = [] # CPU source for batches/tests.
var barrier_block_colors := PackedInt32Array()
var barrier_run_ranges: Array[Vector2i] = []
var barrier_edges: Array[PackedVector3Array] = [] # Actual enabled collision spans.
var _fence_spans: Array[Dictionary] = []

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
	SurfaceDetector.tag_collision(road, preload("res://resources/surfaces/asphalt.tres"))
	_build_shoulders(generated)
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

func barrier_clearance(offset: float, side: float) -> float:
	if not barrier_runs.is_empty():
		var limits := corridor_limits(offset)
		return (limits.x if side < 0 else limits.y) - road_width * 0.5
	var profile := left_barrier_clearance if side < 0.0 else right_barrier_clearance
	var fraction := fposmod(offset, curve.get_baked_length()) / curve.get_baked_length()
	var clearance := profile.sample(fraction) if profile and profile.point_count > 0 else 0.95
	for section in barrier_sections:
		if section and section.applies(fraction, side) and section.clearance_override >= 0:
			clearance = section.clearance_override
	return clampf(clearance, 0.95, 25.0) if is_finite(clearance) else 0.95

func barrier_enabled(offset: float, side: float) -> bool:
	var fraction := fposmod(offset, curve.get_baked_length()) / curve.get_baked_length()
	var enabled := true
	for section in barrier_sections:
		if section and section.applies(fraction, side):
			enabled = section.barriers_enabled
	return enabled

func barrier_point(offset: float, side: float) -> Vector3:
	return boundary_point(offset, side, barrier_clearance(offset, side))

func corridor_limits(offset: float) -> Vector2:
	if barrier_runs.is_empty():
		return Vector2(road_width * 0.5 + barrier_clearance(offset, -1), road_width * 0.5 + barrier_clearance(offset, 1))
	var center := sample_center(offset)
	var right := sample_forward(offset).cross(Vector3.UP)
	var result := Vector2.ZERO
	for index in 2:
		var direction := right * (-1.0 if index == 0 else 1.0)
		var distance := 250.0
		var a := Vector2(center.x, center.z)
		var b := a + Vector2(direction.x, direction.z) * distance
		for edge in _fence_spans:
			var hit: Variant = Geometry2D.segment_intersects_segment(a, b,
				Vector2(edge.a.x, edge.a.z), Vector2(edge.b.x, edge.b.z))
			if hit != null:
				var on_edge := Vector2(edge.a.x, edge.a.z).distance_to(hit)
				if edge.run.enabled_at((edge.offset + on_edge) / edge.total):
					distance = minf(distance, a.distance_to(hit))
		# The authored outer run always bounds the corridor; half the block width
		# removes its solid face. No width extends beyond physical containment.
		result[index] = maxf(road_width * 0.5, distance - 0.432)
	return result

func legal_outline() -> PackedVector2Array:
	var result := PackedVector2Array()
	if not barrier_runs.is_empty():
		for point in barrier_runs[0].points:
			result.append(Vector2(point.x, point.z))
	return result

func _build_shoulders(parent: Node3D) -> void:
	# The original sand floor is 12 cm below asphalt. A ramp prevents the
	# CharacterBody from catching the raised asphalt edge when rejoining.
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	var length := curve.get_baked_length()
	var steps := ceili(length / sample_spacing)
	for side in [-1.0, 1.0]:
		var base := vertices.size()
		for i in range(steps + 1):
			var offset := length * float(i) / steps
			var inner := boundary_point(offset, side, 0)
			var outer := boundary_point(offset, side, 1.2)
			outer.y = -0.08
			vertices.append(inner)
			vertices.append(outer)
			normals.append(Vector3.UP)
			normals.append(Vector3.UP)
			if i < steps:
				var a := base + i * 2
				if side > 0:
					indices.append_array(PackedInt32Array([a, a + 2, a + 1, a + 1, a + 2, a + 3]))
				else:
					indices.append_array(PackedInt32Array([a, a + 1, a + 2, a + 1, a + 3, a + 2]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var shoulder := MeshInstance3D.new()
	shoulder.name = "RunoffShoulders"
	shoulder.mesh = mesh
	shoulder.material_override = RiotGeometry.material(Color("d7ad68"))
	parent.add_child(shoulder)
	shoulder.create_trimesh_collision()
	SurfaceDetector.tag_collision(shoulder, preload("res://resources/surfaces/sand.tres"))

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
		var offset := curve.get_baked_length() * float(i) / checkpoint_count
		if checkpoint_fractions.size() == checkpoint_count:
			offset = curve.get_baked_length() * checkpoint_fractions[i]
		# Keep finish fixed; numbered gates lie at regular progress sectors.
		# Their asymmetric limits follow actual fences, including grass openings.
		var limits := corridor_limits(offset)
		gate.gate_width = road_width
		gate.left_extent = limits.x
		gate.right_extent = limits.y
		gate.route_curve = curve
		gate.route_transform = global_transform
		gate.route_offset = offset
		gate.route_window = curve.get_baked_length() / checkpoint_count * 0.48
		gate.legal_outline = legal_outline()
		# Keep only the connected corridor belonging to this route sector. A
		# diagonal gate must not silently extend across a different asphalt leg.
		if not barrier_runs.is_empty():
			for side in [-1.0, 1.0]:
				var extent := limits.x if side < 0 else limits.y
				var reachable := road_width * 0.5
				var distance := road_width * 0.5
				while distance <= extent:
					var point := boundary_point(offset, side, distance - road_width * 0.5)
					var difference := absf(curve.get_closest_offset(point) - offset)
					if minf(difference, curve.get_baked_length() - difference) > gate.route_window:
						break
					reachable = distance
					distance += 0.5
				if side < 0:
					gate.left_extent = minf(extent, reachable)
				else:
					gate.right_extent = minf(extent, reachable)
		gate.transform = Transform3D(Basis.looking_at(sample_forward(offset)), sample_center(offset))
		checkpoints.add_child(gate)
		gate.set_debug_visible(show_checkpoints)

func _build_barriers(parent: Node3D) -> void:
	if _barrier_mesh == null:
		_barrier_mesh = BarrierMesh.create()
	var palette: Array[Color] = [Color("ef4444"), Color("3b82f6"), Color("facc15"), Color("22c55e")]
	var transforms: Array = [[], [], [], []]
	var length := curve.get_baked_length()
	barrier_paths.clear()
	barrier_block_transforms.clear()
	barrier_block_colors.clear()
	barrier_run_ranges.clear()
	barrier_edges.clear()
	_fence_spans.clear()
	var body := StaticBody3D.new()
	body.name = "BarrierCollision"
	parent.add_child(body)
	if not barrier_runs.is_empty():
		for run in barrier_runs:
			if run and run.points.size() >= 2:
				_append_authored_run(run, transforms, body)
	else:
		_build_offset_runs(transforms, body)
	if outer_perimeter_enabled:
		_append_perimeter(transforms, body)
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

func _append_block(a: Vector3, b: Vector3, color_index: int, transforms: Array, body: StaticBody3D) -> void:
	var segment := b - a
	var basis := Basis(Vector3.UP, atan2(segment.x, segment.z))
	var size := Vector3(0.8, 1.0, segment.length() + 0.015)
	var block := Transform3D(basis * Basis.from_scale(size), (a + b) * 0.5 + Vector3.UP * 0.5)
	transforms[color_index].append(block)
	barrier_block_transforms.append(block)
	barrier_block_colors.append(color_index)
	barrier_edges.append(PackedVector3Array([a, b]))
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.864, 1.08, size.z)
	collision.shape = box
	body.add_child(collision)
	collision.transform = Transform3D(basis, block.origin)

func _append_authored_run(run: BarrierRun, transforms: Array, body: StaticBody3D) -> void:
	var path := run.path()
	barrier_paths.append(path)
	var total := path.get_baked_length()
	var offset := 0.0
	var spans: Array[Dictionary] = []
	var edge_count := run.points.size() if run.closed else run.points.size() - 1
	for edge in edge_count:
		var start := run.points[edge]
		var end := run.points[(edge + 1) % run.points.size()]
		var length := start.distance_to(end)
		_fence_spans.append({"a": start, "b": end, "offset": offset, "total": total, "run": run})
		var cuts: Array[float] = [0.0, length]
		for gap in run.gaps:
			for fraction in [gap.x, gap.y]:
				var cut: float = fraction * total - offset
				if cut > 0.001 and cut < length - 0.001:
					cuts.append(cut)
		cuts.sort()
		for i in range(cuts.size() - 1):
			var size := cuts[i + 1] - cuts[i]
			if size < 0.01 or not run.enabled_at((offset + (cuts[i] + cuts[i + 1]) * 0.5) / total):
				continue
			spans.append({"a": start.lerp(end, cuts[i] / length), "b": start.lerp(end, cuts[i + 1] / length),
				"count": maxi(1, ceili(size / minf(1.2, barrier_spacing)))})
		offset += length
	if spans.is_empty():
		return
	# A closed source may have authored openings. Start after a real gap, not
	# at an arbitrary resource vertex, so colours do not reset at that vertex.
	if run.closed:
		for i in spans.size():
			var previous: Vector3 = spans[posmod(i - 1, spans.size())].b
			if previous.distance_to(spans[i].a) > 0.02:
				spans = spans.slice(i) + spans.slice(0, i)
				break
	var connected: Array[Dictionary] = []
	for span in spans:
		if not connected.is_empty() and Vector3(connected.back().b).distance_to(span.a) > 0.02:
			_append_connected_blocks(connected, false, transforms, body)
			connected.clear()
		connected.append(span)
	var closed := Vector3(connected.back().b).distance_to(connected[0].a) < 0.02
	_append_connected_blocks(connected, closed, transforms, body)

func _append_connected_blocks(spans: Array[Dictionary], closed: bool, transforms: Array, body: StaticBody3D) -> void:
	var count := 0
	for span in spans:
		count += span.count
	var cycle := barrier_color_group_size * (4 if closed else 1)
	var extra := posmod(-count, cycle)
	for i in extra:
		spans[i % spans.size()].count += 1
	var first := barrier_block_transforms.size()
	var cursor := 0
	for span in spans:
		var a: Vector3 = span.a
		var b: Vector3 = span.b
		for i in int(span.count):
			_append_block(a.lerp(b, float(i) / span.count), a.lerp(b, float(i + 1) / span.count),
				floori(float(cursor) / barrier_color_group_size) % 4, transforms, body)
			cursor += 1
	barrier_run_ranges.append(Vector2i(first, cursor))

func _build_offset_runs(transforms: Array, body: StaticBody3D) -> void:
	var length := curve.get_baked_length()
	for side in [-1.0, 1.0]:
		var path := Curve3D.new()
		path.bake_interval = 0.15
		var samples := ceili(length / 0.6)
		for i in range(samples + 1):
			path.add_point(barrier_point(length * float(i) / samples, side))
		barrier_paths.append(path)
		var path_length := path.get_baked_length()
		var blocks := ceili(path_length / minf(1.2, barrier_spacing))
		var first := barrier_block_transforms.size()
		var cursor := 0
		for i in blocks:
			var start := path.sample_baked(path_length * float(i) / blocks)
			var end := path.sample_baked(path_length * float(i + 1) / blocks)
			if not barrier_enabled(curve.get_closest_offset((start + end) * 0.5), side):
				continue
			_append_block(start, end, floori(float(cursor) / barrier_color_group_size) % 4, transforms, body)
			cursor += 1
		barrier_run_ranges.append(Vector2i(first, cursor))

func _append_perimeter(transforms: Array, body: StaticBody3D) -> void:
	var x := playable_half_extents.x
	var z := playable_half_extents.y
	var run := BarrierRun.new()
	run.points = PackedVector3Array([Vector3(-x, -0.08, -z), Vector3(x, -0.08, -z),
		Vector3(x, -0.08, z), Vector3(-x, -0.08, z)])
	_append_authored_run(run, transforms, body)

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
