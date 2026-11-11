extends SceneTree
var failures := 0
func _initialize() -> void: _run.call_deferred()

func save(name: String) -> void:
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/v061_%s.png" % name)

func _run() -> void:
	var app := load("res://scenes/app.tscn").instantiate() as TurboApplication
	app.settings.path = "res://.godot/v061_preview_settings.cfg"
	app.auto_pause_on_focus_loss = false
	root.add_child(app)
	app.settings.vsync = false
	app.settings.resolution = Vector2i(1280,720)
	app.settings.apply_display(root)
	var setup := RaceSetup.new()
	setup.laps = 1
	app.show_circuits(setup)
	await save("circuit_selection")
	setup.circuit_id = &"yoshi_ds"
	app.show_circuits(setup)
	await save("circuit_selection_yoshi")
	app.settings.resolution = Vector2i(1024,768)
	app.settings.ui_scale = 1.25
	app.settings.apply_display(root)
	await save("circuit_selection_4_3")
	app.settings.resolution = Vector2i(1280,720)
	app.settings.ui_scale = 1
	app.settings.apply_display(root)
	for id in [&"figure_8",&"yoshi_ds"]:
		setup.mode = RaceSetup.Mode.TIME_TRIAL
		setup.circuit_id = id
		await app.start_session(setup)
		await save("%s_ready" % id)
		var race := app.game.get_node("RaceManager") as RaceManager
		var driver := AIInput.new()
		driver.kart = race.kart
		driver.line = race.racing_line
		driver.profile = RaceManager.PROFILES[2]
		driver.recovery_requested.connect(race._on_ai_recovery.bind(race.competitors[0]))
		race.kart.add_child(driver)
		race.kart.input_provider = driver
		race._update_driver_gates(race.competitors[0])
		race.start_race()
		for tick in 15000:
			if race.race_complete: break
			await physics_frame
			if tick == 900: await save("%s_minimap" % id)
		var passed: bool = race.race_complete and race.session.lap_times.size()==1 and not race.competitors[0].dnf and not app.game.get_node("Items").enabled
		print("V061 NATIVE TIME TRIAL %s passed=%s time=%.3f recoveries=%d" % [id,passed,race.session.final_time,race.competitors[0].recoveries])
		if not passed: failures += 1
		await save("%s_time_trial_results" % id)
		app.return_home()
	app.queue_free()
	for i in 10: await process_frame
	print("V061 NATIVE failures=",failures)
	quit(1 if failures else 0)
