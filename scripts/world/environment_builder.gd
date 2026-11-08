@tool
extends Node3D
## Deterministic scenery, with no random placement on the road.
@export var track: TrackBuilder
@export var seed_value: int = 1701
@export var tree_count: int = 65
@export var rebuild: bool = false:
	set(_value):
		if is_inside_tree():
			build.call_deferred()

func _ready() -> void:
	if track:
		track.curve_changed.connect(_schedule_build)
	build.call_deferred()

func _schedule_build() -> void:
	build.call_deferred()

func build() -> void:
	var previous := get_node_or_null("Generated")
	if previous:
		remove_child(previous)
		previous.queue_free()
	var generated := Node3D.new()
	generated.name = "Generated"
	add_child(generated)
	var sand := RiotGeometry.material(Color("e3c586"))
	var grass := RiotGeometry.material(Color("6ac947"))
	var leaves := RiotGeometry.material(Color("299c53"))
	var bark := RiotGeometry.material(Color("976244"))
	RiotGeometry.box(generated, "SandGround", Vector3(360, 0.6, 320), Vector3(0, -0.38, 0), sand, true)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	# Low grass islands sit below the road surface; trees have a generous road setback.
	for i in 24:
		var point := Vector3(rng.randf_range(-95, 95), -0.065, rng.randf_range(-85, 85))
		if _road_distance(point) < 13.0:
			continue
		var island := RiotGeometry.cylinder(generated, "GrassIsland", point, 10.0, 10.0, 0.03, grass)
		island.scale = Vector3(rng.randf_range(0.7, 1.7), 1, rng.randf_range(0.7, 1.4))
	var planted := 0
	for attempt in tree_count * 8:
		if planted >= tree_count:
			break
		var point := Vector3(rng.randf_range(-110, 110), -0.06, rng.randf_range(-100, 100))
		if _road_distance(point) < track.road_width * 0.5 + 6.0:
			continue
		var height := rng.randf_range(3.4, 5.5)
		RiotGeometry.cylinder(generated, "Trunk", point + Vector3.UP * 0.7, 0.25, 0.18, 1.4, bark)
		RiotGeometry.cylinder(generated, "Crown", point + Vector3.UP * (height * 0.5 + 0.8),
			1.8, 0.0, height, leaves)
		planted += 1
	for i in 16:
		var angle := TAU * float(i) / 16.0
		var hill := RiotGeometry.cylinder(generated, "DistantHill", Vector3(cos(angle) * 145.0,
			0, sin(angle) * 130.0), 24, 5, rng.randf_range(12, 25), grass)
		hill.position.y = hill.mesh.height * 0.5 - 1.0

func _road_distance(point: Vector3) -> float:
	if not track or not track.curve:
		return INF
	return point.distance_to(track.curve.get_closest_point(point))
