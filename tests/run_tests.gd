extends SceneTree
## Run after editor import: godot --headless --path . --script tests/run_tests.gd

var failures: int = 0
var checks: int = 0

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + message)

func near(actual: float, expected: float, message: String, tolerance: float = 0.0001) -> void:
	check(absf(actual - expected) < tolerance, "%s: got %f expected %f" % [message, actual, expected])

func _run() -> void:
	_test_commands()
	_test_dynamics()
	await _test_track()
	await _test_main()
	await preload("res://tests/race_tests.gd").new().run(self)
	await preload("res://tests/runoff_tests.gd").new().run(self)
	await preload("res://tests/handling_tests.gd").new().run(self)
	await preload("res://tests/corrective_tests.gd").new().run(self)
	await preload("res://tests/vertical_stability_tests.gd").new().run(self)
	await preload("res://tests/presentation_tests.gd").new().run(self)
	await preload("res://tests/competitor_tests.gd").new().run(self)
	await preload("res://tests/item_tests.gd").new().run(self)
	await preload("res://tests/powerup_balance_tests.gd").new().run(self)
	await preload("res://tests/alpha_tests.gd").new().run(self)
	await preload("res://tests/circuit_tests.gd").new().run(self)
	await preload("res://tests/crossing_collision_tests.gd").new().run(self)
	await preload("res://tests/circuit_performance_tests.gd").new().run(self)
	print("Turbo Riot: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func _test_commands() -> void:
	var command := DrivingCommand.new(2, -3, -4)
	near(command.throttle, 1, "Throttle clamps")
	near(command.brake, 0, "Brake clamps")
	near(command.steering, -1, "Steering clamps")
	command = DrivingCommand.new(0.4, 0.6, 0.25)
	near(command.throttle, 0.4, "Analogue throttle preserved")
	near(command.brake, 0.6, "Analogue brake preserved")
	near(command.steering, 0.25, "Analogue steering preserved")
	command = DrivingCommand.new(NAN, INF, -INF)
	near(command.throttle + command.brake + command.steering, 0, "Nonfinite commands sanitized")

func _test_dynamics() -> void:
	var config := KartConfig.new()
	near(KartDynamics.longitudinal_speed(0, DrivingCommand.new(1), config, 0.5), 8, "Acceleration")
	near(KartDynamics.longitudinal_speed(20, DrivingCommand.new(0, 1), config, 0.5), 6, "Braking")
	near(KartDynamics.longitudinal_speed(10, DrivingCommand.new(), config, 0.5), 7, "Coasting")
	near(KartDynamics.longitudinal_speed(1, DrivingCommand.new(0, 1), config, 1), 0, "Brake stops before reverse")
	near(KartDynamics.longitudinal_speed(-1, DrivingCommand.new(1), config, 1), 0, "Throttle stops reverse first")
	near(KartDynamics.longitudinal_speed(0, DrivingCommand.new(1, 1), config, 0.1), -1.6, "Brake priority")
	for rate in [30, 60, 144]:
		var speed := 0.0
		for i in rate * 10:
			speed = KartDynamics.longitudinal_speed(speed, DrivingCommand.new(1), config, 1.0 / rate)
		near(speed, 22, "Forward cap at %d Hz" % rate)
		speed = 0.0
		for i in rate * 10:
			speed = KartDynamics.longitudinal_speed(speed, DrivingCommand.new(0, 1), config, 1.0 / rate)
		near(speed, -7, "Reverse cap at %d Hz" % rate)
		var lateral := 10.0
		for i in rate:
			lateral = KartDynamics.damp_lateral(lateral, config.lateral_grip, 1.0 / rate)
		near(lateral, 10 * exp(-9.0), "Exponential grip at %d Hz" % rate)
	near(KartDynamics.steering_radians(0, DrivingCommand.new(0, 0, 1), config, 1), 0, "No stationary turn")
	check(KartDynamics.steering_radians(10, DrivingCommand.new(0, 0, 1), config, 1) < 0, "Right turn sign")
	check(KartDynamics.steering_radians(-5, DrivingCommand.new(0, 0, 1), config, 1) > 0, "Reverse turn sign")

func _test_track() -> void:
	var packed := load("res://scenes/track.tscn") as PackedScene
	check(packed != null, "Track scene loads")
	if not packed:
		return
	var track := packed.instantiate() as TrackBuilder
	root.add_child(track)
	check(track.is_curve_closed(), "Curve closes")
	check(track.curve.get_baked_length() > 300, "Useful circuit length")
	var vertices := track.road_vertices
	var indices := track.road_indices
	check(vertices.size() > 100, "Road generated")
	check(indices.size() % 3 == 0, "Triangles complete")
	check(vertices[0].is_equal_approx(vertices[vertices.size() - 2]), "Left seam closes")
	check(vertices[1].is_equal_approx(vertices[vertices.size() - 1]), "Right seam closes")
	var valid := true
	var flat := true
	var width_ok := true
	var nondegenerate := true
	var upward_faces := true
	for i in vertices.size():
		valid = valid and vertices[i].is_finite()
		flat = flat and absf(vertices[i].y - 0.04) < 0.0001
		if i % 2 == 0:
			width_ok = width_ok and absf(vertices[i].distance_to(vertices[i + 1]) - track.road_width) < 0.001
	for i in range(0, indices.size(), 3):
		var a := indices[i]
		var b := indices[i + 1]
		var c := indices[i + 2]
		valid = valid and mini(a, mini(b, c)) >= 0 and maxi(a, maxi(b, c)) < vertices.size()
		nondegenerate = nondegenerate and (vertices[b] - vertices[a]).cross(vertices[c] - vertices[a]).length() > 0.001
		upward_faces = upward_faces and (vertices[b] - vertices[a]).cross(vertices[c] - vertices[a]).y < 0.0
	check(valid, "Finite vertices and valid indices")
	check(flat, "Consistent elevation")
	check(width_ok, "Consistent road width")
	check(nondegenerate, "Nonzero triangle areas")
	check(upward_faces, "Clockwise road faces collide from above")
	check(track.get_node("Generated/Asphalt").get_child_count() > 0, "Road has collision")
	var batch := track.get_node("Generated/BarrierVisuals0") as MultiMeshInstance3D
	var shared_mesh := true
	for i in 4:
		shared_mesh = shared_mesh and track.get_node("Generated/BarrierVisuals%d" % i).multimesh.mesh == batch.multimesh.mesh
	check(shared_mesh, "All barrier colour batches share one mesh")
	check(batch.multimesh.instance_count > 50, "Barrier blocks are instanced in colour batches")
	var simple_collision := true
	for shape: CollisionShape3D in track.get_node("Generated/BarrierCollision").get_children():
		simple_collision = simple_collision and shape.shape is BoxShape3D
	check(simple_collision, "Barrier collision uses boxes rather than faceted triangles")
	var count := track.get_node("Generated").get_child_count()
	track.build()
	track.build()
	check(track.get_child_count() == 1, "Rebuild replaces subtree")
	check(track.get_node("Generated").get_child_count() == count, "Deterministic generation")
	track.queue_free()
	await process_frame

func _test_main() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	check(packed != null, "Main scene loads")
	if not packed:
		return
	var main := packed.instantiate()
	main.get_node("RaceManager").opponent_count = 0 # Isolated legacy mechanics/presentation fixture.
	root.add_child(main)
	var kart := main.get_node("Kart") as KartController
	# Existing physics checks run during RACING; READY now correctly locks driving.
	var race := main.get_node("RaceManager") as RaceManager
	race.start_race()
	race.session.advance(3.0)
	for i in 60:
		await physics_frame
	check(kart.is_on_floor(), "Kart grounded after spawn")
	check(kart.position.y > 0.40, "Kart rests on asphalt, above sand")
	near(kart.signed_speed, 0, "No idle motion", 0.01)
	check(kart.global_position.distance_to(kart.safe_spawn.origin) < 1, "Safe spawn stays in place")
	check(main.get_node("ChaseCamera").target == kart, "Camera linked")
	check(InputMap.has_action("accelerate"), "Player actions registered")
	# Exercise real CharacterBody motion with the actual input provider.
	Input.action_press("accelerate")
	for i in 60:
		await physics_frame
	Input.action_release("accelerate")
	check(kart.signed_speed > 10, "Integrated acceleration moves kart")
	check(kart.position.distance_to(kart.safe_spawn.origin) > 5.0, "Acceleration produces world displacement")
	check(kart.signed_speed <= kart.config.max_forward_speed + 0.01, "Integrated forward cap")
	kart.reset_to_spawn()
	near(kart.velocity.length(), 0, "Reset clears velocity")
	check(kart.global_transform.is_equal_approx(kart.safe_spawn), "Reset restores transform")
	check(main.get_node("ChaseCamera").global_position.distance_to(kart.global_position) < 10, "Camera snaps on reset")
	Input.action_press("brake")
	for i in 60:
		await physics_frame
	Input.action_release("brake")
	check(kart.signed_speed < -5.0, "Integrated reverse")
	check(kart.signed_speed >= -kart.config.max_reverse_speed - 0.01, "Integrated reverse cap")
	Input.action_press("accelerate")
	for i in 12:
		await physics_frame
	Input.action_release("accelerate")
	check(kart.signed_speed > -3.0, "Throttle brakes reverse motion")
	kart.reset_to_spawn()
	# Start near a real barrier and drive into it, checking static-body response.
	var track := main.get_node("Track") as TrackBuilder
	var offset := 8.0 # Preserve the narrow-wall regression in the start corridor.
	var right := track.sample_forward(offset).cross(Vector3.UP)
	var wall_distance := track.corridor_limits(offset).y
	kart.position = track.sample_center(offset) + right * (wall_distance - 2.0) + Vector3.UP * 0.65
	kart.basis = Basis.looking_at(right)
	Input.action_press("accelerate")
	for i in 90:
		await physics_frame
	Input.action_release("accelerate")
	var displacement := (kart.position - track.sample_center(offset)).dot(right)
	check(displacement < wall_distance + 0.1, "Visible barrier blocks kart")
	check(absf(kart.signed_speed) < 3.0, "Wall impact reduces speed")
	var recovery := kart.get_node("Recovery") as KartRecovery
	recovery.stuck_seconds = 0.15
	recovery.cooldown_remaining = 0
	var recoveries: Array[int] = [0]
	kart.reset_performed.connect(func() -> void: recoveries[0] += 1)
	Input.action_press("accelerate")
	for i in 45:
		await physics_frame
	Input.action_release("accelerate")
	check(recoveries[0] == 1, "Sustained grounded wall jam recovers once")
	check(recovery.cooldown_remaining > 0, "Stuck recovery starts cooldown")
	main.queue_free()
	await process_frame
