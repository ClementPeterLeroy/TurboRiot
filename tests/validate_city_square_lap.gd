extends SceneTree
## Native application lap with physical AI input and the player's chase camera.
## Do not use --fixed-fps: this is also a real-time presentation smoke check.
func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var prefix := "v061_city"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--report-prefix="):prefix=arg.get_slice("=",1).validate_filename()
	var app := load("res://scenes/app.tscn").instantiate() as TurboApplication
	app.settings.path = "res://.godot/city_lap_settings.cfg"
	app.auto_pause_on_focus_loss = false
	root.add_child(app)
	app.settings.vsync = false
	app.settings.resolution = Vector2i(1920, 1080)
	app.settings.apply_display(root)
	var setup := RaceSetup.new()
	setup.mode = RaceSetup.Mode.TIME_TRIAL
	setup.circuit_id = &"delfino_square_ds"
	setup.laps = 1
	await app.start_session(setup)
	var race := app.game.get_node("RaceManager") as RaceManager
	var driver := AIInput.new()
	driver.kart = race.kart
	# Like a real AI competitor, follow one directed route. The human progress
	# line also projects alternatives, which must not change an AI's target path.
	driver.line = race._driver_line(0)
	driver.profile = RaceManager.PROFILES[2]
	driver.recovery_requested.connect(race._on_ai_recovery.bind(race.competitors[0]))
	race.kart.add_child(driver)
	race.kart.input_provider = driver
	race._update_driver_gates(race.competitors[0])
	race.start_race()
	var camera := app.game.get_node("ChaseCamera") as Camera3D
	var blockers: Dictionary = {}
	var sampled_frames := 0
	for tick in 15000:
		if race.race_complete:
			break
		await physics_frame
		var origin := race.kart.global_position + Vector3.UP
		var query := PhysicsRayQueryParameters3D.create(origin, camera.global_position, 1, [race.kart.get_rid()])
		var hit := race.kart.get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty():
			var key := str(hit.collider.get_path())
			blockers[key] = int(blockers.get(key, 0)) + 1
		sampled_frames += 1
		if tick == 900:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://artifacts/%s_native_lap.png"%prefix)
	var passed := race.race_complete and race.session.lap_times.size() == 1 and not race.competitors[0].dnf and race.competitors[0].recoveries == 0 and blockers.is_empty()
	var report := {"passed": passed, "lap_time": race.session.final_time, "recoveries": race.competitors[0].recoveries,
		"camera_obstructions": blockers, "physics_samples": sampled_frames, "resolution": [1920, 1080], "native_rendering": true}
	FileAccess.open("res://artifacts/%s_native_lap.json"%prefix, FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	print("CITY_NATIVE_LAP ", JSON.stringify(report))
	app.queue_free()
	for i in 10:
		await process_frame
	quit(0 if passed else 1)
