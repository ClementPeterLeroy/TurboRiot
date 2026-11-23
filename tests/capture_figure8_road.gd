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
	await capture(camera,Vector3(-165,110,145),Vector3(-35,0,-15),"overview")
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=220
	await capture(camera,Vector3(-35,450,-10),Vector3(-35,0,-10.001),"top")
	camera.projection=Camera3D.PROJECTION_PERSPECTIVE
	camera.current=false
	var race := world.get_node("RaceManager") as RaceManager
	var kart := race.kart
	var offset := race.track.curve.get_closest_offset(Vector3(-90,6,40))
	kart.safe_spawn=race.track.global_transform*Transform3D(Basis.looking_at(race.track.sample_forward(offset)),race.track.sample_center(offset)+Vector3.UP*.65)
	kart.reset_to_spawn()
	var chase := world.get_node("ChaseCamera") as Camera3D
	chase.current=true
	chase.snap_to_target()
	for frame in 20:await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/v061_figure8_milestone_a_chase.png")
	world.queue_free()
	await process_frame
	quit()

func capture(camera: Camera3D, position: Vector3, focus: Vector3, label: String) -> void:
	camera.global_position=position
	camera.look_at(focus,Vector3.FORWARD if absf((focus-position).normalized().y)>0.99 else Vector3.UP)
	for frame in 12: await process_frame
	await RenderingServer.frame_post_draw
	var path := "res://artifacts/v061_figure8_milestone_a_%s.png" % label
	root.get_texture().get_image().save_png(path)
	print("FIGURE8 CAPTURE ",path)
