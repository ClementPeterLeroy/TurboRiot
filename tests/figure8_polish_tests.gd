extends RefCounted

class TestInput extends DrivingInput:
	var command := DrivingCommand.new()
	func get_command() -> DrivingCommand:
		return command

func run(s: SceneTree) -> void:
	var world := TrackRegistry.get_definition(&"figure_8").instantiate_race()
	world.managed = true
	world.get_node("Items").enabled = false
	world.get_node("RaceManager").opponent_count = 0
	s.root.add_child(world)
	await s.physics_frame
	await s.physics_frame
	var track := world.get_node("Track") as TrackBuilder
	var race := world.get_node("RaceManager") as RaceManager
	var kart := race.kart
	var gantry := track.get_node("EnvironmentArt/Signage/StartGantry")
	s.check(gantry.find_child("GantryBrand", true, false) == null, "Old baked gantry wordmark is completely absent")
	s.check(FileAccess.get_sha256("res://assets/brand/turbo_riot_logo.png") == "2e248ca86eb58fc27596fd556199e1ef78bad1f04254f679195bf97997a584fe", "Runtime brand is a byte-identical copy of the supplied transparent artwork")
	var brand := gantry.get_node("OfficialBrand") as Node3D
	for face_name in ["Front", "Back"]:
		var face := brand.get_node(face_name) as MeshInstance3D
		var quad := face.mesh as QuadMesh
		var paint := quad.material as StandardMaterial3D
		s.near(quad.size.x / quad.size.y, 1920.0 / 819, "Official %s logo retains source aspect ratio" % face_name)
		s.check(quad.size.y < 1.8 and face.position.x == 0 and absf(face.position.y - 7.8) < 0.001 and face.basis.determinant() > 0.99, "Official %s logo is centered within the panel without reflected scaling" % face_name)
		s.check(paint.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA and paint.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED, "Official %s logo preserves transparency and unlit colors" % face_name)
	s.check(brand.get_node("Front").basis.z.dot(Vector3.FORWARD) > 0.99 and brand.get_node("Back").basis.z.dot(Vector3.BACK) > 0.99, "Logo faces point outward on both sides")
	var pads := track.get_node("SpeedPads")
	s.check(pads.get_child_count() == 2, "Figure-8 contains exactly two authored speed pads")
	race.start_race()
	race.set_physics_process(false)
	race.session.advance(3)
	var input := TestInput.new()
	kart.add_child(input)
	kart.input_provider = input
	for pad: BoostPad in pads.get_children():
		var offset: float = pad.get_meta("route_offset")
		s.check(pad.global_position.distance_to(track.sample_center(offset) + Vector3.UP * 0.015) < 0.001 and (-pad.global_basis.z).dot(track.sample_forward(offset)) > 0.999, "%s follows the actual centerline elevation and forward direction" % pad.name)
		s.check(pad.strength == 1.25 and pad.duration == 1 and pad.cooldown == 2 and pad.initial_impulse == 5, "%s uses restrained shared boost tuning" % pad.name)
		s.check(pad.get_node("Generated/SurfaceTrigger") is Area3D and pad.get_node("Generated/SpeedPadArtwork").get_child_count() == 1, "%s separates a flat visual from non-solid detection" % pad.name)
		var forward := -pad.global_basis.z
		forward.y = 0
		var heading := Basis.looking_at(forward.normalized())
		kart.safe_spawn = Transform3D(heading, pad.to_global(Vector3(0, 0.55, 7)))
		kart.reset_to_spawn()
		input.command = DrivingCommand.new()
		for i in 35:
			await s.physics_frame
		var before := kart.boost.activation_serial
		kart.velocity = forward.normalized() * 17
		input.command = DrivingCommand.new(1)
		var activated := false
		var airborne := 0
		var maximum_speed := 0.0
		for i in 130:
			await s.physics_frame
			activated = activated or kart.boost.source == &"boost_pad"
			maximum_speed = maxf(maximum_speed, Vector2(kart.velocity.x, kart.velocity.z).length())
			if not kart.is_on_floor():
				airborne += 1
		s.check(activated and kart.boost.activation_serial - before == 1, "%s activates once through its real Area3D crossing" % pad.name)
		s.check(maximum_speed > 23 and maximum_speed <= 27.75 and airborne == 0, "%s accelerates without excessive speed or launching the kart: speed %.3f air %d" % [pad.name, maximum_speed, airborne])
		s.check(not kart.boost.active(), "%s boost expires normally" % pad.name)
		# Real occupancy: freeze the body on the pad, not its trigger processing.
		kart.safe_spawn = Transform3D(heading, pad.global_position + Vector3.UP * 0.4)
		kart.reset_to_spawn()
		input.command = DrivingCommand.new()
		for i in 35:
			await s.physics_frame
		kart.set_physics_process(false)
		kart.boost.clear()
		var occupancy_serial := kart.boost.activation_serial
		for i in 140:
			await s.physics_frame
			kart.boost.clear()
		# Teleporting onto the pad is a new entry: at most one activation may
		# occur after its reset cooldown. Continuing occupancy cannot repeat it.
		s.check(kart.boost.activation_serial - occupancy_serial <= 1, "%s cannot repeatedly boost a stationary occupant" % pad.name)
		kart.safe_spawn.origin = kart.global_position
		kart.reset_to_spawn()
		occupancy_serial = kart.boost.activation_serial
		for i in 140:
			await s.physics_frame
		s.check(kart.boost.activation_serial == occupancy_serial, "%s does not retrigger when resetting an already occupied pad" % pad.name)
		kart.set_physics_process(true)
	input.command = DrivingCommand.new()
	world.queue_free()
	await s.process_frame
	# A fresh, fully managed AI lap exercises the real gate/navigation lifecycle
	# rather than an AI provider attached to the deliberately locked human fixture.
	var ai_world := TrackRegistry.get_definition(&"figure_8").instantiate_race()
	ai_world.managed = true
	ai_world.get_node("Items").enabled = false
	var ai_race := ai_world.get_node("RaceManager") as RaceManager
	ai_race.opponent_count = 0
	ai_race.ai_only = true
	ai_race.lap_count = 1
	s.root.add_child(ai_world)
	ai_race.start_race()
	var seen := {}
	for i in 4000:
		await s.physics_frame
		for pad: BoostPad in ai_world.get_node("Track/SpeedPads").get_children():
			if pad._cooldowns.has(ai_race.kart.get_instance_id()) and ai_race.kart.boost.source == &"boost_pad":
				seen[pad.name] = true
		if ai_race.race_complete:
			break
	for name in [&"BridgeApproach", &"CornerExit"]:
		s.check(seen.has(name), "%s activates for the real AI racer during its physical lap" % name)
	s.check(ai_race.race_complete and ai_race.competitors[0].recoveries == 0, "AI completes the polished circuit without recovery")
	ai_world.queue_free()
	await s.process_frame
