extends RefCounted

func run(s: SceneTree) -> void:
	var main := load("res://scenes/main.tscn").instantiate() as Node3D
	main.get_node("Items").enabled = false # Isolate pre-item regression fixture.
	main.get_node("RaceManager").opponent_count = 0 # Isolated legacy mechanics/presentation fixture.
	s.root.add_child(main)
	var track := main.get_node("Track") as TrackBuilder
	var race := main.get_node("RaceManager") as RaceManager
	var kart := main.get_node("Kart") as KartController
	race.set_physics_process(false)
	kart.set_physics_process(false)
	await s.physics_frame
	await s.physics_frame
	_geometry(s, track)
	await s.process_frame
	await s.process_frame # Settle editor-style queued rebuilds before starting races.
	_gates(s, race)
	await _pads(s, main)
	await _trees(s, main)
	main.queue_free()
	await s.process_frame

func _geometry(s: SceneTree, track: TrackBuilder) -> void:
	s.near(track.road_width, 14.4, "Reference road width corresponds to 80 pixels at 0.18 m/pixel")
	s.check(track.barrier_runs.size() == 2, "Reference has independent frame and infield fence resources")
	var outside := track.barrier_runs[0].points
	s.check(outside.has(Vector3(40.5, -0.08, -61.56)) and outside.has(Vector3(-5.4, -0.08, 64.8)), "Stepped reference perimeter corners retained")
	s.check(track.barrier_runs[1].points.size() == 16, "Reference stepped infield and lower-left stub traced")
	s.check(track.barrier_color_group_size == 5, "Default barrier colour group is five")
	for run in track.barrier_run_ranges:
		var sequence_ok := true
		for i in run.y:
			sequence_ok = sequence_ok and track.barrier_block_colors[run.x + i] == floori(float(i) / 5) % 4
		s.check(sequence_ok and run.y % 5 == 0, "Every connected fence repeats complete R5 B5 Y5 G5 groups across corners")
	var first := track.barrier_block_transforms.duplicate()
	track.build()
	s.check(track.barrier_block_transforms == first and track.get_child_count() == 1, "Reference fence regeneration is deterministic and duplicate-free")
	track.barrier_color_group_size = 3
	track.build()
	var configurable := true
	for run in track.barrier_run_ranges:
		for i in run.y:
			configurable = configurable and track.barrier_block_colors[run.x + i] == floori(float(i) / 3) % 4
	s.check(configurable, "Changing colour group size preserves phase around polygon corners")
	track.barrier_color_group_size = 5
	track.build()

func _gates(s: SceneTree, race: RaceManager) -> void:
	var helper := preload("res://tests/race_tests.gd").new()
	for gate in race.gates:
		for x in [-gate.left_extent * 0.85, -gate.gate_width * 0.5 - 1, 0.0, gate.gate_width * 0.5 + 1, gate.right_extent * 0.85]:
			var a := gate.to_global(Vector3(x, 0.6, 2))
			var b := gate.to_global(Vector3(x, 0.6, -2))
			s.check(gate.crossing_fraction(a, b) >= 0, "Gate %d covers connected road/runoff line %.1f" % [gate.gate_index, x])
			s.check(gate.crossing_fraction(b, a) < 0, "Off-road gate direction remains enforced")
		var outside := gate.to_global(Vector3(gate.right_extent + 3, 0.6, 2))
		s.check(gate.crossing_fraction(outside, outside - gate.global_basis.z * 4) < 0, "Gate remains finite at legal corridor edge")
	race.start_race()
	race.session.advance(3)
	# Four-metre crossings at distant gates alone cannot constitute a full lap.
	for index in range(1, race.gates.size()):
		var gate := race.gates[index]
		race.process_movement(gate.to_global(Vector3(0, 0.6, 2)), gate.to_global(Vector3(0, 0.6, -2)))
	s.check(race.session.next_checkpoint == 1 and race.session.lap_times.is_empty(), "Skipping large route portions cannot manufacture checkpoint progress")
	race.restart_race()
	race.session.advance(3)
	for lap in 3:
		for index in range(1, race.gates.size()):
			race.session.advance(0.5)
			var side := -1.0 if index % 2 == 0 else 1.0
			helper._cross(race, index, false, side * (race.track.road_width * 0.5 + 1))
			s.check(race.session.next_checkpoint == index + 1, "Continuous sand racing line validates gate %d" % index)
		race.session.advance(0.5)
		# The final line can legally pass through the accessible right-stem grass.
		helper._cross(race, 0, false, 28.0 if lap == 2 else 0.0)
		s.check(race.session.lap_times.size() == lap + 1, "Off-road route completes exactly one valid lap")
	s.check(race.session.state == RaceSession.State.FINISHED, "Three runoff-inclusive laps finish normally")

func _place(kart: KartController, transform: Transform3D) -> void:
	kart.safe_spawn = transform
	kart.reset_to_spawn()

func _pads(s: SceneTree, main: Node3D) -> void:
	var kart := main.get_node("Kart") as KartController
	var race := main.get_node("RaceManager") as RaceManager
	race.restart_race()
	race.session.advance(3)
	kart.set_physics_process(true)
	kart.get_node("Recovery").stuck_seconds = 0
	await s.process_frame # Deferred feature rebuild from geometry checks.
	var pad := main.get_node("TrackFeatures/Generated").get_child(0) as BoostPad
	var forward := -pad.global_basis.z
	for scenario in ["forward", "reverse", "wrong_heading"]:
		var basis := pad.global_basis if scenario != "wrong_heading" else Basis.looking_at(-forward)
		var entry_side := 1.0 if scenario == "reverse" else -1.0
		_place(kart, Transform3D(basis, pad.global_position + forward * entry_side * 4.5 + Vector3.UP * 0.42))
		for i in 75:
			await s.physics_frame
		kart.velocity = forward * (-6.0 if scenario == "reverse" else 6.0)
		Input.action_press("accelerate" if scenario == "forward" else "brake")
		var previous := kart.position
		var previous_yaw := kart.rotation.y
		var stable := true
		var saw_boost := false
		var entry_speed := 0.0
		for i in 65:
			await s.physics_frame
			stable = stable and kart.position.distance_to(previous) < 1.5
			stable = stable and absf(wrapf(kart.rotation.y - previous_yaw, -PI, PI)) < 0.005
			previous = kart.position
			previous_yaw = kart.rotation.y
			if not saw_boost and kart.boost.source == &"boost_pad": entry_speed = kart.velocity.dot(forward)
			saw_boost = saw_boost or kart.boost.source == &"boost_pad"
		Input.action_release("accelerate")
		Input.action_release("brake")
		s.check(saw_boost, "Pad activates for " + scenario)
		s.check(entry_speed > 5, "Pad initial impulse propels in track direction for " + scenario)
		s.check(stable, "Pad has no automatic yaw lock or teleport: " + scenario)
	kart.reset_to_spawn()
	s.check(kart.boost.direction_remaining == 0 and kart.boost.direction == Vector3.ZERO, "Recovery clears pad redirection")
	kart.activate_boost(&"mini_turbo", 1.3, 1)
	s.check(kart.boost.direction == Vector3.ZERO, "Drift mini-turbo remains nondirectional")
	kart.boost.clear()

func _trees(s: SceneTree, main: Node3D) -> void:
	var kart := main.get_node("Kart") as KartController
	var trees: Array[MeshInstance3D] = []
	for child in main.get_node("Environment/Generated").get_children():
		if str(child.name).begins_with("Trunk"):
			trees.append(child)
	s.check(trees.size() > 0, "Procedural trees exist")
	var shared := true
	var shape := trees[0].get_node("TrunkCollision").get_child(0).shape as CylinderShape3D
	for tree in trees:
		shared = shared and tree.get_node("TrunkCollision").get_child(0).shape == shape
	s.check(shared and shape.radius <= 0.1801 and is_equal_approx(shape.height, 1.4), "Trees reuse a cylinder contained within visible trunks")
	var target: MeshInstance3D
	for tree in trees:
		if tree.position.x < 95 or absf(tree.position.z) > 100:
			continue
		var isolated := true
		for other in trees:
			if other != tree and tree.position.distance_to(other.position) < 5:
				isolated = false
		if isolated:
			target = tree
			break
	s.check(target != null, "A clear procedural tree is available for collision regression")
	if not target:
		return
	var position := Vector3(target.position.x, 0.5, target.position.z)
	var space := kart.get_world_3d().direct_space_state
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(position - Vector3.RIGHT, position + Vector3.RIGHT, 1))
	s.check(not hit.is_empty() and hit.collider == target.get_node("TrunkCollision"), "Trunk collider is positioned on its visible mesh")
	var high := Vector3(position.x, 1.8, position.z)
	s.check(space.intersect_ray(PhysicsRayQueryParameters3D.create(high - Vector3.RIGHT * 2, high + Vector3.RIGHT * 2, 1)).is_empty(), "Foliage has no oversized solid collision")
	for beside in [false, true]:
		var spawn := Vector3(target.position.x - 3, 0.57, target.position.z + (0.95 if beside else 0.0))
		_place(kart, Transform3D(Basis.looking_at(Vector3.RIGHT), spawn))
		for i in 15:
			await s.physics_frame
		Input.action_press("accelerate")
		for i in 90:
			await s.physics_frame
		Input.action_release("accelerate")
		if beside:
			s.check(kart.position.x > target.position.x + 2, "Kart passes beside trunk beneath foliage")
		else:
			s.check(kart.position.x < target.position.x - 0.8 and absf(kart.signed_speed) < 2, "Kart cannot drive through a procedural trunk")
