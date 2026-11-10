extends SceneTree
## Scripted native review captures; not developer visual acceptance.
class TestInput extends DrivingInput:
	var command := DrivingCommand.new()
	func get_command() -> DrivingCommand: return command

var main: Node3D
var kart: KartController
var track: TrackBuilder
var input: TestInput
var caption: Label

func _initialize() -> void: _run.call_deferred()

func _save(name: String, text: String) -> void:
	caption.text = text
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/balance_%s.png" % name)

func _place(side := 0.0) -> void:
	var offset := track.curve.get_baked_length() * 0.85
	var forward := track.sample_forward(offset)
	var at := track.sample_center(offset) + forward.cross(Vector3.UP) * side
	at.y = -0.08 if absf(side) > track.road_width / 2 + 1.2 else 0.04
	kart.safe_spawn = Transform3D(Basis.looking_at(forward), at + Vector3.UP * 0.42)
	kart.reset_to_spawn()
	input.command = DrivingCommand.new()
	for i in 30: await physics_frame

func _run() -> void:
	root.size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute("res://artifacts")
	main = load("res://scenes/main.tscn").instantiate()
	main.get_node("RaceManager").opponent_count = 0
	main.get_node("Items").enabled = false
	root.add_child(main)
	var race := main.get_node("RaceManager") as RaceManager
	race.set_physics_process(false)
	race.start_race()
	race.session.advance(3)
	race.session.advance(1) # Clear the GO overlay in this paused-race capture.
	kart = race.kart
	track = race.track
	kart.get_node("Recovery").set_physics_process(false)
	input = TestInput.new()
	kart.add_child(input)
	kart.input_provider = input
	var layer := CanvasLayer.new()
	layer.layer = 20
	root.add_child(layer)
	caption = Label.new()
	caption.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	caption.offset_left = 30
	caption.offset_top = -65
	caption.offset_right = 1250
	caption.offset_bottom = -35
	caption.add_theme_color_override("font_shadow_color", Color.BLACK)
	caption.add_theme_constant_override("shadow_offset_x", 2)
	caption.add_theme_constant_override("shadow_offset_y", 2)
	caption.add_theme_font_size_override("font_size", 21)
	layer.add_child(caption)
	await _place()
	kart.velocity = -kart.global_basis.z * 22
	input.command = DrivingCommand.new(1)
	kart.activate_item_boost(&"mushroom", 1.4, 1.8)
	for i in 6: await physics_frame
	await _save("mushroom_burst_720", "Mushroom activation: brief radial burst, 1280 x 720")
	for i in 40: await physics_frame
	await _save("mushroom_sustain_720", "Mushroom: sustained edge streaks, centre kept clear")
	root.size = Vector2i(1920, 1080)
	main.get_node("ChaseCamera").fov = 85
	main.get_node("ChaseCamera").distance = 9.0
	main.get_node("ChaseCamera").height = 5.5
	for i in 3: await process_frame
	kart.activate_item_boost(&"mushroom", 1.4, 1.8)
	for i in 6: await physics_frame
	await _save("burst_1080", "Mushroom: 1920 x 1080, changed camera FOV")
	root.size = Vector2i(1280, 720)
	main.get_node("ChaseCamera").fov = 68
	main.get_node("ChaseCamera").distance = 7.5
	main.get_node("ChaseCamera").height = 4.5
	kart.boost.clear()
	for i in 75: await physics_frame
	await _save("fade", "After expiry: streaks fade away")
	await _place()
	kart.velocity = -kart.global_basis.z * 20
	input.command = DrivingCommand.new(1)
	kart.activate_directional_boost(-kart.global_basis.z, 1.5, 1.4)
	for i in 6: await physics_frame
	await _save("pad_burst", "Speed-pad activation: shared radial feedback")
	for index in [1, 3]:
		await _place()
		kart.velocity = -kart.global_basis.z * 20
		input.command = DrivingCommand.new(1)
		var item: ItemDefinition = ItemCatalog.ITEMS[index]
		kart.receive_item_hit(Vector3.ZERO, item.hit_seconds, item.speed_multiplier, item.grip_multiplier,
			item.momentum_retention, item.spin_degrees, item.hit_control, item.control_recovery_seconds)
		for i in roundi(item.hit_seconds * 60 * 0.5): await physics_frame
		await _save("spin_%s_half" % str(item.identifier), "%s: actual body %.0f degrees, %.1f km/h" % [item.display_name, rad_to_deg(kart.effects.spin_angle), kart.velocity.length() * 3.6])
		for i in roundi(item.hit_seconds * 60 * 0.5): await physics_frame
		await _save("spin_%s_end" % str(item.identifier), "%s: completed %.0f degrees; smooth control recovery" % [item.display_name, rad_to_deg(kart.effects.spin_angle)])
	await _place(-9.5)
	input.command = DrivingCommand.new(1)
	kart.activate_item_boost(&"mushroom", 1.4, 1.8)
	for i in 65: await physics_frame
	main.get_node("HUD").debug_visible = true
	await _save("sand_mushroom", "Mushroom on sand: surface detection remains active")
	main.queue_free()
	layer.queue_free()
	await process_frame
	quit()
