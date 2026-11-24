class_name TrackRegistry
extends RefCounted
const IDS := [&"reference", &"figure_8", &"yoshi_ds"]
## Deferred authoring/catalog entries do not enter race setup validation.
const CATALOG_IDS := [&"reference", &"figure_8", &"yoshi_ds", &"baby_park", &"wario_stadium_ds", &"delfino_square_ds"]

static func catalog_entries() -> Array[TrackDefinition]:
	var result: Array[TrackDefinition] = []
	for id in CATALOG_IDS: result.append(_definition(id))
	return result

static func entries() -> Array[TrackDefinition]:
	var result: Array[TrackDefinition] = []
	for id in IDS: result.append(get_definition(id))
	return result

static func get_definition(id: StringName) -> TrackDefinition:
	return _definition(id if id in IDS else &"reference")

static func _definition(id: StringName) -> TrackDefinition:
	var definition := TrackDefinition.new()
	definition.identifier = id
	match definition.identifier:
		&"figure_8":
			definition.display_name = "Circuit 8"
			definition.category = "Private educational / Mario Kart DS"
			definition.description = "Sweeping turns, packed grandstands and a soaring stadium crossover."
			definition.accent = Color("fb67ae")
			definition.scene = load("res://scenes/tracks/figure_8.tscn")
			definition.pickup_fractions = PackedFloat32Array([0.12, 0.45, 0.8])
		&"yoshi_ds":
			definition.display_name = "Serpent Coast"
			definition.category = "Private educational / Mario Kart DS"
			definition.description = "Thread coastal gardens and tunnels through a winding island course."
			definition.scene = load("res://scenes/tracks/yoshi_ds.tscn")
			definition.pickup_fractions = PackedFloat32Array([0.18, 0.48, 0.77])
		&"baby_park", &"wario_stadium_ds", &"delfino_square_ds":
			definition.available = false
			definition.internal_only = true
			definition.display_name = {&"baby_park": "Legend Park", &"wario_stadium_ds": "Riot Arena", &"delfino_square_ds": "Sunhaven Square"}[id]
			if id == &"baby_park": definition.authoring_scene_path = "res://scenes/tracks/Baby_park.tscn"
		_:
			definition.display_name = "Desert Run"
			definition.category = "Development / debugging"
			definition.description = "Sun-baked straights, sandy runoffs and a tight desert hairpin."
			definition.accent = Color("ffd45b")
	return definition
