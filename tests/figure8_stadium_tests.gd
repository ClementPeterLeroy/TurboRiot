extends RefCounted
## Road identity, physical envelopes and authored assembly contracts.
func run(s: SceneTree) -> void:
	var world := TrackRegistry.get_definition(&"figure_8").instantiate_race()
	world.managed = true
	world.get_node("Items").enabled = false
	world.get_node("RaceManager").opponent_count = 0
	s.root.add_child(world)
	await s.physics_frame
	await s.physics_frame
	var track := world.get_node("Track") as TrackBuilder
	var kart := world.get_node("Kart") as KartController
	var art := track.get_node("EnvironmentArt") as Node3D
	var study := load("res://scenes/tracks/archive/figure_8_road_study.tscn").instantiate() as TrackBuilder
	var identical := track.curve.point_count == study.curve.point_count
	for i in track.curve.point_count:
		identical = identical and track.curve.get_point_position(i).is_equal_approx(study.curve.get_point_position(i))
		identical = identical and track.curve.get_point_in(i).is_equal_approx(study.curve.get_point_in(i))
		identical = identical and track.curve.get_point_out(i).is_equal_approx(study.curve.get_point_out(i))
	s.check(identical and track.road_width == study.road_width and track.sample_spacing == study.sample_spacing, "Stadium preserves the complete accepted road curve, handles, width and sampling")
	study.free()
	s.check(art.get_node("Grandstands").get_child_count() == 15, "Stadium provides fifteen independently editable curved grandstand instances")
	var west := art.get_node("Grandstands/West00") as Node3D
	var east := art.get_node("Grandstands/East00") as Node3D
	s.check(west.scene_file_path == east.scene_file_path, "Opposite stands reuse one authored module scene")
	s.check(west.find_child("SteppedTerraces", true, false) != null and west.find_child("RearWall", true, false) != null and west.find_child("AisleStairs", true, false) != null, "Grandstand model includes stepped structure, closed rear wall and aisle stairs")
	s.check(west.find_child("SeatPans", true, false) != null and west.find_child("CrowdHeads", true, false) != null, "Grandstand includes modeled seats and batched low-poly spectators")
	s.check(west.find_child("Columns", true, false) != null and west.find_child("CanopyPanels", true, false) != null, "Grandstand canopy has authored structural columns")
	var pit := art.get_node("Pits/Garage01")
	s.check(art.get_node_or_null("Pits/Garage08") != null and pit.find_child("DoorPanels", true, false) != null, "Pit complex has eight garage bays with framed panel doors")
	s.check(pit.find_child("ObservationGlazing", true, false) != null and pit.find_child("BalconyRail", true, false) != null, "Pit bays include observation glazing and balcony detail")
	s.check(art.get_node("Pits/RaceControl").find_child("ControlCabin", true, false) != null, "Pit complex has its own integrated race-control tower")
	s.check(art.get_node("Signage/StartGantry").find_child("StartingLights", true, false) != null, "Authored start gantry includes a five-light bank")
	s.check(art.get_node("Bridge/Infrastructure").find_child("StructuralDeck", true, false) != null and art.get_node("Bridge/SupportCollision").get_child_count() == 6, "Bridge has continuous structural deck, four piers and two abutments")
	s.check(art.get_node("Terrain/BankCollision").get_child_count() == 2, "Approaches have two surveyed grass embankment collision strips")
	s.check(art.get_node("Perimeter/WallCollision").get_child_count() > 50, "Stadium perimeter has continuous physical enclosure")
	s.check(art.get_node("Safety/TrackSafety").find_child("FenceGrid00", true, false) != null, "Catch fences use batched opaque mesh grid geometry")
	s.check(art.get_node("Lighting").get_child_count() == 6, "Six reusable structural lighting masts frame the stadium")
	var source_floor := track.get_node("Generated/Asphalt/Asphalt_col")
	var road_clear := true
	var intrusions: Array[String] = []
	var length := track.curve.get_baked_length()
	for i in ceili(length):
		var offset := length * (i + 0.25) / ceili(length)
		for side in [-6.5, 0.0, 6.5]:
			var p: Vector3 = track.sample_center(offset) + track.road_right(offset) * side
			var hit := track.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(p + Vector3.UP, p - Vector3.UP, 1, [kart.get_rid()]))
			if hit.is_empty() or hit.collider != source_floor:
				road_clear = false
				if intrusions.size() < 5:
					intrusions.append("offset %.2f side %.1f %s" % [offset, side, "missing" if hit.is_empty() else str(hit.collider.get_path())])
	s.check(road_clear, "Every metre and all driving lanes retain source-road support without scenery intrusion: " + str(intrusions))
	var ceiling := INF
	for x in [-60.0, -50.4, -40.0]:
		for z in [-6.0, -1.25, 3.5]:
			var p := Vector3(x, 0.14, z)
			var hit := track.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(p, p + Vector3.UP * 10, 1, [kart.get_rid()]))
			if not hit.is_empty():
				ceiling = minf(ceiling, hit.position.y - 0.04)
	s.check(ceiling > 5.5 and ceiling < 8, "Structural underpass leaves more than 5.5 m physical kart/camera headroom")
	var banks_supported := true
	for offset in [190.0, 240.0, 430.0, 480.0]:
		for side in [-1.0, 1.0]:
			var p: Vector3 = track.sample_center(offset) + track.road_right(offset) * side * 10
			var hit := track.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(p + Vector3.UP, p - Vector3.UP * 5, 1, [kart.get_rid()]))
			banks_supported = banks_supported and not hit.is_empty() and hit.collider == art.get_node("Terrain/BankCollision") and hit.normal.y > 0.3
	s.check(banks_supported, "Both raised approaches have upward-facing grass support beyond the rail")
	s.check(not track.get_node("Generated/BarrierVisuals0").visible and track.get_node("Generated/BarrierCollision").collision_layer == 1, "Authored safety replaces temporary block visuals without changing track collision")
	var materials_valid := _materials_valid(art)
	s.check(materials_valid, "Stadium materials remain opaque except the official transparent logo")
	var id := art.get_instance_id()
	track.build()
	await s.process_frame
	s.check(is_instance_valid(art) and art.get_instance_id() == id and not track.get_node("Generated/BarrierVisuals0").visible, "Road rebuild preserves authored stadium and reapplies presentation binding")
	print("STADIUM envelopes road_clear=", road_clear, " headroom=", ceiling, " materials=", materials_valid)
	world.queue_free()
	await s.process_frame

func _materials_valid(node: Node) -> bool:
	if node is MeshInstance3D:
		for surface in node.mesh.get_surface_count():
			var paint := node.get_active_material(surface) as BaseMaterial3D
			var official_logo := node.get_parent().name == &"OfficialBrand" and paint != null and paint.albedo_texture != null and paint.albedo_texture.resource_path == "res://assets/brand/turbo_riot_logo.png"
			if paint == null or (paint.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED and not official_logo):
				return false
	for child in node.get_children():
		if not _materials_valid(child):
			return false
	return true
