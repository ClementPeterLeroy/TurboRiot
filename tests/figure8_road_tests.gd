extends RefCounted
## Saved road geometry, separate from the archived environment contracts.
func run(s: SceneTree) -> void:
	var definition := TrackRegistry.get_definition(&"figure_8")
	var world := definition.instantiate_race()
	world.managed = true
	world.get_node("RaceManager").opponent_count = 0
	world.get_node("Items").enabled = false
	s.root.add_child(world)
	await s.physics_frame
	var track := world.get_node("Track") as TrackBuilder
	var original := load("res://scenes/tracks/archive/figure_8_before_reconstruction.tscn").instantiate() as TrackBuilder
	var curve := track.curve
	var points_preserved := curve.point_count == original.curve.point_count
	var smooth_derivatives := true
	var smooth_curvature := true
	for i in curve.point_count - 1:
		var p := curve.get_point_position(i)
		var old := original.curve.get_point_position(i)
		points_preserved = points_preserved and Vector2(p.x, p.z).is_equal_approx(Vector2(old.x, old.z))
		var previous := posmod(i - 1, curve.point_count - 1)
		var next := (i + 1) % (curve.point_count - 1)
		var incoming := -curve.get_point_in(i)
		var outgoing := curve.get_point_out(i)
		smooth_derivatives = smooth_derivatives and incoming.distance_to(outgoing) < 0.00001
		var left_second := 6 * (curve.get_point_position(previous) + curve.get_point_out(previous) - p - 2 * curve.get_point_in(i))
		var right_second := 6 * (curve.get_point_position(next) + curve.get_point_in(next) - p - 2 * outgoing)
		smooth_curvature = smooth_curvature and Vector2(left_second.x - right_second.x, left_second.z - right_second.z).length() < 0.0001
	s.check(points_preserved, "Road reconstruction preserves every original horizontal interpolation point")
	s.check(track.is_curve_closed(), "Reconstructed figure-eight closes without a seam")
	s.check(smooth_derivatives, "Reconstructed spline has continuous first derivatives, including elevation and closure")
	s.check(smooth_curvature, "Periodic horizontal spline has continuous second derivatives at every join")
	s.near(track.road_width, 15, "Road reconstruction retains 15 m racing width")
	s.check(track.sample_spacing <= 0.5, "Reconstructed road samples at most half-metre longitudinal intervals")
	var length := curve.get_baked_length()
	var maximum_grade := 0.0
	var maximum_height := -INF
	var minimum_height := INF
	var minimum_radius := INF
	for i in ceili(length * 2):
		var offset := length * i / ceili(length * 2)
		var forward := track.sample_forward(offset)
		maximum_grade = maxf(maximum_grade, absf(forward.y) / Vector2(forward.x, forward.z).length())
		maximum_height = maxf(maximum_height, track.sample_center(offset).y)
		minimum_height = minf(minimum_height, track.sample_center(offset).y)
		var a := track.sample_forward(fposmod(offset - 0.5, length))
		var b := track.sample_forward(fposmod(offset + 0.5, length))
		var angle := absf(Vector2(a.x, a.z).angle_to(Vector2(b.x, b.z)))
		if angle > 0.00001:
			minimum_radius = minf(minimum_radius, 1.0 / angle)
	s.check(maximum_grade < 0.08, "Reconstructed approaches remain below eight percent grade")
	s.check(absf(maximum_height - minimum_height - 8) < 0.03, "Reconstructed crossing retains approximately eight metres of rise")
	s.check(minimum_radius > 23, "Reconstructed turns avoid tight curvature spikes")
	s.check(length > 660 and length < 667, "Reconstruction preserves recognizable circuit length")
	var widths_ok := true
	for i in track.road_vertices.size() / 2:
		widths_ok = widths_ok and absf(track.road_vertices[i * 2].distance_to(track.road_vertices[i * 2 + 1]) - 15) < 0.001
	s.check(widths_ok, "Every reconstructed road cross-section has consistent width")
	var triangles_ok := true
	for i in range(0, track.road_indices.size(), 3):
		var a := track.road_vertices[track.road_indices[i]]
		var b := track.road_vertices[track.road_indices[i + 1]]
		var c := track.road_vertices[track.road_indices[i + 2]]
		triangles_ok = triangles_ok and a.is_finite() and b.is_finite() and c.is_finite() and (c - a).cross(b - a).y > 0.01
	s.check(triangles_ok, "Reconstructed road triangles remain finite, nondegenerate and upward-facing")
	var art := track.get_node_or_null("EnvironmentArt")
	s.check(track.road_study_mode and art != null and art.get_meta("stadium_revision", 0) == 1, "Reconstructed road retains its ribbon kerbs with the new authored stadium assembly")
	var kerbs := track.get_node("Generated/StudyKerbs") as MeshInstance3D
	s.check(kerbs != null and kerbs.mesh.get_surface_count() == 1 and kerbs.get_child_count() == 0, "Study kerbs use one continuous batched visual mesh without collision")
	var lower := Vector3(-50.4, 0.2, -1.25)
	# Query each deck from above: the road is a one-sided collision ribbon.
	# Physical underpass travel is exercised by crossing_collision_tests.gd.
	var query := PhysicsRayQueryParameters3D.create(Vector3(lower.x, 10, lower.z), lower, 1)
	var roof := track.get_world_3d().direct_space_state.intersect_ray(query)
	s.check(not roof.is_empty() and roof.position.y > 7.5, "Upper crossing collision clears the lower driving envelope")
	var floor_hit := track.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(lower, lower - Vector3.UP, 1))
	s.check(not floor_hit.is_empty() and absf(floor_hit.position.y - 0.04) < 0.001, "Lower crossing retains its independent ground-level road support")
	s.check(not original.road_study_mode and original.get_node_or_null("EnvironmentArt") != null, "Archived road retains original scenery and rendering configuration")
	original.free()
	world.queue_free()
	await s.process_frame
