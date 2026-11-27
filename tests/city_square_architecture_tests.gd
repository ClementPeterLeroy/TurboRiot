extends RefCounted
## Actual saved source instances and entrance clearances; no driving code changes.
func run(s: SceneTree) -> void:
	var frozen: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/city_architecture_frozen.json"))
	# The later local paving pass explicitly supersedes only its four approved
	# source/export hashes. The original architectural baseline remains recorded.
	var local := "res://tests/fixtures/city_transitions.json"
	if FileAccess.file_exists(local):
		var approved: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(local))
		for path in frozen:
			if approved.current_hashes.has(path):frozen[path]=approved.current_hashes[path]
	for path in frozen:s.check(FileAccess.get_sha256("res://"+path)==preload("res://tests/music_scope.gd").expected_hash(path,frozen[path]),"Architecture feature freeze: "+path)
	var world := TrackRegistry.get_definition(&"delfino_square_ds").instantiate_race()
	world.managed=true
	world.get_node("Items").enabled=false
	world.get_node("RaceManager").opponent_count=0
	s.root.add_child(world)
	await s.physics_frame
	var track := world.get_node("Track") as TrackBuilder
	var kart := world.get_node("Kart") as KartController
	var camera := world.get_node("ChaseCamera") as Camera3D
	var ground := track.get_node("Ground") as Node3D
	var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/environment/city_square/manifest.json"))
	var models := {}
	for house in ground.get_node("Architecture").get_children():
		var mesh := house.find_child("House",true,false) as MeshInstance3D
		if mesh:models[mesh.mesh.get_instance_id()]=true
	s.check(models.size()==6,"All house instances share the same six module meshes")
	for house in manifest.houses:
		if not manifest.entrance_setbacks_x.has(house.name):continue
		var instance := ground.get_node("Architecture/"+house.name) as Node3D
		s.check(instance.position.distance_to(Vector3(house.position[0],house.position[1],house.position[2]))<.001,"Entrance instance agrees with source manifest: "+house.name)
	for name in manifest.link_setbacks_x:
		var mesh := ground.get_node("ArchitecturalLinks/"+name) as MeshInstance3D
		var collider := ground.get_node(name+"Collision").get_child(0) as CollisionShape3D
		s.check(mesh.transform.is_equal_approx(collider.transform),"Entrance collision follows moved source: "+name)
		var faces := mesh.mesh.get_faces()
		s.check(faces==collider.shape.get_faces(),"Entrance collision matches corrected roof/wall mesh: "+name)
	kart.set_physics_process(false)
	camera.set_process(false)
	var samples: Array[Dictionary]=[]
	var clear := true
	var minimum_clearance := 100.0
	var minimum_camera := 100.0
	for offset in range(1070,1141,2):
		var center := track.sample_center(offset)
		var forward := track.sample_forward(offset)
		forward.y=0
		for side in [-1.0,1.0]:
			var p := center+Vector3.UP*1.4
			var hit := track.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(p,p+track.road_right(offset)*side*20,1,[kart.get_rid()]))
			if not hit.is_empty():minimum_clearance=minf(minimum_clearance,p.distance_to(hit.position))
		for lane in [-3.5,0.0,3.5]:
			kart.safe_spawn=Transform3D(Basis.looking_at(forward.normalized()),center+track.road_right(offset)*lane+Vector3.UP*.416)
			kart.reset_to_spawn()
			camera.snap_to_target()
			for i in 60:camera._process(1.0/60.0)
			var distance := camera.global_position.distance_to(kart.global_position)
			minimum_camera=minf(minimum_camera,distance)
			var visible := not camera.is_position_behind(kart.global_position+Vector3.UP*.5)
			clear=clear and distance>6.0 and visible
			samples.append({"offset":offset,"lane":lane,"camera_distance":distance,"visible":visible})
	s.check(minimum_clearance>5.0,"Entire garden-to-avenue transition keeps facades outside the full 10 m garden road")
	s.check(clear,"Centre and both driving lanes keep a visible kart and at least 6 m chase-camera clearance")
	var report_path := "res://artifacts/v061_city_transitions_clearance.json" if manifest.get("transition_revision",0)>0 else "res://artifacts/v061_city_architecture_clearance.json"
	FileAccess.open(report_path,FileAccess.WRITE).store_string(JSON.stringify({"minimum_facade_clearance":minimum_clearance,"minimum_camera_distance":minimum_camera,"samples":samples},"\t"))
	world.queue_free()
	await s.process_frame
