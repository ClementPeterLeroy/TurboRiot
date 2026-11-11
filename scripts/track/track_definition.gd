class_name TrackDefinition
extends Resource
## Circuit assets/configuration only; race progress belongs to RaceManager.
@export var identifier: StringName
@export var display_name: String
@export var category: String
@export var description: String
@export var scene: PackedScene
@export var default_laps := 3
@export var grid_row_spacing := 5.5
@export var grid_lane_spacing := 4.2
@export var grid_stagger := 2.0
@export var pickup_fractions := PackedFloat32Array()
@export var pad_fractions := PackedFloat32Array()

func instantiate_race() -> Node3D:
	var world := load("res://scenes/main.tscn").instantiate() as Node3D
	world.set_meta("circuit_id", identifier)
	if scene == null: return world # Untouched original authoring fixture.
	# Keep the original sibling's construction order and all exported node links.
	var track := world.get_node("Track") as TrackBuilder
	var source := scene.instantiate() as TrackBuilder
	for property in ["curve", "road_width", "sample_spacing", "use_curve_elevation", "use_curve_banking", "outer_perimeter_enabled",
		"playable_half_extents", "checkpoint_count", "checkpoint_fractions", "barrier_runs", "barrier_sections",
		"left_barrier_clearance", "right_barrier_clearance"]:
		track.set(property, source.get(property))
	var ground := source.get_node("Ground")
	source.remove_child(ground)
	ground.owner = null
	track.add_child(ground)
	source.free()
	var environment := world.get_node("Environment")
	world.remove_child(environment)
	environment.free()
	var race := world.get_node("RaceManager") as RaceManager
	race.track = track
	race.grid_row_spacing = grid_row_spacing
	race.grid_lane_spacing = grid_lane_spacing
	race.grid_stagger = grid_stagger
	race.recovery_half_extents = track.playable_half_extents + Vector2.ONE * 8
	var features := world.get_node("TrackFeatures")
	features.track = track
	features.ramp_enabled = false
	features.boost_fractions = pad_fractions
	var items := world.get_node("Items") as ItemSystem
	items.track = track
	items.row_configurations = []
	for fraction in pickup_fractions:
		var row := LootRowConfig.new()
		row.route_fraction = fraction
		row.spacing = minf(3.2, (track.road_width - 3.0) / 3.0)
		items.row_configurations.append(row)
	return world

func preview_curve() -> Curve3D:
	var source := (scene if scene else load("res://scenes/track.tscn") as PackedScene).instantiate() as TrackBuilder
	var result := source.curve
	source.free()
	return result
