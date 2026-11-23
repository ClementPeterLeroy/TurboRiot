extends SceneTree
## Isolated 1080p comparison: new pads/logo disabled, then enabled.
## The removed old wordmark is absent in both cases. Never use --fixed-fps.
func _initialize() -> void: run.call_deferred()

func run() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	root.size = Vector2i(1920,1080)
	DisplayServer.window_set_size(root.size)
	root.content_scale_factor = 1
	var args := OS.get_cmdline_user_args()
	var prefix := "v061_final_polish_performance"
	for arg in args:
		if arg.begins_with("--report-prefix="): prefix=arg.get_slice("=",1).validate_filename()
	var results: Array[Dictionary] = []
	var cases := ["before"] if "--baseline-only" in args else ["before","after"]
	for label in cases:
		var definition := TrackRegistry.get_definition(&"figure_8")
		var start_load := Time.get_ticks_usec()
		var world := definition.instantiate_race()
		if label=="before":
			for path in ["Track/SpeedPads", "Track/EnvironmentArt/Signage/StartGantry/OfficialBrand"]:
				var node := world.get_node(path)
				node.get_parent().remove_child(node)
				node.free()
		world.managed=true
		world.get_node("Items").external_audio=true
		var race := world.get_node("RaceManager") as RaceManager
		race.ai_only=true
		race.opponent_count=6
		race.difficulty=2
		race.lap_count=10
		race.use_command_line_configuration=false
		root.add_child(world)
		world.get_node("Items").rng.seed=42
		await physics_frame
		var load_ms := (Time.get_ticks_usec()-start_load)/1000.0
		race.start_race()
		race.session.advance(3)
		if RenderingServer.has_method("viewport_set_measure_render_time"):
			RenderingServer.call("viewport_set_measure_render_time",root.get_viewport_rid(),true)
		for tick in 360: await physics_frame
		var shapes := _shape_count(world)
		var start := Time.get_ticks_usec()
		var previous := start
		var first_tick := Engine.get_physics_frames()
		var frames := 0
		var physics := 0.0
		var draws := 0.0
		var primitives := 0.0
		var rendered_objects := 0.0
		var render_cpu := 0.0
		var render_gpu := 0.0
		var frame_ms: Array[float] = []
		while Engine.get_physics_frames()-first_tick < 720:
			await process_frame
			var now := Time.get_ticks_usec()
			frame_ms.append((now-previous)/1000.0)
			previous=now
			frames+=1
			physics+=Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000
			draws+=Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
			primitives+=Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
			rendered_objects+=Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)
			if RenderingServer.has_method("viewport_get_measured_render_time_cpu"):
				render_cpu+=RenderingServer.call("viewport_get_measured_render_time_cpu",root.get_viewport_rid())
				render_gpu+=RenderingServer.call("viewport_get_measured_render_time_gpu",root.get_viewport_rid())
		var seconds := (Time.get_ticks_usec()-start)/1000000.0
		frame_ms.sort()
		var result := {"case":label,"fps":frames/seconds,"physics_hz":(Engine.get_physics_frames()-first_tick)/seconds,
			"mean_frame_ms":seconds*1000/frames,"p95_frame_ms":frame_ms[floori((frames-1)*0.95)],"p99_frame_ms":frame_ms[floori((frames-1)*0.99)],
			"mean_physics_ms":physics/frames,"mean_draw_calls":draws/frames,"mean_rendered_primitives":primitives/frames,
			"mean_rendered_objects":rendered_objects/frames,"render_cpu_ms":render_cpu/frames,"render_gpu_ms":render_gpu/frames,
			"static_memory_bytes":Performance.get_monitor(Performance.MEMORY_STATIC),"video_memory_bytes":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),
			"load_ms":load_ms,"collision_shapes":shapes,"nodes":get_node_count(),"rendered_frames":frames,"seconds":seconds}
		results.append(result)
		print("FIGURE8 ENVIRONMENT ",JSON.stringify(result))
		world.queue_free()
		for frame in 12: await process_frame
	var report := {"engine":Engine.get_version_info().string,"gpu":RenderingServer.get_video_adapter_name(),"cpu":OS.get_processor_name(),
		"resolution":[1920,1080],"vsync":false,"physics_ticks":Engine.physics_ticks_per_second,"racers":7,"items":true,"difficulty":"Challenging","seed":42,"results":results}
	FileAccess.open("res://artifacts/%s.json" % prefix,FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	quit()

func _shape_count(node: Node) -> int:
	var count := 1 if node is CollisionShape3D else 0
	for child in node.get_children(): count+=_shape_count(child)
	return count
