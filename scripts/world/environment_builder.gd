@tool
extends Node3D
## Deterministic scenery, with no random placement on the road.
@export var track: TrackBuilder
@export var seed_value: int = 1701
@export var tree_count: int = 65
## Metre coordinates traced from the reference's central grass footprint.
## Editable separately from the circuit when authoring an original layout.
@export var infield_outline := PackedVector2Array([
	Vector2(-59.4, -60.3), Vector2(-42.3, -60.3), Vector2(-42.3, -22.5),
	Vector2(31.5, -22.5), Vector2(31.5, -15.3), Vector2(53.1, -15.3),
	Vector2(53.1, 53.1), Vector2(42.3, 53.1), Vector2(42.3, -2.7),
	Vector2(-42.3, -2.7), Vector2(-42.3, 14.4), Vector2(-59.4, 14.4)])
@export var rebuild: bool = false:
	set(_value):
		if is_inside_tree():
			_schedule_build()
var _queued := false

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
	RiotGeometry.box(generated, "SandGround", Vector3(360, 0.6, 320), Vector3(0, -0.38, 0), sand, true)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	_build_infield(generated, grass)
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
		if _road_distance(point) < track.road_width * 0.5 + 6.0:
			continue
		var height := rng.randf_range(3.4, 5.5)
		RiotGeometry.cylinder(generated, "Trunk", point + Vector3.UP * 0.7, 0.25, 0.18, 1.4, bark)
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
		hill.position = Vector3(cos(angle) * 145.0, -2.0, sin(angle) * 130.0)
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

func _road_distance(point: Vector3) -> float:
	if not track or not track.curve:
		return INF
	return point.distance_to(track.curve.get_closest_point(point))
