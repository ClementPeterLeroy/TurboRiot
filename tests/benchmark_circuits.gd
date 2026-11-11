extends SceneTree
## Native, real wall-clock A/B. Do not use --fixed-fps or concurrent benchmarks.
## Legacy fixtures reproduce the preceding collision/minimap implementation only.
class LegacyMap extends Control:
	var track: TrackBuilder
	var race: RaceManager
	var samples := PackedVector2Array()
	var bounds := Rect2()
	func configure(curve: Curve3D) -> void:
		for point in curve.get_baked_points(): samples.append(Vector2(point.x,point.z))
		bounds=Rect2(samples[0],Vector2.ZERO)
		for point in samples: bounds=bounds.expand(point)
		bounds=bounds.grow(12)
	func project_point(point: Vector2) -> Vector2:
		var scale_factor := minf(size.x/maxf(bounds.size.x,1),size.y/maxf(bounds.size.y,1))
		return (point-bounds.get_center())*scale_factor+size*0.5
	func _process(_delta: float) -> void: queue_redraw()
	func _draw() -> void:
		var panel := StyleBoxFlat.new()
		panel.bg_color=Color(0.02,0.05,0.08,0.82)
		panel.set_corner_radius_all(8)
		draw_style_box(panel,Rect2(Vector2.ZERO,size))
		var line := PackedVector2Array()
		for point in samples: line.append(project_point(point))
		draw_polyline(line,Color("101b29"),9,true)
		draw_polyline(line,Color("93d6df"),4,true)
		draw_circle(line[0],5,Color("ffda58"))
		for record in race.competitors:
			var point := track.to_local(record.kart.get_global_transform_interpolated().origin)
			draw_circle(project_point(Vector2(point.x,point.z)),4 if record.is_player else 2.5,Color("ffda58") if record.is_player else Color("fafafa"))

func _initialize() -> void: run.call_deferred()
func run() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps=0
	root.size=Vector2i(1280,720)
	root.content_scale_factor=1
	var results: Array[Dictionary] = []
	var prefix := "v061_circuit_performance"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--report-prefix="): prefix=arg.get_slice("=",1).validate_filename()
	for id in [&"reference",&"yoshi_ds"]:
		for legacy in [true,false]:
			var main := TrackRegistry.get_definition(id).instantiate_race()
			main.managed=true
			main.get_node("Items").external_audio=true
			var race := main.get_node("RaceManager") as RaceManager
			race.ai_only=true
			root.add_child(main)
			main.get_node("Items").rng.seed=42
			var map: Control=main.get_node("HUD/CircuitMap")
			if legacy:
				var asphalt := race.track.get_node("Generated/Asphalt") as MeshInstance3D
				for child in asphalt.get_children():
					asphalt.remove_child(child)
					child.queue_free()
				asphalt.create_trimesh_collision()
				SurfaceDetector.tag_collision(asphalt,preload("res://resources/surfaces/asphalt.tres"))
				var old_map := LegacyMap.new()
				old_map.track=race.track
				old_map.race=race
				old_map.configure(race.track.curve)
				var hud := main.get_node("HUD")
				hud.remove_child(map)
				map.queue_free()
				hud.add_child(old_map)
				old_map.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
				old_map.offset_left=-244
				old_map.offset_top=-184
				old_map.offset_right=-24
				old_map.offset_bottom=-24
				map=old_map
			var draws := {"route":0}
			map.draw.connect(func() -> void: draws.route+=1)
			race.start_race()
			race.session.advance(3)
			for tick in 360: await physics_frame
			draws.route=0
			var started := Time.get_ticks_usec()
			var previous := started
			var start_physics := Engine.get_physics_frames()
			var frames := 0
			var physics_ms := 0.0
			var draw_calls := 0.0
			var frame_times: Array[float] = []
			while Engine.get_physics_frames()-start_physics<360:
				await process_frame
				var now := Time.get_ticks_usec()
				frame_times.append((now-previous)/1000.0)
				previous=now
				frames+=1
				physics_ms+=Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000
				draw_calls+=Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
			var seconds := (Time.get_ticks_usec()-started)/1000000.0
			frame_times.sort()
			var result := {"circuit":id,"legacy":legacy,"fps":frames/seconds,"physics_hz":(Engine.get_physics_frames()-start_physics)/seconds,
				"mean_physics_ms":physics_ms/frames,"p95_frame_ms":frame_times[mini(frame_times.size()-1,floori(frame_times.size()*0.95))],
				"mean_draw_calls":draw_calls/frames,"map_points":map.samples.size(),"static_route_redraws":draws.route,"rendered_frames":frames,"seconds":seconds}
			results.append(result)
			print("CIRCUIT PERFORMANCE ",JSON.stringify(result))
			main.queue_free()
			await process_frame
	var report := {"engine":Engine.get_version_info().string,"gpu":RenderingServer.get_video_adapter_name(),"resolution":[1280,720],"vsync":false,"physics_ticks":Engine.physics_ticks_per_second,"results":results}
	FileAccess.open("res://artifacts/%s.json" % prefix,FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	quit()
