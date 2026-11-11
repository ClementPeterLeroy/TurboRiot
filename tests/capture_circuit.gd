extends SceneTree
func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var id: StringName = &"figure_8"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--circuit="): id = StringName(arg.get_slice("=", 1))
	var trace: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://resources/tracks/%s_trace.json" % id))
	var dimensions := Vector2i(trace.image_size[0], trace.image_size[1])
	root.size = dimensions
	DisplayServer.window_set_size(dimensions)
	var world := TrackRegistry.get_definition(id).instantiate_race()
	world.managed = true
	world.get_node("Items").enabled = false
	world.get_node("HUD").visible = false
	world.get_node("Kart").visible = false
	world.get_node("RaceManager").opponent_count = 0
	root.add_child(world)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.size = dimensions.y * float(trace.metres_per_pixel)
	camera.position = Vector3(0, 600, 0)
	camera.rotation_degrees.x = -90
	camera.far = 1000
	world.add_child(camera)
	camera.current = true
	for frame in 12: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/v061_%s_top.png" % id)
	print("Captured native orthographic %s %s" % [id, root.size])
	world.queue_free()
	await process_frame
	quit()
