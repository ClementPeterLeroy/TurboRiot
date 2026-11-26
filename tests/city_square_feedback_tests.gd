extends RefCounted
class Commands extends DrivingInput:
	var command := DrivingCommand.new(1)
	func get_command() -> DrivingCommand: return command

func run(s: SceneTree) -> void:
	var world := TrackRegistry.get_definition(&"delfino_square_ds").instantiate_race()
	world.managed=true
	world.get_node("RaceManager").opponent_count=0
	world.get_node("Items").enabled=false
	s.root.add_child(world)
	await s.physics_frame
	var race := world.get_node("RaceManager") as RaceManager
	var track := race.track as AuthoredCircuit
	var kart := race.kart
	var environment := track.get_node("Ground")
	var paved := environment.find_child("PavedStreets",true,false) as MeshInstance3D
	var material := paved.get_active_material(0)
	environment._apply(environment)
	s.check(paved.get_active_material(0)==material,"Editor material re-entry preserves existing overrides without repeated cloning")
	s.check(track.road_width>=20 and track.route_branches[0].width>=20,"Both city streets are at least twice their original width")
	var road_clear := true
	for variant in 2:
		var line := RacingLine.new()
		line.build(track,variant,false)
		var branch := track.route_branches[0]
		for i in range(10,111,2):
			var offset := line.from_canonical(branch.entry_offset+i)
			for side in [-8.5,8.5]:
				var p := line.point_at(offset,side)
				var hit := track.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(p+Vector3.UP,p-Vector3.UP,1,[kart.get_rid()]))
				if hit.is_empty() or str(hit.collider.name)!="PavedStreetsCollision":road_clear=false
	s.check(road_clear,"Widened stair streets have full support and no house colliders in racing lanes")
	for index in [1,2]:
		var gate: CheckpointGate=race.gates[index]
		s.check(gate.route_offset<track.route_branches[1].entry_offset,"Avenue gate precedes the fountain fork")
		for lane in [-10.0,10.0]:
			var p: Vector3 = gate.global_position+gate.global_basis.x*lane+Vector3.UP*.4
			s.check(gate.crossing_fraction(p+gate.global_basis.z,p-gate.global_basis.z)>0,"Avenue checkpoint accepts the full road width")
	for index in [11,12]:
		var gate: CheckpointGate=race.gates[index]
		var accepted_grass := false
		for side in [-1,1]:
			var extent := gate.left_extent if side<0 else gate.right_extent
			if extent<8:continue
			var p: Vector3 = gate.global_position+gate.global_basis.x*side*minf(12,extent-1)+Vector3.UP*.4
			var hit := track.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(p+Vector3.UP,p-Vector3.UP*3,1,[kart.get_rid()]))
			if not hit.is_empty() and hit.collider.get_meta("surface").identifier==&"grass":
				accepted_grass=gate.crossing_fraction(p+gate.global_basis.z,p-gate.global_basis.z)>0 and race.racing_line.legal(p,race.racing_line.project(p))
		s.check(accepted_grass,"Garden checkpoint and legal-progress corridor include real connected grass: "+str(index))
	var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/environment/city_square/manifest.json"))
	var blocks := {}
	for house in manifest.houses:
		if house.has("block"):
			if not blocks.has(house.block):blocks[house.block]=[]
			blocks[house.block].append(house)
	var joined := true
	for lots in blocks.values():
		for i in range(1,lots.size()):
			var a: Dictionary=lots[i-1]
			var b: Dictionary=lots[i]
			var axis := Vector3(cos(a.yaw),0,-sin(a.yaw))
			var delta := Vector3(b.position[0]-a.position[0],0,b.position[2]-a.position[2])
			if b.lot!=a.lot+1 or absf(absf(delta.dot(axis))-(a.size[0]+b.size[0])*.5)>.002:joined=false
	s.check(blocks.size()>=10 and joined,"Consecutive terrace houses share party-wall positions without empty lots")
	race.start_race()
	race.session.advance(3)
	race.set_physics_process(false)
	var input := Commands.new()
	kart.add_child(input)
	kart.input_provider=input
	var contacts: Array[Dictionary]=[]
	for sector in ["finish","plaza"]:
		for lane in [-8.0,0.0,8.0]:
			var offset := track.curve.get_baked_length()-10 if sector=="finish" else 95.0
			var start: Vector3 = track.sample_center(offset)+Vector3.RIGHT*lane
			kart.safe_spawn=Transform3D(Basis.IDENTITY,start+Vector3.UP*.65)
			kart.reset_to_spawn()
			for i in 15:await s.physics_frame
			kart.velocity=Vector3.FORWARD*20
			var largest_step := 0.0
			var previous := kart.global_position
			for i in 100:
				await s.physics_frame
				largest_step=maxf(largest_step,kart.global_position.distance_to(previous))
				previous=kart.global_position
			print("CITY_CONTACT ",sector," lane=",lane," largest_step=",largest_step," lateral_shift=",kart.global_position.x-start.x)
			contacts.append({"sector":sector,"lane":lane,"largest_step":largest_step,"lateral_shift":kart.global_position.x-start.x})
			s.check(largest_step<.6 and absf(kart.global_position.x-start.x)<.05,"No solver teleport at "+sector+" lane "+str(lane))
			s.check(kart.global_position.z<start.z-30 and kart.velocity.length()>18,"Unobstructed physical traversal at "+sector+" lane "+str(lane))
	FileAccess.open("res://artifacts/v061_city_feedback_contact.json",FileAccess.WRITE).store_string(JSON.stringify(contacts,"\t"))
	var generated_id := track.get_node("Generated").get_instance_id()
	for cycle in 2:
		track._schedule_rebuild()
		await s.process_frame
		await s.process_frame
		var replacement_id := track.get_node("Generated").get_instance_id()
		s.check(replacement_id!=generated_id and not track._queued,"Authored scene rebuild queue remains usable after cycle "+str(cycle+1))
		generated_id=replacement_id
	world.queue_free()
	await s.process_frame
