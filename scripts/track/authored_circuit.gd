@tool
class_name AuthoredCircuit
extends TrackBuilder
## Saved road/junction/plaza meshes own collision. The curve owns race stations.
@export var width_profile: Curve

func build() -> void:
	var previous := get_node_or_null("Generated")
	if previous:
		remove_child(previous)
		previous.queue_free()
	var generated := Node3D.new()
	generated.name = "Generated"
	add_child(generated)
	_build_checkpoints(generated)
	var white := RiotGeometry.material(Color("eee8d7"))
	var dark := RiotGeometry.material(Color("25313a"))
	var forward := sample_forward(0)
	for row in 2:
		for column in 16:
			var tile := RiotGeometry.box(generated, "FinishMark", Vector3(1.2,0.012,0.65), sample_center(0) + road_right(0) * (column - 7.5) * 1.2 + forward * row * .65 + Vector3.UP * .02, white if (row+column)%2==0 else dark)
			tile.rotation.y = atan2(-forward.x,-forward.z)
	geometry_rebuilt.emit()

func corridor_limits(offset: float) -> Vector2:
	var width := width_profile.sample(fposmod(offset,curve.get_baked_length()) / curve.get_baked_length()) if width_profile else road_width
	return Vector2.ONE * width * .5

func spawn_transform() -> Transform3D:
	var forward := sample_forward(0)
	forward.y = 0
	return global_transform * Transform3D(Basis.looking_at(forward.normalized()), sample_center(0) + Vector3.UP * .65)
