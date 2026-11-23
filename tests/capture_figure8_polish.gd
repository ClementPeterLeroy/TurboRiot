extends SceneTree
## Final-polish inspection: both logo faces and both pads, using the chase camera.
func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	root.size = Vector2i(1600, 900)
	DisplayServer.window_set_size(root.size)
	var world := TrackRegistry.get_definition(&"figure_8").instantiate_race()
	world.managed = true
	world.get_node("Items").enabled = false
	world.get_node("RaceManager").opponent_count = 0
	world.get_node("HUD").visible = false
	root.add_child(world)
	var kart := world.get_node("Kart") as KartController
	var track := world.get_node("Track") as TrackBuilder
	var chase := world.get_node("ChaseCamera") as Camera3D
	var locations := {"arch_front": 648.0, "pad_approach": 267.0, "pad_exit": 603.0}
	for label in locations:
		var offset: float = locations[label]
		kart.safe_spawn = Transform3D(Basis.looking_at(track.sample_forward(offset)), track.sample_center(offset) + Vector3.UP * 0.65)
		kart.reset_to_spawn()
		chase.current = true
		chase.snap_to_target()
		for i in 25:
			await process_frame
		await _save(label)
	# Inspect the rear face with the same chase camera, facing back along the road.
	kart.safe_spawn = Transform3D(Basis.looking_at(-track.sample_forward(12)), track.sample_center(12) + Vector3.UP * 0.65)
	kart.reset_to_spawn()
	chase.snap_to_target()
	for i in 25: await process_frame
	await _save("arch_back")
	var camera := Camera3D.new()
	camera.far = 1200
	world.add_child(camera)
	camera.current = true
	camera.global_position = Vector3(-180, 135, 170)
	camera.look_at(Vector3(-40, 0, -10))
	await _save("overview")
	camera.global_position = Vector3(-108, 12, 22)
	camera.look_at(Vector3(-50, 4, -1))
	await _save("bridge_side")
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 290
	camera.global_position = Vector3(-35, 470, -10)
	camera.look_at(Vector3(-35, 0, -10.001), Vector3.FORWARD)
	await _save("top")
	world.queue_free()
	await process_frame
	quit()

func _save(label: String) -> void:
	for i in 10:
		await process_frame
	await RenderingServer.frame_post_draw
	var path := "res://artifacts/v061_final_polish_%s.png" % label
	root.get_texture().get_image().save_png(path)
	print("STADIUM_CAPTURE ", path)
