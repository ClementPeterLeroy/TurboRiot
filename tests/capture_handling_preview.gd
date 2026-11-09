extends SceneTree
## Automated rendered scene inspection, not a human playtest or race record.
var main: Node3D

func _initialize() -> void:
	_start.call_deferred()

func _save(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/handling_%s.png" % label)

func _place(kart: KartController, transform: Transform3D) -> void:
	kart.safe_spawn = transform
	kart.reset_to_spawn()

func _start() -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts")
	main = load("res://scenes/main.tscn").instantiate()
	main.get_node("RaceManager").opponent_count = 0 # Isolated legacy mechanics/presentation fixture.
	root.add_child(main)
	root.size = Vector2i(1280, 720)
	var race := main.get_node("RaceManager") as RaceManager
	race.set_physics_process(false)
	race.start_race()
	race.session.advance(3)
	race.session.advance(10)
	var kart := main.get_node("Kart") as KartController
	kart.get_node("Recovery").stuck_seconds = 0
	main.get_node("HUD").debug_visible = true
	var track := main.get_node("Track") as TrackBuilder
	var offset := track.curve.get_baked_length() * 0.85
	_place(kart, Transform3D(Basis.looking_at(track.sample_forward(offset)), track.sample_center(offset) + Vector3.UP * 0.42))
	for i in 15:
		await physics_frame
	kart.velocity = -kart.global_basis.z * 19
	Input.action_press("accelerate")
	Input.action_press("steer_left", 0.8)
	Input.action_press("drift")
	for i in 110:
		await physics_frame
		if kart.drift.level(kart.config) >= 1:
			break
	await _save("drift")
	print("Rendered drift activity: active=", kart.drift.active, " charge=", kart.drift.charge)
	Input.action_release("drift")
	for i in 2:
		await physics_frame
	await _save("mini_turbo")
	print("Rendered release boost source: ", kart.boost.source)
	Input.action_release("steer_left")
	Input.action_release("accelerate")
	var features := main.get_node("TrackFeatures")
	var pad := features.get_node("Generated").get_child(0) as BoostPad
	_place(kart, Transform3D(pad.global_basis, pad.global_position + Vector3.UP * 0.42))
	for i in 20:
		await physics_frame
	await _save("boost_pad")
	var ramp := features.get_node("Generated/RunoffJump") as KartRamp
	_place(kart, ramp.global_transform * Transform3D(Basis.IDENTITY, Vector3(0, 0.42, 2)))
	for i in 15:
		await physics_frame
	kart.velocity = -ramp.global_basis.z * 18
	Input.action_press("accelerate")
	var captured_air := false
	for i in 100:
		await physics_frame
		if not captured_air and not kart.is_on_floor() and kart.position.y > ramp.global_position.y + ramp.height + 0.2:
			for frame in 6:
				await physics_frame
			await _save("airborne")
			captured_air = true
	Input.action_release("accelerate")
	await _save("landed")
	print("Rendered real ramp airborne state: ", captured_air)
	main.get_node("HUD").visible = false
	var camera := main.get_node("ChaseCamera") as Camera3D
	camera.set_process(false)
	camera.global_position = ramp.to_global(Vector3(8, 5, 3))
	camera.look_at(ramp.to_global(Vector3(0, 0.6, -3.5)))
	await _save("ramp")
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 215
	camera.position = Vector3(0, 230, 1)
	camera.look_at(Vector3.ZERO, Vector3.FORWARD)
	await _save("layout")
	camera.size = 340
	await _save("perimeter")
	print("Saved handling previews to artifacts/handling_*.png")
	quit()
