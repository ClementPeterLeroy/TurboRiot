extends RefCounted
## Quantitative contact regressions, using real CharacterBody and trimesh floors.
class TestInput extends DrivingInput:
	var command := DrivingCommand.new()
	func get_command() -> DrivingCommand:
		return command

func run(s: SceneTree) -> void:
	var main := load("res://scenes/main.tscn").instantiate() as Node3D
	s.root.add_child(main)
	var race := main.get_node("RaceManager") as RaceManager
	race.set_physics_process(false)
	race.start_race()
	race.session.advance(3)
	var kart := main.get_node("Kart") as KartController
	kart.get_node("Recovery").set_physics_process(false)
	var provider := TestInput.new()
	kart.add_child(provider)
	kart.input_provider = provider
	var camera := main.get_node("ChaseCamera") as Camera3D
	camera.set_process(false)
	var visual := kart.get_node("Visual") as Node3D
	visual.set_process(false)
	# Remote, flat triangulated asphalt isolates contact from route departures,
	# barriers and scenery; the actual source-road/shoulder is also tested below.
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(180, 240)
	plane.subdivide_width = 119
	plane.subdivide_depth = 159
	floor_mesh.mesh = plane
	floor_mesh.position = Vector3(500, 0.04, 500)
	main.add_child(floor_mesh)
	floor_mesh.create_trimesh_collision()
	SurfaceDetector.tag_collision(floor_mesh, preload("res://resources/surfaces/asphalt.tres"))
	await s.physics_frame
	for mode in ["idle", "accelerate_brake", "steering", "drift"]:
		provider.command = DrivingCommand.new()
		_place(kart, Vector3(500, 0.6, 550), Basis.IDENTITY)
		for i in 60:
			await s.physics_frame
			camera._process(1.0 / 60)
		if mode == "drift":
			kart.velocity = -kart.basis.z * 16
		var ys: Array[float] = []
		var camera_ys: Array[float] = []
		var airborne := 0
		var maximum_vy := 0.0
		var cosmetic_offset := 0.0
		var drift_seen := false
		for i in 240:
			var steering := (0.5 if (i / 30) % 2 == 0 else -0.5) if mode in ["steering", "drift"] else 0.0
			provider.command = DrivingCommand.new(0 if mode == "idle" or (mode == "accelerate_brake" and i >= 150) else 1,
				1 if mode == "accelerate_brake" and i >= 150 else 0, steering, mode == "drift")
			await s.physics_frame
			var body_transform := kart.global_transform
			visual._process(1.0 / 60)
			cosmetic_offset = maxf(cosmetic_offset, visual.position.length())
			if kart.global_transform != body_transform:
				cosmetic_offset = INF
			camera._process(1.0 / 60)
			ys.append(kart.global_position.y)
			camera_ys.append(camera.global_position.y)
			maximum_vy = maxf(maximum_vy, absf(kart.velocity.y))
			if not kart.is_on_floor(): airborne += 1
			drift_seen = drift_seen or kart.drift.active
		var spread: float = ys.max() - ys.min()
		var variance := _variance(ys)
		print("Vertical ", mode, ": range=", spread, " variance=", variance, " airborne=", airborne,
			" camera_range=", camera_ys.max() - camera_ys.min())
		s.check(spread < 0.002 and variance < 0.000001, "Flat asphalt body Y variance stays below tolerance: " + mode)
		s.check(airborne == 0 and maximum_vy < 0.01, "No flat-floor contact flicker or upward impulses: " + mode)
		s.check(camera_ys.max() - camera_ys.min() < 0.002, "Camera has no artificial vertical bob: " + mode)
		s.check(cosmetic_offset == 0, "Cosmetics keep a separate child transform without height animation: " + mode)
		if mode == "drift": s.check(drift_seen, "Vertical stability was measured during actual drifting")
	provider.command = DrivingCommand.new()
	await _shoulders(s, main, provider)
	# Exercise actual reset APIs following the contact measurements.
	var recovery := kart.get_node("Recovery") as KartRecovery
	recovery.cooldown_remaining = 0
	s.check(recovery.recover() and kart.velocity == Vector3.ZERO, "Recovery resets stable contact motion")
	race.restart_race()
	s.check(race.session.state == RaceSession.State.COUNTDOWN and kart.velocity == Vector3.ZERO,
		"Restart clears motion and begins one fresh countdown")
	main.queue_free()
	await s.process_frame

func _place(kart: KartController, position: Vector3, basis: Basis) -> void:
	kart.safe_spawn = Transform3D(basis, position)
	kart.reset_to_spawn()

func _variance(values: Array[float]) -> float:
	var mean := 0.0
	for value in values: mean += value / values.size()
	var result := 0.0
	for value in values: result += (value - mean) ** 2 / values.size()
	return result

func _shoulders(s: SceneTree, main: Node3D, provider: TestInput) -> void:
	var kart := main.get_node("Kart") as KartController
	var track := main.get_node("Track") as TrackBuilder
	var center := track.sample_center(track.curve.get_baked_length() * 0.015)
	for side in [-1.0, 1.0]:
		var outward: Vector3 = track.sample_forward(track.curve.get_baked_length() * 0.015).cross(Vector3.UP) * side
		for rejoin in [false, true]:
			var direction: Vector3 = -outward if rejoin else outward
			var start: Vector3 = center + outward * (10.0 if rejoin else 5.0) + Vector3.UP * 0.6
			_place(kart, start, Basis.looking_at(direction))
			for i in 45: await s.physics_frame
			kart.velocity = direction * 12
			provider.command = DrivingCommand.new(1)
			var airborne := 0
			var maximum_y := -INF
			for i in (75 if rejoin else 32):
				await s.physics_frame
				if not kart.is_on_floor(): airborne += 1
				maximum_y = maxf(maximum_y, kart.position.y)
			provider.command = DrivingCommand.new()
			print("Shoulder side=", side, " rejoin=", rejoin, " air=", airborne, " max_y=", maximum_y)
			# Up to 2 cm of solver clearance at a box/shoulder crest is allowed;
			# continuous contact is required on every transition frame.
			s.check(airborne == 0 and maximum_y < center.y + 0.375 + 0.02,
				"Continuous asphalt/sand shoulder has no false takeoff: side %s rejoin %s" % [side, rejoin])
			var lateral := (kart.position - center).dot(outward)
			s.check(lateral < 6 if rejoin else lateral > 8.4,
				"Stability scenario actually crosses asphalt/sand boundary")
