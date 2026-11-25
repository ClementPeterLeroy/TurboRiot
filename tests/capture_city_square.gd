extends SceneTree
## Actual shared chase camera at six required sites, plus structural views.
func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	root.size = Vector2i(1600, 900)
	DisplayServer.window_set_size(root.size)
	var world := TrackRegistry.get_definition(&"delfino_square_ds").instantiate_race()
	world.managed = true
	world.get_node("Items").enabled = false
	world.get_node("RaceManager").opponent_count = 0
	world.get_node("HUD").visible = false
	root.add_child(world)
	var kart := world.get_node("Kart") as KartController
	var track := world.get_node("Track") as TrackBuilder
	var chase := world.get_node("ChaseCamera") as Camera3D
	var locations := {"avenue": 0.0, "fountain": 155.0, "city": 330.0, "outer_stairs": 445.0, "docks": 650.0, "gardens": 1010.0}
	for label in locations:
		var offset: float = locations[label]
		kart.safe_spawn = Transform3D(Basis.looking_at(track.sample_forward(offset)), track.sample_center(offset) + Vector3.UP * 0.65)
		kart.reset_to_spawn()
		chase.current = true
		chase.snap_to_target()
		for i in 25:
			await process_frame
		await _save(label)
	for variant in 2:
		var line := RacingLine.new()
		line.build(track,variant,false)
		var offset := line.from_canonical(track.route_branches[0].entry_offset+55)
		var forward := line.point_at(offset+.2)-line.point_at(offset-.2)
		forward.y=0
		kart.safe_spawn=Transform3D(Basis.looking_at(forward.normalized()),line.point_at(offset)+Vector3.UP*.65)
		kart.reset_to_spawn()
		chase.snap_to_target()
		for i in 25: await process_frame
		await _save("left_long_stairs" if variant==1 else "right_short_stairs")
	var camera := Camera3D.new()
	camera.far = 1200
	world.add_child(camera)
	camera.current = true
	camera.global_position = Vector3(220, 250, 280)
	camera.look_at(Vector3(-20, 2, -20))
	await _save("overview")
	camera.global_position = Vector3(185, 8, 50)
	camera.look_at(Vector3(120, 1, 65))
	await _save("dock_side")
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 320
	camera.global_position = Vector3(-10, 470, -10)
	camera.look_at(Vector3(-10, 0, -10.001), Vector3.FORWARD)
	await _save("top")
	world.queue_free()
	await process_frame
	quit()

func _save(label: String) -> void:
	for i in 10:
		await process_frame
	await RenderingServer.frame_post_draw
	var path := "res://artifacts/v061_city_%s.png" % label
	root.get_texture().get_image().save_png(path)
	print("CITY_CAPTURE ", path)
