class_name TurboApplication
extends Node
const RACE := preload("res://scenes/main.tscn")
const MENU := preload("res://scenes/ui/alpha_menu.tscn")
var settings := AppSettings.new()
var setup := RaceSetup.new()
var quick_setup := RaceSetup.new()
var trial_setup := RaceSetup.new()
var audio := AudioDirector.new()
var menu: AlphaMenu
var game: Node3D
var screen := "home"
var transitioning := false
var auto_pause_on_focus_loss := true
var _world := Node.new()
var _generation := 0
var _settings_back := "home"
var _draft: AppSettings
var _controller_ids: Array[int] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().auto_accept_quit = false
	get_window().min_size = Vector2i(960, 540)
	add_child(audio)
	settings.load_settings()
	settings.apply_audio()
	settings.apply_display(get_window())
	add_child(_world)
	var canvas := CanvasLayer.new()
	canvas.layer = 10
	add_child(canvas)
	menu = MENU.instantiate()
	canvas.add_child(menu)
	menu.cue_requested.connect(audio.play)
	_bind_pause()
	Input.joy_connection_changed.connect(_on_controller_connection)
	show_home()

func _bind_pause() -> void:
	for pair in [["ui_accept", JOY_BUTTON_A], ["ui_cancel", JOY_BUTTON_B]]:
		var navigation := InputEventJoypadButton.new()
		navigation.device = -1
		navigation.button_index = pair[1]
		if not InputMap.action_has_event(pair[0], navigation): InputMap.action_add_event(pair[0], navigation)
	if InputMap.has_action("pause_race"): return
	InputMap.add_action("pause_race")
	var key := InputEventKey.new()
	key.physical_keycode = KEY_ESCAPE
	InputMap.action_add_event("pause_race", key)
	var pad := InputEventJoypadButton.new()
	pad.button_index = JOY_BUTTON_START
	InputMap.action_add_event("pause_race", pad)

func show_home() -> void:
	screen = "home"
	menu.page("TURBO RIOT", "PLAYABLE ALPHA  /  v0.6.0-dev")
	menu.button("Quick Race", func() -> void: show_configuration(RaceSetup.Mode.QUICK_RACE))
	menu.button("Time Trial", func() -> void: show_configuration(RaceSetup.Mode.TIME_TRIAL))
	menu.button("Settings", func() -> void: show_settings("home"))
	menu.button("Credits", show_credits)
	menu.button("Exit Game", quit_game)
	menu.finish()

func show_configuration(mode: RaceSetup.Mode) -> void:
	screen = "config"
	var draft := quick_setup.validated() if mode == RaceSetup.Mode.QUICK_RACE else trial_setup.validated()
	draft.mode = mode
	menu.page("TIME TRIAL" if mode == RaceSetup.Mode.TIME_TRIAL else "QUICK RACE", "Single player / Circuit 01")
	var opponents: OptionButton
	var difficulty: OptionButton
	if mode == RaceSetup.Mode.QUICK_RACE:
		opponents = menu.option("AI opponents", [0, 1, 2, 3, 4, 5, 6], draft.opponents)
		difficulty = menu.option("AI difficulty", ["Casual", "Standard", "Challenging"], draft.difficulty)
	else: menu.text("No AI or competitive items. Complete ordered laps against the clock.")
	var lap_options: Array = []
	for count in range(1, 21): lap_options.append(count)
	var laps := menu.option("Laps", lap_options, draft.laps - 1)
	_controller_ids.assign([-2, -1])
	var devices: Array = ["Keyboard + any controller", "Keyboard only"]
	for device in Input.get_connected_joypads():
		_controller_ids.append(device)
		devices.append("Controller %d: %s" % [device + 1, Input.get_joy_name(device)])
	var selected := _controller_ids.find(draft.controller)
	var controller := menu.option("Player controls", devices, maxi(0, selected))
	menu.button("Start Race", func() -> void:
		draft.opponents = opponents.selected if is_instance_valid(opponents) else 0
		draft.difficulty = difficulty.selected if is_instance_valid(difficulty) else draft.difficulty
		draft.laps = laps.selected + 1
		draft.controller = _controller_ids[controller.selected]
		start_session(draft))
	menu.button("Back", show_home, true)
	menu.finish()

func start_session(request: RaceSetup, countdown := false) -> void:
	if transitioning: return
	transitioning = true
	_generation += 1
	var generation := _generation
	_dispose_game()
	setup = request.validated()
	if setup.controller >= 0 and setup.controller not in Input.get_connected_joypads(): setup.controller = -2
	if setup.mode == RaceSetup.Mode.QUICK_RACE: quick_setup = setup.validated()
	else: trial_setup = setup.validated()
	screen = "loading"
	menu.page("PREPARING THE GRID", "Loading the circuit and racers...")
	menu.button("Cancel", return_home, true)
	menu.finish()
	await get_tree().process_frame
	await get_tree().process_frame # Present loading before procedural initialization.
	if generation != _generation: return
	var instance := RACE.instantiate() as Node3D
	instance.managed = true
	instance.process_mode = Node.PROCESS_MODE_PAUSABLE
	var race := instance.get_node("RaceManager") as RaceManager
	race.opponent_count = setup.opponents
	race.difficulty = setup.difficulty
	race.lap_count = setup.laps
	race.ai_only = false
	race.driver_profile_override = null
	race.race_timeout_seconds = maxf(480, setup.laps * 120)
	race.use_command_line_configuration = false
	var items := instance.get_node("Items") as ItemSystem
	items.enabled = setup.items_enabled()
	items.external_audio = true
	instance.get_node("Kart/PlayerInput").assigned_device = setup.controller
	var hud := instance.get_node("HUD") as RaceHUD
	hud.managed = true
	hud.time_trial = setup.mode == RaceSetup.Mode.TIME_TRIAL
	hud.restart_requested.connect(restart_session)
	hud.menu_requested.connect(return_home)
	_world.add_child(instance)
	game = instance
	for button: Button in [hud.primary, hud.ready_button]:
		button.theme = menu.theme
		button.custom_minimum_size.y = 44
	audio.bind_race(race, items)
	race.field_completed.connect(_seal_results)
	menu.visible = false
	screen = "race"
	transitioning = false
	if countdown: race.start_race()
	else: hud.focus_primary.call_deferred()

func _dispose_game() -> void:
	audio.unbind_race()
	get_tree().paused = false
	Engine.max_fps = 0
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if settings.vsync else DisplayServer.VSYNC_DISABLED)
	if is_instance_valid(game):
		game.process_mode = Node.PROCESS_MODE_DISABLED
		_world.remove_child(game)
		game.queue_free()
	game = null

func restart_session() -> void:
	start_session(setup, true)

func _seal_results() -> void:
	if not is_instance_valid(game): return
	var items := game.get_node("Items") as ItemSystem
	items.reset_items()
	items.process_mode = Node.PROCESS_MODE_DISABLED
	game.get_node("RaceManager").set_physics_process(false)

func return_home() -> void:
	_generation += 1
	transitioning = false
	_dispose_game()
	settings.apply_audio()
	show_home()

func pause_session() -> void:
	if not is_instance_valid(game) or transitioning: return
	get_tree().paused = true
	game.get_node("HUD").visible = false
	audio.pause_audio(true)
	screen = "pause"
	menu.page("PAUSED", "The race, AI, items and effect timers are stopped.", true)
	menu.button("Resume", resume_session)
	menu.button("Restart Race", restart_session)
	menu.button("Settings", func() -> void: show_settings("pause"))
	menu.button("Main Menu", return_home, true)
	menu.finish()

func resume_session() -> void:
	if not is_instance_valid(game):
		return_home()
		return
	game.get_node("Kart/PlayerInput").suppress_item_until_release = true
	game.get_node("HUD").visible = true
	menu.visible = false
	screen = "race"
	audio.pause_audio(false)
	get_tree().paused = false

func show_settings(back: String) -> void:
	_settings_back = back
	_draft = settings.copy()
	screen = "settings"
	menu.page("SETTINGS", "Apply to save. Back cancels unsaved changes.", back == "pause")
	var fullscreen := menu.toggle("Fullscreen", _draft.fullscreen)
	fullscreen.toggled.connect(func(value: bool) -> void: _draft.fullscreen = value)
	var sizes: Array = []
	for resolution: Vector2i in AppSettings.RESOLUTIONS: sizes.append("%d x %d" % [resolution.x, resolution.y])
	var resolution := menu.option("Window resolution", sizes, AppSettings.RESOLUTIONS.find(_draft.resolution))
	resolution.item_selected.connect(func(index: int) -> void: _draft.resolution = AppSettings.RESOLUTIONS[index])
	var vsync := menu.toggle("VSync", _draft.vsync)
	vsync.toggled.connect(func(value: bool) -> void: _draft.vsync = value)
	var scale := menu.slider("UI scale", _draft.ui_scale, 0.85, 1.25)
	scale.value_changed.connect(func(value: float) -> void: _draft.ui_scale = value)
	for bus: String in _draft.volumes:
		var volume := menu.slider(bus + " volume", _draft.volumes[bus])
		volume.value_changed.connect(func(value: float) -> void:
			_draft.volumes[bus] = value
			_draft.apply_audio())
		var mute := menu.toggle("Mute " + bus, _draft.muted[bus])
		mute.toggled.connect(func(value: bool) -> void:
			_draft.muted[bus] = value
			_draft.apply_audio())
	menu.text("CONTROLS\nWASD / arrows: drive  |  Triggers + left stick: drive\nShift / LB: drift  |  Space / B: item\nEnter / A: READY start  |  R / Y: recover\nF5 / X: restart  |  Esc / Start: pause\nMenus: arrows / D-pad, Enter / A, Esc / B back\nF3 debug; F4 presentation; F6 CSV; F7 FPS; F8 AI")
	menu.button("Apply", apply_settings)
	menu.button("Back", close_settings, true)
	menu.finish()

func apply_settings() -> void:
	var display_changed := settings.fullscreen != _draft.fullscreen or settings.resolution != _draft.resolution or settings.vsync != _draft.vsync or settings.ui_scale != _draft.ui_scale
	settings = _draft.copy()
	settings.apply_audio()
	if display_changed: settings.apply_display(get_window())
	menu.message.text = "Settings saved." if settings.save_settings() == OK else "Settings applied, but could not be saved."

func close_settings() -> void:
	settings.apply_audio()
	if _settings_back == "pause": pause_session()
	else: show_home()

func show_credits() -> void:
	screen = "credits"
	menu.page("CREDITS", "Turbo Riot / development prototype")
	menu.text("Built with Godot Engine (MIT license).\n\nGame code and procedural art: Turbo Riot project contributors.\n\nMenu music, engine loop and cues are original synthesized placeholders generated for this project. No third-party game recordings are included.\n\nThe educational reference circuit is retained for private testing. Original circuits and the Graffiti Speed identity are deferred to later milestones.")
	menu.button("Back", show_home, true)
	menu.finish()

func quit_game() -> void:
	_dispose_game()
	get_tree().quit()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo: return
	if event.is_action_pressed("pause_race") or event.is_action_pressed("ui_cancel"):
		if screen == "race":
			# B is an item button during gameplay, never pause/back.
			if is_instance_valid(game) and game.get_node("RaceManager").session.state == RaceSession.State.FINISHED: return_home()
			elif event.is_action_pressed("pause_race"): pause_session()
			elif is_instance_valid(game) and game.get_node("RaceManager").session.state == RaceSession.State.READY: return_home()
			else: return
		elif screen == "pause": resume_session()
		elif screen == "settings": close_settings()
		elif screen == "config" or screen == "credits": show_home()
		elif screen == "loading": return_home()
		get_viewport().set_input_as_handled()
		return
	if screen == "pause" and event.is_action_pressed("restart_race"):
		restart_session()
		get_viewport().set_input_as_handled()
		return
	if screen != "race" or not is_instance_valid(game) or get_tree().paused: return
	if event is InputEventJoypadButton and setup.controller >= -1 and event.device != setup.controller: return
	if event.is_action_pressed("restart_race"): restart_session()
	elif event.is_action_pressed("reset_kart"): game.get_node("Kart/Recovery").recover()
	elif event.is_action_pressed("start_race"): game.get_node("RaceManager").start_race()

func _notification(what: int) -> void:
	if not is_node_ready(): return
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT and auto_pause_on_focus_loss and screen == "race": pause_session()
	if what == NOTIFICATION_WM_CLOSE_REQUEST: quit_game()

func _on_controller_connection(device: int, connected: bool) -> void:
	if not connected and setup.controller == device and is_instance_valid(game):
		settings.apply_audio()
		pause_session()
		menu.message.text = "Selected controller disconnected. Reconnect to resume, or return to Main Menu to choose controls."
