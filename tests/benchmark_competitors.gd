extends SceneTree
## Native render benchmark. Do not pass --fixed-fps: measure actual wall time.
func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	root.size = Vector2i(1280, 720)
	var results: Array[Dictionary] = []
	for count in [1, 7]:
		var main := load("res://scenes/main.tscn").instantiate() as Node3D
		main.get_node("Items").enabled = false # Isolate pre-item regression fixture.
		var race := main.get_node("RaceManager") as RaceManager
		race.opponent_count = count - 1
		race.ai_only = true
		root.add_child(main)
		race.start_race()
		race.session.advance(3)
		for i in 90: await physics_frame
		var start := Time.get_ticks_usec()
		var physics_start := Engine.get_physics_frames()
		var frames := 0
		var physics_ms := 0.0
		var max_physics_ms := 0.0
		var draws := 0.0
		while Time.get_ticks_usec() - start < 3000000:
			await process_frame
			frames += 1
			var sample := Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000
			physics_ms += sample
			max_physics_ms = maxf(max_physics_ms, sample)
			draws += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		var seconds := (Time.get_ticks_usec() - start) / 1000000.0
		var result := {"racers": count, "render_fps": frames / seconds,
			"physics_hz": (Engine.get_physics_frames() - physics_start) / seconds,
			"mean_physics_ms": physics_ms / frames, "max_sampled_physics_ms": max_physics_ms,
			"mean_draw_calls": draws / frames, "seconds": seconds}
		results.append(result)
		print("BENCHMARK ", JSON.stringify(result))
		main.queue_free()
		await process_frame
	DirAccess.make_dir_recursive_absolute("res://artifacts")
	var report := FileAccess.open("res://artifacts/competitors_performance.json", FileAccess.WRITE)
	report.store_string(JSON.stringify(results, "\t"))
	report.close()
	quit()
