extends RefCounted
func run(s: SceneTree) -> void:
	var world := TrackRegistry.get_definition(&"delfino_square_ds").instantiate_race()
	world.managed=true
	world.get_node("Items").enabled=false
	world.get_node("RaceManager").opponent_count=0
	s.root.add_child(world)
	await s.physics_frame
	await s.physics_frame
	var track := world.get_node("Track") as AuthoredCircuit
	var race := world.get_node("RaceManager") as RaceManager
	var kart := race.kart
	s.check(track!=null and track.is_curve_closed(),"City uses a closed authored circuit and native mesh scene")
	s.check(track.route_branches.size()==2 and race.gates.size()==14,"City has alternative streets/fountain and common ordered gates")
	var previews := TrackRegistry.get_definition(&"delfino_square_ds").preview_branches()
	s.check(previews.size()==2 and previews[0]==track.route_branches[0].curve and previews[1]==track.route_branches[1].curve,"City previews share actual branch resources without loading environment instances")
	s.check(track.get_node("Ground/Architecture").get_child_count()>130,"City reuses modular townhouses in coherent blocks")
	s.check(not track.has_node("Generated/BarrierCollision"),"City has no artificial track barriers")
	s.check(world.get_node("TrackFeatures/Generated").get_child_count()==0,"City adds no speed pads or optional launch ramps")
	var street := track.route_branches[0]
	s.near(street.curve.get_baked_length(),street.exit_offset-street.entry_offset,"Both city streets have equal three-dimensional length",.01)
	s.near(street.curve.get_point_position(0).y-street.curve.get_point_position(street.curve.point_count-1).y,5.4,"Both stair routes descend 5.4 metres",.01)
	var errors: Array[String]=[]
	for variant in 4:
		var line := RacingLine.new()
		line.build(track,variant,false)
		var clear := true
		for i in line.points.size():
			var p := line.points[i]
			var hit := track.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(p+Vector3.UP,p-Vector3.UP,1,[kart.get_rid()]))
			if hit.is_empty() or not str(hit.collider.name) in ["PavedStreetsCollision","TimberDecksCollision"]:
				clear=false
				if errors.size()<4:errors.append(str(p))
		s.check(clear,"Every route variant has continuous physical support: "+str(variant)+str(errors))
		for offset in [10.0,100.0,300.0,600.0,1000.0]:
			s.near(line.routes.to_canonical(line.from_canonical(offset)),offset,"Branch station mapping round-trips",.02)
	var fountain := track.route_branches[1]
	var driver := AIInput.new()
	driver.line=RacingLine.new()
	driver.line.build(track,3,false)
	var previous_input := kart.input_provider
	kart.input_provider=driver
	var fork_gate: CheckpointGate=race.gates[2]
	var pose := race._recovery_pose(race.competitors[0],fork_gate)
	var station := driver.line.from_canonical(fork_gate.route_offset)+2
	s.check(pose.origin.distance_to(driver.line.point_at(station)+Vector3.UP*.65)<.001,"Branch recovery stays on the selected alternative")
	var heading := driver.line.point_at(station+.2)-driver.line.point_at(station-.2)
	heading.y=0
	s.check((-pose.basis.z).dot(heading.normalized())>.999 and pose.basis.y.dot(Vector3.UP)>.999,"Branch recovery faces the chosen route with an upright body")
	kart.input_provider=previous_input
	driver.free()
	var required := race.racing_line.minimum_interval_length(fountain.entry_offset+.001,fountain.exit_offset+20)
	s.near(required,fountain.curve.get_baked_length()+20-.001,"Gate rounding retains valid alternative interval travel",.03)
	var garden := track.get_node("Ground/Terrain").find_child("GardenGrass",true,false) as MeshInstance3D
	s.check(garden!=null,"Gardens have separate grass geometry and surface")
	var offset := 720.0
	var center := track.sample_center(offset)
	var right := track.road_right(offset)
	var outside := center-right*12 # Seaward edge; the other side faces the island.
	var hit := track.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(outside+Vector3.UP,outside-Vector3.UP*5,1,[kart.get_rid()]))
	s.check(hit.is_empty(),"Exposed dock edge has no hidden floor or collision wall")
	race.start_race()
	race.session.advance(3)
	var checkpoint := race.session.next_checkpoint
	var recovery := kart.get_node("Recovery") as KartRecovery
	recovery.cooldown_remaining=0
	kart.global_position=outside+Vector3.DOWN
	var reset := [false]
	kart.reset_performed.connect(func() -> void: reset[0]=true,CONNECT_ONE_SHOT)
	for i in 100:
		await s.physics_frame
		if reset[0]:break
	s.check(reset[0] and kart.global_position.y>1,"Falling off the exposed dock triggers water recovery")
	s.check(race.session.next_checkpoint==checkpoint and race.session.lap_times.is_empty(),"Water recovery preserves validated progress without awarding a shortcut")
	world.queue_free()
	await s.process_frame
