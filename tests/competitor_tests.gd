extends RefCounted

class SlowInput extends DrivingInput:
	var kart: KartController
	func get_command() -> DrivingCommand:
		return DrivingCommand.new(clampf((6.0 - kart.signed_speed) * 0.5, 0, 1), 0.25 if kart.signed_speed > 6.5 else 0)

func run(s: SceneTree) -> void:
	var main := load("res://scenes/main.tscn").instantiate() as Node3D
	s.root.add_child(main)
	var race := main.get_node("RaceManager") as RaceManager
	race.set_physics_process(false)
	for record in race.competitors:
		record.kart.set_physics_process(false)
		record.kart.get_node("Recovery").set_physics_process(false)
		if record.kart.input_provider is AIInput: record.kart.input_provider.set_physics_process(false)
	await s.physics_frame
	s.check(race.competitors.size() == 7, "Default field contains one human and six AI karts")
	var grid_clear := true
	var models_unique := true
	var same_physics := true
	var lane_continuity := true
	for record in race.competitors:
		same_physics = same_physics and record.kart.config == race.kart.config and record.kart.collision_mask == 3 and record.kart.collision_layer == 2
		if record.kart.input_provider is AIInput:
			lane_continuity = lane_continuity and absf(record.kart.input_provider.lane_offset - race.racing_line.project(record.kart.position).y) < 0.05
		for other in race.competitors:
			if other == record: continue
			grid_clear = grid_clear and record.grid.origin.distance_to(other.grid.origin) > 3
			models_unique = models_unique and record.session != other.session and record.kart.boost != other.kart.boost and record.kart.drift != other.kart.drift
		s.check(record.grid.basis.y.dot(Vector3.UP) > 0.99, "Grid kart is upright and tangent-aligned")
	s.check(grid_clear, "Staggered seven-kart grid has clear nonoverlapping collider spacing")
	s.check(models_unique, "Every competitor owns independent clocks, gates, drift and boosts")
	s.check(same_physics, "All drivers share the same KartConfig and kart/world collision rules")
	s.check(lane_continuity, "Lane transitions begin at each physical grid lane, avoiding an inward swerve before a pass")
	race.start_race()
	var all_locked := true
	for record in race.competitors: all_locked = all_locked and not record.kart.driving_enabled
	s.check(all_locked, "Every racer remains locked during the countdown")
	race._physics_process(1)
	var same_countdown := true
	for record in race.competitors: same_countdown = same_countdown and is_equal_approx(record.session.countdown_remaining, 2)
	s.check(same_countdown, "Individual racer countdown clocks mirror the shared countdown")
	race.session.advance(3)
	var all_go := true
	for record in race.competitors: all_go = all_go and record.kart.driving_enabled and record.session.race_time == 0
	s.check(all_go, "One GO transition releases every racer with identical zero clocks")
	_line_and_driver(s, race)
	_recovery(s, race)
	_lifecycle(s, race, main.get_node("HUD"))
	race.set_debug_visible(true)
	s.check(race.has_node("AIDebug") and race.ai_debug_summary().contains("Target"), "F3 exposes cached waypoints, AI target/commands and recovery telemetry")
	race.track.build()
	s.check(race.competitors.size() == 7 and race.has_node("AIDebug") and race.get_node("AIDebug").visible \
		and race.phase == RaceSession.State.READY, "Track rebuild refreshes active debug/line caches without duplicating the field")
	race.set_debug_visible(false)
	s.check(not race.get_node("AIDebug").visible, "Normal gameplay hides AI debug visualization")
	main.queue_free()
	await s.process_frame
	await _overtake(s)
	await _kart_collision(s)

func _line_and_driver(s: SceneTree, race: RaceManager) -> void:
	var line := race.racing_line
	s.check(line.points.size() > 100 and line.point_at(0).distance_to(line.point_at(line.length)) < 0.001,
		"Cached racing line closes at the finish and follows source geometry")
	var projection := line.project(line.point_at(10, 2))
	s.near(projection.y, 2, "Cached projection measures signed lateral distance", 0.1)
	var casual := RaceManager.PROFILES[0] as AIDriverProfile
	var standard := RaceManager.PROFILES[1] as AIDriverProfile
	var challenging := RaceManager.PROFILES[2] as AIDriverProfile
	s.check(casual.speed_fraction < standard.speed_fraction and standard.speed_fraction < challenging.speed_fraction,
		"Difficulty uses ordered speed decisions without changing physical caps")
	s.check(casual.braking_confidence < challenging.braking_confidence and not casual.drift_enabled and challenging.drift_enabled,
		"Profiles differ in braking, drift, recovery and steering competence")
	var sharp := 0
	for i in line.curvatures.size():
		if line.curvatures[i] > line.curvatures[sharp]: sharp = i
	var corner := line.planned_speed(sharp * line.spacing, 22, race.kart.config, standard)
	var anticipation := line.planned_speed(sharp * line.spacing - 8, 22, race.kart.config, standard)
	s.check(corner < 11 and anticipation < race.kart.config.max_forward_speed * standard.speed_fraction,
		"Curvature planning brakes ahead of a sharp corner, not only at its apex")
	s.check(line.planned_speed(sharp * line.spacing, 22, race.kart.config, casual) < line.planned_speed(sharp * line.spacing, 22, race.kart.config, challenging),
		"Corner confidence produces an observable difficulty difference")
	var record := race.competitors[1]
	var driver := record.kart.input_provider as AIInput
	# A real driver's bounded pursuit command corrects either lateral error.
	for side in [-2.0, 2.0]:
		var offset := 10.0
		record.kart.safe_spawn = Transform3D(Basis.looking_at(line.forwards[line.index_at(offset)]), line.point_at(offset, side) + Vector3.UP * 0.5)
		record.kart.reset_to_spawn()
		record.kart.velocity = -record.kart.basis.z * 16
		record.kart.signed_speed = 16
		driver.traffic = []
		driver._physics_process(1.0 / 60)
		s.check(driver.get_command().steering * side < 0, "Pure pursuit steers toward the line from either side")
		s.check(absf(driver.get_command().steering) <= driver.profile.steering_response / 60 + 0.001,
			"Steering changes are rate-limited rather than waypoint zigzags")
	race.restart_race()
	race.session.advance(3)

func _recovery(s: SceneTree, race: RaceManager) -> void:
	var record := race.competitors[1]
	var driver := record.kart.input_provider as AIInput
	var recovery := record.kart.get_node("Recovery") as KartRecovery
	var others_cursor := race.competitors[2].session.next_checkpoint
	recovery.cooldown_remaining = 0
	driver._physics_process(driver.profile.recovery_delay + 0.1)
	s.check(record.recoveries == 1 and record.session.next_checkpoint == 1, "Stalled AI requests normal recovery without granting a gate")
	s.check(race.competitors[2].session.next_checkpoint == others_cursor and race.session.next_checkpoint == 1,
		"One AI recovery cannot alter another competitor or human progress")
	driver._physics_process(driver.profile.recovery_delay + 0.1)
	s.check(record.recoveries == 1, "AI recovery obeys the shared cooldown")
	recovery.cooldown_remaining = 0
	record.kart.global_position = race.racing_line.point_at(driver.expected_offset + 12) + Vector3.UP * 0.5
	record.kart.reset_performed.emit() # Deliberately inject a lost-navigation state.
	recovery.cooldown_remaining = 0 # The injected reset signal starts its normal cooldown.
	driver._physics_process(1.3)
	s.check(record.recoveries == 2 and record.kart.global_transform.is_equal_approx(record.kart.safe_spawn),
		"Missed expected gate returns AI to its latest validated recovery transform")
	s.check(record.session.lap_times.is_empty(), "Navigation recovery never manufactures a lap")

func _cross(race: RaceManager, record: CompetitorState, index: int) -> void:
	var gate := race.gates[index]
	var length := race.racing_line.length
	var start := race.gates[record.session.latest_checkpoint].route_offset
	var distance := fposmod(gate.route_offset - start, length)
	var previous := race.track.to_global(race.track.sample_center(fposmod(start + 2, length)) + Vector3.UP * 0.6)
	var traveled := 4.0
	while traveled < distance - 2:
		var point := race.track.to_global(race.track.sample_center(fposmod(start + traveled, length)) + Vector3.UP * 0.6)
		race.process_competitor_movement(record, previous, point)
		previous = point
		traveled += 2
	var a := gate.to_global(Vector3(0, 0.6, 2))
	race.process_competitor_movement(record, previous, a)
	race.process_competitor_movement(record, a, gate.to_global(Vector3(0, 0.6, -2)))

func _finish(race: RaceManager, record: CompetitorState) -> void:
	for index in range(1, race.gates.size()):
		record.session.advance(1)
		_cross(race, record, index)
	record.session.advance(1)
	_cross(race, record, 0)

func _lifecycle(s: SceneTree, race: RaceManager, hud: RaceHUD) -> void:
	race.lap_count = 1
	for record in race.competitors: record.session.lap_count = 1
	race.restart_race()
	race.session.advance(3)
	var ai := race.competitors[1]
	_finish(race, ai)
	s.check(ai.finish_order == 1 and not ai.kart.driving_enabled and ai.kart.collision_layer == 0,
		"AI can finish first, retaining order and leaving no blocking kart at the line")
	s.check(race.session.state == RaceSession.State.RACING and race.competitors[2].kart.driving_enabled,
		"AI finish leaves human and other opponents racing")
	_finish(race, race.competitors[0])
	s.check(race.competitors[0].finish_order == 2 and race.competitors[2].session.state == RaceSession.State.RACING,
		"Human finish shows results while unfinished AI continues")
	hud._refresh()
	s.check(hud.card_text.text.contains("Rivet") and hud.card_text.text.contains("RACING") and hud.card_text.text.contains("POSITION 2"),
		"Results include ordered names, times and still-racing competitors")
	race._clock = race._first_finish + race.finish_grace_seconds
	race._physics_process(1.0 / 60)
	s.check(race.race_complete and race.competitors[2].dnf and race.competitors[2].finish_order == 0,
		"Finish grace deadline marks unfinished competitors DNF consistently")
	s.check(race.standings()[0] == ai and race.standings()[1].is_player, "Later DNF/results updates preserve the actual finishing order")
	hud._refresh()
	s.check(hud.card_text.text.contains("DNF"), "Results display DNF distinctly from completed times")
	race.restart_race()
	var cleared := true
	for record in race.competitors:
		cleared = cleared and record.session.state == RaceSession.State.COUNTDOWN and record.session.lap_times.is_empty() \
			and record.session.race_time == 0 and record.finish_order == 0 and not record.dnf and record.kart.collision_layer == 2 \
			and record.kart.global_transform.is_equal_approx(record.grid) and record.kart.velocity == Vector3.ZERO
		if record.kart.input_provider is AIInput:
			var driver := record.kart.input_provider as AIInput
			cleared = cleared and driver._time == 0 and driver._pass_hold == 0 and driver.lane_target == 0 \
				and driver.target_speed == 0 and not driver.get_command().drift
	s.check(cleared, "Restart restores every grid pose, clock, gate, collision, finish and DNF state")
	# Ranking is route-validated, not proximity to finish.
	var a := race.competitors[0]
	var b := race.competitors[1]
	a.session.lap_times.append(30)
	b.session.next_checkpoint = race.gates.size()
	race._update_ranking()
	s.check(race.standings()[0] == a, "Completed laps outrank a physically nearer finish on an earlier lap")
	a.session.lap_times.clear()
	a.session.next_checkpoint = 4
	b.session.next_checkpoint = 3
	b.segment_progress = 0.999
	race._update_ranking()
	s.check(race.standings()[0] == a, "Validated checkpoint count outranks fractional physical progress")
	var units := a.progress_units(race.gates.size())
	race.process_competitor_movement(a, a.kart.position, Vector3(1000, 1, 1000))
	s.near(a.progress_units(race.gates.size()), units, "Unsupported shortcut teleport cannot increase rank")
	race.restart_race()
	a.finish_timestamp = 20.012
	b.finish_timestamp = 20.002
	race._pending.assign([a, b])
	race._flush_finishes()
	s.check(b.finish_order == 1 and a.finish_order == 2, "Subtick crossing time orders same-tick finishes independently of iteration order")
	race.return_to_ready()

func _overtake(s: SceneTree) -> void:
	var main := load("res://scenes/main.tscn").instantiate() as Node3D
	var race := main.get_node("RaceManager") as RaceManager
	race.opponent_count = 1
	s.root.add_child(main)
	race.set_physics_process(false)
	race.start_race()
	race.session.advance(3)
	var slow := race.kart
	var ai := race.competitors[1].kart
	var driver := ai.input_provider as AIInput
	var input := SlowInput.new()
	input.kart = slow
	slow.add_child(input)
	slow.input_provider = input
	var offset := race.racing_line.length * 0.76
	for index in 2:
		var body := slow if index == 0 else ai
		var position := offset + (12 if index == 0 else 0)
		body.safe_spawn = Transform3D(Basis.looking_at(race.racing_line.forwards[race.racing_line.index_at(position)]),
			race.racing_line.point_at(position) + Vector3.UP * 0.6)
		body.reset_to_spawn()
	var side_changes := 0
	var previous_side := 0
	var passed := false
	var saw_pass := false
	for i in 360:
		await s.physics_frame
		if driver.passing_side != 0:
			saw_pass = true
			if previous_side != 0 and driver.passing_side != previous_side: side_changes += 1
			previous_side = driver.passing_side
		var forward := race.racing_line.forwards[race.racing_line.index_at(driver.current_offset)]
		passed = passed or (ai.position - slow.position).dot(forward) > 4
	s.check(saw_pass and passed, "Real AI commands physically overtake a slower kart on a straight")
	s.check(side_changes == 0, "Passing target holds its side without repeated left-right oscillation")
	s.check(absf(driver.lane_offset) < 1.0, "AI returns toward the racing line after completing the pass")
	main.queue_free()
	await s.process_frame

func _kart_collision(s: SceneTree) -> void:
	var main := load("res://scenes/main.tscn").instantiate() as Node3D
	var race := main.get_node("RaceManager") as RaceManager
	race.opponent_count = 1
	s.root.add_child(main)
	race.set_physics_process(false)
	race.start_race()
	race.session.advance(3)
	var human := race.kart
	var opponent := race.competitors[1].kart
	opponent.set_physics_process(false)
	opponent.input_provider.set_physics_process(false)
	var offset := race.racing_line.length * 0.76
	var forward := race.racing_line.forwards[race.racing_line.index_at(offset)]
	human.safe_spawn = Transform3D(Basis.looking_at(forward), race.racing_line.point_at(offset) + Vector3.UP * 0.6)
	human.reset_to_spawn()
	opponent.safe_spawn = Transform3D(Basis.looking_at(forward), race.racing_line.point_at(offset + 5) + Vector3.UP * 0.376)
	opponent.reset_to_spawn()
	for i in 20: await s.physics_frame
	Input.action_press("accelerate")
	for i in 90: await s.physics_frame
	Input.action_release("accelerate")
	s.check((opponent.position - human.position).dot(forward) > 1.9 and absf(human.signed_speed) < 2,
		"Real CharacterBody kart-to-kart collision blocks motion without passing through")
	main.queue_free()
	await s.process_frame
