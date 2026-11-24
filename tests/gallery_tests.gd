extends RefCounted

func run(s: SceneTree) -> void:
	var names := {&"reference": "Desert Run", &"figure_8": "Circuit 8", &"yoshi_ds": "Serpent Coast", &"baby_park": "Legend Park", &"wario_stadium_ds": "Riot Arena", &"delfino_square_ds": "Sunhaven Square"}
	for definition in TrackRegistry.catalog_entries():
		s.check(definition.display_name == names[definition.identifier], "Catalog display name: " + str(definition.identifier))
		if definition.identifier not in TrackRegistry.IDS:
			s.check(not definition.available and definition.internal_only and definition.preview_curve() == null, "Deferred circuits stay out of normal selection without fake previews")
	s.check(TrackRegistry.IDS == [&"reference", &"figure_8", &"yoshi_ds"], "Menu redesign preserves existing launch identifiers")
	var scratch := Curve3D.new()
	for p in [Vector3.ZERO, Vector3(10, 0, 0), Vector3(10, 0, 10), Vector3.ZERO]: scratch.add_point(p)
	var old := CircuitOutline.snapshot_for(scratch)
	scratch.set_point_position(1, Vector3(25, 0, 0))
	var changed := CircuitOutline.snapshot_for(scratch)
	s.check(changed.bounds.size.x > old.bounds.size.x, "Preview cache invalidates when its authoritative curve changes")
	CircuitOutline._cache.erase(scratch.get_instance_id())
	var app := load("res://scenes/app.tscn").instantiate() as TurboApplication
	app.settings.path = "res://.godot/gallery_tests.cfg"
	app.auto_pause_on_focus_loss = false
	s.root.add_child(app)
	app.show_circuits(RaceSetup.new())
	await _frames(s)
	var gallery := app.menu.gallery
	s.check(gallery.cards.size() == 3 and gallery.focusables.size() == 5, "Gallery contains three playable cards and two separate actions")
	var expected_scenes := ["", "res://scenes/tracks/figure_8.tscn", "res://scenes/tracks/yoshi_ds.tscn"]
	for i in gallery.cards.size():
		var card := gallery.cards[i]
		var curve := card.definition.preview_curve()
		var packed: PackedScene = card.definition.scene
		s.check((packed.resource_path if packed else "") == expected_scenes[i], "Card retains the original scene reference: " + card.definition.display_name)
		var data := card.outline.snapshot
		var accurate := true
		for j in data.points.size():
			var p := curve.sample_baked(curve.get_baked_length() * j / (data.points.size() - 1), true)
			accurate = accurate and data.points[j].distance_to(Vector2(p.x, p.z)) < 0.0001
		s.check(accurate and not card.outline.is_processing(), "Outline is cached from actual XZ centerline without per-frame work: " + card.definition.display_name)
		var p0: Vector2 = card.outline.projected[0]
		var ratio: float = p0.distance_to(card.outline.projected[8]) / data.points[0].distance_to(data.points[8])
		var ratio2: float = card.outline.projected[20].distance_to(card.outline.projected[40]) / data.points[20].distance_to(data.points[40])
		s.near(ratio, ratio2, "Outline applies one uniform scale", 0.0001)
	s.check(not gallery.cards[1].outline.elevated.is_empty() and gallery.cards[0].outline.elevated.is_empty(), "Circuit 8 preview separates its elevated crossing; flat tracks stay flat")
	var labels := _visible_text(gallery).to_lower()
	var clean := true
	for forbidden in ["mario", "nintendo", "educational", "debug", "development", "available", "checkpoint", "mesh", "item row", "greybox"]:
		clean = clean and not forbidden in labels
	s.check(clean, "Normal gallery contains no developer/reference/implementation labels")
	await _key(s, KEY_RIGHT)
	s.check(app.quick_setup.circuit_id == &"reference" and s.root.gui_get_focus_owner() == gallery.cards[1], "Arrow browsing moves focus without silently changing selection")
	await _key(s, KEY_ENTER)
	s.check(app.quick_setup.circuit_id == &"figure_8" and app.screen == "circuits" and app.game == null, "Confirming a card selects it without launching")
	var axis := InputEventJoypadMotion.new()
	axis.axis = JOY_AXIS_LEFT_X
	axis.axis_value = -1
	s.root.push_input(axis)
	await _frames(s)
	axis = InputEventJoypadMotion.new()
	axis.axis = JOY_AXIS_LEFT_X
	axis.axis_value = 0
	s.root.push_input(axis)
	await _joy(s, JOY_BUTTON_A)
	s.check(app.quick_setup.circuit_id == &"reference", "Controller analog navigation and A select a card")
	axis = InputEventJoypadMotion.new()
	axis.axis = JOY_AXIS_LEFT_X
	axis.axis_value = 0.3
	s.root.push_input(axis)
	await _frames(s)
	s.check(s.root.gui_get_focus_owner() == gallery.cards[0] and gallery._repeat.is_stopped(), "Analog deadzone prevents focus drift")
	axis.axis_value = 1
	s.root.push_input(axis)
	await _frames(s, 28)
	s.check(s.root.gui_get_focus_owner() == gallery.cards[2], "Held analog direction repeats predictably after its initial delay")
	axis = InputEventJoypadMotion.new()
	axis.axis = JOY_AXIS_LEFT_X
	axis.axis_value = 0
	s.root.push_input(axis)
	await _frames(s, 12)
	s.check(s.root.gui_get_focus_owner() == gallery.cards[2] and gallery._repeat.is_stopped(), "Releasing the stick stops repeated navigation")
	await _joy(s, JOY_BUTTON_B)
	s.check(app.screen == "config", "Controller B returns from the gallery")
	app.show_circuits(app.quick_setup)
	await _frames(s)
	await _key(s, KEY_ESCAPE)
	s.check(app.screen == "config", "Escape returns from the gallery")
	app.show_circuits(app.quick_setup)
	await _frames(s)
	app.menu.gallery.cards[1].pressed.emit()
	app.menu.gallery.cards[1].grab_focus()
	await _key(s, KEY_DOWN)
	s.check(s.root.gui_get_focus_owner() == app.menu.gallery._start, "Down moves from the gallery to Start Race")
	await _key(s, KEY_ENTER)
	await _frames(s, 6)
	s.check(app.screen == "race" and is_instance_valid(app.game) and app.game.get_meta("circuit_id") == &"figure_8", "Separate Start action launches the selected existing circuit")
	app.return_home()
	app.show_circuits(app.quick_setup)
	await _frames(s)
	s.check(app.menu.gallery.cards[1].chosen and s.root.gui_get_focus_owner() == app.menu.gallery.cards[1], "Returning from a race restores selected circuit and visible focus")
	for row in [[1920,1080,1.0], [1280,720,1.0], [960,540,1.0], [1024,768,1.25], [960,540,1.5]]:
		s.root.size = Vector2i(row[0], row[1])
		s.root.content_scale_factor = row[2]
		await _frames(s, 5)
		gallery = app.menu.gallery
		var visible_rect := gallery.get_global_rect()
		var fits := true
		for control in gallery.focusables:
			fits = fits and visible_rect.encloses(control.get_global_rect())
		s.check(fits and not gallery._scroll.get_v_scroll_bar().visible and not gallery._scroll.get_h_scroll_bar().visible, "All cards/actions fit without scrolling at %dx%d scale %.2f" % row)
	# Six actual-curve test definitions exercise horizontal growth without
	# exposing the deferred catalog or inventing public placeholder outlines.
	var expanded := TrackRegistry.entries()
	expanded.append_array(TrackRegistry.entries())
	app.menu.page("", "")
	var more := CircuitGallery.new()
	more.configure(expanded, &"reference")
	app.menu.show_gallery(more)
	await _frames(s)
	more.cards[5].grab_focus()
	await _frames(s)
	s.check(more._scroll.scroll_horizontal > 0 and not more._scroll.get_v_scroll_bar().visible and more.get_global_rect().encloses(more._start.get_global_rect()) and more.get_global_rect().encloses(more._back.get_global_rect()), "Additional cards scroll horizontally to follow focus without pushing footer actions offscreen")
	app.show_home()
	await _frames(s)
	s.check(s.root.gui_get_focus_owner() == app.menu.focusables[0], "Gallery teardown restores the existing menu's focus")
	app.queue_free()
	await _frames(s)
	s.root.content_scale_factor = 1
	s.root.size = Vector2i(1280,720)

func _frames(s: SceneTree, count := 3) -> void:
	for i in count: await s.process_frame

func _key(s: SceneTree, code: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		s.root.push_input(event)
	await _frames(s)

func _joy(s: SceneTree, code: JoyButton) -> void:
	for pressed in [true, false]:
		var event := InputEventJoypadButton.new()
		event.button_index = code
		event.pressed = pressed
		s.root.push_input(event)
	await _frames(s)

func _visible_text(node: Node) -> String:
	var result := ""
	if node is Label and node.is_visible_in_tree(): result += node.text + "\n"
	for child in node.get_children(): result += _visible_text(child)
	return result
