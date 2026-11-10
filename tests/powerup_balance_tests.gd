extends RefCounted
class TestInput extends DrivingInput:
	var command := DrivingCommand.new()
	func get_command() -> DrivingCommand: return command

func run(s: SceneTree) -> void:
	_surfaces(s)
	_spin_model(s)
	_feedback(s)
	await _integration(s)

func _surfaces(s: SceneTree) -> void:
	for resource in [preload("res://resources/surfaces/sand.tres"), preload("res://resources/surfaces/grass.tres")]:
		var detector := SurfaceDetector.new()
		detector.current = resource
		detector.effective = resource.multipliers()
		var original: Vector4 = resource.multipliers()
		var boost := BoostController.new()
		boost.activate(&"mushroom", 1.4, 1.8, KartConfig.BoostPolicy.STRONGEST_WINS)
		var immune := detector.handling_multipliers(boost, 1.0 / 60, 8)
		s.check(immune.x == 1 and immune.y == 1 and immune.z == 1, "Mushroom neutralizes acceleration/cap/grip on " + str(resource.identifier))
		s.check(immune.w == original.w and detector.current == resource and detector.effective == original, "Mushroom preserves resistance, detected identity and underlying terrain blend")
		boost.advance(1.81)
		var returning := detector.handling_multipliers(boost, 1.0 / 60, 8)
		s.check(returning.x > original.x and returning.x < 1, "Off-road penalty begins returning smoothly after expiration")
		for i in 120: returning = detector.handling_multipliers(boost, 1.0 / 60, 8)
		s.check(returning.is_equal_approx(original) and resource.multipliers() == original, "Terrain fully restores without mutating shared resources")
		for source: StringName in [&"boost_pad", &"mini_turbo"]:
			detector.reset()
			detector.current = resource
			detector.effective = original
			boost.clear()
			boost.activate(source, 1.5, 1.4, KartConfig.BoostPolicy.STRONGEST_WINS)
			s.check(detector.handling_multipliers(boost, 0.1, 8) == original and boost.mushroom_remaining == 0, "Pad/mini-turbo keep ordinary terrain penalties: " + str(source))
	var overlap := BoostController.new()
	overlap.activate(&"boost_pad", 1.5, 4, KartConfig.BoostPolicy.STRONGEST_WINS)
	overlap.activate(&"mushroom", 1.5, 4, KartConfig.BoostPolicy.STRONGEST_WINS, 1.8)
	overlap.advance(1)
	overlap.activate(&"boost_pad", 1.5, 4, KartConfig.BoostPolicy.STRONGEST_WINS)
	s.near(overlap.mushroom_remaining, 0.8, "Pad overlap cannot refresh mushroom's own immunity timer")
	overlap.advance(0.81)
	s.check(overlap.active() and overlap.mushroom_remaining == 0, "Longer retained boost cap cannot prolong mushroom terrain immunity")
	overlap.activate(&"mushroom", 1.5, 3, KartConfig.BoostPolicy.STRONGEST_WINS, 1.8)
	overlap.activate(&"mini_turbo", 1.2, 0.6, KartConfig.BoostPolicy.REPLACE)
	s.check(overlap.mushroom_remaining == 0 and overlap.feedback_remaining == 0, "Replace policy ends old mushroom immunity and feedback")

func _spin_model(s: SceneTree) -> void:
	for index in [1, 2, 3]:
		var item: ItemDefinition = ItemCatalog.ITEMS[index]
		for rate in [30, 60, 120, 144]:
			var effects := KartEffects.new()
			s.check(effects.apply(item.hit_seconds, item.speed_multiplier, item.grip_multiplier, item.spin_degrees,
				item.hit_control, item.control_recovery_seconds), "Shared spin-out state accepts configured shell/banana reaction")
			var rotation := 0.0
			var frames := 0
			var overlap_rejected := true
			var smooth_recovery := true
			var recovery_seen := false
			var previous_control := effects.control_authority()
			while effects.active() and frames < rate * 4:
				overlap_rejected = overlap_rejected and not effects.apply(item.hit_seconds, 0.4, 0.2, 360)
				rotation += effects.advance(1.0 / rate)
				if effects.recovery_remaining > 0:
					recovery_seen = true
					smooth_recovery = smooth_recovery and effects.control_authority() >= previous_control and effects.control_authority() - previous_control < 0.2
				previous_control = effects.control_authority()
				frames += 1
			s.near(rad_to_deg(rotation), item.spin_degrees, "Spin integrates to configured rotation at %d Hz" % rate, 0.001)
			s.check(overlap_rejected and frames < ceili((item.hit_seconds + item.control_recovery_seconds + 0.1) * rate), "Overlapping hits cannot extend a spin indefinitely")
			s.check(recovery_seen and smooth_recovery and effects.control_authority() == 1 and effects.speed_multiplier == 1 and effects.grip_multiplier == 1, "Control/speed/grip recover smoothly and completely")
			effects.advance(0.5)
			s.check(effects.apply(1.35, 0.55, 0.24, 360), "A recovered kart can receive a later independent hit")
			effects.clear()
			s.check(not effects.active() and effects.total_rotation == 0 and effects.immunity_remaining == 0, "Cleanup removes all spin/recovery/immunity state")
	var invalid := KartEffects.new()
	s.check(not invalid.apply(1.35, 0.5, 0.3, NAN), "Nonfinite spin tuning is rejected before changing state")
	s.check(ItemCatalog.ITEMS[3].hit_seconds > ItemCatalog.ITEMS[1].hit_seconds and ItemCatalog.ITEMS[3].spin_degrees == 540, "Banana has a longer 540-degree reaction")

func _feedback(s: SceneTree) -> void:
	var lines := BoostSpeedLines.new()
	var boost := BoostController.new()
	for source: StringName in [&"mushroom", &"boost_pad"]:
		lines.reset_feedback()
		boost.clear()
		boost.activate(source, 1.5, 1.4, KartConfig.BoostPolicy.STRONGEST_WINS)
		for i in 6: lines.advance_feedback(boost, true, 1.0 / 60)
		var burst := lines.opacity
		for i in 40: lines.advance_feedback(boost, true, 1.0 / 60)
		s.check(burst > lines.opacity and lines.opacity > 0.15, "Eligible boost starts a brief burst followed by subtle sustained streaks: " + str(source))
		boost.advance(2)
		lines.advance_feedback(boost, true, 1.0 / 60)
		s.check(lines.opacity > 0, "Boost lines fade rather than abruptly disappearing")
		for i in 90: lines.advance_feedback(boost, true, 1.0 / 60)
		s.check(lines.opacity == 0, "Boost lines finish fading after expiration")
	boost.activate(&"mini_turbo", 1.3, 1, KartConfig.BoostPolicy.STRONGEST_WINS)
	lines.advance_feedback(boost, true, 0.1)
	s.check(lines.opacity == 0, "Mini-turbos do not acquire mushroom/pad streaks")
	boost.activate(&"boost_pad", 1.5, 1.4, KartConfig.BoostPolicy.STRONGEST_WINS)
	lines.advance_feedback(boost, true, 0.1)
	lines.advance_feedback(boost, false, 0.01)
	s.check(lines.opacity == 0 and lines.burst_remaining == 0, "Race locks clear feedback immediately")
	var weak_lines := BoostSpeedLines.new()
	var strong_lines := BoostSpeedLines.new()
	var weak_boost := BoostController.new()
	var strong_boost := BoostController.new()
	weak_boost.activate(&"mushroom", 1.2, 1.8, KartConfig.BoostPolicy.STRONGEST_WINS)
	strong_boost.activate(&"mushroom", 1.5, 1.8, KartConfig.BoostPolicy.STRONGEST_WINS)
	for i in 10:
		weak_lines.advance_feedback(weak_boost, true, 1.0 / 60)
		strong_lines.advance_feedback(strong_boost, true, 1.0 / 60)
	s.check(strong_lines.opacity > weak_lines.opacity * 2, "Streak intensity scales with boost strength")
	for i in 30: strong_lines.advance_feedback(strong_boost, true, 1.0 / 60)
	strong_boost.activate(&"mushroom", 1.5, 1.8, KartConfig.BoostPolicy.STRONGEST_WINS)
	strong_lines.advance_feedback(strong_boost, true, 1.0 / 60)
	s.check(strong_lines.burst_remaining > 0.2, "A repeated accepted activation starts a fresh burst with the same source")
	weak_lines.free()
	strong_lines.free()
	for resolution in [Vector2(1280, 720), Vector2(1920, 1080), Vector2(1024, 768), Vector2(720, 1280)]:
		for focus in [Vector2(0.5, 0.68), Vector2(0.25, 0.4), Vector2(0.85, 0.8)]:
			var geometry := lines.streak_geometry(resolution, focus)
			var clear_centre := true
			for streak in geometry:
				var relative: Vector2 = (streak[0] - focus * resolution) / resolution
				clear_centre = clear_centre and relative.length() > 0.05 and streak[0].is_finite()
			s.check(geometry.size() == lines.streak_count and clear_centre, "Resolution/focus-independent streaks keep the kart centre clear")
	lines.free()

func _place(body: KartController, at: Vector3) -> void:
	body.safe_spawn = Transform3D(Basis.IDENTITY, at)
	body.reset_to_spawn()
	body.driving_enabled = true
	(body.input_provider as TestInput).command = DrivingCommand.new()

func _integration(s: SceneTree) -> void:
	var main := load("res://scenes/main.tscn").instantiate() as Node3D
	main.get_node("RaceManager").opponent_count = 1
	main.get_node("Items").enabled = false
	s.root.add_child(main)
	var race := main.get_node("RaceManager") as RaceManager
	race.set_physics_process(false)
	race.start_race()
	race.session.advance(3)
	var human := race.kart
	var opponent := race.competitors[1].kart
	for body in [human, opponent]:
		body.input_provider.set_physics_process(false)
		body.get_node("Recovery").set_physics_process(false)
		var provider := TestInput.new()
		body.add_child(provider)
		body.input_provider = provider
	var camera := main.get_node("ChaseCamera") as Camera3D
	camera.set_process(false)
	for index in 3:
		var floor_body := StaticBody3D.new()
		floor_body.position = Vector3(500 + index * 250, -0.5, 400)
		var collision := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(200, 1, 600)
		collision.shape = box
		floor_body.add_child(collision)
		main.add_child(floor_body)
		SurfaceDetector.tag_collision(floor_body, [preload("res://resources/surfaces/asphalt.tres"), preload("res://resources/surfaces/sand.tres"), preload("res://resources/surfaces/grass.tres")][index])
	await s.physics_frame
	_place(opponent, Vector3(520, 0.5, 500))
	for index in [1, 2]:
		_place(human, Vector3(500 + index * 250, 0.5, 550))
		for i in 30: await s.physics_frame
		var identifier: StringName = human.surface_detector.current.identifier
		human.activate_item_boost(&"mushroom", 1.4, 1.8)
		(human.input_provider as TestInput).command = DrivingCommand.new(1)
		for i in 80: await s.physics_frame
		s.check(human.velocity.length() > 29 and human.surface_detector.current.identifier == identifier, "Real mushroom exceeds off-road speed cap while preserving surface name: " + str(identifier))
		var boosted_speed := human.velocity.length()
		human.velocity = -human.global_basis.z * 16 + human.global_basis.x * 3
		var old_yaw := human.rotation.y
		(human.input_provider as TestInput).command = DrivingCommand.new(1, 0, 0.6, true)
		for i in 5: await s.physics_frame
		s.check(human.drift.active and human.rotation.y != old_yaw, "Mushroom retains ordinary steering and drift on " + str(identifier))
		(human.input_provider as TestInput).command = DrivingCommand.new(1)
		for i in 180: await s.physics_frame
		s.check(human.velocity.length() < human.config.max_forward_speed * human.surface_detector.current.max_speed_multiplier + 0.1, "Real off-road speed penalty returns after mushroom expiry")
		print("MUSHROOM %s boosted=%.3f restored=%.3f" % [str(identifier), boosted_speed, human.velocity.length()])
	for index in [1, 2, 3]:
		var item: ItemDefinition = ItemCatalog.ITEMS[index]
		_place(human, Vector3(500, 0.5, 550))
		_place(opponent, Vector3(520, 0.5, 550))
		for i in 30: await s.physics_frame
		camera.snap_to_target()
		for body in [human, opponent]:
			body.velocity = Vector3.FORWARD * 20
			(body.input_provider as TestInput).command = DrivingCommand.new(1)
			s.check(body.receive_item_hit(Vector3.RIGHT * 2, item.hit_seconds, item.speed_multiplier, item.grip_multiplier,
				item.momentum_retention, item.spin_degrees, item.hit_control, item.control_recovery_seconds), "Human/opponent accept identical shared spin reaction")
		var yaw := human.rotation.y
		var total_yaw := 0.0
		var airborne := 0
		var max_step := 0.0
		var max_orbit := 0.0
		var match_effects := true
		var speed_after_hit := 0.0
		var minimum_y := INF
		var maximum_y := -INF
		var start := human.position
		for frame in ceili((item.hit_seconds + item.control_recovery_seconds + 0.2) * 60):
			await s.physics_frame
			camera._process(1.0 / 60)
			var change := wrapf(human.rotation.y - yaw, -PI, PI)
			total_yaw += change
			yaw = human.rotation.y
			max_step = maxf(max_step, absf(change))
			if frame == 4: speed_after_hit = human.velocity.length()
			if not human.is_on_floor(): airborne += 1
			minimum_y = minf(minimum_y, human.position.y)
			maximum_y = maxf(maximum_y, human.position.y)
			match_effects = match_effects and is_equal_approx(human.effects.spin_angle, opponent.effects.spin_angle) and human.velocity.distance_to(opponent.velocity) < 0.003
			if human.effects.spinning(): max_orbit = maxf(max_orbit, absf((camera.global_position - human.global_position).x))
		s.near(rad_to_deg(total_yaw), item.spin_degrees, "Actual CharacterBody completes configured spin: " + item.display_name, 0.03)
		s.check(max_step < deg_to_rad(9) and airborne == 0 and maximum_y - minimum_y < 0.002, "Incremental yaw preserves flat grounding without vertical impulses")
		s.check(speed_after_hit > 1 and speed_after_hit < 14, "Spin meaningfully reduces speed without a zero-velocity reset")
		s.check(match_effects, "Human and AI kart bodies receive identical spin/velocity response")
		s.check(human.position.distance_to(start) < 40 and max_orbit < 1.5, "Spin slides under bounded inertia while the chase view avoids orbiting")
		s.check(not human.effects.active() and human.effects.control_authority() == 1, "Actual kart restores normal control after spin/recovery")
		print("SPIN %s degrees=%.3f hit_speed=%.3f body_y_range=%.8f orbit_x=%.3f" % [item.display_name, rad_to_deg(total_yaw), speed_after_hit, maximum_y - minimum_y, max_orbit])
	await _wall_and_cleanup(s, main, human, race)
	main.queue_free()
	await s.process_frame

func _wall_and_cleanup(s: SceneTree, main: Node3D, kart: KartController, race: RaceManager) -> void:
	var wall := StaticBody3D.new()
	wall.position = Vector3(501.4, 1, 500)
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.2, 2, 100)
	collision.shape = box
	wall.add_child(collision)
	main.add_child(wall)
	_place(kart, Vector3(500.1, 0.5, 530))
	for i in 20: await s.physics_frame
	kart.velocity = Vector3.FORWARD * 15
	kart.receive_item_hit(Vector3.RIGHT, 1.65, 0.5, 0.2, 0.5, 540)
	var stable := true
	var maximum_overlap := 0.0
	var old_position := kart.position
	for i in 130:
		await s.physics_frame
		stable = stable and kart.is_on_floor() and kart.position.distance_to(old_position) < 0.7 and kart.position.x < 501.3
		var extent := absf(kart.global_basis.x.x) * 0.625 + absf(kart.global_basis.z.x) * 1.05
		maximum_overlap = maxf(maximum_overlap, kart.position.x + extent - 501.3)
		old_position = kart.position
	s.check(stable, "Spin beside a real wall avoids tunnelling, launch or excessive per-frame displacement")
	s.check(maximum_overlap < 0.03, "Rotating box collider remains separated from the wall throughout a spin")
	print("SPIN wall maximum_overlap=%.6f" % maximum_overlap)
	_place(kart, Vector3(500, 4, 530))
	for i in 2: await s.physics_frame
	kart.velocity = Vector3(0, 6, -12)
	var height := kart.position.y
	s.check(kart.receive_item_hit(Vector3.RIGHT, 1.35, 0.55, 0.24, 0.55, 360) and kart.velocity.y == 6, "Airborne hit preserves existing vertical launch velocity")
	for i in 4: await s.physics_frame
	s.check(kart.position.y > height and kart.velocity.y > 0 and not kart.is_on_floor(), "Spinning kart can continue a legitimate upward jump")
	for i in 150: await s.physics_frame
	s.check(kart.is_on_floor() and not kart.effects.active(), "Spinning airborne kart lands and recovers normally")
	_place(kart, Vector3(500, 0.5, 530))
	s.check(kart.receive_item_hit(Vector3.RIGHT, 1.35, 0.55, 0.24, 0.55, 360), "Cleanup test begins with an accepted new spin")
	for i in 12: await s.physics_frame
	s.check(kart.effects.spinning(), "Recovery cleanup runs during an actual active spin")
	kart.reset_to_spawn()
	s.check(not kart.effects.active() and kart.effects.spin_angle == 0 and kart.effects.control_authority() == 1, "Recovery clears an in-progress spin and control impairment")
	kart.receive_item_hit(Vector3.RIGHT, 1.35, 0.55, 0.24, 0.55, 360)
	race.restart_race()
	s.check(not kart.effects.active() and kart.effects.total_rotation == 0 and kart.boost.mushroom_remaining == 0, "Restart clears spin, immunity and mushroom state")
	race.session.advance(3)
	kart.receive_item_hit(Vector3.RIGHT, 1.35, 0.55, 0.24, 0.55, 360)
	race._on_competitor_state(RaceSession.State.FINISHED, race.competitors[0])
	s.check(not kart.effects.active() and kart.effects.total_rotation == 0 and not kart.driving_enabled, "Race completion clears spin state and locks item effects")
