extends SceneTree
## Native source/module and real-chase-camera views, before/after architecture.
var prefix := "v061_city_architecture"
func _initialize() -> void:run.call_deferred()
func save(label: String) -> void:
	for i in 12:await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/%s_%s.png"%[prefix,label])
func run() -> void:
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
	var results: Array[Dictionary]=[]
	for offset in [1070.0,1085.0,1095.0,1105.0,1115.0]:
		var forward := track.sample_forward(offset)
		forward.y=0
		kart.safe_spawn=Transform3D(Basis.looking_at(forward.normalized()),track.sample_center(offset)+Vector3.UP*.416)
		kart.reset_to_spawn()
		camera.snap_to_target()
		for i in 30:await process_frame
		var clearance := []
		for side in [-1.0,1.0]:
			var p := kart.global_position+Vector3.UP
			var hit := track.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(p,p+track.road_right(offset)*side*20,1,[kart.get_rid()]))
			clearance.append({"side":side,"distance":p.distance_to(hit.position) if not hit.is_empty() else 20,"collider":str(hit.collider.name) if not hit.is_empty() else "none"})
		results.append({"offset":offset,"camera_distance":kart.global_position.distance_to(camera.global_position),"clearance":clearance})
		print("CITY_ENTRY_VIEW ",JSON.stringify(results[-1]))
		await save("entry_%d"%int(offset))
	var overview := Camera3D.new()
	world.add_child(overview)
	overview.current=true
	overview.global_position=Vector3(-90,38,145)
	overview.look_at(Vector3(-119,3,105))
	await save("entry_overview")
	world.queue_free()
	for i in 3:await process_frame
	var gallery := Node3D.new()
	gallery.set_script(load("res://scripts/track/city_materials.gd"))
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-40,-32,0)
	sun.light_energy=1.5
	sun.shadow_enabled=true
	gallery.add_child(sun)
	var ambient := WorldEnvironment.new()
	ambient.environment=Environment.new()
	ambient.environment.background_mode=Environment.BG_COLOR
	ambient.environment.background_color=Color("6f9cac")
	ambient.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	ambient.environment.ambient_light_color=Color("b6c1c5")
	ambient.environment.ambient_light_energy=.55
	gallery.add_child(ambient)
	var floor_node := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size=Vector2(70,70)
	floor_node.mesh=plane
	floor_node.material_override=RiotGeometry.material(Color("405661"))
	gallery.add_child(floor_node)
	root.add_child(gallery)
	var eye := Camera3D.new()
	eye.fov=50
	gallery.add_child(eye)
	eye.current=true
	for name in ["townhouse","narrow_house","wide_house","merchant_house","corner_house","harbour_house"]:
		var model := load("res://scenes/environment/city_square/%s.tscn"%name).instantiate() as Node3D
		model.position.y=.9
		gallery.add_child(model)
		gallery._apply(model)
		for view in ["front","rear","above"]:
			eye.global_position=Vector3(17,8,-23) if view=="front" else Vector3(-17,9,23) if view=="rear" else Vector3(16,23,-19)
			eye.look_at(Vector3(0,5,0))
			await save(name+"_"+view)
		model.queue_free()
		await process_frame
	for x in [-4.0,4.0]:
		var model := load("res://scenes/environment/city_square/townhouse.tscn").instantiate() as Node3D
		model.position=Vector3(x,.9,0)
		gallery.add_child(model)
		gallery._apply(model)
	eye.global_position=Vector3(14,18,-21)
	eye.look_at(Vector3(0,5,0))
	await save("adjacent_roofs")
	FileAccess.open("res://artifacts/%s_entry.json"%prefix,FileAccess.WRITE).store_string(JSON.stringify(results,"\t"))
	gallery.queue_free()
	await process_frame
	quit()
