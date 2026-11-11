extends SceneTree
## Run a single new circuit before proceeding to the next reconstruction.
var failures := 0
func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _run() -> void:
	var id: StringName = &"figure_8"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--circuit="): id = StringName(argument.get_slice("=", 1))
	var world := TrackRegistry.get_definition(id).instantiate_race()
	world.get_node("Items").enabled = false
	root.add_child(world)
	var track := world.get_node("Track") as TrackBuilder
	check(track.is_curve_closed(), "Closed curve")
	var vertices := track.road_vertices
	var indices := track.road_indices
	var minimum_area := INF
	var minimum_width := INF
	for i in range(0, indices.size(), 3):
		var cross := (vertices[indices[i+1]]-vertices[indices[i]]).cross(vertices[indices[i+2]]-vertices[indices[i]])
		minimum_area = minf(minimum_area, cross.length())
		if cross.y >= -0.0001: print("BAD FACE ", vertices[indices[i]], " index ", indices[i])
		check(cross.y < -0.0001, "Clockwise nondegenerate upward face")
	for i in range(0, vertices.size(), 2):
		minimum_width = minf(minimum_width, vertices[i].distance_to(vertices[i+1]))
	check(absf(minimum_width-track.road_width) < 0.001, "Constant full road width")
	check(vertices[0].distance_to(vertices[vertices.size()-2]) < 0.001, "Seam left")
	check(vertices[1].distance_to(vertices[vertices.size()-1]) < 0.001, "Seam right")
	var race := world.get_node("RaceManager") as RaceManager
	for a in race.competitors:
		check(absf(race.racing_line.project(a.grid.origin).y) + 0.9 < track.road_width/2, "Grid inside road")
		for b in race.competitors:
			if a != b: check(a.grid.origin.distance_to(b.grid.origin) > 2.5, "Grid spacing")
	print("CIRCUIT %s length=%.2f width=%.2f triangles=%d minimum_area=%.4f failures=%d" % [id,track.curve.get_baked_length(),minimum_width,indices.size()/3,minimum_area,failures])
	world.queue_free()
	await process_frame
	quit(1 if failures else 0)
