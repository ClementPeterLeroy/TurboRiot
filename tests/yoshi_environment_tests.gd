extends RefCounted
func run(s: SceneTree) -> void:
	var world := TrackRegistry.get_definition(&"yoshi_ds").instantiate_race()
	world.managed=true
	world.get_node("Items").enabled=false
	world.get_node("RaceManager").opponent_count=0
	s.root.add_child(world)
	await s.physics_frame
	var track := world.get_node("Track") as TrackBuilder
	var kart := world.get_node("Kart") as KartController
	var art := track.get_node("EnvironmentArt")
	s.check(art.get_node("Trees").get_child_count()==21 and art.get_node("Flowers").get_child_count()==12,"Yoshi contains individually editable garden instances")
	s.check(art.get_node("Tunnels").get_child_count()==2 and art.get_node("Grandstands").get_child_count()==2,"Yoshi has two modular tunnels and two start stands")
	s.check(art.get_node("Paddock").get_child_count()==3,"Yoshi has three reusable paddock buildings")
	var length := track.curve.get_baked_length()
	var clear := true
	var island := true
	for i in 600:
		var offset := length*(i+0.2)/600
		for side in [-9.0,0.0,9.0]:
			var p: Vector3=track.sample_center(offset)+track.road_right(offset)*side
			var ray := PhysicsRayQueryParameters3D.create(p+Vector3.UP,p-Vector3.UP,1,[kart.get_rid()])
			var hit := track.get_world_3d().direct_space_state.intersect_ray(ray)
			clear=clear and not hit.is_empty()
			if not hit.is_empty():clear=clear and hit.collider==track.get_node("Generated/Asphalt/Asphalt_col")
		# The island must support the shoulders outside the existing barriers too.
		for side in [-12.0,12.0]:
			var p: Vector3=track.sample_center(offset)+track.road_right(offset)*side
			var hit := track.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(p+Vector3.UP,p-Vector3.UP,1,[kart.get_rid()]))
			island=island and not hit.is_empty()
	s.check(clear,"Yoshi scenery preserves source-asphalt support across every sampled driving lane")
	s.check(island,"Authored island supports the entire road corridor and shoulders")
	var minimum := INF
	var roof := true
	for tunnel: Node3D in art.get_node("Tunnels").get_children():
		for x in [-10.0,0.0,10.0]:
			var p: Vector3=tunnel.to_global(Vector3(x,.3,0))
			var hit := track.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(p,p+Vector3.UP*20,1,[kart.get_rid()]))
			roof=roof and not hit.is_empty()
			if not hit.is_empty():minimum=minf(minimum,hit.position.y-.04)
	s.check(roof and minimum>7.0,"Tunnel arches clear the kart and chase camera across the road width")
	var tree0 := art.get_node("Trees/GardenTree00")
	var tree1 := art.get_node("Trees/GardenTree01")
	s.check(tree0.scene_file_path==tree1.scene_file_path,"Trees reuse the same PackedScene rather than unique generated meshes")
	s.check(art.get_node("Sea").position.y< -1 and art.get_node("Sea").get_child_count()==0,"Animated sea remains below the island and has no driving collision")
	var hit := track.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(0,1,104),Vector3(0,-1,104),1,[kart.get_rid()]))
	s.check(not hit.is_empty() and hit.normal.y>.99 and hit.collider.get_meta("surface",null)==preload("res://resources/surfaces/grass.tres"),"Island grass uses upward support and explicit SurfaceConfig")
	var sea_hit := track.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(190,1,190),Vector3(190,-5,190),1,[kart.get_rid()]))
	s.check(sea_hit.is_empty(),"Coastal water has no hidden grass floor")
	var id := art.get_instance_id()
	track.build()
	await s.process_frame
	s.check(is_instance_valid(art) and art.get_instance_id()==id,"Procedural road rebuild retains authored Yoshi environment")
	print("YOSHI ENVIRONMENT minimum_tunnel_clearance=",minimum)
	world.queue_free()
	await s.process_frame
