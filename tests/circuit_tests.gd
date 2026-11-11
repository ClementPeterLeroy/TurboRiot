extends RefCounted

func _frames(s: SceneTree, count := 4) -> void:
	for i in count: await s.process_frame

func run(s: SceneTree) -> void:
	var invalid := RaceSetup.new()
	invalid.circuit_id = &"missing"
	s.check(invalid.validated().circuit_id == &"reference", "Unknown circuit falls back safely")
	s.check(TrackRegistry.entries().size() == 3, "Registry exposes exactly three implemented circuits")
	for id in [&"figure_8", &"yoshi_ds"]:
		await _geometry(s, id)
	await _navigation(s)

func _geometry(s: SceneTree, id: StringName) -> void:
	var definition := TrackRegistry.get_definition(id)
	var world := definition.instantiate_race()
	world.managed = true
	world.get_node("Items").external_audio = true
	s.root.add_child(world)
	var track := world.get_node("Track") as TrackBuilder
	var race := world.get_node("RaceManager") as RaceManager
	s.check(track.is_curve_closed() and track.curve.point_count > 25, "%s has a detailed closed trace" % id)
	var valid_faces := true
	var valid_width := true
	for i in range(0, track.road_indices.size(), 3):
		var indices := track.road_indices
		var v := track.road_vertices
		var normal := (v[indices[i+1]]-v[indices[i]]).cross(v[indices[i+2]]-v[indices[i]])
		valid_faces = valid_faces and normal.is_finite() and normal.y < -0.0001
	for i in range(0, track.road_vertices.size(), 2):
		valid_width = valid_width and absf(track.road_vertices[i].distance_to(track.road_vertices[i+1])-track.road_width) < 0.001
	s.check(valid_faces, "%s road has finite, nondegenerate, correctly wound faces" % id)
	s.check(valid_width, "%s preserves the full authored width without corner collapse" % id)
	var banked := definition.scene.instantiate() as TrackBuilder
	banked.curve = banked.curve.duplicate()
	for i in banked.curve.point_count: banked.curve.set_point_tilt(i, 0.12)
	banked.use_curve_banking = true
	var bank_right := banked.road_right(0)
	s.check(absf(bank_right.y)>0.05 and absf(bank_right.dot(banked.sample_forward(0)))<0.01, "Optional authored banking rotates a perpendicular road cross-section")
	s.check(not track.use_curve_banking, "Neither traced circuit invents reference banking")
	banked.free()
	var vertices := track.road_vertices
	s.check(vertices[0].distance_to(vertices[vertices.size()-2]) < 0.001 and vertices[1].distance_to(vertices[vertices.size()-1]) < 0.001, "%s road seam is closed" % id)
	var flat_intersections := 0
	var raised_intersections := 0
	var length := track.curve.get_baked_length()
	var count := ceili(length/3)
	for i in count:
		var a := track.sample_center(length*i/count)
		var b := track.sample_center(length*(i+1)/count)
		for j in range(i+2,count):
			if i == 0 and j == count-1: continue
			var c := track.sample_center(length*j/count)
			var d := track.sample_center(length*(j+1)/count)
			var hit: Variant = Geometry2D.segment_intersects_segment(Vector2(a.x,a.z),Vector2(b.x,b.z),Vector2(c.x,c.z),Vector2(d.x,d.z))
			if hit == null: continue
			var first_height := lerpf(a.y,b.y,Vector2(a.x,a.z).distance_to(hit)/Vector2(a.x,a.z).distance_to(Vector2(b.x,b.z)))
			var second_height := lerpf(c.y,d.y,Vector2(c.x,c.z).distance_to(hit)/Vector2(c.x,c.z).distance_to(Vector2(d.x,d.z)))
			if absf(first_height-second_height) > 4: raised_intersections += 1
			else: flat_intersections += 1
	s.check(flat_intersections == 0, "%s has no at-grade centerline intersections" % id)
	s.check(raised_intersections == (1 if id == &"figure_8" else 0), "%s crossing topology matches the inspected reference" % id)
	var safe_grid := true
	for record in race.competitors:
		safe_grid = safe_grid and absf(race.racing_line.project(record.grid.origin).y)+1 < track.road_width/2
		for other in race.competitors:
			if other != record: safe_grid = safe_grid and record.grid.origin.distance_to(other.grid.origin)>2.5
	s.check(safe_grid and race.competitors.size()==7, "%s supports a separated seven-kart grid" % id)
	s.check(race.gates.size()==24 and race.racing_line.points.size()>200, "%s owns fresh gates and cached AI samples" % id)
	var correct_gates := true
	for gate in race.gates:
		var before := gate.global_transform * Vector3(0,0.5,1)
		var after := gate.global_transform * Vector3(0,0.5,-1)
		correct_gates = correct_gates and gate.crossing_fraction(before,after)>=0 and gate.crossing_fraction(after,before)<0
		correct_gates = correct_gates and gate.crossing_fraction(before+gate.global_basis.x*track.road_width*2,after+gate.global_basis.x*track.road_width*2)<0
	s.check(correct_gates, "%s gates accept forward crossings and reject reverse/adjacent paths" % id)
	var items := world.get_node("Items") as ItemSystem
	s.check(items.rows.size()==3 and items.rows[0].configuration.route_fraction==definition.pickup_fractions[0], "%s pickups use circuit progress rather than reference-world anchors" % id)
	s.check(world.get_node("TrackFeatures").get_node("Generated").get_child_count()==0, "%s does not inherit the original runoff ramp or pads" % id)
	var map := world.get_node("HUD/CircuitMap") as CircuitMap
	s.check(map.route==track.curve and definition.preview_curve().get_baked_length()==length, "%s preview and live minimap use the same geometry" % id)
	var next := race.session.next_checkpoint
	s.check(next==1, "%s starts requiring the first ordered gate" % id)
	var safe := race.gates[3].recovery_transform()
	race.kart.safe_spawn = safe
	race.kart.get_node("Recovery").cooldown_remaining = 0
	race.kart.get_node("Recovery").recover()
	s.check(race.kart.global_position.distance_to(safe.origin)<0.001 and not race.kart.boost.active(), "%s recovery uses a valid route pose and clears temporary state" % id)
	world.queue_free()
	await _frames(s)

func _navigation(s: SceneTree) -> void:
	var app := load("res://scenes/app.tscn").instantiate() as TurboApplication
	app.settings.path = "res://.godot/v061_test_settings.cfg"
	app.auto_pause_on_focus_loss = false
	s.root.add_child(app)
	await _frames(s)
	var setup := RaceSetup.new()
	setup.opponents=2
	setup.laps=5
	setup.circuit_id=&"yoshi_ds"
	app.show_circuits(setup)
	app.show_home() # Same-frame Back must not focus removed circuit buttons.
	await _frames(s)
	s.check(app.screen=="home" and s.root.gui_get_focus_owner()==app.menu.focusables[0], "Rapid circuit-screen cancellation keeps safe focus")
	app.show_circuits(setup)
	await _frames(s)
	s.check(app.screen=="circuits" and app.menu.focusables.size()==5, "Circuit screen has three circuit buttons plus Start and Back")
	await _key(s,KEY_UP)
	await _key(s,KEY_ENTER)
	s.check(app.quick_setup.circuit_id==&"figure_8", "Keyboard navigates and selects an actual circuit card")
	for button in [JOY_BUTTON_DPAD_DOWN,JOY_BUTTON_A]:
		for pressed in [true,false]:
			var pad := InputEventJoypadButton.new()
			pad.button_index=button
			pad.pressed=pressed
			s.root.push_input(pad)
		await _frames(s)
	s.check(app.quick_setup.circuit_id==&"yoshi_ds", "Injected controller navigation selects the next circuit")
	app.menu.focusables[0].grab_focus()
	await _frames(s)
	var motion := InputEventMouseMotion.new()
	motion.position = app.menu.focusables[0].get_global_rect().get_center()
	s.root.push_input(motion, true) # Control rects are viewport-local after UI scaling.
	await _frames(s)
	for pressed in [true,false]:
		var mouse := InputEventMouseButton.new()
		mouse.button_index=MOUSE_BUTTON_LEFT
		mouse.position=app.menu.focusables[0].get_global_rect().get_center()
		mouse.pressed=pressed
		s.root.push_input(mouse, true)
	await _frames(s)
	s.check(app.quick_setup.circuit_id==&"reference", "Circuit card updates the selected setup")
	app.menu.focusables[4].pressed.emit()
	await _frames(s)
	s.check(app.screen=="config" and app.quick_setup.laps==5 and app.quick_setup.opponents==2, "Back preserves circuit and race configuration")
	for mode in [RaceSetup.Mode.QUICK_RACE,RaceSetup.Mode.TIME_TRIAL]:
		for id in [&"figure_8",&"yoshi_ds",&"reference"]:
			setup.mode=mode
			setup.circuit_id=id
			setup.laps=1
			app.start_session(setup)
			await _frames(s,6)
			var previous := app.game
			s.check(previous.get_meta("circuit_id")==id and previous.get_node("RaceManager").competitors.size()==(3 if mode==RaceSetup.Mode.QUICK_RACE else 1), "%s loads selected circuit in mode %d" % [id,mode])
			s.check(previous.get_node("Items").enabled==(mode==RaceSetup.Mode.QUICK_RACE), "Selected circuit respects mode item policy")
			app.restart_session()
			await _frames(s,6)
			s.check(not is_instance_valid(previous) and app.game.get_meta("circuit_id")==id, "Restart disposes the old world and keeps the selected circuit")
			app.return_home()
			await _frames(s)
			s.check(app.game==null and app._world.get_child_count()==0 and not s.paused, "Return home leaves no racers, AI paths, items or paused world")
	app.queue_free()
	await _frames(s)

func _key(s: SceneTree, key: Key) -> void:
	for pressed in [true,false]:
		var event := InputEventKey.new()
		event.keycode=key
		event.physical_keycode=key
		event.pressed=pressed
		s.root.push_input(event)
	await _frames(s)
