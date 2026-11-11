class_name TrackRegistry
extends RefCounted
const IDS := [&"reference", &"figure_8", &"yoshi_ds"]

static func entries() -> Array[TrackDefinition]:
	var result: Array[TrackDefinition] = []
	for id in IDS: result.append(get_definition(id))
	return result

static func get_definition(id: StringName) -> TrackDefinition:
	var definition := TrackDefinition.new()
	definition.identifier = id if id in IDS else &"reference"
	match definition.identifier:
		&"figure_8":
			definition.display_name = "Figure-8 Circuit"
			definition.category = "Private educational / Mario Kart DS"
			definition.description = "Broad turns and a simple raised central crossing. Greybox testing grounds."
			definition.scene = load("res://scenes/tracks/figure_8.tscn")
			definition.pickup_fractions = PackedFloat32Array([0.12, 0.45, 0.8])
		&"yoshi_ds":
			definition.display_name = "GCN Yoshi Circuit (DS)"
			definition.category = "Private educational / Mario Kart DS"
			definition.description = "A distinctive winding silhouette with tight successive corners. Greybox testing grounds."
			definition.scene = load("res://scenes/tracks/yoshi_ds.tscn")
			definition.pickup_fractions = PackedFloat32Array([0.18, 0.48, 0.77])
		_:
			definition.display_name = "Existing Reference Circuit"
			definition.category = "Development / debugging"
			definition.description = "Original reference layout, runoff ramp, pads and three blue-marker item rows."
	return definition
