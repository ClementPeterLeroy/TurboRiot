extends SceneTree
func _initialize() -> void: _run.call_deferred()

func _run() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	root.size = Vector2i(1280, 720)
	var results: Array[Dictionary] = []
	for with_items in [false, true]:
		var main := load("res://scenes/main.tscn").instantiate() as Node3D
		var race := main.get_node("RaceManager") as RaceManager
		var items := main.get_node("Items") as ItemSystem
		items.enabled = with_items
		race.ai_only = true
		root.add_child(main)
		race.start_race()
		for i in 200: await physics_frame
		var start := Time.get_ticks_usec()
		var frame_start := Engine.get_physics_frames()
		var frames := 0
		var total_physics := 0.0
		var total_draws := 0.0
		var total_actors := 0.0
		var maximum_physics := 0.0
		var refill_tick := -1
		while Time.get_ticks_usec() - start < 3000000:
			await process_frame
			if with_items and items.actors.size() < 7:
				# Refill one per physics tick to sustain seven active item queries.
				if Engine.get_physics_frames() != refill_tick:
					refill_tick = Engine.get_physics_frames()
					var actor := ItemActor.new()
					actor.definition = ItemCatalog.ITEMS[2]
					actor.source = race.kart
					actor.system = items
					items.add_child(actor)
					var forward := -race.kart.global_basis.z
					actor.position = race.kart.global_position + forward * (4 + items.actors.size() * 1.3) + race.kart.global_basis.x * ((items.actors.size() % 3) - 1) * 1.5
					actor.direction = forward
					actor.reset_physics_interpolation()
					items.actors.append(actor)
			frames += 1
			var cost := Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000
			total_physics += cost
			maximum_physics = maxf(maximum_physics, cost)
			total_draws += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
			total_actors += items.actors.size()
		var seconds := (Time.get_ticks_usec() - start) / 1000000.0
		var result := {"items": with_items, "racers": 7, "render_fps": frames / seconds,
			"physics_hz": (Engine.get_physics_frames() - frame_start) / seconds,
			"mean_physics_ms": total_physics / frames, "max_sampled_physics_ms": maximum_physics,
			"mean_draw_calls": total_draws / frames, "mean_active_actors": total_actors / frames}
		results.append(result)
		print("ITEM BENCHMARK ", JSON.stringify(result))
		main.queue_free()
		await process_frame
	DirAccess.make_dir_recursive_absolute("res://artifacts")
	var report := FileAccess.open("res://artifacts/items_performance.json", FileAccess.WRITE)
	report.store_string(JSON.stringify(results, "\t"))
	report.close()
	quit()
