extends SceneTree
## Native display / render-rate A/B trace. No motion equations are overridden.
var main: Node3D

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	main = load("res://scenes/main.tscn").instantiate()
	var legacy := "--legacy" in OS.get_cmdline_user_args()
	if legacy:
		var legacy_kart := main.get_node("Kart") as KartController
		legacy_kart.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		var legacy_camera := main.get_node("ChaseCamera") as Camera3D
		legacy_camera.set_script(load("res://tests/fixtures/legacy_presentation_camera.gd"))
		legacy_camera.target = legacy_kart
	root.add_child(main)
	root.size = Vector2i(1280, 720)
	var race := main.get_node("RaceManager") as RaceManager
	race.set_physics_process(false)
	race.start_race()
	race.session.advance(3)
	race.session.advance(1) # Clear GO overlay so the rendered marker is visible.
	var kart := main.get_node("Kart") as KartController
	kart.get_node("Recovery").stuck_seconds = 0
	var track := main.get_node("Track") as TrackBuilder
	var diagnostics := main.get_node("PresentationDebug")
	# Use the long upper straight and remove optional pads/ramp from this
	# diagnostic scene, so propulsion stays at 79.2 km/h throughout every run.
	main.get_node("TrackFeatures").queue_free()
	await process_frame
	# A unique unshaded marker lets the saved frames independently verify the
	# rendered pixels, rather than relying only on calculated projections.
	var marker := MeshInstance3D.new()
	var marker_mesh := SphereMesh.new()
	marker_mesh.radius = 0.08
	marker_mesh.height = 0.16
	marker.mesh = marker_mesh
	var paint := StandardMaterial3D.new()
	paint.albedo_color = Color(1, 0, 1)
	paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	marker.material_override = paint
	marker.position = Vector3(0, 1.25, 0)
	kart.get_node("Visual").add_child(marker)
	var failures := 0
	DirAccess.make_dir_recursive_absolute("res://artifacts")
	var pixel_only := "--pixels-only" in OS.get_cmdline_user_args()
	var output := FileAccess.open("res://artifacts/presentation_legacy.csv" if legacy else ("res://artifacts/presentation_pixels_probe.csv" if pixel_only else "res://artifacts/presentation_probe.csv"), FileAccess.WRITE)
	output.store_csv_line(PackedStringArray(["cap", "mode", "time", "physics_tick", "body_y", "visual_pitch", "camera_pitch", "relative_z", "relative_pitch", "helmet_y", "nose_y", "grounded"]))
	for cap in ([120] if pixel_only else [60, 120, 0]):
		Engine.max_fps = cap
		for mode in ([0] if pixel_only or legacy else range(4)):
			Input.action_release("accelerate")
			diagnostics.set_mode(0)
			var offset := track.curve.get_baked_length() * 0.76
			kart.safe_spawn = Transform3D(Basis.looking_at(track.sample_forward(offset)), track.sample_center(offset) + Vector3.UP * 0.6)
			kart.reset_to_spawn()
			for i in 40: await physics_frame
			kart.velocity = -kart.global_basis.z * 22
			Input.action_press("accelerate")
			diagnostics.set_mode(mode)
			await create_timer(0.7).timeout # Remove initial camera settling trend.
			var start := Time.get_ticks_usec()
			var frames := 0
			var minimum := INF
			var maximum := -INF
			var pitch_min := INF
			var pitch_max := -INF
			while Time.get_ticks_usec() - start < 1500000:
				await RenderingServer.frame_post_draw
				var sample: Dictionary = diagnostics.sample()
				minimum = minf(minimum, sample.helmet_y)
				maximum = maxf(maximum, sample.helmet_y)
				pitch_min = minf(pitch_min, sample.relative_pitch)
				pitch_max = maxf(pitch_max, sample.relative_pitch)
				frames += 1
				output.store_csv_line(PackedStringArray([str(cap),str(mode),str(Time.get_ticks_usec()),str(Engine.get_physics_frames()),str(kart.position.y),str(kart.get_node("Visual").rotation.x),str(main.get_node("ChaseCamera").rotation.x),str(sample.relative_position.z),str(sample.relative_pitch),str(sample.helmet_y),str(sample.nose_y),str(kart.is_on_floor())]))
			print("Presentation cap=",cap," mode=",mode," frames=",frames," screen_y_range=",maximum-minimum," relative_pitch_range=",pitch_max-pitch_min)
			if not legacy and maximum - minimum >= 1.0:
				failures += 1
				push_error("Presentation exceeds one-pixel screen-Y range")
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://artifacts/presentation_%s_%s_%s.png" % ["legacy" if legacy else "fixed",cap,mode])
			# Readback can stall the GPU. Keep it outside the timed rate window.
			if mode == 0 and cap == 120:
				for frame in 8:
					await RenderingServer.frame_post_draw
					root.get_texture().get_image().save_png("res://artifacts/presentation_%s_pixel_%02d.png" % ["legacy" if legacy else "fixed",frame])
	Input.action_release("accelerate")
	output.close()
	Engine.max_fps = 0
	print("Presentation renderer scenarios: ", 1 if pixel_only else (3 if legacy else 12), ", failures: ", failures)
	quit(1 if failures else 0)
