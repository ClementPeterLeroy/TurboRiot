extends RefCounted
## Race rules are tested both as a model and through scene orchestration.

func run(suite: SceneTree) -> void:
	_test_lifecycle(suite)
	_test_gate(suite)
	await _test_scene(suite)

func _test_lifecycle(suite: SceneTree) -> void:
	var race := RaceSession.new()
	race.checkpoint_count = 4
	suite.check(race.state == RaceSession.State.READY, "Race starts READY")
	race.advance(10)
	suite.near(race.race_time, 0, "Ready timer frozen")
	suite.check(not race.cross_checkpoint(1), "Ready gates ignored")
	race.start()
	suite.check(race.state == RaceSession.State.COUNTDOWN and race.indicator() == "3", "Countdown begins at 3")
	race.advance(1)
	suite.check(race.indicator() == "2", "Countdown shows 2")
	race.start()
	suite.near(race.countdown_remaining, 2, "Repeated start cannot duplicate/reset countdown")
	race.advance(1)
	suite.check(race.indicator() == "1", "Countdown shows 1")
	suite.near(race.race_time, 0, "Countdown timer frozen")
	suite.check(not race.cross_checkpoint(1), "Countdown gates ignored")
	race.advance(1)
	suite.check(race.state == RaceSession.State.RACING and race.indicator() == "GO!", "GO transitions to RACING")
	suite.near(race.race_time, 0, "Timer starts at GO")
	race.advance(1)
	suite.check(race.indicator().is_empty(), "GO indicator expires")
	suite.check(not race.cross_checkpoint(0), "Initial finish crossing is not a lap")
	suite.check(not race.cross_checkpoint(2), "Skipped checkpoint rejected")
	suite.check(race.next_checkpoint == 1, "Bad order preserves expected gate")
	suite.check(not race.cross_checkpoint(1, false), "Reverse checkpoint rejected")
	for lap in 3:
		for checkpoint in range(1, 4):
			suite.check(race.cross_checkpoint(checkpoint), "Ordered lap %d gate %d" % [lap, checkpoint])
			suite.check(not race.cross_checkpoint(checkpoint), "Repeated checkpoint rejected")
		suite.check(not race.cross_checkpoint(0, false), "Reverse finish rejected after valid sequence")
		race.advance(10 + lap)
		suite.check(race.cross_checkpoint(0), "Valid lap completed")
		suite.check(race.lap_times.size() == lap + 1, "Exactly one lap increment")
		suite.check(not race.cross_checkpoint(0), "Repeated finish rejected")
	suite.check(race.state == RaceSession.State.FINISHED, "Race finishes after 3 laps")
	suite.near(race.final_time, 34, "Final race time")
	suite.near(race.lap_times[0], 11, "First lap timing")
	suite.near(race.last_lap_time(), 12, "Last lap timing")
	suite.near(race.best_lap_time(), 11, "Best lap timing")
	suite.check(race.current_lap() == 3, "Finished lap count bounded")
	race.advance(20)
	suite.near(race.race_time, 34, "Finished timer frozen")
	suite.check(not race.cross_checkpoint(1), "Finished gates ignored")
	race.reset(true)
	suite.check(race.state == RaceSession.State.COUNTDOWN and race.indicator() == "3", "Restart countdown reset")
	suite.check(race.lap_times.is_empty(), "Restart clears lap results")
	suite.near(race.race_time + race.lap_start_time + race.final_time + race.best_lap_time(), 0, "Restart clears all clocks")
	suite.check(race.next_checkpoint == 1 and race.latest_checkpoint == 0, "Restart clears checkpoint state")
	race.advance(0.5)
	race.reset(true)
	suite.near(race.countdown_remaining, 3, "Restart during countdown replaces old countdown")
	race.reset()
	suite.check(race.state == RaceSession.State.READY, "Return to READY")
	# Configurable race length and timer partition invariance.
	race.lap_count = 1
	race.checkpoint_count = 2
	race.start()
	race.advance(3)
	for i in 60:
		race.advance(1.0 / 60)
	race.cross_checkpoint(1)
	race.cross_checkpoint(0)
	suite.check(race.state == RaceSession.State.FINISHED, "Configurable one-lap race")
	suite.near(race.final_time, 1.0, "Consistent accumulated physics time")
	race.advance(NAN)
	suite.near(race.final_time, 1.0, "Nonfinite delta cannot corrupt timer")
	suite.check(RaceHUD.format_time(65.123) == "01:05.123", "HUD time formatting")

func _test_gate(suite: SceneTree) -> void:
	var gate := load("res://scenes/checkpoint.tscn").instantiate() as CheckpointGate
	suite.root.add_child(gate)
	suite.near(gate.crossing_fraction(Vector3(0, 1, 2), Vector3(0, 1, -2)), 0.5, "Swept gate crossing")
	suite.check(gate.crossing_fraction(Vector3(0, 1, -2), Vector3(0, 1, 2)) < 0, "Backward finish plane rejected")
	suite.check(gate.crossing_fraction(Vector3(0, 1, 0), Vector3(0, 1, 0)) < 0, "Stationary plane occupancy rejected")
	suite.check(gate.crossing_fraction(Vector3(0, 1, -0.1), Vector3(0, 1, -2)) < 0, "Remaining past gate does not repeat")
	suite.check(gate.crossing_fraction(Vector3(6, 1, 2), Vector3(6, 1, -2)) < 0, "Outside road width rejected")
	suite.check(gate.crossing_fraction(Vector3(0, 5, 2), Vector3(0, 5, -2)) < 0, "Above gate rejected")
	suite.check(gate.crossing_fraction(Vector3(0, -1, 2), Vector3(0, -1, -2)) < 0, "Below gate rejected")
	suite.near(gate.crossing_fraction(Vector3(0, 1, 50), Vector3(0, 1, -50)), 0.5, "High speed cannot tunnel through gate")
	gate.transform = Transform3D(Basis(Vector3.UP, 0.8), Vector3(30, 2, -20))
	suite.near(gate.crossing_fraction(gate.to_global(Vector3(0, 1, 2)), gate.to_global(Vector3(0, 1, -2))), 0.5,
		"Transformed gate uses local direction")
	gate.queue_free()

func _cross(race: RaceManager, index: int, reverse: bool = false) -> void:
	var gate := race.gates[index]
	var a := gate.to_global(Vector3(0, 0.6, 2))
	var b := gate.to_global(Vector3(0, 0.6, -2))
	race.process_movement(b if reverse else a, a if reverse else b)

func _test_scene(suite: SceneTree) -> void:
	var main := load("res://scenes/main.tscn").instantiate() as Node3D
	suite.root.add_child(main)
	var race := main.get_node("RaceManager") as RaceManager
	var kart := main.get_node("Kart") as KartController
	var recovery := kart.get_node("Recovery") as KartRecovery
	var hud := main.get_node("HUD") as RaceHUD
	race.set_physics_process(false) # Advance the orchestration clock explicitly.
	var spawn := kart.position
	Input.action_press("accelerate")
	for i in 8:
		await suite.physics_frame
	Input.action_release("accelerate")
	suite.check(not kart.driving_enabled, "READY locks driving")
	suite.near(Vector2(kart.position.x - spawn.x, kart.position.z - spawn.z).length(), 0, "Throttle cannot move before start")
	race.start_race()
	race.session.advance(1)
	suite.check(not kart.driving_enabled, "COUNTDOWN locks driving")
	race.restart_race()
	suite.near(race.session.countdown_remaining, 3, "Scene restart replaces countdown")
	race.session.advance(3)
	suite.check(kart.driving_enabled, "GO unlocks kart")
	suite.check(race.gates.size() == main.get_node("Track").checkpoint_count, "Configured gates built")
	_cross(race, 0)
	suite.check(race.session.lap_times.is_empty(), "Scene initial finish ignored")
	_cross(race, 2)
	suite.check(race.session.next_checkpoint == 1, "Scene out-of-order crossing ignored")
	_cross(race, 1, true)
	suite.check(race.session.next_checkpoint == 1, "Scene reversed checkpoint ignored")
	_cross(race, 1)
	_cross(race, 2)
	race.session.advance(5)
	recovery.cooldown_remaining = 0
	kart.global_position = Vector3(0, 1, 0)
	kart.velocity = Vector3(10, -5, 2)
	suite.check(recovery.recover(), "Manual recovery succeeds")
	suite.check(kart.global_transform.is_equal_approx(race.gates[2].recovery_transform()), "Recovery uses latest validated gate")
	suite.near(kart.velocity.length(), 0, "Recovery clears residual velocity")
	suite.near(race.session.race_time, 5, "Recovery preserves race time")
	suite.check(race.session.next_checkpoint == 3 and race.session.latest_checkpoint == 2, "Recovery preserves checkpoint progress")
	suite.check(not recovery.recover(), "Recovery cooldown prevents repeated reset")
	suite.check(race._previous_position.is_equal_approx(kart.global_position), "Recovery resamples crossing baseline")
	race._physics_process(0.1)
	suite.check(race.session.next_checkpoint == 3, "Recovery is not a checkpoint sweep")
	suite.near(race.session.race_time, 5.1, "Clock continues after recovery")
	suite.check(main.get_node("ChaseCamera").global_position.distance_to(kart.global_position) < 10, "Recovery synchronizes camera")
	recovery.cooldown_remaining = 0
	kart.global_position.y = recovery.fall_height - 2
	recovery._physics_process(0.016)
	suite.check(kart.global_transform.is_equal_approx(race.gates[2].recovery_transform()), "Fall recovery returns to safe gate")
	suite.check(race.session.next_checkpoint == 3, "Fall recovery cannot award checkpoints")
	_cross(race, 0)
	suite.check(race.session.lap_times.is_empty(), "Recovering cannot skip remaining gates")
	race.restart_race()
	suite.check(kart.global_transform.is_equal_approx(main.get_node("Track").spawn_transform()), "Restart restores initial grid spawn")
	suite.check(race.session.next_checkpoint == 1 and race.session.race_time == 0, "Restart resets scene progress/time")
	race.session.advance(3)
	for lap in 3:
		for checkpoint in range(1, race.gates.size()):
			race.session.advance(0.5)
			_cross(race, checkpoint)
		_cross(race, 0, true)
		suite.check(race.session.lap_times.size() == lap, "Scene reverse finish cannot award lap")
		race.session.advance(0.5)
		_cross(race, 0)
		suite.check(race.session.lap_times.size() == lap + 1, "Scene valid lap increments once")
		if lap == 0:
			recovery.cooldown_remaining = 0
			recovery.recover()
			suite.check(race.session.lap_times.size() == 1, "Recovery preserves completed laps")
			suite.near(race.session.last_lap_time(), 6, "Recovery preserves lap results")
			suite.check(race.session.next_checkpoint == 1, "Recovery after finish cannot award the next lap")
	suite.check(race.session.state == RaceSession.State.FINISHED, "Scene completes 3-lap time trial")
	suite.check(not kart.driving_enabled, "Finish locks driving")
	suite.near(race.session.final_time, 18, "Scene final time includes all laps")
	hud._refresh()
	suite.check(hud.card.visible and hud.card_text.text.contains("Lap 3"), "Results show individual lap times")
	suite.check(hud.card_text.text.contains("BEST LAP"), "Results show best lap")
	race.set_debug_visible(true)
	suite.check(race.gates[1].get_node("Debug").visible, "Debug exposes checkpoints")
	race.set_debug_visible(false)
	suite.check(not race.gates[1].get_node("Debug").visible, "Normal gameplay hides checkpoints")
	hud.primary.pressed.emit()
	suite.check(race.session.state == RaceSession.State.COUNTDOWN and race.session.lap_times.is_empty(), "Results restart button resets race")
	hud.ready_button.pressed.emit()
	suite.check(race.session.state == RaceSession.State.READY and not kart.driving_enabled, "Return to Ready button works")
	# Rebuilding source geometry updates gates and resets race without stale nodes.
	main.get_node("Track").build()
	suite.check(is_instance_valid(race.gates[0]) and race.session.state == RaceSession.State.READY, "Track rebuild refreshes race gate references")
	main.queue_free()
	await suite.process_frame
