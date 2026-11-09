extends RefCounted
## Render invariants and diagnostic isolation; native multi-rate rendering is
## exercised separately by capture_presentation_probe.gd.
func run(s: SceneTree) -> void:
	var main := load("res://scenes/main.tscn").instantiate() as Node3D
	s.root.add_child(main)
	await s.process_frame
	await s.process_frame
	var kart := main.get_node("Kart") as KartController
	var camera := main.get_node("ChaseCamera") as Camera3D
	var visual := kart.get_node("Visual") as Node3D
	var diagnostic := main.get_node("PresentationDebug")
	var race := main.get_node("RaceManager") as RaceManager
	# Constant-speed follow must have the same relative pose at all rates and
	# through irregular frame pacing; this fails with endpoint-only lerp.
	var results: Array[Vector3] = []
	for rate in [60, 120, 720]:
		var position := Vector3.ZERO
		var previous := Vector3.ZERO
		for i in rate * 2:
			var next := Vector3(0, 0, -22.0 * (i + 1) / rate)
			position = camera.smooth_moving_target(position, previous, next, 1.0 / rate, 8)
			previous = next
		results.append(position - previous)
	var position := Vector3.ZERO
	var previous := Vector3.ZERO
	var elapsed := 0.0
	for i in 120:
		var delta := 1.0 / 120 if i % 2 == 0 else 3.0 / 120
		elapsed += delta
		var next := Vector3(0, 0, -22.0 * elapsed)
		position = camera.smooth_moving_target(position, previous, next, delta, 8)
		previous = next
	results.append(position - previous)
	for result in results:
		s.check(result.distance_to(Vector3(0, 0, 2.75 * (1.0 - exp(-16.0)))) < 0.0001,
			"Constant-speed camera relative position is invariant to render rate/pacing")
	race.set_physics_process(false)
	kart.set_physics_process(false)
	kart.get_node("Recovery").set_physics_process(false)
	s.check(ProjectSettings.get_setting("physics/common/physics_interpolation"), "Physics-body render interpolation is explicitly enabled")
	s.check(camera.physics_interpolation_mode == Node.PHYSICS_INTERPOLATION_MODE_OFF,
		"Per-render camera is not automatically interpolated a second time")
	s.check(visual.physics_interpolation_mode == Node.PHYSICS_INTERPOLATION_MODE_OFF,
		"Render-frame cosmetics only inherit the body's interpolation")
	var original_pose := kart.global_transform
	var original_velocity := Vector3(0, 0, 22)
	kart.velocity = original_velocity
	var original_config := kart.config
	for mode in 4:
		diagnostic.set_mode(mode)
		s.check(kart.global_transform == original_pose and kart.velocity == original_velocity and kart.config == original_config,
			"Diagnostic mode %d does not mutate physics/configuration" % mode)
		s.check(visual.cosmetics_enabled == (mode == 0 or mode == 2), "Mode selects cosmetics independently of movement")
		visual._process(1.0 / 120)
		if mode == 1 or mode == 3:
			s.check(visual.rotation == Vector3.ZERO, "Static/minimal mode disables cosmetic root pitch and roll")
		s.check(camera.diagnostic_mode == (1 if mode == 2 else (2 if mode == 3 else 0)), "Mode selects intended camera isolation")
	diagnostic.set_mode(2)
	var orientation := camera.global_basis
	camera._process(1.0 / 120)
	s.check(camera.global_basis.is_equal_approx(orientation), "Mode C freezes world camera orientation")
	diagnostic.set_mode(3)
	camera._process(1.0 / 120)
	var pose: Transform3D = camera.render_target_transform
	s.check(camera.global_position.is_equal_approx(pose.origin + pose.basis.z * camera.distance + Vector3.UP * camera.height),
		"Minimal mode follows the exact shared render pose without filtering")
	var sample: Dictionary = diagnostic.sample()
	s.check(sample.render_visual.is_equal_approx(pose * visual.transform), "Diagnostic projections use rendered parent and cosmetic child transforms")
	s.near(sample.relative_position.y, camera.height, "Relative camera position uses shared render pose")
	diagnostic.set_mode(0)
	diagnostic.start_capture()
	diagnostic._process(1.0 / 120)
	var capture_path: String = diagnostic.capture_path
	diagnostic.stop_capture()
	var capture := FileAccess.get_file_as_string(capture_path)
	s.check(capture.contains("render_visual_transform") and capture.contains("relative_pitch_deg") and capture.contains("A Normal"),
		"Optional CSV captures render/physics transforms and relative screen-angle measurements")
	var hud := main.get_node("HUD") as RaceHUD
	hud.debug_visible = true
	hud._process(1.0 / 120)
	s.check(hud.debug_label.text.contains("A Normal") and hud.debug_label.text.contains("F4 mode"),
		"F3 debug panel exposes active A/B mode and diagnostic shortcuts")
	race.return_to_ready()
	s.check(camera.global_position.is_equal_approx(kart.position + kart.basis.z * camera.distance + Vector3.UP * camera.height),
		"Reset immediately snaps camera without retaining an old interpolated pose")
	main.queue_free()
	await s.process_frame
