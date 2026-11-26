extends RefCounted
class Commands extends DrivingInput:
	var command := DrivingCommand.new()
	func get_command() -> DrivingCommand:return command

func ground(track: TrackBuilder, kart: KartController, p: Vector3) -> Dictionary:
	return track.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(p+Vector3.UP*4,p-Vector3.UP*5,1,[kart.get_rid()]))

func place(s: SceneTree, kart: KartController, input: Commands, p: Vector3, direction: Vector3) -> void:
	input.command=DrivingCommand.new()
	direction.y=0
	kart.safe_spawn=Transform3D(Basis.looking_at(direction.normalized()),p+Vector3.UP*.7)
	kart.reset_to_spawn()
	for i in 35:await s.physics_frame

func horizontal_hash(curve: Curve3D) -> String:
	var values := PackedFloat32Array()
	for i in curve.point_count:
		for p in [curve.get_point_in(i),curve.get_point_out(i),curve.get_point_position(i)]:values.append(p.x);values.append(p.z)
	return _sha(values.to_byte_array())
func _sha(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()

func run(s: SceneTree) -> void:
	var world := TrackRegistry.get_definition(&"delfino_square_ds").instantiate_race()
	world.managed=true
	world.get_node("Items").enabled=false
	world.get_node("RaceManager").opponent_count=0
	s.root.add_child(world)
	await s.physics_frame
	var race := world.get_node("RaceManager") as RaceManager
	var track := race.track as AuthoredCircuit
	var kart := race.kart
	var plan: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://resources/tracks/city_square/structural_plan.json"))
	var survey: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://resources/tracks/city_square/survey.json"))
	for pair in [["centerline.tres",track.curve],["left_street.tres",track.route_branches[0].curve],["fountain_lane.tres",track.route_branches[1].curve]]:
		s.check(horizontal_hash(pair[1])==plan.horizontal_sha256[pair[0]],"Structural correction preserves every XZ curve point/handle: "+pair[0])
	var merge_curve: Curve3D=track.route_branches[0].curve
	var merge := merge_curve.sample_baked(merge_curve.get_closest_offset(Vector3(38.161,2.8,-21.40948)),true)
	var support := ground(track,kart,merge)
	s.check(not support.is_empty() and str(support.collider.name)=="PavedStreetsCollision" and absf(support.position.y-merge.y)<.03,"Overlapping street union keeps the left merge floor at its actual route height")
	var environment := track.get_node("Ground")
	s.check(not environment.has_node("HarbourIslandCollision") and environment.find_child("HarbourIsland",true,false)==null,"Harbour island mesh and collision are removed")
	var architecture := environment.get_node("Architecture")
	var unwanted := false
	for child in architecture.get_children():unwanted=unwanted or str(child.name).begins_with("Block") or str(child.name) in ["Harbour00","Harbour01","Harbour02"]
	s.check(not unwanted,"Purple rear houses and the three island houses are absent")
	s.check(architecture.has_node("Avenue_Left_00") and architecture.has_node("HarbourApproach_Right_01"),"Existing avenue and harbour-descent frontages remain")
	var links := environment.get_node("ArchitecturalLinks")
	s.check(links.get_child_count()==plan.frontages.size(),"All twelve annotated architectural boundary groups have saved roofed links")
	var report: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://resources/tracks/city_square/structural_report.json"))
	var coverage: Array[Dictionary]=[]
	for path in report.frontage_paths:
		var tested := 0
		var covered := 0
		for i in range(0,path.points.size(),4):
			var point: Array=path.points[i]
			var p := Vector3(point[0],point[1],point[2])
			var normal := Vector3(path.normals[i][0],0,path.normals[i][1])
			var behind := ground(track,kart,p+normal*.5)
			if not behind.is_empty() and str(behind.collider.name) in ["PavedStreetsCollision","TimberDecksCollision"]:continue # Preserve real road openings.
			tested+=1
			# Existing coastal/garden corner facades sit up to 5 m behind the
			# land boundary; street-facing architecture must remain within 4 m.
			var reach := 5.0 if path.name in ["CoastFront","GardenTownEdge"] else 4.0
			var hit := track.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(p-normal*.4+Vector3.UP*2,p+normal*reach+Vector3.UP*2,1,[kart.get_rid()]))
			if not hit.is_empty():covered+=1
		var fraction := float(covered)/maxi(tested,1)
		coverage.append({"name":path.name,"tested":tested,"covered":covered,"fraction":fraction})
		print("CITY_FRONTAGE ",JSON.stringify(coverage[-1]))
		s.check(tested>0 and fraction==1.0,"Continuous physical architectural boundary outside street openings: "+path.name)
	var inside_island := ground(track,kart,Vector3(115,2,100))
	s.check(inside_island.is_empty(),"The former island is open water without a hidden collision floor")
	for offset in [680.0,740.0,830.0]:
		var center := track.sample_center(offset)
		for side in [-1.0,1.0]:
			var deck := ground(track,kart,center+track.road_right(offset)*side*8.7)
			s.check(not deck.is_empty() and str(deck.collider.name)=="TimberDecksCollision","Widened wood supports both lanes beyond the old platform edge")
	race.start_race()
	race.session.advance(3)
	race.set_physics_process(false)
	kart.get_node("Recovery").set_physics_process(false)
	var input := Commands.new()
	kart.add_child(input)
	kart.input_provider=input
	var measurements: Array[Dictionary]=[]
	for index in survey.stair_flights.size():
		var flight: Dictionary=survey.stair_flights[index]
		var a := Vector3(flight.start[0],flight.start[1],flight.start[2])
		var b := Vector3(flight.end[0],flight.end[1],flight.end[2])
		var axis := b-a
		axis.y=0
		var length := axis.length()
		axis=axis.normalized()
		var steps := environment.find_children("*Flight%d_*"%index,"MeshInstance3D",true,false)
		var straight := steps.size()>8
		var clear_junctions := true
		for step: MeshInstance3D in steps:
			var bounds: AABB=step.global_transform*step.mesh.get_aabb()
			var center := bounds.get_center()-a
			center.y=0
			if absf(center.dot(axis.cross(Vector3.UP)))>.03:straight=false
			for junction in [Vector2(30,-88.5),Vector2(82.5,-88.5),Vector2(30,-22.5),Vector2(82.5,-22.5)]:
				if bounds.position.x<junction.x+10 and bounds.end.x>junction.x-10 and bounds.position.z<junction.y+10 and bounds.end.z>junction.y-10:clear_junctions=false
		s.check(straight,"Visible staircase treads follow one straight line: flight "+str(index))
		s.check(clear_junctions,"No staircase tread enters a corner/intersection footprint: flight "+str(index))
		for uphill in [false,true]:
			var direction := -axis if uphill else axis
			var start := b+axis*2 if uphill else a-axis*2
			await place(s,kart,input,start,direction)
			input.command=DrivingCommand.new(1)
			var air := 0
			var completed := false
			for tick in 420:
				await s.physics_frame
				if not kart.is_on_floor():air+=1
				if (kart.global_position-start).dot(direction)>length+3:
					completed=true
					break
			measurements.append({"flight":index,"uphill":uphill,"completed":completed,"airborne":air,"final_position":str(kart.global_position)})
			print("CITY_STAIR ",JSON.stringify(measurements[-1]))
			s.check(completed,"Staircase traverses uphill/downhill: flight "+str(index)+" uphill="+str(uphill))
			s.check(air==0,"Staircase retains genuine ground contact: flight "+str(index)+" uphill="+str(uphill))
		var midpoint := a.lerp(b,.5)
		await place(s,kart,input,midpoint,axis)
		kart.velocity=axis*8
		input.command=DrivingCommand.new(0,1)
		var braked := false
		for i in 60:
			await s.physics_frame
			if kart.signed_speed<=.1:braked=true;break
		input.command=DrivingCommand.new()
		s.check(braked and kart.is_on_floor(),"Moving kart brakes to a standstill halfway on staircase "+str(index))
		var stopped := kart.global_position
		for i in 30:await s.physics_frame
		s.check(kart.global_position.distance_to(stopped)<.1 and kart.is_on_floor(),"Kart can remain stopped halfway on staircase "+str(index))
		input.command=DrivingCommand.new(1)
		for i in 90:await s.physics_frame
		s.check((kart.global_position-stopped).dot(axis)>8,"Kart accelerates again from staircase standstill "+str(index))
		await place(s,kart,input,midpoint,axis)
		stopped=kart.global_position
		input.command=DrivingCommand.new(0,1)
		for i in 120:await s.physics_frame
		s.check((kart.global_position-stopped).dot(axis)<-5 and kart.is_on_floor(),"Kart reverses uphill from a stair standstill "+str(index))
	var grass_cases := 0
	for offset in [975.0,995.0,1020.0,1040.0,1060.0,1080.0,1120.0]:
		var center := track.sample_center(offset)
		var right := track.road_right(offset)
		var width := track.width_profile.sample(offset/track.curve.get_baked_length())
		for side in [-1.0,1.0]:
			var p: Vector3=center+right*side*(width/2+3)
			var hit := ground(track,kart,p)
			if hit.is_empty() or str(hit.collider.name)!="GardenGrassCollision":continue
			# An intentional house frontage is not a road/grass opening. Exclude
			# only real architecture at body height, never a paved-edge lip.
			var wall := track.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(hit.position+Vector3.UP,center+Vector3.UP,1,[kart.get_rid()]))
			if not wall.is_empty() and absf(wall.normal.y)<.5:
				var is_architecture := architecture.is_ancestor_of(wall.collider)
				for frontage in plan.frontages:is_architecture=is_architecture or str(wall.collider.name)==frontage.name+"Collision"
				if is_architecture:continue
			grass_cases+=1
			var start: Vector3=hit.position
			await place(s,kart,input,start,-right*side)
			input.command=DrivingCommand.new(1)
			var completed := false
			var air := 0
			for i in 180:
				await s.physics_frame
				if not kart.is_on_floor():air+=1
				if (kart.global_position-start).dot(-right*side)>width/2+4:completed=true;break
			s.check(completed and air==0,"Grass re-entry has no trapping lip/airborne transition at "+str(offset)+" side="+str(side))
			s.check(kart.surface_detector.current.identifier==&"asphalt","Grass re-entry restores actual paved-surface detection")
			await place(s,kart,input,center,right*side)
			input.command=DrivingCommand.new(1)
			for i in 150:
				await s.physics_frame
				if (kart.global_position-center).dot(right*side)>width/2+3:break
			s.check(kart.surface_detector.current.identifier==&"grass" and kart.is_on_floor(),"Kart can leave the path for real slowing grass at "+str(offset))
	s.check(grass_cases>=4,"Garden physical re-entry covers multiple locations and both accessible sides")
	var recovery := kart.get_node("Recovery") as KartRecovery
	recovery.set_physics_process(true)
	input.command=DrivingCommand.new()
	for side in [-1.0,1.0]:
		var outside: Vector3=track.sample_center(740)+track.road_right(740)*side*12
		s.check(ground(track,kart,outside).is_empty(),"Both widened dock sides remain exposed to water")
		kart.safe_spawn=race.grid_transform(0)
		kart.velocity=Vector3.ZERO
		kart.global_position=outside+Vector3.UP*.65
		recovery.cooldown_remaining=0
		var reset := [false]
		var callback := func() -> void:reset[0]=true
		kart.reset_performed.connect(callback)
		for tick in 120:
			await s.physics_frame
			if reset[0]:break
		kart.reset_performed.disconnect(callback)
		s.check(reset[0] and race.session.next_checkpoint==1,"Water recovery works from either dock edge without awarding progress")
	FileAccess.open("res://artifacts/v061_city_structure_physics.json",FileAccess.WRITE).store_string(JSON.stringify({"stairs":measurements,"grass_cases":grass_cases,"frontages":coverage},"\t"))
	world.queue_free()
	await s.process_frame
