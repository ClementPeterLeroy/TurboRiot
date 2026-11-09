@tool
extends Node3D
## Deterministic scenery, with no random placement on the road.
@export var track: TrackBuilder
@export var seed_value: int = 1701
@export var tree_count: int = 65
## Metre coordinates traced from the reference's central grass footprint.
## Editable separately from the circuit when authoring an original layout.
@export var infield_outline := PackedVector2Array([Vector2(-59.0400, -60.3000), Vector2(-41.9400, -60.3000), Vector2(-41.9400, -22.5000), Vector2(31.3200, -22.5000), Vector2(31.3200, -15.3000), Vector2(53.6400, -15.3000), Vector2(53.6400, 53.6400), Vector2(41.0400, 53.6400), Vector2(41.0400, -2.3400), Vector2(-41.9400, -2.3400), Vector2(-41.9400, 14.7600), Vector2(-58.6800, 14.7600), Vector2(-58.6800, 27.7200), Vector2(-64.9800, 27.7200), Vector2(-64.9800, 8.6400), Vector2(-59.0400, 8.6400)])
@export var rebuild: bool = false:
	set(_value):
		if is_inside_tree():
			_schedule_build()
var _queued := false
var _trunk_shape: CylinderShape3D

func _ready() -> void:
	if track:
		track.geometry_rebuilt.connect(_schedule_build)
	_schedule_build()

func _schedule_build() -> void:
	if _queued:
		return
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
	var sand := RiotGeometry.material(Color("d7ad68"))
	var grass := RiotGeometry.material(Color("2ecc40"))
	var leaves := RiotGeometry.material(Color("299c53"))
	var bark := RiotGeometry.material(Color("976244"))
	if _trunk_shape == null:
		_trunk_shape = CylinderShape3D.new()
		_trunk_shape.radius = 0.18 # Inscribed within the visible 0.25 -> 0.18 taper.
		_trunk_shape.height = 1.4
	var ground := RiotGeometry.box(generated, "SandGround", Vector3(360, 0.6, 320), Vector3(0, -0.38, 0), sand, true)
	SurfaceDetector.tag_collision(ground, preload("res://resources/surfaces/sand.tres"))
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	_build_infield(generated, grass)
	_grass_patch(generated, Vector3(65.25, -0.06, -75.78), Vector2(49.5, 28.44), grass)
	_grass_patch(generated, Vector3(-47.7, -0.06, 77.4), Vector2(84.6, 25.2), grass)
	var crown_mesh := SphereMesh.new()
	crown_mesh.radius = 1.0
	crown_mesh.height = 2.0
	crown_mesh.radial_segments = 10
	crown_mesh.rings = 5
	var planted := 0
	for attempt in tree_count * 8:
		if planted >= tree_count:
			break
		var point := Vector3(rng.randf_range(-110, 110), -0.06, rng.randf_range(-100, 100))
		if _inside_driving_envelope(point):
			continue
		var height := rng.randf_range(3.4, 5.5)
		var trunk := RiotGeometry.cylinder(generated, "Trunk", point + Vector3.UP * 0.7, 0.25, 0.18, 1.4, bark)
		var body := StaticBody3D.new()
		body.name = "TrunkCollision"
		trunk.add_child(body)
		var collision := CollisionShape3D.new()
		collision.shape = _trunk_shape
		body.add_child(collision)
		var crown := MeshInstance3D.new()
		crown.name = "Crown"
		crown.mesh = crown_mesh
		crown.material_override = leaves
		generated.add_child(crown)
		crown.position = point + Vector3.UP * (height * 0.5 + 0.55)
		crown.scale = Vector3(1.4, (height - 1.1) * 0.5, 1.4)
		planted += 1
	var hill_mesh := SphereMesh.new()
	hill_mesh.radius = 1.0
	hill_mesh.height = 2.0
	hill_mesh.radial_segments = 12
	hill_mesh.rings = 6
	for i in 16:
		var angle := TAU * float(i) / 16.0
		var hill := MeshInstance3D.new()
		hill.name = "DistantHill"
		hill.mesh = hill_mesh
		hill.material_override = grass
		generated.add_child(hill)
		hill.position = Vector3(cos(angle) * 170.0, -2.0, sin(angle) * 155.0)
		hill.scale = Vector3(25.0, rng.randf_range(12, 22), 23.0)

func _build_infield(parent: Node3D, grass: Material) -> void:
	var indices := Geometry2D.triangulate_polygon(infield_outline)
	if indices.is_empty():
		return
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in indices:
		var point := infield_outline[index]
		surface.set_normal(Vector3.UP)
		surface.add_vertex(Vector3(point.x, -0.055, point.y))
	var field := MeshInstance3D.new()
	field.name = "GrassInfield"
	field.mesh = surface.commit()
	field.material_override = grass
	# This thin decorative polygon lies above sand, below asphalt, with no collider.
	grass.cull_mode = BaseMaterial3D.CULL_DISABLED
	parent.add_child(field)
	var region := Area3D.new()
	region.name = "GrassSurface"
	region.collision_layer = 8
	region.collision_mask = 0
	region.monitoring = false
	region.position.y = 0.2
	parent.add_child(region)
	var polygon := CollisionPolygon3D.new()
	polygon.polygon = infield_outline
	polygon.depth = 1.0
	polygon.rotation.x = PI * 0.5
	region.add_child(polygon)
	region.set_meta("surface", preload("res://resources/surfaces/grass.tres"))

func _grass_patch(parent: Node3D, center: Vector3, size: Vector2, grass: Material) -> void:
	RiotGeometry.box(parent, "OuterGrass", Vector3(size.x, 0.015, size.y), center, grass)
	var area := Area3D.new()
	area.name = "OuterGrassSurface"
	area.position = Vector3(center.x, 0.2, center.z)
	area.collision_layer = 8
	area.collision_mask = 0
	area.monitoring = false
	parent.add_child(area)
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(size.x, 1, size.y)
	collision.shape = box
	area.add_child(collision)
	area.set_meta("surface", preload("res://resources/surfaces/grass.tres"))

func _inside_driving_envelope(point: Vector3) -> bool:
	if not track or not track.curve:
		return false
	var offset := track.curve.get_closest_offset(point)
	var center := track.sample_center(offset)
	var right := track.sample_forward(offset).cross(Vector3.UP)
	var side := -1.0 if (point - center).dot(right) < 0.0 else 1.0
	var clearance := track.road_width * 0.5 + track.barrier_clearance(offset, side) + 3.0
	return point.distance_to(center) < clearance
