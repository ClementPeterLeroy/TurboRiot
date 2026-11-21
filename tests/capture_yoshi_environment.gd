extends SceneTree
func _initialize() -> void: run.call_deferred()

func run() -> void:
	root.size=Vector2i(1600,900)
	DisplayServer.window_set_size(root.size)
	var world := TrackRegistry.get_definition(&"yoshi_ds").instantiate_race()
	world.managed=true
	world.get_node("Items").enabled=false
	world.get_node("RaceManager").opponent_count=0
	world.get_node("HUD").visible=false
	root.add_child(world)
	var camera := Camera3D.new()
	camera.far=1000
	world.add_child(camera)
	camera.current=true
	await capture(camera,Vector3(190,160,250),Vector3(0,0,-10),"overview")
	await capture(camera,Vector3(5,4,144),Vector3(20,4,170),"paddock")
	await capture(camera,Vector3(8,4,-14),Vector3(55,4,-14),"tunnel")
	await capture(camera,Vector3(-55,4,-90),Vector3(-85,4,-105),"gardens")
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=440
	await capture(camera,Vector3(0,600,0),Vector3(0,0,-.001),"top")
	world.queue_free()
	await process_frame
	quit()

func capture(camera: Camera3D, position: Vector3, focus: Vector3, label: String) -> void:
	camera.global_position=position
	camera.look_at(focus,Vector3.FORWARD if absf((focus-position).normalized().y)>0.99 else Vector3.UP)
	for frame in 12: await process_frame
	await RenderingServer.frame_post_draw
	var path := "res://artifacts/v061_yoshi_environment_%s.png" % label
	root.get_texture().get_image().save_png(path)
	print("YOSHI CAPTURE ",path)
