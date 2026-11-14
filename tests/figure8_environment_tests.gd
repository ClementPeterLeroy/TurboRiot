extends RefCounted
## Physical space contracts for additions around the unchanged driving surface.
func run(s: SceneTree) -> void:
	var world := TrackRegistry.get_definition(&"figure_8").instantiate_race()
	world.managed=true
	world.get_node("Items").enabled=false
	world.get_node("RaceManager").opponent_count=0
	s.root.add_child(world)
	var track := world.get_node("Track") as TrackBuilder
	var kart := world.get_node("Kart") as KartController
	var art := track.get_node_or_null("EnvironmentArt") as Node3D
	s.check(art!=null, "Figure-8 authored environment survives application circuit loading")
	if art==null:
		world.queue_free()
		await s.process_frame
		return
	await s.physics_frame
	s.check(art.get_node("Grandstands").get_child_count()==2 and art.get_node("Props").get_child_count()==4,
		"Figure-8 uses two stands and four individually editable flags")
	var finish := art.get_node("Grandstands/FinishStand") as Node3D
	var north := art.get_node("Grandstands/NorthStand") as Node3D
	s.check(finish.scene_file_path==north.scene_file_path and not finish.scene_file_path.is_empty(), "Grandstands are instances of one reusable PackedScene")
	var first_mesh := finish.find_child("SteppedStructure",true,false) as MeshInstance3D
	var second_mesh := north.find_child("SteppedStructure",true,false) as MeshInstance3D
	s.check(first_mesh!=null and second_mesh!=null and first_mesh.mesh==second_mesh.mesh, "Both grandstands share imported mesh resources")
	var materials_ok := _materials_ok(art)
	s.check(materials_ok, "Every environment mesh has a valid opaque material")
	var length := track.curve.get_baked_length()
	var clear_road := true
	var maximum_height_error := 0.0
	var source_floor := track.get_node("Generated/Asphalt/Asphalt_col")
	# Keep support and scenery off all racing lanes, including the full grades.
	for i in ceili(length/2):
		var offset := length*(i+0.3)/ceili(length/2)
		for lateral in [-5.5,0.0,5.5]:
			var point: Vector3 = track.sample_center(offset)+track.road_right(offset)*lateral
			var ray := PhysicsRayQueryParameters3D.create(point+Vector3.UP,point-Vector3.UP,1,[kart.get_rid()])
			var hit := track.get_world_3d().direct_space_state.intersect_ray(ray)
			clear_road=clear_road and not hit.is_empty()
			if not hit.is_empty():
				clear_road=clear_road and hit.collider==source_floor
				maximum_height_error=maxf(maximum_height_error,absf(hit.position.y-point.y))
	# Identity is stronger than comparing against the ideal curve: the original
	# one-metre triangulated road itself approximates that curve between rows.
	s.check(clear_road, "New structure collision never replaces/intersects the source road in any driving lane")
	var piers_clear := true
	for pier: MeshInstance3D in art.get_node("Bridge/Supports").get_children():
		var bounds := pier.global_transform*pier.get_aabb()
		piers_clear=piers_clear and (bounds.end.z < -11.0 or bounds.position.z > 9.0)
	s.check(piers_clear, "All four bridge piers clear the lower road and its barriers")
	var minimum_clearance := INF
	var roof_hits := 0
	for x in [-60.0,-50.4,-40.0]:
		for z in [-6.0,-1.25,3.5]:
			var point := Vector3(x,0.14,z)
			var ray := PhysicsRayQueryParameters3D.create(point,point+Vector3.UP*10,1,[kart.get_rid()])
			var hit := track.get_world_3d().direct_space_state.intersect_ray(ray)
			if not hit.is_empty():
				roof_hits+=1
				minimum_clearance=minf(minimum_clearance,hit.position.y-0.04)
	# The bridge is diagonal: some corners of this lower-road rectangle have
	# open sky rather than a roof. Clearance applies where a roof actually exists.
	s.check(roof_hits>=5 and minimum_clearance>2.25, "Physical bridge underside clears the actual 0.75 m kart hull and visible driver with margin")
	var stand_clear := true
	for i in 120:
		var offset := length*i/120
		var c := track.sample_center(offset)
		for stand in [finish,north]:
			var box := AABB(Vector3(-30,0,-6),Vector3(60,4.8,12))
			var local: Vector3 = stand.to_local(c)
			stand_clear=stand_clear and not box.grow(2.0).has_point(local)
	s.check(stand_clear, "Grandstand structural masses stay outside road space")
	var profile: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://resources/tracks/figure_8_environment_profile.json"))
	var banks_supported := true
	for section in profile.banks:
		var row: Dictionary=section[section.size()/2]
		var c := Vector3(row.center[0],row.center[1],row.center[2])
		var right := Vector3(row.right[0],row.right[1],row.right[2]).normalized()
		for side in [-1.0,1.0]:
			var point: Vector3 = c+right*side*13.9
			point.y=lerpf(c.y-0.12,-0.08,0.5)
			var hit := track.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(point+Vector3.UP,point-Vector3.UP,1,[kart.get_rid()]))
			banks_supported=banks_supported and not hit.is_empty()
			if not hit.is_empty():banks_supported=banks_supported and hit.normal.y>0.8 and hit.collider.get_meta("surface",null)==preload("res://resources/surfaces/grass.tres")
	s.check(banks_supported, "Approach verges have upward-facing support and explicit grass surface metadata")
	s.check(art.get_node("Bridge/DeckCollision").get_child_count()==42 and art.get_node("Bridge/Supports").get_child_count()==4,
		"Bridge uses a bounded set of simple deck and support collisions")
	s.check(kart.get_node("Recovery").recovery_half_extents==track.playable_half_extents+Vector2.ONE*8,
		"Figure-8 environment retains existing circuit recovery bounds")
	# Rebuild only the procedural road; authored instances must survive intact.
	var stand_id := finish.get_instance_id()
	track.build()
	await s.process_frame
	s.check(is_instance_valid(art) and finish.get_instance_id()==stand_id, "Procedural rebuild preserves authored scenery instances and placement")
	print("FIGURE8 ENVIRONMENT clearance=%.3fm maximum_road_height_error=%.5fm" % [minimum_clearance,maximum_height_error])
	world.queue_free()
	await s.process_frame

func _materials_ok(node: Node) -> bool:
	if node is MeshInstance3D:
		if node.mesh==null:return false
		for i in node.mesh.get_surface_count():
			var paint: Material = node.get_active_material(i)
			if not paint is BaseMaterial3D or paint.transparency!=BaseMaterial3D.TRANSPARENCY_DISABLED:return false
	for child in node.get_children():
		if not _materials_ok(child):return false
	return true
