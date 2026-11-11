extends RefCounted
## Real physics: no transform correction, teleporting or constant-speed override
## during a measured traversal. --legacy-box restores the old collider only.
class TestInput extends DrivingInput:
	var command := DrivingCommand.new()
	func get_command() -> DrivingCommand: return command

func run(s: SceneTree) -> void:
	var world := TrackRegistry.get_definition(&"figure_8").instantiate_race()
	world.managed = true
	world.get_node("Items").enabled = false
	world.get_node("RaceManager").opponent_count = 0
	s.root.add_child(world)
	var race := world.get_node("RaceManager") as RaceManager
	race.set_physics_process(false)
	race.start_race()
	race.session.advance(3)
	var kart := race.kart
	if "--legacy-box" in OS.get_cmdline_user_args():
		var shape := BoxShape3D.new()
		shape.size = Vector3(1.25,0.75,2.1)
		kart.get_node("Collision").shape = shape
		kart.get_node("Collision").position = Vector3.ZERO
		kart.get_node("RoadContact").disabled = true
		kart.get_node("RearRoadContact").disabled = true
	var collider_bounds := AABB()
	for child in kart.get_children():
		if child is CollisionShape3D and not child.disabled:
			collider_bounds = collider_bounds.merge(child.transform * child.shape.get_debug_mesh().get_aabb())
	var extents := collider_bounds.size
	s.check(extents.is_equal_approx(Vector3(1.25,0.75,2.1)), "Crossing correction preserves the kart collider's original outer dimensions")
	kart.get_node("Recovery").set_physics_process(false)
	var input := TestInput.new()
	kart.add_child(input)
	kart.input_provider = input
	var track := race.track
	var first := track.curve.get_closest_offset(track.curve.get_point_position(14))
	var last := track.curve.get_closest_offset(track.curve.get_point_position(20))
	var direction := track.sample_forward(first)
	direction.y = 0
	direction = direction.normalized()
	var modes := ["upper"] if "--upper-only" in OS.get_cmdline_user_args() else ["upper", "mushroom", "upper_reverse", "lower"]
	for mode in modes:
		for lane in [0.0, -4.5, 4.5]:
			var start := first
			var finish := last
			var forward := direction
			if mode == "upper_reverse":
				start = last
				finish = first
				forward = -direction
			elif mode == "lower":
				start = 5
				finish = 90
				forward = track.sample_forward(start)
			await _drive(s, kart, input, track, start, finish, forward, lane, mode)
	input.command = DrivingCommand.new()
	await _surface_heights(s, track)
	# Ignore physical fences for this stationary surface-query fixture only;
	# every measured drive above used the real track and barriers.
	track.get_node("Generated/BarrierCollision").collision_layer = 0
	await s.physics_frame
	var crest := track.curve.get_closest_offset(track.curve.get_point_position(17))
	for extra in [0.0, 0.15]:
		var lateral: float = 0.0 if extra == 0 else track.road_width * 0.5 + extra
		kart.global_position = track.sample_center(crest) + track.road_right(crest) * lateral + Vector3.UP * 0.6
		kart.set_physics_process(false)
		var detector := SurfaceDetector.new()
		for i in 20: detector.update(kart, kart.config, 1.0 / 60)
		s.check(detector.current.identifier == (&"asphalt" if extra == 0 else &"sand"), "Crossing correction preserves asphalt/sand surface detection")
	world.queue_free()
	await s.process_frame

func _drive(s: SceneTree, kart: KartController, input: TestInput, track: TrackBuilder,
	start: float, finish: float, forward: Vector3, lane: float, mode: String) -> void:
	input.command = DrivingCommand.new()
	kart.safe_spawn = Transform3D(Basis.looking_at(forward), track.sample_center(start) + forward.cross(Vector3.UP) * lane + Vector3.UP * 0.8)
	kart.reset_to_spawn()
	for i in 30: await s.physics_frame
	var speed := 22.0
	if mode == "mushroom":
		kart.activate_item_boost(&"mushroom", 1.4, 15)
		speed = 30.8
	kart.velocity = forward * speed
	input.command = DrivingCommand.new(1)
	var origin := kart.global_position
	var distance := (track.sample_center(finish) - track.sample_center(start)).dot(forward)
	var minimum_speed := INF
	var minimum_motion := INF
	var airborne := 0
	var false_walls := 0
	var completed := false
	for tick in 700:
		await s.physics_frame
		minimum_speed = minf(minimum_speed, Vector2(kart.velocity.x, kart.velocity.z).length())
		minimum_motion = minf(minimum_motion, Vector2(kart.get_real_velocity().x, kart.get_real_velocity().z).length())
		if not kart.is_on_floor(): airborne += 1
		var progress := (kart.global_position - origin).dot(forward)
		if progress > 5 and progress < distance - 5:
			for i in kart.get_slide_collision_count():
				var collision := kart.get_slide_collision(i)
				for j in collision.get_collision_count():
					if collision.get_normal(j).y < cos(kart.floor_max_angle + 0.01):
						false_walls += 1
						if false_walls < 4: print("CROSSING BAD ",mode," lane=",lane," progress=",progress," collider=",collision.get_collider(j).get_path()," normal=",collision.get_normal(j)," position=",collision.get_position(j))
		if progress >= distance - 0.3:
			completed = true
			break
	print("CROSSING %s lane=%.1f min_velocity=%.3f min_motion=%.3f air=%d false_walls=%d complete=%s" % [mode,lane,minimum_speed,minimum_motion,airborne,false_walls,completed])
	s.check(completed, "Crossing route can be traversed: %s lane %.1f" % [mode,lane])
	s.check(minimum_speed > speed * 0.85 and minimum_motion > speed * 0.8, "No phantom stop or hidden displacement stall: %s lane %.1f" % [mode,lane])
	s.check(airborne == 0, "Crossing traversal retains real floor support: %s lane %.1f" % [mode,lane])
	s.check(false_walls == 0, "No false wall normals inside the crossing: %s lane %.1f" % [mode,lane])

func _surface_heights(s: SceneTree, track: TrackBuilder) -> void:
	var first := track.curve.get_closest_offset(track.curve.get_point_position(14))
	var last := track.curve.get_closest_offset(track.curve.get_point_position(20))
	var maximum_error := 0.0
	var supported := true
	for i in 30:
		var offset := lerpf(first,last,float(i)/29)
		for lane in [-5.0,0.0,5.0]:
			var point: Vector3 = track.sample_center(offset) + track.road_right(offset) * lane
			var query := PhysicsRayQueryParameters3D.create(point + Vector3.UP, point - Vector3.UP, 1)
			var hit := track.get_world_3d().direct_space_state.intersect_ray(query)
			if hit.is_empty(): supported = false
			else: maximum_error = maxf(maximum_error, absf(hit.position.y - point.y))
	print("CROSSING surface_support=%s maximum_visual_height_error=%.5fm" % [supported,maximum_error])
	s.check(supported and maximum_error < 0.005, "Unmodified bridge road collision matches its visible surface within 5 mm across driving lanes")
