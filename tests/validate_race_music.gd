extends SceneTree
## Full physical local-player race; no injected checkpoint/lap signals.
func _initialize() -> void:run.call_deferred()
func run() -> void:
	var laps := 3
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--laps="):laps=clampi(arg.get_slice("=",1).to_int(),1,20)
	var app := load("res://scenes/app.tscn").instantiate() as TurboApplication
	app.settings.path="res://.godot/music_race_probe_settings.cfg"
	app.auto_pause_on_focus_loss=false
	root.add_child(app)
	var music := root.get_node("MusicManager") as MusicController
	var general_starts: int=music.starts[&"general"]
	var final_starts: int=music.starts[&"final"]
	var setup := RaceSetup.new()
	setup.mode=RaceSetup.Mode.TIME_TRIAL
	setup.laps=laps
	await app.start_session(setup)
	var race := app.game.get_node("RaceManager") as RaceManager
	var input := AIInput.new()
	input.kart=race.kart
	input.line=race._driver_line(0)
	input.profile=RaceManager.PROFILES[2]
	input.recovery_requested.connect(race._on_ai_recovery.bind(race.competitors[0]))
	race.kart.add_child(input)
	race.kart.input_provider=input
	race._update_driver_gates(race.competitors[0])
	var selections: Array[Dictionary]=[]
	var callback := func() -> void:selections.append({"lap":race.session.current_lap(),"completed":race.session.lap_times.size(),"time":race.session.race_time})
	music.final_lap_selected.connect(callback)
	race.start_race()
	for tick in 30000:
		await physics_frame
		if race.race_complete:break
	for i in 30:await process_frame
	var passed := race.race_complete and not race.competitors[0].dnf and race.session.lap_times.size()==laps
	passed=passed and selections.size()==1 and selections[0].lap==laps and selections[0].completed==laps-1
	passed=passed and music.starts[&"final"]-final_starts==1 and music.starts[&"general"]-general_starts==(0 if laps==1 else 1)
	var report := {"passed":passed,"laps":laps,"lap_times":race.session.lap_times,"recoveries":race.competitors[0].recoveries,"final_selections":selections,"general_starts":music.starts[&"general"]-general_starts,"final_starts":music.starts[&"final"]-final_starts}
	FileAccess.open("res://artifacts/music_physical_race_%d.json"%laps,FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("MUSIC_PHYSICAL_RACE ",JSON.stringify(report))
	music.final_lap_selected.disconnect(callback)
	app.return_home()
	await music.shutdown()
	app.queue_free()
	for i in 3:await process_frame
	quit(0 if passed else 1)
