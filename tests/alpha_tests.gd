extends RefCounted

func run(s: SceneTree) -> void:
	_configuration(s)
	_settings(s)
	_audio_assets(s)
	await _application(s)

func _configuration(s: SceneTree) -> void:
	var setup := RaceSetup.new()
	s.check(setup.laps == 3 and setup.opponents == 6, "Alpha race defaults retain three laps and six opponents")
	setup.opponents = 99
	setup.difficulty = -8
	setup.laps = 0
	setup.controller = 99
	var valid := setup.validated()
	s.check(valid.opponents == 6 and valid.difficulty == 0 and valid.laps == 1 and valid.controller == -2, "Race setup validates supported limits before spawning")
	s.check(setup.opponents == 99 and valid != setup, "Validated session is independent of editable configuration")
	setup.mode = RaceSetup.Mode.TIME_TRIAL
	valid = setup.validated()
	s.check(valid.opponents == 0 and not valid.items_enabled(), "Time Trial forces one human and disables competitive items")
	setup.mode = RaceSetup.Mode.QUICK_RACE
	s.check(setup.items_enabled(), "Quick Race retains competitive items even with zero opponents")

func _settings(s: SceneTree) -> void:
	var settings := AppSettings.new()
	settings.path = "res://.godot/alpha_settings_test.cfg"
	settings.fullscreen = true
	settings.resolution = Vector2i(1024, 768)
	settings.vsync = false
	settings.ui_scale = 1.1
	settings.volumes.Music = 0.23
	settings.muted.Effects = true
	s.check(settings.save_settings() == OK, "Settings persist through ConfigFile")
	var restored := AppSettings.new()
	restored.path = settings.path
	s.check(restored.load_settings() == OK and restored.fullscreen and restored.resolution == Vector2i(1024, 768) and not restored.vsync, "Display configuration survives a fresh settings instance")
	s.near(restored.ui_scale, 1.1, "UI scale persists")
	s.check(is_equal_approx(restored.volumes.Music, 0.23) and restored.muted.Effects, "Independent volume/mute settings persist")
	var invalid := ConfigFile.new()
	invalid.set_value("display", "resolution", "broken")
	invalid.set_value("display", "fullscreen", 44)
	invalid.set_value("display", "vsync", "yes")
	invalid.set_value("display", "ui_scale", NAN)
	invalid.set_value("audio", "Master", INF)
	invalid.set_value("audio", "Music", 5)
	invalid.set_value("audio", "Effects", "loud")
	invalid.set_value("audio", "Effects_muted", 1)
	invalid.save(settings.path)
	restored = AppSettings.new()
	restored.path = settings.path
	restored.load_settings()
	s.check(restored.resolution == Vector2i(1280, 720) and not restored.fullscreen and restored.vsync and restored.ui_scale == 1, "Invalid display values safely use defaults")
	s.check(restored.volumes.Master == 0.8 and restored.volumes.Music == 1 and restored.volumes.Effects == 0.7 and not restored.muted.Effects, "Invalid audio values fall back or clamp safely")
	var file := FileAccess.open(settings.path, FileAccess.WRITE)
	file.store_string("not a valid [config")
	file.close()
	restored = AppSettings.new()
	restored.path = settings.path
	restored.load_settings()
	s.check(restored.resolution == Vector2i(1280, 720) and restored.ui_scale == 1, "Unrecognized settings contents retain usable defaults")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(settings.path))
	settings.path = "res://.godot/alpha_missing_folder/settings.cfg"
	s.check(settings.save_settings() != OK, "Unwritable settings report failure instead of pretending to save")

func _audio_assets(s: SceneTree) -> void:
	for event: StringName in AudioDirector.EVENTS + [&"music"]:
		var wave := RiotSounds.sound(event)
		s.check(wave.data.size() > 0 and wave.mix_rate == 22050 and wave == RiotSounds.sound(event), "Synthesized cue/loop is valid and shared: " + str(event))
	s.check(RiotSounds.sound(&"engine").loop_mode == AudioStreamWAV.LOOP_FORWARD and RiotSounds.sound(&"music").loop_mode == AudioStreamWAV.LOOP_FORWARD, "Engine and music loop without per-frame restarts")
	var peak := 0
	for index in range(0, RiotSounds.sound(&"engine").data.size(), 2): peak = maxi(peak, absi(RiotSounds.sound(&"engine").data.decode_s16(index)))
	s.check(peak < 16384, "Engine placeholder preserves substantial audio headroom")

func _frames(s: SceneTree, count := 3) -> void:
	for i in count: await s.process_frame

func _key(s: SceneTree, key: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = key
		event.physical_keycode = key
		event.pressed = pressed
		s.root.push_input(event)
	await _frames(s)

func _application(s: SceneTree) -> void:
	var app := load("res://scenes/app.tscn").instantiate() as TurboApplication
	app.settings.path = "res://.godot/alpha_app_test_settings.cfg"
	s.root.add_child(app)
	await _frames(s)
	s.check(app.screen == "home" and app.game == null and app.menu.focusables.size() == 5, "Application starts with one navigable five-entry main menu")
	var first := app.menu.focusables[0]
	s.check(s.root.gui_get_focus_owner() == first, "Initial menu has visible keyboard/controller focus")
	await _key(s, KEY_DOWN)
	s.check(s.root.gui_get_focus_owner() == app.menu.focusables[1], "Keyboard navigation follows menu focus order")
	await _key(s, KEY_ENTER)
	s.check(app.screen == "config" and app.menu.heading.text == "TIME TRIAL", "Keyboard confirmation opens Time Trial configuration")
	await _key(s, KEY_ESCAPE)
	s.check(app.screen == "home", "Escape returns to the parent menu without exiting")
	for pressed in [true, false]:
		var pad := InputEventJoypadButton.new()
		pad.device = 0
		pad.button_index = JOY_BUTTON_DPAD_DOWN
		pad.pressed = pressed
		s.root.push_input(pad)
	await _frames(s)
	s.check(s.root.gui_get_focus_owner() == app.menu.focusables[1], "Injected D-pad event navigates the same menu focus graph")
	for button in [JOY_BUTTON_A, JOY_BUTTON_B]:
		for pressed in [true, false]:
			var event := InputEventJoypadButton.new()
			event.button_index = button
			event.pressed = pressed
			s.root.push_input(event)
		await _frames(s)
		s.check(app.screen == ("config" if button == JOY_BUTTON_A else "home"), "Injected controller confirm/back follows menu navigation")
	var quick := app.menu.focusables[0]
	for pressed in [true, false]:
		var click := InputEventMouseButton.new()
		click.position = quick.get_global_rect().get_center()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = pressed
		s.root.push_input(click)
	await _frames(s)
	s.check(app.screen == "config", "Mouse click reaches Quick Race through actual GUI routing")
	app.show_home()
	app.show_settings("home")
	var sliders: Array[HSlider] = []
	var toggles: Array[CheckBox] = []
	for child in app.menu.body.get_children():
		if child is HSlider: sliders.append(child)
		if child is CheckBox: toggles.append(child)
	sliders[2].value = 0.19 # UI scale, Master, then Music.
	toggles[4].button_pressed = true # Fullscreen, VSync, then three mutes.
	s.check(app._draft.volumes.Music == 0.19 and app._draft.volumes.Master == 0.8 and app._draft.volumes.Effects == 0.7, "Audio slider callbacks update only their own category")
	s.check(app._draft.muted.Effects and not app._draft.muted.Music, "Mute UI callbacks stay category-local")
	app.apply_settings()
	s.check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Effects")) and not AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")), "Audio categories mute independently")
	s.near(db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))), 0.19, "Music bus applies its own saved volume")
	app._draft.volumes.Music = 0.9
	app._draft.apply_audio()
	app.close_settings()
	s.check(app.screen == "home" and app.settings.volumes.Music == 0.19, "Back cancels unsaved audio edits")
	app.settings.muted.Effects = false
	app.settings.apply_audio()
	var setup := RaceSetup.new()
	setup.opponents = 1
	setup.laps = 1
	app.start_session(setup)
	s.check(app.transitioning and app.screen == "loading", "Launching presents a distinct initialization screen")
	app.return_home()
	await _frames(s)
	s.check(app.game == null and app.screen == "home", "Cancelled loading cannot create a stale hidden race")
	await app.start_session(setup)
	await _frames(s)
	var race := app.game.get_node("RaceManager") as RaceManager
	var kart := race.kart
	s.check(race.competitors.size() == 2 and race.lap_count == 1 and race.difficulty == setup.difficulty and race.competitors[1].kart.input_provider.profile == RaceManager.PROFILES[setup.difficulty], "Session settings and selected driver profile are applied before racer initialization")
	s.check(race.session.state == RaceSession.State.READY and not kart.driving_enabled, "Configured race enters READY with controls locked")
	race.start_race()
	for i in 35: await s.physics_frame
	var countdown := race.session.countdown_remaining
	app.pause_session()
	for i in 25: await s.physics_frame
	s.check(race.session.countdown_remaining == countdown and s.paused and app.screen == "pause", "Pause freezes countdown while menu remains active")
	app.show_settings("pause")
	app.close_settings()
	s.check(s.paused and app.screen == "pause", "Closing pause settings returns to pause, never running the race")
	app.resume_session()
	for i in 155: await s.physics_frame
	s.check(race.session.state == RaceSession.State.RACING and kart.driving_enabled, "Resume completes the synchronized countdown and enables driving")
	s.check(int(app.audio.events.get(&"countdown", 0)) == 3 and int(app.audio.events.get(&"go", 0)) == 1, "Countdown produces three beeps and exactly one GO event")
	var hits_before := int(app.audio.events.get(&"item_hit", 0))
	app.audio.play(&"item_hit", kart.global_position + Vector3.RIGHT * 100)
	app.audio.play(&"item_hit", kart.global_position)
	s.check(int(app.audio.events.get(&"item_hit", 0)) == hits_before + 1, "Inaudible distant events cannot suppress a nearby player's feedback")
	var provider := kart.input_provider
	provider.assigned_device = -1
	for pressed in [true, false]:
		var keyboard := InputEventKey.new()
		keyboard.keycode = KEY_W
		keyboard.physical_keycode = KEY_W
		keyboard.pressed = pressed
		Input.parse_input_event(keyboard)
		Input.flush_buffered_events()
		s.check(provider.get_command().throttle == (1.0 if pressed else 0.0), "Keyboard-only assignment reads and releases physical-key input events")
	provider.assigned_device = 15
	Input.action_press("accelerate")
	s.check(provider.get_command().throttle == 0, "Unavailable assigned controller does not borrow keyboard/all-pad action state")
	Input.action_release("accelerate")
	provider.assigned_device = -2
	var mini_before := int(app.audio.events.get(&"mini_turbo", 0))
	for i in 2:
		kart.activate_boost(&"mini_turbo", 1.3, 1)
		app.audio._process(0.1)
	s.check(int(app.audio.events.get(&"mini_turbo", 0)) == mini_before + 2, "Accepted same-source mini-turbo refreshes each produce an audio cue")
	var items := app.game.get_node("Items") as ItemSystem
	var inventory := kart.get_node("Inventory") as KartInventory
	inventory.pickup(ItemCatalog.ITEMS[0])
	Input.action_press("use_item")
	app.pause_session()
	app.resume_session()
	for i in 5: await s.physics_frame
	s.check(inventory.held != null, "Resume/Back cannot accidentally consume an item while its button is held")
	Input.action_release("use_item")
	for i in 2: await s.physics_frame
	Input.action_press("use_item")
	for i in 2: await s.physics_frame
	Input.action_release("use_item")
	s.check(inventory.held == null and kart.boost.mushroom_remaining > 0, "Item input re-arms normally after release")
	inventory.pickup(ItemCatalog.ITEMS[2])
	items.activate(kart, inventory)
	kart.receive_item_hit(Vector3.RIGHT, 1.35, 0.55, 0.24, 0.55, 360)
	items.rows[0].boxes[0].try_collect(kart)
	for i in 2: await s.physics_frame
	var actor := items.actors[0]
	var snapshot := [race.session.race_time, kart.global_transform, kart.boost.remaining, kart.effects.remaining,
		actor.age, race.competitors[1].kart.global_transform, items.rows[0].boxes[0].remaining]
	app.pause_session()
	for i in 45: await s.physics_frame
	var after := [race.session.race_time, kart.global_transform, kart.boost.remaining, kart.effects.remaining,
		actor.age, race.competitors[1].kart.global_transform, items.rows[0].boxes[0].remaining]
	s.check(snapshot == after, "Pause freezes race clock, kart/AI transforms, boosts, spin, projectiles and box respawn")
	s.check(app.menu.focusables.size() == 4 and s.root.gui_get_focus_owner() != null, "Pause UI remains focusable while all gameplay is frozen")
	var old_game := app.game
	await app.start_session(app.setup, true)
	await _frames(s)
	s.check(not is_instance_valid(old_game) and not is_instance_valid(actor) and not s.paused, "Restart disposes old race and projectiles and clears pause")
	race = app.game.get_node("RaceManager")
	s.check(race.session.state == RaceSession.State.COUNTDOWN and race.session.lap_times.is_empty() and race.session.next_checkpoint == 1, "Restart creates fresh countdown/progress instead of reusing models")
	s.check(app.game.get_node("Items").actors.is_empty() and race.kart.get_node("Inventory").held == null and not race.kart.effects.active(), "Fresh race has no stale item/spin/inventory state")
	app.return_home()
	setup.mode = RaceSetup.Mode.TIME_TRIAL
	setup.opponents = 6
	await app.start_session(setup)
	race = app.game.get_node("RaceManager")
	s.check(race.competitors.size() == 1 and not app.game.get_node("Items").enabled and app.game.get_node("Items").rows.is_empty(), "Time Trial spawns no AI, loot or competitive item system")
	race.start_race()
	race.session.advance(3)
	var finishes_before := int(app.audio.events.get(&"finish", 0))
	for gate in range(1, race.gates.size()): race.session.cross_checkpoint(gate)
	race.session.advance(1)
	race.session.cross_checkpoint(0)
	await _frames(s)
	var hud := app.game.get_node("HUD") as RaceHUD
	s.check(hud.card.visible and hud.card_title.text == "TIME TRIAL RESULTS" and race.session.lap_times.size() == 1, "Ordered model completion opens distinct Time Trial results")
	s.check(not race.session.cross_checkpoint(0) and int(app.audio.events.get(&"finish", 0)) == finishes_before + 1, "Completed race cannot duplicate finish/audio events")
	s.check(hud.ready_button.text == "Main Menu" and hud.primary.text == "Restart Race", "Results expose fresh restart and main-menu navigation")
	s.check(not race.is_physics_processing() and app.game.get_node("Items").process_mode == Node.PROCESS_MODE_DISABLED and app.game.get_node("Items").actors.is_empty(), "Overall completion seals race/item timers while keeping results UI alive")
	await _key(s, KEY_UP)
	s.check(s.root.gui_get_focus_owner() == hud.get_node("Overlay/Center/Card/Stack/Scroll"), "Results details are reachable through keyboard/controller focus")
	await _key(s, KEY_RIGHT)
	s.check(s.root.gui_get_focus_owner() == hud.primary, "Results scrolling has a clear path back to action buttons")
	hud.menu_requested.emit()
	await _frames(s)
	s.check(app.game == null and app.screen == "home" and app._world.get_child_count() == 0, "Results Main Menu disposes the active race subtree")
	s.check(app.quick_setup.opponents == 1 and app.trial_setup.validated().opponents == 0, "Time Trial configuration cannot leak its zero opponents into Quick Race preferences")
	for i in 3:
		await app.start_session(setup)
		s.check(app._world.get_child_count() == 1, "Repeated launch keeps exactly one race")
		app.return_home()
		await _frames(s)
		s.check(app.audio.race == null and app.audio._connections.is_empty() and not app.audio.engine.playing, "Returning home unbinds signals and stops race audio")
	await app.start_session(setup)
	app.notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	s.check(s.paused and app.screen == "pause", "Focus loss automatically pauses a live session")
	app.return_home()
	app.queue_free()
	await _frames(s)
	s.paused = false
	s.auto_accept_quit = true
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://.godot/alpha_app_test_settings.cfg"))
