extends SceneTree
var app: TurboApplication
var failures := 0

func _initialize() -> void: _run.call_deferred()

func _save(name: String) -> void:
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/alpha_%s.png" % name)

func _check(value: bool, label: String) -> void:
	print("ALPHA NATIVE %s: %s" % [label, value])
	if not value:
		failures += 1
		push_error("Native alpha validation failed: " + label)

func _autopilot(race: RaceManager) -> void:
	var driver := AIInput.new()
	driver.name = "PreviewDriver"
	driver.kart = race.kart
	driver.line = race.racing_line
	driver.profile = RaceManager.PROFILES[race.difficulty]
	for record in race.competitors: driver.traffic.append(record.kart)
	driver.recovery_requested.connect(race._on_ai_recovery.bind(race.competitors[0]))
	race.kart.add_child(driver)
	race.kart.input_provider = driver
	race._update_driver_gates(race.competitors[0])

func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts")
	var path := "res://.godot/alpha_preview_settings.cfg"
	if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	app = load("res://scenes/app.tscn").instantiate()
	app.settings.path = path
	app.auto_pause_on_focus_loss = false # Automation drives the window; real app default is true.
	root.add_child(app)
	app.settings.vsync = false
	app.settings.apply_display(root)
	app.audio.play(&"confirm")
	app.audio.unbind_race()
	_check(app.audio._ui_voices.any(func(voice: AudioStreamPlayer) -> bool: return voice.playing), "menu cue survives race-audio reset")
	await _save("home_720")
	app.show_configuration(RaceSetup.Mode.QUICK_RACE)
	await _save("configuration")
	app.show_credits()
	await _save("credits")
	app.show_settings("home")
	await _save("settings")
	app.menu.focusables[-2].grab_focus()
	await _save("settings_controls")
	app.settings.resolution = Vector2i(1024, 768)
	app.settings.ui_scale = 1.25
	app.settings.apply_display(root)
	app.show_home()
	await _save("home_4_3_scaled")
	_check(root.size == Vector2i(1024, 768), "4:3 window resize")
	app.settings.fullscreen = true
	app.settings.apply_display(root)
	for i in 10: await process_frame
	_check(DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN, "fullscreen transition")
	app.settings.fullscreen = false
	app.settings.resolution = Vector2i(1920, 1080)
	app.settings.ui_scale = 1
	app.settings.apply_display(root)
	await _save("home_1080")
	_check(DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED, "return to windowed")
	app.settings.resolution = Vector2i(1280, 720)
	app.settings.apply_display(root)
	var setup := RaceSetup.new()
	setup.laps = 1
	await app.start_session(setup)
	await _save("ready")
	var race := app.game.get_node("RaceManager") as RaceManager
	_autopilot(race)
	race.start_race()
	for i in 45: await physics_frame
	await _save("countdown")
	for i in 240: await physics_frame
	_check(app.audio.engine.playing, "single persistent engine loop")
	await _save("racing")
	app.pause_session()
	var clock := race.session.race_time
	await _save("pause")
	app.show_settings("pause")
	await _save("pause_settings")
	_check(race.session.race_time == clock and app.audio.engine.stream_paused, "paused race clock and engine")
	app.close_settings()
	app.resume_session()
	for i in 10000:
		if race.race_complete: break
		await physics_frame
	var passed := race.race_complete
	for record in race.competitors: passed = passed and record.finish_order > 0 and not record.dnf
	_check(passed, "seven physical racers complete one lap through application")
	await _save("results")
	app.return_home()
	setup.mode = RaceSetup.Mode.TIME_TRIAL
	await app.start_session(setup)
	await _save("time_trial_ready")
	_check(app.game.get_node("RaceManager").competitors.size() == 1 and not app.game.get_node("Items").enabled, "Time Trial initialization")
	race = app.game.get_node("RaceManager")
	_autopilot(race)
	race.start_race()
	for i in 6000:
		if race.race_complete: break
		await physics_frame
	_check(race.race_complete and not race.competitors[0].dnf and race.session.lap_times.size() == 1, "physical Time Trial completion")
	await _save("time_trial_results")
	await app.start_session(setup, true)
	for i in 10: await physics_frame
	app.pause_session()
	await app.start_session(setup, true)
	_check(app.audio.engine.playing and not app.audio.engine.stream_paused, "restart from pause restores engine audio")
	app.return_home()
	app.queue_free()
	for i in 12: await process_frame
	if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("ALPHA NATIVE failures=", failures)
	quit(1 if failures else 0)
