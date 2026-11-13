extends RefCounted

class IdleInput extends DrivingInput:
	func get_command() -> DrivingCommand: return DrivingCommand.new()

func run(s: SceneTree) -> void:
	await _run_scene(s, "res://scenes/tracks/Bikini_bottom_test.tscn", ^"bikini_bottom_track_blockout/TR_BikiniBottom_Road_Test")
	await _run_scene(s, "res://scenes/tracks/Bikini_bottom_test_v2.tscn", ^"bikini_bottom_test_track/BikiniBottom_test_v1")

func _run_scene(s: SceneTree, scene_path: String, road_path: NodePath) -> void:
	print("BIKINI RECOVERY SCENE ", scene_path)
	var world := load(scene_path).instantiate() as Node3D
	s.root.add_child(world)
	var kart := world.get_node("Kart") as KartController
	var recovery := kart.get_node("Recovery") as KartRecovery
	var road := world.get_node(road_path) as MeshInstance3D
	var collider := road.get_node("StaticBody3D/CollisionShape3D") as CollisionShape3D
	var faces := (collider.shape as ConcavePolygonShape3D).get_faces()
	var road_bounds: AABB = road.global_transform * road.get_aabb()
	var envelope := recovery.recovery_half_extents
	var fall := recovery.fall_height
	var original_spawn := kart.safe_spawn
	var resets := [0]
	kart.reset_performed.connect(func() -> void: resets[0] += 1)
	kart.set_physics_process(false)
	recovery.set_physics_process(false)
	var input := IdleInput.new()
	kart.add_child(input)
	kart.input_provider = input
	await s.physics_frame
	s.check(fall < road_bounds.position.y - 5.0, "Bikini fall threshold clears the lowest authored road")
	var enclosed := true
	var low := Vector3.ZERO
	var outer := Vector3.ZERO
	var min_y := INF
	var max_x := 0.0
	for index in range(0, faces.size(), 3):
		var point: Vector3 = collider.global_transform * ((faces[index]+faces[index+1]+faces[index+2])/3.0)
		enclosed = enclosed and absf(point.x)<envelope.x and absf(point.z)<envelope.y and point.y>fall
		if point.y < min_y:
			min_y = point.y
			low = point
		if absf(point.x)>max_x:
			max_x = absf(point.x)
			outer = point
	s.check(enclosed, "Every Bikini collision triangle lies within its recovery envelope")
	s.check(low.y < -8.0 and absf(outer.x)>178.0, "Bikini fixture exercises both legacy recovery limits")
	# Reproduce each old reset through the real recovery branch, then exercise
	# the same locations with the scene's configured envelope.
	for point in [low, outer]:
		_place(kart, recovery, point + Vector3.UP * 0.65, original_spawn.basis)
		recovery.recovery_half_extents = Vector2(178,158)
		recovery.fall_height = -8
		var before: int = resets[0]
		recovery._physics_process(1.0/60)
		s.check(resets[0]==before+1, "Original defaults reproduce a reset on valid Bikini road")
		recovery.recovery_half_extents = envelope
		recovery.fall_height = fall
		_place(kart, recovery, point + Vector3.UP * 0.65, original_spawn.basis)
		before = resets[0]
		kart.set_physics_process(true)
		recovery.set_physics_process(true)
		for tick in 120: await s.physics_frame
		s.check(resets[0]==before and kart.is_on_floor(), "Real kart stays supported without false recovery on Bikini low/outer road")
		kart.set_physics_process(false)
		recovery.set_physics_process(false)
	for point in [Vector3(envelope.x+1,0,0), Vector3(0,0,envelope.y+1), Vector3(0,fall-1,0)]:
		_place(kart, recovery, point, original_spawn.basis)
		var before: int = resets[0]
		recovery._physics_process(1.0/60)
		s.check(resets[0]==before+1 and kart.global_transform.is_equal_approx(original_spawn), "Leaving Bikini safety envelope still recovers to the authored spawn")
	_place(kart, recovery, original_spawn.origin, original_spawn.basis)
	s.check(recovery.recover() and kart.safe_spawn.is_equal_approx(original_spawn), "Manual recovery preserves the authored Bikini safe position")
	s.check(not recovery.recover(), "Bikini recovery retains cooldown protection")
	var ray := PhysicsRayQueryParameters3D.create(original_spawn.origin,original_spawn.origin-Vector3.UP*3,1,[kart.get_rid()])
	var hit := kart.get_world_3d().direct_space_state.intersect_ray(ray)
	s.check(not hit.is_empty() and hit.collider==collider.get_parent(), "Authored Bikini recovery spawn is supported by the road collider")
	var default_recovery := KartRecovery.new()
	s.check(default_recovery.fall_height==-8 and default_recovery.recovery_half_extents==Vector2(178,158), "Other circuits retain shared recovery defaults")
	default_recovery.free()
	print("BIKINI RECOVERY extents=%s fall=%.3f low=%.3f outer_x=%.3f" % [envelope,fall,low.y,outer.x])
	world.queue_free()
	await s.process_frame

func _place(kart: KartController, recovery: KartRecovery, point: Vector3, heading: Basis) -> void:
	kart.reset_to_spawn()
	kart.global_transform = Transform3D(heading,point)
	kart.reset_physics_interpolation()
	recovery.cooldown_remaining = 0
