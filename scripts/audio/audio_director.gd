class_name AudioDirector
extends Node
const EVENTS := [&"navigate", &"confirm", &"back", &"countdown", &"go", &"engine", &"drift", &"drift_loop",
	&"mini_turbo", &"boost_pad", &"mushroom", &"collision", &"pickup", &"item_use", &"item_hit", &"lap", &"finish"]
var race: RaceManager
var engine := AudioStreamPlayer.new()
var drift_loop := AudioStreamPlayer.new()
var music := AudioStreamPlayer.new()
var events := {} # Transient diagnostics, never persisted.
var _voices: Array[AudioStreamPlayer] = []
var _ui_voices: Array[AudioStreamPlayer] = []
var _connections: Array[Dictionary] = []
var _cooldowns := {}
var _clock := 0.0
var _voice := 0
var _ui_voice := 0
var _countdown := -1
var _boost_source: StringName = &""
var _boost_serial := 0
var _drifting := false
var _paused := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for bus in ["Music", "Effects"]:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			var index := AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, bus)
			AudioServer.set_bus_send(index, "Master")
	for player in [engine, drift_loop, music]: add_child(player)
	engine.bus = "Effects"
	drift_loop.bus = "Effects"
	music.bus = "Music"
	music.volume_db = -9
	for i in 12:
		var player := AudioStreamPlayer.new()
		player.bus = "Effects"
		player.volume_db = -12
		add_child(player)
		_voices.append(player)
	for i in 3:
		var player := AudioStreamPlayer.new()
		player.bus = "Effects"
		add_child(player)
		_ui_voices.append(player)
	if DisplayServer.get_name() != "headless":
		engine.stream = RiotSounds.sound(&"engine")
		drift_loop.stream = RiotSounds.sound(&"drift_loop")
		music.stream = RiotSounds.sound(&"music")
		music.play()

func play(event: StringName, at: Variant = null) -> void:
	if _clock < float(_cooldowns.get(event, -1)): return
	var gain := 1.0
	if at is Vector3 and is_instance_valid(race):
		gain = clampf(1 - at.distance_to(race.kart.global_position) / 50, 0, 1)
	if gain == 0: return
	_cooldowns[event] = _clock + (0.16 if event == &"collision" else 0.06)
	events[event] = int(events.get(event, 0)) + 1
	if DisplayServer.get_name() == "headless": return
	var ui_event := event in [&"navigate", &"confirm", &"back"]
	var player := _ui_voices[_ui_voice % _ui_voices.size()] if ui_event else _voices[_voice % _voices.size()]
	if ui_event: _ui_voice += 1
	else: _voice += 1
	player.stop()
	player.stream = RiotSounds.sound(event)
	player.volume_db = -12 + linear_to_db(maxf(0.01, gain))
	player.play()

func _connect_event(source: Signal, callback: Callable) -> void:
	source.connect(callback)
	_connections.append({"signal": source, "callback": callback})

func bind_race(value: RaceManager, items: ItemSystem) -> void:
	unbind_race()
	race = value
	_countdown = -1
	_boost_source = &""
	_boost_serial = 0
	_drifting = false
	_connect_event(race.session.state_changed, _on_state)
	_connect_event(race.session.lap_completed, func(_lap: int, _time: float) -> void: play(&"lap"))
	_connect_event(items.sound_requested, func(event: StringName, at: Vector3) -> void: play(event, at))
	if not items.enabled:
		_connect_event(race.get_node("KartContacts").impact, func(at: Vector3, _strength: float) -> void: play(&"collision", at))
	_connect_event(race.kart.wall_impacted, func(_strength: float) -> void: play(&"collision"))
	if DisplayServer.get_name() != "headless": engine.play()

func unbind_race() -> void:
	for connection in _connections:
		var source: Signal = connection.signal
		if is_instance_valid(source.get_object()) and source.is_connected(connection.callback): source.disconnect(connection.callback)
	_connections.clear()
	race = null
	_paused = false
	engine.stop()
	drift_loop.stop()
	engine.stream_paused = false
	drift_loop.stream_paused = false
	for voice in _voices: voice.stop()
	music.volume_db = -9
	_cooldowns.clear()

func pause_audio(value: bool) -> void:
	_paused = value
	engine.stream_paused = value
	drift_loop.stream_paused = value
	for voice in _voices: voice.stop()
	music.volume_db = -15 if value else -9

func _on_state(state: RaceSession.State) -> void:
	if state == RaceSession.State.RACING: play(&"go")
	if state == RaceSession.State.FINISHED:
		play(&"finish")
		engine.stop()
		drift_loop.stop()

func _process(delta: float) -> void:
	_clock += delta
	if not is_instance_valid(race) or _paused: return
	if race.session.state == RaceSession.State.COUNTDOWN:
		var count := ceili(race.session.countdown_remaining)
		if count > 0 and count != _countdown:
			_countdown = count
			play(&"countdown")
	var kart := race.kart
	var speed := Vector2(kart.velocity.x, kart.velocity.z).length()
	engine.pitch_scale = clampf(0.8 + speed / kart.config.max_forward_speed * 1.4, 0.6, 2.8)
	engine.volume_db = -28 + clampf(speed / 22, 0, 1) * 10 + kart.current_command.throttle * 3
	if kart.drift.active and not _drifting: play(&"drift")
	if kart.drift.active and not drift_loop.playing and DisplayServer.get_name() != "headless": drift_loop.play()
	if not kart.drift.active: drift_loop.stop()
	_drifting = kart.drift.active
	if kart.boost.active() and (kart.boost.source != _boost_source or kart.boost.activation_serial != _boost_serial): play(kart.boost.source)
	_boost_source = kart.boost.source if kart.boost.active() else &""
	_boost_serial = kart.boost.activation_serial

func _exit_tree() -> void:
	unbind_race()
	for player in [engine, drift_loop, music] + _voices + _ui_voices:
		player.stop()
		player.stream = null
