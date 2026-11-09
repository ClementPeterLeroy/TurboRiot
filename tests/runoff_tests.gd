extends RefCounted

func run(suite: SceneTree) -> void:
	var main := load("res://scenes/main.tscn").instantiate() as Node3D
	main.get_node("RaceManager").opponent_count = 0 # Isolated legacy mechanics/presentation fixture.
	suite.root.add_child(main)
	var track := main.get_node("Track") as TrackBuilder
	var length := track.curve.get_baked_length()
	suite.check(track.barrier_clearance(0, -1) > 3, "Reference outside fence leaves start runoff")
	suite.check(track.barrier_clearance(length * 0.06, -1) > 3, "Outer straight has sand runoff")
	suite.check(track.barrier_clearance(length * 0.015, 1) > 10, "Inner opening provides grass runoff")
	suite.check(track.barrier_clearance(length * 0.17, 1) > 1, "Hairpin corridor uses the reference infield fence")
	suite.check(track.barrier_clearance(length * 0.06, 1) != track.barrier_clearance(length * 0.06, -1), "Sides independently configurable")
	var clear_of_road := true
	var finite := true
	for path in track.barrier_paths:
		suite.check(path.get_point_position(0).is_equal_approx(path.get_point_position(path.point_count - 1)), "Outer barrier loop closes")
		for i in path.point_count:
			var point := path.get_point_position(i)
			finite = finite and point.is_finite()
			clear_of_road = clear_of_road and point.distance_to(track.curve.get_closest_point(point)) > track.road_width * 0.5 + 0.45
	suite.check(finite, "Outer paths contain finite geometry")
	suite.check(clear_of_road, "Configured outer barriers do not cross the asphalt")
	var visuals: Array[Vector3] = []
	var consistent_blocks := true
	# The headless dummy renderer does not retain MultiMesh GPU transforms.
	# Check the actual CPU transforms supplied to the renderer instead.
	for transform in track.barrier_block_transforms:
		visuals.append(transform.origin)
		consistent_blocks = consistent_blocks and transform.basis.z.length() <= 1.22
	suite.check(consistent_blocks, "Runoff transitions retain consistent block lengths")
	var matching_colliders := true
	for shape: CollisionShape3D in track.get_node("Generated/BarrierCollision").get_children():
		var found := false
		for point in visuals:
			if point.distance_squared_to(shape.position) < 0.000001:
				found = true
				break
		matching_colliders = matching_colliders and found
	suite.check(matching_colliders, "All boundary colliders match actual visible blocks")
	# Profile edits trigger an editor-style rebuild; restore the shared resource.
	var profile := track.barrier_runs[0]
	var old_points := profile.points.duplicate()
	var changed := old_points.duplicate()
	changed[0].x -= 0.1
	profile.points = changed
	await suite.process_frame
	suite.check(track.barrier_paths[0].get_point_position(0).is_equal_approx(changed[0]), "Authored run edits rebuild outer boundaries")
	profile.points = old_points
	await suite.process_frame
	suite.check(track.get_child_count() == 1, "Profile edits do not duplicate generated nodes")
	var environment := main.get_node("Environment")
	await suite.process_frame
	var trees_clear := true
	for node in environment.get_node("Generated").get_children():
		if str(node.name).begins_with("Trunk"):
			trees_clear = trees_clear and not environment._inside_driving_envelope(Vector3(node.position.x, -0.06, node.position.z))
	suite.check(trees_clear, "Scenery stays outside the accessible runoff envelope")
	var race := main.get_node("RaceManager") as RaceManager
	race.set_physics_process(false)
	race.start_race()
	race.session.advance(3)
	var gate := race.gates[1]
	suite.check(gate.crossing_fraction(gate.to_global(Vector3(track.road_width * 0.5 + 2, 0.6, 2)),
		gate.to_global(Vector3(track.road_width * 0.5 + 2, 0.6, -2))) >= 0, "Legal sand line is covered by checkpoint")
	var kart := main.get_node("Kart") as KartController
	kart.get_node("Recovery").stuck_seconds = 0
	for side in [-1.0, 1.0]:
		var offset := length * 0.015 # Right-stem grass opening, 530–650 reference pixels.
		var center := track.sample_center(offset)
		var outwards: Vector3 = track.sample_forward(offset).cross(Vector3.UP) * side
		kart.global_transform = Transform3D(Basis.looking_at(outwards), center + Vector3.UP * 0.65)
		kart.velocity = Vector3.ZERO
		kart.reset_performed.emit()
		for i in 20:
			await suite.physics_frame
		Input.action_press("accelerate")
		for i in 210: # Surface penalties now require longer to reach the same wall.
			await suite.physics_frame
		Input.action_release("accelerate")
		var displacement := (kart.position - center).dot(outwards)
		suite.check(displacement > 9, "Kart crosses kerb into accessible runoff, side %s" % side)
		suite.check(displacement < track.road_width * 0.5 + track.barrier_clearance(offset, side), "Outer barrier contains kart, side %s" % side)
		suite.check(absf(kart.signed_speed) < 3, "Outer wall collision reduces speed, side %s" % side)
		if side > 0:
			var outline: PackedVector2Array = main.get_node("Environment").infield_outline
			suite.check(Geometry2D.is_point_in_polygon(Vector2(kart.position.x, kart.position.z), outline), "Grass infield is physically accessible")
		kart.basis = Basis.looking_at(-outwards)
		kart.velocity = Vector3.ZERO
		var returned_to_road := false
		Input.action_press("accelerate")
		for i in 210:
			await suite.physics_frame
			if absf((kart.position - center).dot(outwards)) < 1 and kart.is_on_floor():
				returned_to_road = true
		Input.action_release("accelerate")
		suite.check(returned_to_road, "Kart can rejoin asphalt without recovery, side %s" % side)
	main.queue_free()
	await suite.process_frame
