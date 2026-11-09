extends RefCounted

func run(suite: SceneTree) -> void:
	_models(suite)
	await _scene(suite)

func _models(s: SceneTree) -> void:
	var c := KartConfig.new()
	var sand := load("res://resources/surfaces/sand.tres") as SurfaceConfig
	var grass := load("res://resources/surfaces/grass.tres") as SurfaceConfig
	s.near(sand.acceleration_multiplier, 0.6, "Sand acceleration multiplier")
	s.near(grass.max_speed_multiplier, 0.75, "Grass speed multiplier")
	s.near(grass.lateral_grip_multiplier, 0.7, "Grass grip multiplier")
	var speed := KartDynamics.longitudinal_speed(22, DrivingCommand.new(1), c, 1.0 / 60, 0.6, 0.6, 1.7)
	s.check(speed < 22 and speed > 21, "Off-road transition does not instantaneously clamp speed")
	for i in 600:
		speed = KartDynamics.longitudinal_speed(speed, DrivingCommand.new(1), c, 1.0 / 60, 0.6, 0.6, 1.7)
	s.near(speed, 13.2, "Sand sustainable top speed")
	speed = KartDynamics.longitudinal_speed(0, DrivingCommand.new(1), c, 0.5, 0.75, 0.75)
	s.near(speed, 6, "Surface acceleration calculation")
	speed = KartDynamics.longitudinal_speed(30, DrivingCommand.new(1), c, 1.0 / 60)
	s.check(speed > 29 and speed < 30, "Boost expiration removes excess speed gradually")
	var detector := SurfaceDetector.new()
	detector.blend(grass, 0.02, 8, 0.06)
	s.check(detector.current.identifier == &"asphalt", "Surface debounce rejects one-frame boundary noise")
	detector.blend(grass, 0.04, 8, 0.06)
	s.check(detector.current == grass and detector.effective.x > 0.75 and detector.effective.x < 1, "Surface properties blend instead of snapping")
	for i in 120:
		detector.blend(grass, 1.0 / 60, 8, 0.06)
	s.near(detector.effective.x, 0.75, "Settled grass acceleration")
	for i in 120:
		detector.blend(SurfaceDetector.ASPHALT, 1.0 / 60, 8, 0.06)
	s.near(detector.effective.x, 1, "Returning to asphalt restores base handling")
	var drift := DriftController.new()
	var held := DrivingCommand.new(1, 0, 0.8, true)
	drift.update(held, 2, 2, true, false, c, 1)
	s.check(not drift.active, "Drift requires minimum speed")
	drift.update(held, 18, 2, false, false, c, 1)
	s.check(not drift.active, "Airborne drift activation rejected")
	drift.update(DrivingCommand.new(1, 0, 0, true), 18, 2, true, false, c, 1)
	s.check(not drift.active, "Drift activation requires steering")
	drift.update(held, 18, 0, true, false, c, 1)
	s.check(drift.active and drift.charge == 0, "Holding drift without lateral activity cannot charge")
	drift.update(held, 18, 2, true, false, c, 1)
	s.check(drift.level(c) == 1, "Mini-turbo level 1 threshold")
	drift.update(DrivingCommand.new(1, 0, -0.8, true), 18, -2, true, false, c, 1)
	s.check(drift.active and drift.level(c) == 2, "Countersteering preserves controllable drift and charges level 2")
	drift.update(held, 18, 2, true, false, c, 1.5)
	s.check(drift.level(c) == 3, "Mini-turbo level 3 threshold")
	var release := DrivingCommand.new(1, 0, 0.8, false)
	s.check(drift.update(release, 18, 2, true, false, c, 0.01) == 3, "Valid charged release awards turbo")
	s.check(not drift.active and drift.charge == 0, "Drift release clears charge")
	for interruption in ["air", "wall", "slow", "invalid_release"]:
		drift.update(held, 18, 2, true, false, c, 2)
		var award := drift.update(release, 2 if interruption == "slow" else 18,
			0 if interruption == "invalid_release" else 2, interruption != "air", interruption == "wall", c, 0.01)
		s.check(award == 0 and not drift.active and drift.charge == 0, "Interrupted/invalid drift grants no boost: " + interruption)
	var boost := BoostController.new()
	s.check(boost.activate(&"mini_turbo", 1.3, 0.8, c.boost_policy), "Boost activates")
	boost.advance(0.3)
	s.near(boost.remaining, 0.5, "Boost duration counts down")
	s.check(not boost.activate(&"weak", 1.2, 5, c.boost_policy), "Weaker overlapping boost ignored")
	s.near(boost.remaining, 0.5, "Weaker boost cannot extend stronger effect")
	s.check(boost.activate(&"boost_pad", 1.5, 0.2, c.boost_policy), "Stronger source replaces strength")
	s.near(boost.remaining, 0.5, "Stronger source retains longer remaining duration")
	boost.activate(&"boost_pad", 1.5, 0.9, c.boost_policy)
	s.near(boost.remaining, 0.9, "Equal-strength refresh uses longer duration")
	boost.activate(&"replacement", 1.1, 0.1, KartConfig.BoostPolicy.REPLACE)
	s.near(boost.strength, 1.1, "Configurable replacement policy")
	boost.advance(0.11)
	s.check(not boost.active() and boost.source == &"" and boost.strength == 1, "Boost expiration clears all temporary parameters")
	s.near(c.max_forward_speed, 22, "Boost never mutates base KartConfig")
	s.near(KartDynamics.air_yaw(18, held, c, 0.1), KartDynamics.steering_radians(18, held, c, 0.1) * c.air_steering_authority,
		"Air steering authority is reduced")
	var section := BarrierSection.new()
	section.start_fraction = 0.9
	section.end_fraction = 0.1
	section.sides = BarrierSection.Sides.LEFT
	s.check(section.applies(0.95, -1) and section.applies(0.05, -1) and not section.applies(0.5, -1), "Barrier segment wraps across lap seam")
	s.check(not section.applies(0.95, 1), "Barrier side selection")

func _place(kart: KartController, location: Vector3, basis: Basis = Basis.IDENTITY) -> void:
	kart.safe_spawn = Transform3D(basis, location)
	kart.reset_to_spawn()

func _scene(s: SceneTree) -> void:
	var main := load("res://scenes/main.tscn").instantiate() as Node3D
	s.root.add_child(main)
	var race := main.get_node("RaceManager") as RaceManager
	race.set_physics_process(false)
	race.start_race()
	race.session.advance(3)
	var kart := main.get_node("Kart") as KartController
	kart.get_node("Recovery").stuck_seconds = 0
	var track := main.get_node("Track") as TrackBuilder
	var length := track.curve.get_baked_length()
	s.check(not track.barrier_enabled(length * 0.85, -1) and track.barrier_enabled(length * 0.85, 1), "Authored outer opening keeps opposite boundary enabled")
	var perimeter := kart.get_world_3d().direct_space_state.intersect_ray(
		PhysicsRayQueryParameters3D.create(Vector3(168, 0.5, 0), Vector3(172, 0.5, 0), 1))
	# Wait for newly created static geometry to enter the physics world.
	await s.physics_frame
	await s.physics_frame
	perimeter = kart.get_world_3d().direct_space_state.intersect_ray(
		PhysicsRayQueryParameters3D.create(Vector3(168, 0.5, 0), Vector3(172, 0.5, 0), 1))
	s.check(not perimeter.is_empty(), "Visible outer perimeter contains open sections")
	var opening := track.barrier_point(length * 0.85, -1) + Vector3.UP * 0.5
	var across := track.sample_forward(length * 0.85).cross(Vector3.UP) * 2
	var gap := kart.get_world_3d().direct_space_state.intersect_ray(
		PhysicsRayQueryParameters3D.create(opening - across, opening + across, 1))
	s.check(gap.is_empty(), "Disabled barrier section has no invisible collision wall")
	var opposite := track.barrier_point(length * 0.85, 1) + Vector3.UP * 0.5
	var wall := kart.get_world_3d().direct_space_state.intersect_ray(
		PhysicsRayQueryParameters3D.create(opposite - across, opposite + across, 1))
	s.check(not wall.is_empty(), "Opposite side remains collidable beside opening")
	kart.set_physics_process(false)
	var samples := {"asphalt": Vector3(75.6, 0.46, 0), "sand": Vector3(100, 0.34, 0), "grass": Vector3(-50, 0.34, -35)}
	for identifier in samples:
		_place(kart, samples[identifier])
		await s.physics_frame
		await s.physics_frame
		for i in 12:
			kart.surface_detector.update(kart, kart.config, 0.1)
		s.check(kart.surface_detector.current.identifier == StringName(identifier), "Procedural ground detects " + identifier)
	kart.set_physics_process(true)
	# Real drift activation and countersteering through the same player provider.
	_place(kart, track.sample_center(length * 0.03) + Vector3.UP * 0.42, Basis.looking_at(track.sample_forward(length * 0.03)))
	for i in 12:
		await s.physics_frame
	kart.velocity = -kart.global_basis.z * 18
	Input.action_press("accelerate")
	Input.action_press("steer_right", 0.8)
	Input.action_press("drift")
	for i in 18:
		await s.physics_frame
	s.check(kart.drift.active and kart.drift.charge > 0, "Actual lateral kart motion charges a drift")
	Input.action_release("steer_right")
	Input.action_press("steer_left", 0.8)
	for i in 8:
		await s.physics_frame
	s.check(kart.drift.active, "Kart remains drifting during countersteer")
	Input.action_release("steer_left")
	Input.action_release("drift")
	Input.action_release("accelerate")
	var features := main.get_node("TrackFeatures")
	_place(kart, Vector3(110, 6, 20))
	for i in 2:
		await s.physics_frame
	kart.velocity = Vector3(0, 0, -18)
	Input.action_press("accelerate")
	Input.action_press("steer_right", 0.8)
	Input.action_press("drift")
	for i in 8:
		await s.physics_frame
	s.near(Vector2(kart.velocity.x, kart.velocity.z).length(), 18, "Air throttle/steering cannot manufacture horizontal momentum", 0.001)
	s.check(not kart.drift.active, "Physical airborne kart cannot drift")
	Input.action_release("accelerate")
	Input.action_release("steer_right")
	Input.action_release("drift")
	var pad := features.get_node("Generated").get_child(0) as BoostPad
	_place(kart, pad.global_position + Vector3.UP * 0.42, pad.global_basis)
	for i in 20:
		await s.physics_frame
	s.check(kart.boost.active() and kart.boost.source == &"boost_pad", "Area boost pad activates on a grounded kart")
	s.check(kart.surface_detector.current.identifier == &"boost_pad", "Boost pad surface detected independently of asphalt")
	kart.boost.clear()
	for i in 70:
		await s.physics_frame
	s.check(not kart.boost.active(), "Remaining on pad cannot repeatedly activate boost")
	kart.activate_boost(&"test", 1.6, 2)
	kart.reset_to_spawn()
	for i in 70:
		await s.physics_frame
	s.check(not kart.boost.active(), "Reset on occupied pad clears boost without re-triggering after cooldown")
	var ramp := features.get_node("Generated/RunoffJump") as KartRamp
	_place(kart, ramp.to_global(Vector3(0, 0.42, 2.0)), ramp.global_basis)
	for i in 15:
		await s.physics_frame
	kart.velocity = -ramp.global_basis.z * 18
	Input.action_press("accelerate")
	var airborne := false
	var landed := false
	var maximum_height := kart.position.y
	var maximum_upward_speed := 0.0
	var premature_air_frames := 0
	for i in 120:
		await s.physics_frame
		maximum_height = maxf(maximum_height, kart.position.y)
		maximum_upward_speed = maxf(maximum_upward_speed, kart.velocity.y)
		var local := ramp.to_local(kart.position)
		if local.z < -1.5 and local.z > -ramp.length + 0.6 and not kart.is_on_floor():
			premature_air_frames += 1
		if not kart.is_on_floor() and kart.position.y > ramp.global_position.y + ramp.height + 0.2:
			airborne = true
		if airborne and kart.is_on_floor() and kart.position.y < 0.8:
			landed = true
	Input.action_release("accelerate")
	s.check(airborne and maximum_height > ramp.global_position.y + ramp.height + 0.2, "Actual ramp geometry launches kart")
	s.check(maximum_upward_speed > 1, "Ramp tangent supplies upward momentum without jump impulses")
	s.check(premature_air_frames <= 1, "Kart keeps floor contact along the incline until launch edge")
	s.check(landed, "Kart lands safely after jump")
	s.check(kart.global_position.is_finite() and main.get_node("ChaseCamera").global_position.is_finite(), "Jump/camera positions remain finite")
	kart.drift.active = true
	kart.drift.charge = 2
	kart.activate_boost(&"test", 1.4, 2)
	var recovery := kart.get_node("Recovery") as KartRecovery
	recovery.cooldown_remaining = 0
	var next_gate := race.session.next_checkpoint
	recovery.recover()
	s.check(not kart.drift.active and kart.drift.charge == 0 and not kart.boost.active(), "Recovery clears drift charge and active boost")
	s.check(race.session.next_checkpoint == next_gate, "Temporary-state cleanup preserves race progress")
	kart.drift.active = true
	kart.drift.charge = 1.5
	kart.activate_boost(&"test", 1.4, 2)
	race.restart_race()
	s.check(not kart.drift.active and not kart.boost.active() and race.session.race_time == 0, "Race restart clears temporary effects and timing")
	recovery.cooldown_remaining = 0
	kart.rotation.z = PI * 0.5
	recovery._physics_process(0.01)
	s.check(kart.global_basis.y.dot(Vector3.UP) > 0.99, "Unusual body orientation recovers upright")
	recovery.cooldown_remaining = 0
	kart.position.x = recovery.recovery_half_extents.x + 2
	recovery._physics_process(0.01)
	s.check(kart.global_transform.is_equal_approx(kart.safe_spawn), "Independent recovery bounds work beyond open barriers")
	var count := features.get_node("Generated").get_child_count()
	features.build()
	features.build()
	s.check(features.get_child_count() == 1 and features.get_node("Generated").get_child_count() == count, "Feature rebuilds do not duplicate pads/ramps")
	main.queue_free()
	await s.process_frame
