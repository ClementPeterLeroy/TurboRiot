class_name MusicController
extends Node
## Autoload: two transports, at most one audible. Paused race transport retains
## its decoder and exact position; only menu transport runs while game is paused.
signal track_started(kind: StringName)
signal final_lap_selected
@export var transition_seconds := 0.18
@export var final_lap_fade_seconds := 0.07
@export var gain_db := -9.0
var menu_path := "res://assets/music/main_menu_first.wav"
var general_path := "res://assets/music/racing_general.wav"
var final_path := "res://assets/music/racing_final_lap.wav"
var report_missing_assets := true
var asset_issues := PackedStringArray()
var starts := {&"menu":0, &"general":0, &"final":0}
var final_lap_transitions := 0
var final_lap := false
var paused := false
var session: RaceSession
var menu_player := AudioStreamPlayer.new()
var race_player := AudioStreamPlayer.new()
var _general: AudioStream
var _final: AudioStream
var _cache := {}
var _active: AudioStreamPlayer
var _target: AudioStreamPlayer
var _target_stream: AudioStream
var _target_kind: StringName = &""
var _target_epoch := -1
var _epoch := 0
var _player_epoch := -1
var _suspended_race := false
var _phase := 0 # 0 steady, 1 fade out, 2 fade in.
var _gain := 0.0
var _from_gain := 0.0
var _elapsed := 0.0
var _duration := 0.0

static func ensure_buses() -> void:
	for name in ["Music","Effects"]:
		if AudioServer.get_bus_index(name)>=0:continue
		AudioServer.add_bus()
		var index := AudioServer.bus_count-1
		AudioServer.set_bus_name(index,name)
		AudioServer.set_bus_send(index,"Master")

func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	ensure_buses()
	for player in [menu_player,race_player]:
		player.bus="Music"
		player.volume_db=-80
		add_child(player)

func _issue(message: String) -> void:
	if message in asset_issues:return
	asset_issues.append(message)
	if report_missing_assets:push_warning(message)

func _loop_copy(stream: AudioStream, source: String) -> AudioStream:
	if stream==null or not is_finite(stream.get_length()) or stream.get_length()<=0:
		_issue("Music unavailable or empty: "+source)
		return null
	var result := stream.duplicate() as AudioStream
	if result is AudioStreamWAV:
		result.loop_mode=AudioStreamWAV.LOOP_FORWARD
		result.loop_begin=0
		result.loop_end=roundi(result.get_length()*result.mix_rate)
	elif result is AudioStreamOggVorbis or result is AudioStreamMP3:
		result.loop=true
	else:
		_issue("Unsupported looping music format: "+source)
		return null
	result.set_meta("music_source",source)
	return result

func _load_track(path: String) -> AudioStream:
	if _cache.has(path):return _cache[path]
	var stream: AudioStream
	if not path.is_empty() and ResourceLoader.exists(path):stream=load(path) as AudioStream
	_cache[path]=_loop_copy(stream,path)
	return _cache[path]

func bind_session(value: RaceSession, general_override: AudioStream=null, final_override: AudioStream=null) -> void:
	if session==value:
		_sync_racing() if session and session.state==RaceSession.State.RACING else play_menu()
		return
	release_session()
	session=value
	_general=_loop_copy(general_override,"circuit general theme") if general_override else null
	if _general==null:_general=_load_track(general_path)
	_final=_general if general_override and final_override==general_override else _loop_copy(final_override,"circuit final theme") if final_override else null
	if _final==null:_final=_load_track(final_path)
	if _final==null:_final=_general # Missing final asset retains the general loop.
	_new_run()
	if session:
		session.state_changed.connect(_on_state)
		session.lap_completed.connect(_on_lap)
		if session.state==RaceSession.State.RACING:_sync_racing()
		else:play_menu()

func _new_run() -> void:
	_epoch+=1
	final_lap=false
	final_lap_transitions=0
	paused=false
	_suspended_race=false

func release_session(expected: RaceSession=null) -> void:
	if expected and session!=expected:return # Late teardown cannot detach a newer race.
	_disconnect_session()
	paused=false
	_suspended_race=false
	final_lap=false
	_general=null
	_final=null
	play_menu()
	if _active!=race_player:
		race_player.stop()
		race_player.stream=null

func _disconnect_session() -> void:
	if session:
		if session.state_changed.is_connected(_on_state):session.state_changed.disconnect(_on_state)
		if session.lap_completed.is_connected(_on_lap):session.lap_completed.disconnect(_on_lap)
	session=null

func play_menu() -> void:
	_request(menu_player,_load_track(menu_path),&"menu",transition_seconds)

func pause_race() -> void:
	if paused:return
	paused=true
	# Pause immediately, before the menu fade-in; no race audio advances behind it.
	if race_player.playing:_suspended_race=true
	race_player.stream_paused=true
	if _active==race_player:
		_active=null
		_gain=0
		_phase=0
	play_menu()

func resume_race() -> void:
	if not paused:return
	paused=false
	if session and session.state==RaceSession.State.RACING:_sync_racing()
	else:play_menu()

func _on_state(state: RaceSession.State) -> void:
	if state in [RaceSession.State.READY,RaceSession.State.COUNTDOWN]:
		_new_run()
		play_menu()
	elif state==RaceSession.State.RACING:_sync_racing()
	elif state==RaceSession.State.FINISHED:
		paused=false
		play_menu()
		if _active!=race_player:race_player.stop()

func _on_lap(_number: int,_seconds: float) -> void:
	# RaceSession emits before FINISHED. Do not enter final music at race completion.
	if session and session.lap_times.size()<session.lap_count:_sync_racing()

func _sync_racing() -> void:
	if session==null or session.state!=RaceSession.State.RACING:return
	if not final_lap and session.current_lap()==session.lap_count and session.lap_times.size()<session.lap_count:
		final_lap=true
		final_lap_transitions+=1
		final_lap_selected.emit()
	if paused:return
	_request(race_player,_final if final_lap else _general,&"final" if final_lap else &"general",final_lap_fade_seconds if final_lap else transition_seconds)

func _request(player: AudioStreamPlayer, stream: AudioStream, kind: StringName, seconds: float) -> void:
	var epoch := _epoch if player==race_player else -1
	if _target==player and _target_stream==stream and _target_kind==kind and _target_epoch==epoch:return
	_target=player
	_target_stream=stream
	_target_kind=kind
	_target_epoch=epoch
	_duration=maxf(0,seconds) if is_finite(seconds) else 0
	_elapsed=0
	_from_gain=_gain
	var same := _active==player and player.stream==stream and player.playing and (player!=race_player or _player_epoch==epoch)
	if same:
		_phase=2 # Cancel a pending switch without restarting the active transport.
	elif is_instance_valid(_active) and _active.playing and not _active.stream_paused and _gain>0:
		_phase=1
	else:_activate()
	if _duration==0:_process(0)

func _activate() -> void:
	if is_instance_valid(_active):
		_active.stop()
		_active.stream=null
	_active=null
	_gain=0
	_elapsed=0
	_from_gain=0
	if _target_stream==null:
		_phase=0
		return
	# Godot's playing getter is false for a suspended decoder. It must not be
	# used by itself to decide whether resume needs a new play() call.
	var retained := _target==race_player and _suspended_race and _target.stream==_target_stream and _player_epoch==_target_epoch
	var restart := not retained and (not _target.playing or _target.stream!=_target_stream or (_target==race_player and _player_epoch!=_target_epoch))
	if restart:
		_target.stop()
		_target.stream=_target_stream
		_target.volume_db=-80
		_target.play()
		starts[_target_kind]=int(starts.get(_target_kind,0))+1
		if _target==race_player:_player_epoch=_target_epoch
		track_started.emit(_target_kind)
	_target.stream_paused=false
	if _target==race_player:_suspended_race=false
	_active=_target
	_phase=2

func _process(delta: float) -> void:
	if _phase==0:return
	_elapsed+=maxf(0,delta)
	var fraction := 1.0 if _duration<=0 else minf(1,_elapsed/_duration)
	if _phase==1:
		_gain=lerpf(_from_gain,0,fraction)
		_apply_gain()
		if fraction>=1:_activate()
	elif _phase==2:
		_gain=lerpf(_from_gain,1,fraction)
		_apply_gain()
		if fraction>=1:_phase=0

func _apply_gain() -> void:
	if is_instance_valid(_active):_active.volume_db=gain_db+linear_to_db(maxf(.00001,_gain))

func stop_all() -> void:
	_disconnect_session()
	for player in [menu_player,race_player]:
		player.stop()
		player.stream=null
		player.stream_paused=false
	_active=null
	_target=null
	_target_stream=null
	_phase=0
	_gain=0
	paused=false
	final_lap=false
	_suspended_race=false

func shutdown() -> void:
	stop_all()
	# Let the audio mixer retire stopped WAV decoders before engine shutdown.
	var deadline := Time.get_ticks_msec()+80
	while is_inside_tree() and Time.get_ticks_msec()<deadline:await get_tree().process_frame
	_cache.clear()

func _exit_tree() -> void:
	stop_all()
	_cache.clear()
