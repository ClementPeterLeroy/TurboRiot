extends SceneTree
## Native/Dummy audio mixer probe. Never run with --fixed-fps: real decoder
## positions, sample capture, looping and suspended transport identity matter.
var music: MusicController
var checks := 0
var failures := 0
var capture := AudioEffectCapture.new()
var metrics: Array[Dictionary]=[]
func _initialize() -> void:run.call_deferred()
func check(value: bool,message: String) -> void:
	checks+=1
	if not value:failures+=1;push_error(message)
func audible() -> int:
	return int(music.menu_player.playing and not music.menu_player.stream_paused)+int(music.race_player.playing and not music.race_player.stream_paused)
func wait_wall(seconds: float) -> void:
	var deadline := Time.get_ticks_usec()+roundi(seconds*1000000)
	while Time.get_ticks_usec()<deadline:
		await process_frame
		check(audible()<=1,"At most one audible music transport during every sampled frame")
func energy(label: String) -> void:
	var frames := capture.get_buffer(capture.get_frames_available())
	var peak := 0.0
	for frame in frames:peak=maxf(peak,maxf(absf(frame.x),absf(frame.y)))
	check(frames.size()>0 and peak>.00001,"Real decoded PCM reaches Music bus: "+label)
	metrics.append({"capture":label,"frames":frames.size(),"peak":peak})
func lap(model: RaceSession) -> void:
	model.advance(1)
	for gate in range(1,model.checkpoint_count):model.cross_checkpoint(gate)
	model.cross_checkpoint(0)
func pause_probe(app: TurboApplication,label: String) -> void:
	var decoder := music.race_player.get_stream_playback()
	var starts: Dictionary=music.starts.duplicate()
	app.pause_session()
	var saved := decoder.get_playback_position()
	await wait_wall(.25)
	var held := decoder.get_playback_position()
	check(absf(held-saved)<.035,"Paused decoder retains position: "+label)
	var menu_starts: int=music.starts[&"menu"]
	app.show_settings("pause");app.close_settings()
	await wait_wall(.1)
	check(music.starts[&"menu"]==menu_starts,"Pause settings do not restart menu WAV")
	app.resume_session()
	var deadline := Time.get_ticks_msec()+2000
	while music.race_player.stream_paused and Time.get_ticks_msec()<deadline:await process_frame
	var resumed := music.race_player.get_playback_position()
	check(music.race_player.get_stream_playback()==decoder,"Resume keeps the same audio decoder: "+label)
	check(resumed>=saved-.035 and resumed<=saved+.06,"Resume starts from saved playback position: "+label)
	check(music.starts[&"general"]==starts[&"general"] and music.starts[&"final"]==starts[&"final"],"Resume does not invoke play again: "+label)
	metrics.append({"pause":label,"saved":saved,"held":held,"resumed":resumed,"same_decoder":music.race_player.get_stream_playback()==decoder})
	await wait_wall(.16)
	check(music.race_player.get_playback_position()>resumed+.08,"Resumed decoder advances: "+label)
	decoder=null
func loop_probe(player: AudioStreamPlayer,label: String) -> void:
	player.seek(player.stream.get_length()-.08)
	await wait_wall(.3)
	check(player.playing and player.get_playback_position()<1,"Full imported WAV wraps and keeps playing: "+label)
	energy(label+" loop")
func run() -> void:
	music=root.get_node("MusicManager") as MusicController
	music.stop_all()
	music.transition_seconds=.04
	music.final_lap_fade_seconds=.02
	Engine.max_fps=120
	var app := load("res://scenes/app.tscn").instantiate() as TurboApplication
	app.settings.path="res://.godot/music_native_probe_settings.cfg"
	app.settings.resolution=Vector2i(960,540)
	app.settings.vsync=false
	app.auto_pause_on_focus_loss=false
	root.add_child(app)
	for bus in ["Master","Music"]:
		AudioServer.set_bus_mute(AudioServer.get_bus_index(bus),false)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus),0)
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Effects"),true)
	capture.buffer_length=1
	var music_bus := AudioServer.get_bus_index("Music")
	var effect_index := AudioServer.get_bus_effect_count(music_bus)
	AudioServer.add_bus_effect(music_bus,capture)
	await wait_wall(.35)
	energy("menu")
	var request := RaceSetup.new()
	request.mode=RaceSetup.Mode.TIME_TRIAL
	request.laps=3
	await app.start_session(request)
	var race := app.game.get_node("RaceManager") as RaceManager
	race.set_physics_process(false)
	race.kart.set_physics_process(false)
	race.start_race();race.session.advance(3)
	# Scene loading can consume the first render frame. Measure decoder advance
	# after activation, independently of that loading/fade interval.
	var activation_deadline := Time.get_ticks_msec()+3000
	while not music.race_player.playing and Time.get_ticks_msec()<activation_deadline:await process_frame
	await wait_wall(.35)
	check(music.race_player.get_playback_position()>.1,"General WAV advances in real mixer time")
	energy("general")
	await pause_probe(app,"general")
	await loop_probe(music.race_player,"general")
	lap(race.session);lap(race.session)
	await wait_wall(.25)
	check(music.final_lap and music.final_lap_transitions==1,"Validated final-lap event switches the real transport once")
	energy("final")
	await pause_probe(app,"final")
	await loop_probe(music.race_player,"final")
	for i in 8:
		app.pause_session()
		await wait_wall(.012)
		app.resume_session()
		await wait_wall(.012)
	await wait_wall(.2)
	check(music.final_lap and music.race_player.playing and audible()==1,"Repeated rapid pause/resume settles on correct final theme")
	lap(race.session)
	await wait_wall(.2)
	check(music.menu_player.playing and not music.race_player.playing,"Race finish stops racing loop and enters results music")
	app.pause_session()
	var menu_starts: int=music.starts[&"menu"]
	app.return_home()
	await wait_wall(.12)
	check(music.starts[&"menu"]==menu_starts,"Quit from paused results retains menu playback")
	await loop_probe(music.menu_player,"menu")
	var report := {"checks":checks,"failures":failures,"passed":failures==0,"real_time_mixer":true,"audio_driver_requested":"Dummy","metrics":metrics}
	FileAccess.open("res://artifacts/music_playback_validation.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("MUSIC_PLAYBACK ",JSON.stringify(report))
	await music.shutdown()
	AudioServer.remove_bus_effect(music_bus,effect_index)
	app.queue_free()
	for i in 3:await process_frame
	quit(1 if failures else 0)
