extends RefCounted
var music: MusicController
func settle() -> void:
	for i in 20:music._process(.05)
func audible() -> int:
	var count := 0
	for player in [music.menu_player,music.race_player]:
		if player.playing and not player.stream_paused:count+=1
	return count
func lap(model: RaceSession) -> bool:
	model.advance(1)
	for gate in range(1,model.checkpoint_count):model.cross_checkpoint(gate)
	return model.cross_checkpoint(0)
func run(s: SceneTree) -> void:
	var checks_before: int=s.checks
	var failures_before: int=s.failures
	music=s.root.get_node("MusicManager") as MusicController
	music.stop_all()
	music.set_process(false)
	var fixture: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/music_update.json"))
	s.check(fixture.approved_code_hashes.keys().size()==5,"Music scope supersedes exactly five integration files, preserving historical fixtures")
	for path in fixture.assets:s.check(FileAccess.get_sha256("res://"+path)==fixture.assets[path],"Original music file unchanged: "+path)
	for path in fixture.unchanged_gameplay:s.check(FileAccess.get_sha256("res://"+path)==fixture.unchanged_gameplay[path],"Music preserves gameplay/circuit data: "+path)
	for path in fixture.approved_code_hashes:s.check(FileAccess.get_sha256("res://"+path)==fixture.approved_code_hashes[path],"Reviewed music integration: "+path)
	var buses := AudioServer.bus_count
	MusicController.ensure_buses()
	s.check(AudioServer.bus_count==buses and AudioServer.get_bus_index("Music")>=0 and AudioServer.get_bus_index("Effects")>=0,"Audio buses are independent and created once")
	for path in [music.menu_path,music.general_path,music.final_path]:
		var original := load(path) as AudioStreamWAV
		var stream := music._load_track(path) as AudioStreamWAV
		s.check(stream!=original and stream.loop_mode==AudioStreamWAV.LOOP_FORWARD and stream.loop_end==roundi(original.get_length()*original.mix_rate),"WAV loops use full sample range without modifying shared asset: "+path)
		s.check(original.loop_mode==AudioStreamWAV.LOOP_DISABLED and stream.data==original.data,"Loop configuration leaves source audio samples/import loop flag intact")
	music.play_menu()
	settle()
	var menu_starts: int=music.starts[&"menu"]
	for i in 10:music.play_menu();settle()
	s.check(music.starts[&"menu"]==menu_starts and audible()==1,"Repeated menu requests never restart or overlap menu music")
	for laps in [1,2,3,5,20]:
		var model := RaceSession.new()
		model.lap_count=laps
		model.checkpoint_count=3
		music.bind_session(model)
		model.start()
		s.check(music.final_lap_transitions==0 and not music.final_lap,"Fresh countdown resets final-lap state: "+str(laps))
		model.advance(3)
		settle()
		s.check(music.final_lap==(laps==1),"One-lap race starts on final theme; longer races start general: "+str(laps))
		var ai := RaceSession.new()
		ai.lap_count=1
		ai.checkpoint_count=3
		ai.start();ai.advance(3);lap(ai)
		s.check(music.session==model and music.final_lap==(laps==1),"Unbound AI progression/finish cannot select local final music")
		for index in laps:
			s.check(lap(model),"Validated local lap completes: %d/%d"%[index+1,laps])
			settle()
			if index+1<laps:s.check(music.final_lap==(index+1==laps-1),"Final selection follows authoritative local lap count")
			var before: int=music.final_lap_transitions
			s.check(not model.cross_checkpoint(0,false) and not model.cross_checkpoint(0) and before==music.final_lap_transitions,"Reverse/duplicate finish crossings cannot retrigger music")
			s.check(audible()<=1,"Track changes never run two audible transports")
		s.check(music.final_lap_transitions==1 and music.menu_player.playing and not music.race_player.playing,"Final theme selected once, then results use menu music")
		model.reset(true)
		model.advance(3)
		settle()
		s.check(music.final_lap==(laps==1) and music.final_lap_transitions==(1 if laps==1 else 0),"In-place race restart resets music epoch and final selection")
		music.release_session(model)
		settle()
	# Pause during normal/final music and interrupted fades, including settings
	# returning to pause and quit-to-menu continuity.
	var model := RaceSession.new()
	model.checkpoint_count=3
	music.bind_session(model)
	model.start();model.advance(3);settle()
	for final in [false,true]:
		if final:lap(model);lap(model);settle()
		var stream := music.race_player.stream
		var starts: Dictionary=music.starts.duplicate()
		music.pause_race();settle()
		s.paused=true
		s.check(music.race_player.stream_paused and music.menu_player.playing and audible()==1,"Pause suspends the racing transport while menu transport runs")
		var count: int=music.starts[&"menu"]
		music.pause_race();music.play_menu();settle()
		s.check(music.starts[&"menu"]==count,"Pause/settings navigation is idempotent")
		music.resume_race();settle()
		s.paused=false
		s.check(music.race_player.stream==stream and not music.race_player.stream_paused and not music.menu_player.playing,"Resume restores same normal/final decoder without overlap")
		s.check(music.starts[&"general"]==starts[&"general"] and music.starts[&"final"]==starts[&"final"],"Resume never calls play again on suspended race audio")
	for i in 30:
		music.pause_race();music._process(.01)
		s.check(audible()<=1,"Rapid pause has one audible transport")
		music.resume_race();music._process(.01)
		s.check(audible()<=1,"Rapid resume has one audible transport")
	settle()
	music.pause_race();settle()
	menu_starts=music.starts[&"menu"]
	music.release_session(model);settle()
	s.check(music.starts[&"menu"]==menu_starts and not music.race_player.playing,"Abandoning paused race keeps the existing menu playback")
	# Start a different race while an old transition is pending; late teardown
	# and old model signals must never affect its theme or lap state.
	var next := RaceSession.new()
	next.lap_count=1
	music.bind_session(next)
	next.start();next.advance(3)
	music.release_session(model)
	model.reset(true);model.advance(3)
	settle()
	s.check(music.session==next and music.final_lap and music.final_lap_transitions==1,"Consecutive race binding is independent; stale prior-race events are disconnected")
	var position := music.race_player.get_playback_position()
	var final_starts: int=music.starts[&"final"]
	for i in 5:music.bind_session(next);music._on_state(RaceSession.State.RACING);settle()
	s.check(music.starts[&"final"]==final_starts and music.final_lap_transitions==1 and music.race_player.get_playback_position()>=position,"Repeated racing events never restart the same theme")
	music.stop_all()
	var old_paths := [music.menu_path,music.general_path,music.final_path]
	music.report_missing_assets=false
	music.final_path="res://assets/music/__missing_final_test.wav"
	model=RaceSession.new();model.lap_count=1
	music.bind_session(model);model.start();model.advance(3);settle()
	s.check(music.final_lap and music.race_player.stream==music._load_track(music.general_path),"Missing final track falls back to the general looping track")
	music.menu_path="res://assets/music/__missing_menu_test.wav"
	music.pause_race();settle()
	s.check(audible()==0 and music.race_player.stream_paused,"Missing pause menu track gives safe silence while preserving racing audio")
	music.resume_race();settle()
	s.check(audible()==1 and music.final_lap,"Resume still works after missing menu asset")
	music.general_path="res://assets/music/__missing_general_test.wav"
	music.bind_session(RaceSession.new());music.session.start();music.session.advance(3);settle()
	s.check(audible()==0 and music.asset_issues.size()>=3,"Missing racing assets never crash or leave old audio playing")
	music.menu_path=old_paths[0];music.general_path=old_paths[1];music.final_path=old_paths[2]
	music.report_missing_assets=true
	music.stop_all()
	var custom := RiotSounds.sound(&"music")
	model=RaceSession.new();model.lap_count=1
	music.bind_session(model,custom,custom);model.start();model.advance(3);settle()
	s.check(music.race_player.stream!=custom and music.race_player.stream.data==custom.data,"Optional circuit themes loop through independent runtime resources")
	music.stop_all()
	await _application(s)
	music.set_process(true)
	await music.shutdown()
	var report := {"checks":s.checks-checks_before,"failures":s.failures-failures_before,"passed":s.failures==failures_before}
	FileAccess.open("res://artifacts/music_state_validation.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))

func _application(s: SceneTree) -> void:
	var app := load("res://scenes/app.tscn").instantiate() as TurboApplication
	app.settings.path="res://.godot/music_application_test.cfg"
	app.auto_pause_on_focus_loss=false
	s.root.add_child(app)
	settle()
	var before: int=music.starts[&"menu"]
	app.show_configuration(RaceSetup.Mode.QUICK_RACE)
	app.show_circuits(RaceSetup.new())
	app.show_settings("home")
	app.close_settings()
	app.show_credits()
	app.show_home()
	settle()
	s.check(music.starts[&"menu"]==before,"All existing application menu screens preserve one uninterrupted menu track")
	var request := RaceSetup.new()
	request.opponents=1
	await app.start_session(request)
	var race := app.game.get_node("RaceManager") as RaceManager
	race.set_physics_process(false)
	race.start_race();race.session.advance(3);settle()
	lap(race.competitors[1].session);lap(race.competitors[1].session);settle()
	s.check(not music.final_lap and music.session==race.session,"Real application binds only the local player, never the AI leader")
	lap(race.session);lap(race.session);settle()
	s.check(music.final_lap and music.final_lap_transitions==1,"Application validated local progression selects final music")
	app.pause_session();settle()
	before=music.starts[&"menu"]
	app.show_settings("pause");app.close_settings();settle()
	s.check(s.paused and music.starts[&"menu"]==before,"Pause settings return without restarting music")
	app.settings.volumes.Music=.21
	app.settings.apply_audio()
	app.settings.save_settings()
	var restored := AppSettings.new()
	restored.path=app.settings.path
	restored.load_settings()
	s.near(restored.volumes.Music,.21,"Music volume persists through the existing settings file")
	s.near(db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))),.21,"Saved Music volume applies during pause playback")
	app.resume_session();settle()
	s.check(music.final_lap and not music.race_player.stream_paused,"Application resumes final music without losing lap state")
	await app.start_session(request,true)
	settle()
	s.check(not music.final_lap and music.final_lap_transitions==0,"Restarting from final lap resets to fresh countdown audio state")
	app.pause_session();settle()
	before=music.starts[&"menu"]
	app.return_home();settle()
	s.check(music.starts[&"menu"]==before and music.session==null,"Paused abandonment retains menu playback and detaches the race")
	await app.start_session(request)
	app.queue_free()
	for i in 4:await s.process_frame
	settle()
	s.check(music.session==null,"Application teardown leaves no stale race signal binding")
	s.paused=false
	s.auto_accept_quit=true
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://.godot/music_application_test.cfg"))
