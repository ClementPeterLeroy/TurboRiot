@tool
class_name AuthoredCircuit
extends TrackBuilder
## Saved road/junction/plaza meshes own collision. The curve owns race stations.
@export var width_profile: Curve
@export var drivable_runoff := PackedVector2Array()
@export var runoff_interval := Vector2.ZERO
@export var checkpoint_extents := PackedVector2Array()

func _ready() -> void:
	curve_changed.connect(_schedule_rebuild)
	# Defer tool-generated children until the editor has finished inserting the
	# imported hierarchy. Runtime initialization still builds synchronously.
	if Engine.is_editor_hint(): _schedule_rebuild()
	else: build()

func build() -> void:
	_queued=false
	if not is_curve_closed(): return
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
	var limits := Vector2.ONE * width * .5
	if drivable_runoff.is_empty() or offset<runoff_interval.x or offset>runoff_interval.y:return limits
	var center := sample_center(offset)
	var right := road_right(offset)
	var origin := Vector2(center.x,center.z)
	var direction := Vector2(right.x,right.z)
	var stations: Array[float]=[]
	for i in drivable_runoff.size():
		var hit=Geometry2D.segment_intersects_segment(origin-direction*250,origin+direction*250,drivable_runoff[i],drivable_runoff[(i+1)%drivable_runoff.size()])
		if hit!=null:stations.append((hit-origin).dot(direction))
	if stations.size()>=2:
		stations.sort()
		# Extend only connected grass; never bridge a strip of open water.
		if stations[0]<=limits.y and stations[-1]>=-limits.x:
			limits=Vector2(maxf(limits.x,-stations[0]),maxf(limits.y,stations[-1]))
	return limits

func checkpoint_limits(offset: float, index: int) -> Vector2:
	if index<checkpoint_extents.size() and checkpoint_extents[index].x>=0:return checkpoint_extents[index]
	return corridor_limits(offset)

func spawn_transform() -> Transform3D:
	var forward := sample_forward(0)
	forward.y = 0
	return global_transform * Transform3D(Basis.looking_at(forward.normalized()), sample_center(0) + Vector3.UP * .65)
