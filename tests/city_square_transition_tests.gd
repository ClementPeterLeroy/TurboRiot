extends RefCounted
class LaneDriver extends AIInput:
	var fixed_lane := 0.0
	func _traffic_decision(_delta: float,_speed: float,_curvature: float) -> float:
		lane_target=fixed_lane
		return -1.0

func floor_at(track: TrackBuilder,kart: KartController,p: Vector3) -> Dictionary:
	return track.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(p+Vector3.UP*3,p-Vector3.UP*4,1,[kart.get_rid()]))
func wall(track: TrackBuilder,kart: KartController,a: Vector3,b: Vector3) -> Dictionary:
	return track.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(a,b,1,[kart.get_rid()]))

func run(s: SceneTree) -> void:
	var fixture: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/city_transitions.json"))
	for path in fixture.frozen_files:s.check(FileAccess.get_sha256("res://"+path)==preload("res://tests/music_scope.gd").expected_hash(path,fixture.frozen_files[path]),"Local transition preserves file: "+path)
	for path in fixture.current_hashes:s.check(FileAccess.get_sha256("res://"+path)==fixture.current_hashes[path],"Reviewed local source/scene: "+path)
	var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/environment/city_square/manifest.json"))
	var world := TrackRegistry.get_definition(&"delfino_square_ds").instantiate_race()
	world.managed=true
	world.get_node("Items").enabled=false
	world.get_node("RaceManager").opponent_count=0
	s.root.add_child(world)
	await s.physics_frame
	var race := world.get_node("RaceManager") as RaceManager
	var track := race.track as TrackBuilder
	var kart := race.kart
	var environment := track.get_node("Ground")
	var architecture := environment.get_node("Architecture")
	var lots := {}
	for house in manifest.houses:lots[house.name]=house
	for old in fixture.houses:
		if old.name in fixture.moved_houses:continue
		var instance := architecture.get_node(NodePath(old.name)) as Node3D
		var original := Vector3(old.position[0],old.position[1],old.position[2])
		s.check(lots[old.name]==old and instance.position.distance_to(original)<.001 and absf(angle_difference(instance.rotation.y,old.yaw))<.0001 and instance.scale.is_equal_approx(Vector3.ONE),"Existing house unchanged: "+old.name)
	s.check(manifest.houses.size()==128 and architecture.get_child_count()==128,"Eleven reused local modules are added; no original house is removed")
	s.check(manifest.transition_removed_link_groups==["AvenueEntryWest","AvenueEntryEast"] and environment.get_node("ArchitecturalLinks").get_child_count()==10,"Only the two irregular entrance infills are replaced")
	for name in manifest.transition_removed_link_groups:s.check(not environment.has_node(name+"Collision"),"Removed infill leaves no hidden collider: "+name)
	for name in ["PavedStreets","GardenGrass"]:
		var saved := environment.get_node(name+"Collision").get_child(0) as CollisionShape3D
		var triangles := (saved.shape as ConcavePolygonShape3D).get_faces()
		var valid := true
		for i in range(0,triangles.size(),3):
			var p := (triangles[i]+triangles[i+1]+triangles[i+2])/3
			if p.x>=-146 and p.x<=-75 and p.z>=80 and p.z<=144:
				valid=valid and (triangles[i+1]-triangles[i]).cross(triangles[i+2]-triangles[i]).length_squared()>=1e-12
		s.check(valid,"Imported local collision contains no collapsed triangles: "+name)
	var frontage := true
	var minimum_fountain := INF
	for z in range(-64,-48):
		var p := Vector3(-120,12,z)
		for side in [-1.0,1.0]:
			var hit := wall(track,kart,p,p+Vector3.RIGHT*side*40)
			frontage=frontage and not hit.is_empty() and architecture.is_ancestor_of(hit.collider)
			if not hit.is_empty():minimum_fountain=minf(minimum_fountain,p.distance_to(hit.position))
	s.check(frontage,"Both fountain entrance terrace gaps are filled by shared house modules")
	s.check(minimum_fountain>11.5,"Fountain approach preserves the full 22 m drivable street and sightline")
	var garden_north := true
	for x in range(-95,31,2):
		var hit := wall(track,kart,Vector3(x,5,96),Vector3(x,5,60))
		garden_north=garden_north and not hit.is_empty()
	s.check(garden_north,"Garden north land edge is continuous through the former gap to the coast frontage")
	var garden_west := true
	for z in range(98,142):
		var hit := wall(track,kart,Vector3(-125,4,z),Vector3(-145,4,z))
		garden_west=garden_west and not hit.is_empty() and architecture.is_ancestor_of(hit.collider)
	s.check(garden_west,"Garden and avenue west frontage is a complete modular terrace outside the paved passage")
	var paved := true
	var maximum_grade := 0.0
	for station in range(1068,1119,2):
		for lane in [-7.5,0.0,7.5]:
			var hit := floor_at(track,kart,track.sample_center(station)+track.road_right(station)*lane)
			paved=paved and not hit.is_empty() and str(hit.collider.name)=="PavedStreetsCollision" and hit.normal.y>.8
			if hit.is_empty() or str(hit.collider.name)!="PavedStreetsCollision" or hit.normal.y<=.8:print("CITY_PAVED_BAD ",station," lane=",lane," hit=",hit)
			if not hit.is_empty():maximum_grade=maxf(maximum_grade,1-hit.normal.y)
	s.check(paved,"The expanded 15 m lane envelope is fully paved with walkable support")
	race.start_race()
	race.session.advance(3)
	race.set_physics_process(false)
	kart.get_node("Recovery").set_physics_process(false)
	var line := RacingLine.new()
	line.build(track,0,false)
	var driver := LaneDriver.new()
	driver.kart=kart
	driver.line=line
	driver.profile=RaceManager.PROFILES[2].duplicate()
	driver.profile.speed_fraction=.3
	driver.profile.lateral_acceleration=1.5
	driver.profile.lookahead_base=2.5
	driver.profile.lookahead_seconds=.1
	kart.add_child(driver)
	kart.input_provider=driver
	var measurements: Array[Dictionary]=[]
	for lane in [-6.0,0.0,6.0]:
		driver.set_physics_process(false)
		driver.fixed_lane=lane
		var start: Vector3=track.sample_center(1068)+track.road_right(1068)*lane
		var hit := floor_at(track,kart,start)
		var forward := track.sample_forward(1068)
		forward.y=0
		kart.safe_spawn=Transform3D(Basis.looking_at(forward.normalized()),hit.position+Vector3.UP*.7)
		kart.reset_to_spawn()
		driver._command=DrivingCommand.new()
		for i in 35:await s.physics_frame
		driver.expected_offset=1145
		driver.validated_offset=1060
		driver.lane_target=lane
		driver.lane_offset=lane
		driver.set_physics_process(true)
		var complete := false
		var air := 0
		var step := 0.0
		var previous := kart.global_position.y
		for i in 1000:
			await s.physics_frame
			if not kart.is_on_floor():air+=1
			step=maxf(step,absf(kart.global_position.y-previous))
			previous=kart.global_position.y
			if driver.current_offset>1120 and driver.current_offset<1150:complete=true;break
		measurements.append({"lane":lane,"completed":complete,"airborne":air,"maximum_y_step":step,"last_offset":driver.current_offset})
		s.check(complete,"Kart traverses the local garden entrance on lane "+str(lane))
		s.check(air==0 and step<.08,"Entrance lane retains smooth ground contact: "+str(lane))
	FileAccess.open("res://artifacts/v061_city_transitions_driving.json",FileAccess.WRITE).store_string(JSON.stringify({"lanes":measurements,"fountain_facade_clearance":minimum_fountain,"maximum_grade_factor":maximum_grade},"\t"))
	world.queue_free()
	await s.process_frame
