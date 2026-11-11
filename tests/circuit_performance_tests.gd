extends RefCounted
## Geometry and presentation contracts for the performance correction. Timing
## itself is measured by the native A/B benchmark, not a flaky FPS assertion.
func run(s: SceneTree) -> void:
	for id in TrackRegistry.IDS:
		var definition := TrackRegistry.get_definition(id)
		var scene := definition.scene
		if scene == null: scene = load("res://scenes/track.tscn")
		var track := scene.instantiate() as TrackBuilder
		s.root.add_child(track)
		await s.physics_frame
		var asphalt := track.get_node("Generated/Asphalt") as MeshInstance3D
		var body := asphalt.get_node("Asphalt_col") as StaticBody3D
		var visual_area := 0.0
		for i in range(0,track.road_indices.size(),3):
			var a := track.road_vertices[track.road_indices[i]]
			var b := track.road_vertices[track.road_indices[i+1]]
			var c := track.road_vertices[track.road_indices[i+2]]
			visual_area += (b-a).cross(c-a).length()*0.5
		var flat := not track.use_curve_elevation and not track.use_curve_banking
		if flat:
			var valid := true
			var area := 0.0
			var source_points := {}
			for point in track.road_vertices: source_points[_key(point)] = true
			for node: CollisionShape3D in body.get_children():
				valid = valid and node.shape is ConvexPolygonShape3D
				if not node.shape is ConvexPolygonShape3D: continue
				var points := (node.shape as ConvexPolygonShape3D).points
				var count := points.size()/2
				for i in count:
					var top: Vector3 = node.transform * points[i]
					valid = valid and source_points.has(_key(top)) and absf(top.y-0.04)<0.00001
					valid = valid and (points[i]-points[i+count]).is_equal_approx(Vector3.UP*0.12)
				for i in range(1,count-1): area+=(points[i]-points[0]).cross(points[i+1]-points[0]).length()*0.5
			s.check(valid, "%s convex collision uses the exact original road boundary/top vertices" % id)
			s.check(absf(area-visual_area)<maxf(0.01,visual_area*0.000001), "%s collision covers the original surface without added area or gaps" % id)
		else:
			s.check(body.get_child_count()==1 and body.get_child(0).shape is ConcavePolygonShape3D, "Elevated/banked road retains its original triangle collision")
			s.check((body.get_child(0).shape as ConcavePolygonShape3D).get_faces().size()==track.road_indices.size(), "Figure-8 retains every source collision triangle")
		var supported := true
		for i in 24:
			var offset := track.curve.get_baked_length()*(i+0.35)/24
			for side in [-3.0,0.0,3.0]:
				var point: Vector3 = track.sample_center(offset)+track.road_right(offset)*side
				var ray := PhysicsRayQueryParameters3D.create(track.to_global(point+Vector3.UP),track.to_global(point-Vector3.UP),1)
				var hit := track.get_world_3d().direct_space_state.intersect_ray(ray)
				supported = supported and not hit.is_empty()
				if not hit.is_empty(): supported = supported and absf(track.to_local(hit.position).y-point.y)<0.005
		s.check(supported, "%s driving lanes retain road support and height within 5 mm" % id)
		var map := CircuitMap.new()
		map.size=Vector2(220,160)
		map.configure(track.curve)
		s.root.add_child(map)
		s.check(map.samples.size()<1000 and map.samples.size()>4, "%s minimap has a bounded display-sized path" % id)
		var count := map.samples.size()-1
		var error := 0.0
		for i in count:
			var point := track.curve.sample_baked(track.curve.get_baked_length()*(i+0.5)/count,true)
			var chord := (map.project(map.samples[i])+map.project(map.samples[i+1]))*0.5
			error=maxf(error,map.project(Vector2(point.x,point.z)).distance_to(chord))
		s.check(error<0.5, "%s simplified minimap retains subpixel curve fidelity" % id)
		var diagonal := map.project(map.bounds.end)-map.project(map.bounds.position)
		s.check(absf(diagonal.x/map.bounds.size.x-diagonal.y/map.bounds.size.y)<0.00001, "%s minimap preserves the source aspect ratio" % id)
		var saved := map._line.duplicate()
		var fake_race := RaceManager.new()
		map.race=fake_race
		map.track=track
		for i in 8:
			map._process(1.0/60)
			await s.process_frame
		s.check(map._line==saved, "%s live marker updates preserve the cached route geometry" % id)
		fake_race.free()
		map.queue_free()
		track.queue_free()
		await s.process_frame

func _key(point: Vector3) -> Vector3i:
	return Vector3i(roundi(point.x*10000),roundi(point.y*10000),roundi(point.z*10000))
