extends SceneTree
## Real chase-camera and contextual views of only the two correction zones.
func _initialize() -> void:run.call_deferred()
func run() -> void:
	var prefix := "v061_city_transitions"
	if "--before" in OS.get_cmdline_user_args():prefix+="_before"
	root.size=Vector2i(1600,900)
	DisplayServer.window_set_size(root.size)
	var world := TrackRegistry.get_definition(&"delfino_square_ds").instantiate_race()
	world.managed=true
	world.get_node("Items").enabled=false
	world.get_node("RaceManager").opponent_count=0
	world.get_node("HUD").visible=false
	root.add_child(world)
	var track := world.get_node("Track") as TrackBuilder
	var kart := world.get_node("Kart") as KartController
	var camera := world.get_node("ChaseCamera") as Camera3D
	for offset in [90.0,110.0,130.0,150.0,1070.0,1085.0,1095.0,1105.0,1115.0]:
		var forward := track.sample_forward(offset)
		forward.y=0
		kart.safe_spawn=Transform3D(Basis.looking_at(forward.normalized()),track.sample_center(offset)+Vector3.UP*.416)
		kart.reset_to_spawn()
		camera.snap_to_target()
		await capture(prefix,"race_%d"%offset)
	var eye := Camera3D.new()
	world.add_child(eye)
	eye.current=true
	eye.far=1000
	for spec in [
		["fountain_oblique",Vector3(-174,65,-35),Vector3(-120,10,-80)],
		["garden_oblique",Vector3(-165,65,164),Vector3(-79,2,108)],
		["garden_town_edge",Vector3(22,45,152),Vector3(-60,2,89)],
		["fountain_overhead",Vector3(-120,180,-78),Vector3(-120,0,-78.001)],
		["garden_overhead",Vector3(-66,180,111),Vector3(-66,0,110.999)]]:
		eye.global_position=spec[1]
		eye.look_at(spec[2],Vector3.FORWARD if str(spec[0]).ends_with("overhead") else Vector3.UP)
		await capture(prefix,spec[0])
	world.queue_free()
	await process_frame
	quit()
func capture(prefix: String,label: String) -> void:
	for i in 35:await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/%s_%s.png"%[prefix,label])
