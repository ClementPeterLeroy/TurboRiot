extends SceneTree
func _initialize() -> void: run.call_deferred()

func run() -> void:
	root.size=Vector2i(1600,900)
	DisplayServer.window_set_size(root.size)
	var world := TrackRegistry.get_definition(&"figure_8").instantiate_race()
	world.managed=true
	world.get_node("Items").enabled=false
	world.get_node("RaceManager").opponent_count=0
	world.get_node("HUD").visible=false
	root.add_child(world)
	var camera := Camera3D.new()
	camera.far=1000
	world.add_child(camera)
	camera.current=true
	var c := Vector3(-50.4103,0,-1.2591)
	await capture(camera,Vector3(-210,170,170),Vector3(-35,0,-20),"overview")
	await capture(camera,c+Vector3(38,2.8,0),c+Vector3(-15,3,0),"underpass")
	await capture(camera,c+Vector3(-30,20,38),c+Vector3(12,6,-14),"bridge")
	await capture(camera,Vector3(10,4,-3),Vector3(18,4,22),"grandstand")
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=230
	await capture(camera,Vector3(-35,450,-20),Vector3(-35,0,-20.001),"top")
	world.queue_free()
	await process_frame
	quit()

func capture(camera: Camera3D, position: Vector3, focus: Vector3, label: String) -> void:
	camera.global_position=position
	camera.look_at(focus,Vector3.FORWARD if absf((focus-position).normalized().y)>0.99 else Vector3.UP)
	for frame in 12: await process_frame
	await RenderingServer.frame_post_draw
	var path := "res://artifacts/v061_figure8_environment_%s.png" % label
	root.get_texture().get_image().save_png(path)
	print("FIGURE8 CAPTURE ",path)
